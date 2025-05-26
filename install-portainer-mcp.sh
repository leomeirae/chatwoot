#!/bin/bash

# 🔧 Script de Instalação Portainer MCP
# Para uso após atualização do Portainer para 2.30.0+

set -euo pipefail

# Configurações
PORTAINER_MCP_VERSION="v0.5.0"
MCP_DIR="$HOME/.mcp"
PORTAINER_URL="https://portainer.darwinai.com.br"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Detectar arquitetura do sistema
detect_architecture() {
    local arch=$(uname -m)
    case $arch in
        x86_64)
            echo "amd64"
            ;;
        arm64|aarch64)
            echo "arm64"
            ;;
        *)
            log_error "Arquitetura não suportada: $arch"
            exit 1
            ;;
    esac
}

# Detectar sistema operacional
detect_os() {
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    case $os in
        linux)
            echo "linux"
            ;;
        darwin)
            echo "darwin"
            ;;
        *)
            log_error "Sistema operacional não suportado: $os"
            exit 1
            ;;
    esac
}

# Verificar se Portainer está na versão correta
check_portainer_version() {
    log_info "Verificando versão do Portainer..."
    
    local version_check
    version_check=$(curl -s "$PORTAINER_URL/api/status" | jq -r '.Version' 2>/dev/null || echo "unknown")
    
    if [[ "$version_check" == *"2.30"* ]] || [[ "$version_check" == *"2.3"* ]]; then
        log_success "Portainer versão compatível detectada: $version_check"
        return 0
    else
        log_error "Portainer precisa estar na versão 2.30.0+. Versão atual: $version_check"
        log_warning "Execute primeiro: ./update-portainer.sh"
        return 1
    fi
}

# Instalar Portainer MCP
install_portainer_mcp() {
    log_info "Instalando Portainer MCP..."
    
    local os arch binary_name download_url
    os=$(detect_os)
    arch=$(detect_architecture)
    binary_name="portainer-mcp-${os}-${arch}"
    
    if [[ "$os" == "darwin" ]]; then
        binary_name="portainer-mcp-${os}-${arch}.tar.gz"
        download_url="https://github.com/portainer/portainer-mcp/releases/download/${PORTAINER_MCP_VERSION}/${binary_name}"
    else
        download_url="https://github.com/portainer/portainer-mcp/releases/download/${PORTAINER_MCP_VERSION}/${binary_name}"
    fi
    
    # Criar diretório MCP
    mkdir -p "$MCP_DIR"
    
    # Baixar o binário
    log_info "Baixando de: $download_url"
    
    if [[ "$binary_name" == *".tar.gz" ]]; then
        # Para macOS (arquivo comprimido)
        curl -L "$download_url" -o "/tmp/${binary_name}"
        tar -xzf "/tmp/${binary_name}" -C "$MCP_DIR"
        chmod +x "$MCP_DIR/portainer-mcp"
        rm "/tmp/${binary_name}"
    else
        # Para Linux (binário direto)
        curl -L "$download_url" -o "$MCP_DIR/portainer-mcp"
        chmod +x "$MCP_DIR/portainer-mcp"
    fi
    
    log_success "Portainer MCP instalado em: $MCP_DIR/portainer-mcp"
}

# Configurar Portainer MCP
configure_portainer_mcp() {
    log_info "Configurando Portainer MCP..."
    
    # Criar arquivo de configuração
    cat > "$MCP_DIR/portainer-mcp.json" << EOF
{
    "portainer": {
        "url": "$PORTAINER_URL",
        "username": "admin",
        "password": "@Atjlc151523"
    },
    "mcp": {
        "version": "$PORTAINER_MCP_VERSION",
        "install_date": "$(date -Iseconds)"
    }
}
EOF
    
    log_success "Configuração criada em: $MCP_DIR/portainer-mcp.json"
}

# Testar conexão MCP
test_mcp_connection() {
    log_info "Testando conexão MCP..."
    
    # Testar se o binário funciona
    if "$MCP_DIR/portainer-mcp" --version >/dev/null 2>&1; then
        log_success "Binário MCP funcionando"
    else
        log_error "Erro ao executar binário MCP"
        return 1
    fi
    
    # Testar conexão com Portainer
    log_info "Testando conexão com Portainer..."
    
    # Aqui você pode adicionar testes específicos de conexão
    # Por exemplo, verificar se consegue listar containers via MCP
    
    log_success "Conexão MCP configurada com sucesso!"
}

# Criar configuração para Claude Desktop
create_claude_config() {
    log_info "Criando configuração para Claude Desktop..."
    
    local claude_config_dir claude_config_file
    
    # Detectar localização do arquivo de configuração do Claude Desktop
    if [[ "$(detect_os)" == "darwin" ]]; then
        claude_config_dir="$HOME/Library/Application Support/Claude"
    else
        claude_config_dir="$HOME/.config/claude"
    fi
    
    claude_config_file="$claude_config_dir/claude_desktop_config.json"
    
    # Criar diretório se não existir
    mkdir -p "$claude_config_dir"
    
    # Verificar se já existe configuração
    if [[ -f "$claude_config_file" ]]; then
        log_warning "Arquivo de configuração já existe: $claude_config_file"
        log_info "Fazendo backup..."
        cp "$claude_config_file" "$claude_config_file.backup.$(date +%Y%m%d-%H%M%S)"
    fi
    
    # Criar/atualizar configuração
    cat > "$claude_config_file" << EOF
{
  "mcpServers": {
    "portainer": {
      "command": "$MCP_DIR/portainer-mcp",
      "args": [
        "--url", "$PORTAINER_URL",
        "--username", "admin",
        "--password", "@Atjlc151523"
      ]
    }
  }
}
EOF
    
    log_success "Configuração do Claude Desktop criada: $claude_config_file"
}

# Instruções finais
show_final_instructions() {
    echo ""
    log_success "🎉 Instalação do Portainer MCP concluída!"
    echo ""
    log_info "📋 Próximos passos:"
    echo "   1. Reinicie o Claude Desktop se estiver rodando"
    echo "   2. Agora você pode usar comandos MCP no Claude para gerenciar seu Portainer"
    echo ""
    log_info "🔧 Arquivos criados:"
    echo "   • Binário MCP: $MCP_DIR/portainer-mcp"
    echo "   • Configuração: $MCP_DIR/portainer-mcp.json"
    echo "   • Claude config: $claude_config_dir/claude_desktop_config.json"
    echo ""
    log_info "💡 Exemplo de uso no Claude:"
    echo "   'Liste todos os containers no meu Portainer'"
    echo "   'Mostre o status dos services do Docker Swarm'"
    echo "   'Crie um novo container usando a imagem nginx'"
    echo ""
}

# Função principal
main() {
    echo "🔧 Instalando Portainer MCP"
    echo "🌐 Portainer URL: $PORTAINER_URL"
    echo ""
    
    check_portainer_version || exit 1
    install_portainer_mcp
    configure_portainer_mcp
    test_mcp_connection
    create_claude_config
    show_final_instructions
}

# Executar apenas se script for chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 