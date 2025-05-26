#!/bin/bash

# 🚀 Script de Atualização Portainer Self-Hosted
# De: 2.27.6 LTS → Para: 2.30.0 (Suporte MCP)
# URL: https://portainer.darwinai.com.br

set -euo pipefail

# Configurações
PORTAINER_CURRENT_VERSION="2.27.6"
PORTAINER_NEW_VERSION="2.30.0"
BACKUP_DIR="./portainer-backup-$(date +%Y%m%d-%H%M%S)"
PORTAINER_CONTAINER_NAME="portainer"
AGENT_CONTAINER_NAME="portainer_agent"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções auxiliares
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

# Função para verificar se comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Verificar prerequisites
check_prerequisites() {
    log_info "Verificando pré-requisitos..."
    
    if ! command_exists docker; then
        log_error "Docker não está instalado!"
        exit 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker não está executando ou sem permissões!"
        exit 1
    fi
    
    log_success "Pré-requisitos verificados"
}

# Detectar como Portainer está rodando
detect_portainer_deployment() {
    log_info "Detectando deployment do Portainer..."
    
    # Verificar se há container do Portainer
    if docker ps -a --format "table {{.Names}}" | grep -q "portainer"; then
        PORTAINER_CONTAINER_NAME=$(docker ps -a --format "table {{.Names}}" | grep portainer | head -1)
        log_success "Container encontrado: $PORTAINER_CONTAINER_NAME"
        return 0
    fi
    
    # Verificar se há service no Swarm
    if docker service ls --format "table {{.Name}}" 2>/dev/null | grep -q "portainer"; then
        log_warning "Portainer rodando como Service no Swarm - verificando se é self-hosted"
        DEPLOYMENT_TYPE="swarm_service"
        return 0
    fi
    
    log_error "Não foi possível detectar deployment do Portainer!"
    return 1
}

# Criar backup
create_backup() {
    log_info "Criando backup do Portainer..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup via API do Portainer
    log_info "Fazendo backup via API..."
    curl -X GET "https://portainer.darwinai.com.br/api/backup" \
         -H "X-API-Key: YOUR_API_KEY" \
         -o "$BACKUP_DIR/portainer-backup.tar.gz" 2>/dev/null || {
        log_warning "Backup via API falhou, tentando backup dos volumes..."
    }
    
    # Backup dos volumes Docker
    log_info "Fazendo backup dos volumes..."
    
    # Descobrir volumes do Portainer
    PORTAINER_VOLUMES=$(docker inspect "$PORTAINER_CONTAINER_NAME" 2>/dev/null | jq -r '.[0].Mounts[].Name // empty' | grep -v "^$" || true)
    
    if [ -n "$PORTAINER_VOLUMES" ]; then
        for volume in $PORTAINER_VOLUMES; do
            log_info "Backup do volume: $volume"
            docker run --rm -v "$volume":/data -v "$(pwd)/$BACKUP_DIR":/backup alpine:latest \
                tar czf "/backup/volume-$volume.tar.gz" -C /data . || true
        done
    fi
    
    # Backup da configuração do container
    docker inspect "$PORTAINER_CONTAINER_NAME" > "$BACKUP_DIR/container-config.json" 2>/dev/null || true
    
    log_success "Backup criado em: $BACKUP_DIR"
}

# Parar Portainer
stop_portainer() {
    log_info "Parando Portainer..."
    
    if docker ps --format "table {{.Names}}" | grep -q "$PORTAINER_CONTAINER_NAME"; then
        docker stop "$PORTAINER_CONTAINER_NAME" || true
        log_success "Portainer parado"
    else
        log_warning "Portainer não estava rodando"
    fi
}

# Atualizar imagem
update_image() {
    log_info "Baixando nova imagem do Portainer..."
    
    # Baixar imagem Business Edition
    docker pull portainer/portainer-ee:$PORTAINER_NEW_VERSION
    
    log_success "Nova imagem baixada: portainer/portainer-ee:$PORTAINER_NEW_VERSION"
}

