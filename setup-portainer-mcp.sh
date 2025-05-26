#!/bin/bash

# 🚀 Setup Completo Portainer + MCP
# Atualiza Portainer 2.27.6 → 2.30.0 + Instala MCP

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_step() {
    echo -e "${PURPLE}🔄 $1${NC}"
}

# Banner
show_banner() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                🚀 PORTAINER + MCP SETUP 🚀                   ║"
    echo "║                                                              ║"
    echo "║  • Atualiza Portainer: 2.27.6 LTS → 2.30.0                  ║"
    echo "║  • Instala Portainer MCP v0.5.0                             ║"
    echo "║  • Configura integração com Claude Desktop                  ║"
    echo "║                                                              ║"
    echo "║  🌐 URL: https://portainer.darwinai.com.br                   ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Verificar dependências
check_dependencies() {
    log_step "Verificando dependências..."
    
    local missing_deps=()
    
    # Verificar comandos necessários
    local required_commands=("docker" "curl" "jq")
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Dependências faltando: ${missing_deps[*]}"
        log_info "Para instalar no macOS: brew install ${missing_deps[*]}"
        log_info "Para instalar no Ubuntu: sudo apt-get install ${missing_deps[*]}"
        exit 1
    fi
    
    log_success "Todas as dependências estão instaladas"
}

# Verificar se scripts existem
check_scripts() {
    log_step "Verificando scripts necessários..."
    
    if [[ ! -f "update-portainer.sh" ]]; then
        log_error "Script update-portainer.sh não encontrado!"
        exit 1
    fi
    
    if [[ ! -f "install-portainer-mcp.sh" ]]; then
        log_error "Script install-portainer-mcp.sh não encontrado!"
        exit 1
    fi
    
    # Tornar scripts executáveis
    chmod +x update-portainer.sh install-portainer-mcp.sh
    
    log_success "Scripts verificados e prontos"
}

# Confirmar execução
confirm_execution() {
    echo ""
    log_warning "ATENÇÃO: Este processo irá:"
    echo "   • Parar temporariamente o Portainer atual"
    echo "   • Fazer backup completo das configurações"
    echo "   • Atualizar para Portainer 2.30.0"
    echo "   • Instalar e configurar Portainer MCP"
    echo "   • Modificar configuração do Claude Desktop"
    echo ""
    log_warning "Certifique-se de que:"
    echo "   • Você tem acesso SSH ao servidor do Portainer"
    echo "   • Não há operações críticas rodando no Portainer"
    echo "   • Você fez backup manual se necessário"
    echo ""
    
    read -p "Deseja continuar com o setup completo? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Setup cancelado pelo usuário"
        exit 0
    fi
}

# Executar atualização do Portainer
run_portainer_update() {
    log_step "Executando atualização do Portainer..."
    
    echo ""
    log_info "═══════════════════════════════════════════════════════════"
    log_info "                 ATUALIZANDO PORTAINER                    "
    log_info "═══════════════════════════════════════════════════════════"
    echo ""
    
    if ./update-portainer.sh; then
        log_success "Atualização do Portainer concluída!"
    else
        log_error "Falha na atualização do Portainer!"
        log_warning "Verifique os logs acima e tente novamente"
        exit 1
    fi
}

# Executar instalação do MCP
run_mcp_installation() {
    log_step "Executando instalação do Portainer MCP..."
    
    echo ""
    log_info "═══════════════════════════════════════════════════════════"
    log_info "                INSTALANDO PORTAINER MCP                  "
    log_info "═══════════════════════════════════════════════════════════"
    echo ""
    
    # Aguardar um pouco para Portainer estabilizar
    log_info "Aguardando Portainer estabilizar..."
    sleep 30
    
    if ./install-portainer-mcp.sh; then
        log_success "Instalação do Portainer MCP concluída!"
    else
        log_error "Falha na instalação do MCP!"
        log_warning "Portainer foi atualizado, mas MCP falhou"
        log_info "Você pode tentar novamente executando: ./install-portainer-mcp.sh"
        exit 1
    fi
}

# Teste final
run_final_tests() {
    log_step "Executando testes finais..."
    
    # Verificar se Portainer está respondendo
    log_info "Testando conexão com Portainer..."
    if curl -s "https://portainer.darwinai.com.br/api/status" >/dev/null; then
        log_success "Portainer está respondendo"
    else
        log_warning "Portainer pode não estar totalmente inicializado ainda"
    fi
    
    # Verificar se MCP está instalado
    log_info "Verificando instalação do MCP..."
    if [[ -f "$HOME/.mcp/portainer-mcp" ]]; then
        log_success "Binário MCP encontrado"
    else
        log_warning "Binário MCP não encontrado"
    fi
    
    # Verificar configuração do Claude
    local claude_config
    if [[ "$(uname -s)" == "Darwin" ]]; then
        claude_config="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
    else
        claude_config="$HOME/.config/claude/claude_desktop_config.json"
    fi
    
    if [[ -f "$claude_config" ]]; then
        log_success "Configuração do Claude Desktop encontrada"
    else
        log_warning "Configuração do Claude Desktop não encontrada"
    fi
}

# Instruções finais
show_final_summary() {
    echo ""
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    🎉 SETUP CONCLUÍDO! 🎉                    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    log_success "Portainer atualizado para versão 2.30.0+"
    log_success "Portainer MCP v0.5.0 instalado e configurado"
    log_success "Integração com Claude Desktop configurada"
    
    echo ""
    log_info "🔗 Acesso ao Portainer: https://portainer.darwinai.com.br"
    log_info "👤 Usuário: admin"
    log_info "🔑 Senha: @Atjlc151523"
    
    echo ""
    log_info "📋 Próximos passos:"
    echo "   1. Acesse seu Portainer e verifique se está funcionando"
    echo "   2. Reinicie o Claude Desktop se estiver rodando"
    echo "   3. Teste comandos MCP no Claude:"
    echo "      • 'Liste todos os containers do meu Portainer'"
    echo "      • 'Mostre o status dos services do Docker Swarm'"
    echo "      • 'Crie um container nginx'"
    
    echo ""
    log_info "📁 Arquivos importantes:"
    echo "   • Backup Portainer: ./portainer-backup-*/"
    echo "   • MCP Binary: ~/.mcp/portainer-mcp"
    echo "   • Configuração MCP: ~/.mcp/portainer-mcp.json"
    
    if [[ "$(uname -s)" == "Darwin" ]]; then
        echo "   • Claude Config: ~/Library/Application Support/Claude/claude_desktop_config.json"
    else
        echo "   • Claude Config: ~/.config/claude/claude_desktop_config.json"
    fi
    
    echo ""
    log_warning "💡 Dica: Se algo não funcionar, verifique os logs acima e:"
    echo "   • Reinicie o Claude Desktop"
    echo "   • Aguarde alguns minutos para Portainer estabilizar"
    echo "   • Teste comandos simples primeiro"
    
    echo ""
}

# Função principal
main() {
    show_banner
    check_dependencies
    check_scripts
    confirm_execution
    
    echo ""
    log_step "Iniciando setup completo..."
    
    run_portainer_update
    run_mcp_installation
    run_final_tests
    show_final_summary
    
    log_success "🎉 Setup Portainer + MCP concluído com sucesso!"
}

# Executar apenas se script for chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 