# Recriar container
recreate_container() {
    log_info "Recriando container do Portainer..."
    
    # Remover container antigo
    docker rm "$PORTAINER_CONTAINER_NAME" 2>/dev/null || true
    
    # Detectar volumes e portas do container antigo
    VOLUME_MOUNTS=""
    PORT_MAPPINGS=""
    
    if [ -f "$BACKUP_DIR/container-config.json" ]; then
        # Extrair configurações do backup
        VOLUME_MOUNTS=$(jq -r '.[0].Mounts[] | "-v " + (.Source // .Name) + ":" + .Destination' "$BACKUP_DIR/container-config.json" | tr '\n' ' ')
        PORT_MAPPINGS=$(jq -r '.[0].NetworkSettings.Ports | to_entries[] | "-p " + .value[0].HostPort + ":" + (.key | split("/")[0])' "$BACKUP_DIR/container-config.json" 2>/dev/null | tr '\n' ' ' || echo "-p 9000:9000")
    else
        # Configuração padrão
        VOLUME_MOUNTS="-v portainer_data:/data"
        PORT_MAPPINGS="-p 9000:9000"
    fi
    
    # Criar novo container
    docker run -d \
        --name "$PORTAINER_CONTAINER_NAME" \
        --restart=always \
        $PORT_MAPPINGS \
        $VOLUME_MOUNTS \
        -v /var/run/docker.sock:/var/run/docker.sock \
        portainer/portainer-ee:$PORTAINER_NEW_VERSION
    
    log_success "Container recriado com sucesso"
}

# Atualizar Agent se necessário
update_agent() {
    log_info "Verificando se precisa atualizar Agent..."
    
    if docker ps --format "table {{.Names}}" | grep -q "agent"; then
        AGENT_CONTAINER=$(docker ps --format "table {{.Names}}" | grep agent | head -1)
        
        log_info "Atualizando Portainer Agent..."
        
        # Parar agent
        docker stop "$AGENT_CONTAINER" || true
        docker rm "$AGENT_CONTAINER" || true
        
        # Baixar nova imagem do agent
        docker pull portainer/agent:$PORTAINER_NEW_VERSION
        
        # Recriar agent (configuração típica para Swarm)
        docker run -d \
            --name portainer_agent \
            --restart=always \
            -p 9001:9001 \
            -v /var/run/docker.sock:/var/run/docker.sock \
            -v /var/lib/docker/volumes:/var/lib/docker/volumes \
            portainer/agent:$PORTAINER_NEW_VERSION
        
        log_success "Agent atualizado"
    else
        log_info "Nenhum Agent encontrado - ok para self-hosted"
    fi
}

# Verificar se atualização funcionou
verify_update() {
    log_info "Verificando se atualização funcionou..."
    
    # Aguardar container iniciar
    sleep 10
    
    # Verificar se está rodando
    if docker ps --format "table {{.Names}}" | grep -q "$PORTAINER_CONTAINER_NAME"; then
        log_success "Portainer está rodando!"
        
        # Verificar versão via API
        sleep 5
        VERSION_CHECK=$(curl -s "https://portainer.darwinai.com.br/api/status" | jq -r '.Version' 2>/dev/null || echo "unknown")
        
        if [[ "$VERSION_CHECK" == *"$PORTAINER_NEW_VERSION"* ]]; then
            log_success "✅ Atualização completada! Versão: $VERSION_CHECK"
            log_success "🌐 Acesse: https://portainer.darwinai.com.br"
        else
            log_warning "Versão detectada: $VERSION_CHECK"
        fi
    else
        log_error "Container não está rodando!"
        return 1
    fi
}

# Função principal
main() {
    echo "🚀 Iniciando atualização do Portainer Self-Hosted"
    echo "📍 De: $PORTAINER_CURRENT_VERSION → Para: $PORTAINER_NEW_VERSION"
    echo "🌐 URL: https://portainer.darwinai.com.br"
    echo ""
    
    read -p "Deseja continuar? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Cancelado pelo usuário"
        exit 0
    fi
    
    check_prerequisites
    detect_portainer_deployment
    create_backup
    stop_portainer
    update_image
    recreate_container
    update_agent
    verify_update
    
    echo ""
    log_success "🎉 Atualização concluída com sucesso!"
    log_info "📁 Backup salvo em: $BACKUP_DIR"
    log_info "🔧 Agora você pode instalar o Portainer MCP!"
    echo ""
}

# Executar apenas se script for chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 