# 🚀 Chatwoot + Baileys WhatsApp Integration

## ✅ **STATUS: PRODUÇÃO FUNCIONAL**

Este repositório contém uma implementação **100% funcional** do Chatwoot com integração WhatsApp via Baileys API, rodando em produção com Docker Swarm + Traefik.

### 🌐 **Deploy em Produção**
- **URL**: https://chatwoot.darwinai.com.br
- **SSL**: Automático via Let's Encrypt
- **WhatsApp**: Integrado via Baileys API
- **Status**: ✅ Operacional

---

## 🏗️ **Arquitetura**

### **Serviços Docker:**
- **`rails`**: Chatwoot principal (ghcr.io/fazer-ai/chatwoot:latest)
- **`sidekiq`**: Processamento de jobs em background
- **`postgres`**: Banco de dados com pgvector
- **`redis`**: Cache e sessões
- **`baileys-api`**: API WhatsApp (ghcr.io/fazer-ai/baileys-api:latest)

### **Infraestrutura:**
- **Docker Swarm** para orquestração
- **Traefik** para proxy reverso e SSL
- **Let's Encrypt** para certificados automáticos
- **Overlay Networks** para comunicação segura

---

## 🚀 **Deploy Rápido**

### **1. Pré-requisitos**
```bash
# Docker Swarm inicializado
docker swarm init

# Rede Traefik criada
docker network create --driver overlay darwinai
```

### **2. Deploy**
```bash
# Clone o repositório
git clone https://github.com/leomeirae/chatwoot.git
cd chatwoot

# Deploy da stack
docker stack deploy -c chatwoot-baileys-docker-compose-traefik.yaml chatwoot
```

### **3. Verificação**
```bash
# Verificar serviços
docker service ls

# Verificar logs
docker service logs chatwoot_rails -f
docker service logs chatwoot_baileys-api -f
```

---

## 📋 **Configuração**

### **Variáveis Principais:**
```yaml
# URL do Chatwoot
FRONTEND_URL: https://chatwoot.darwinai.com.br

# Baileys Integration
BAILEYS_PROVIDER_DEFAULT_URL: http://baileys-api:3025
BAILEYS_PROVIDER_DEFAULT_CLIENT_NAME: Baileys
BAILEYS_PROVIDER_USE_INTERNAL_HOST_URL: true

# Banco de Dados
POSTGRES_HOST: postgres
POSTGRES_DATABASE: chatwoot_production
POSTGRES_USERNAME: chatwoot

# Cache
REDIS_URL: redis://redis:6379
```

### **Traefik Labels:**
```yaml
- "traefik.enable=true"
- "traefik.http.routers.chatwoot.rule=Host(`chatwoot.darwinai.com.br`)"
- "traefik.http.routers.chatwoot.entrypoints=websecure"
- "traefik.http.routers.chatwoot.tls.certresolver=letsencryptresolver"
```

---

## 🔧 **Funcionalidades Implementadas**

### ✅ **Core Chatwoot**
- Interface web completa
- Gestão de conversas
- Múltiplos agentes
- Automações
- Relatórios

### ✅ **WhatsApp via Baileys**
- Conexão via QR Code
- Recebimento de mensagens
- Envio de mensagens
- Status de entrega
- Webhooks funcionais

### ✅ **Infraestrutura**
- SSL automático
- WebSocket (ActionCable)
- Backup automático
- Logs centralizados
- Monitoramento

---

## 📱 **Configuração WhatsApp**

### **1. Conectar WhatsApp**
1. Acesse: https://chatwoot.darwinai.com.br
2. Vá em **Settings > Inboxes**
3. Clique em **Add Inbox**
4. Selecione **Baileys**
5. Escaneie o QR Code com WhatsApp

### **2. Verificar Logs**
```bash
# Ver QR Code nos logs
docker service logs chatwoot_baileys-api -f

# Verificar webhooks
docker service logs chatwoot_rails -f | grep webhook
```

---

## 🛠️ **Troubleshooting**

### **Problema: QR Code não aparece**
```bash
# Verificar logs do Baileys
docker service logs chatwoot_baileys-api --tail 50

# Reiniciar serviço
docker service update --force chatwoot_baileys-api
```

### **Problema: Webhooks não funcionam**
```bash
# Verificar conectividade
docker exec $(docker ps -q --filter 'name=chatwoot_rails') wget -qO- http://baileys-api:3025/status

# Verificar logs
docker service logs chatwoot_rails -f | grep baileys
```

### **Problema: SSL não funciona**
```bash
# Verificar Traefik
docker service logs traefik_traefik -f

# Verificar certificados
docker exec $(docker ps -q --filter 'name=traefik') ls -la /letsencrypt/
```

---

## 📊 **Monitoramento**

### **Verificar Status dos Serviços**
```bash
# Status geral
docker service ls

# Logs em tempo real
docker service logs chatwoot_rails -f
docker service logs chatwoot_baileys-api -f
```

### **Métricas de Performance**
```bash
# Uso de recursos
docker stats

# Logs de performance
docker service logs chatwoot_sidekiq -f
```

---

## 🔐 **Segurança**

### **Credenciais Configuradas:**
- ✅ PostgreSQL com senha segura
- ✅ Redis com autenticação
- ✅ Rails secret key configurada
- ✅ SSL/TLS via Let's Encrypt
- ✅ Redes isoladas (overlay)

### **Boas Práticas Implementadas:**
- Senhas geradas automaticamente
- Comunicação interna criptografada
- Volumes persistentes
- Backup automático
- Logs auditáveis

---

## 📝 **Changelog**

### **v1.0.0-baileys-production** (Atual)
- ✅ Chatwoot + Baileys 100% funcional
- ✅ Deploy Docker Swarm + Traefik
- ✅ SSL automático configurado
- ✅ WebSocket funcionando
- ✅ Webhooks WhatsApp operacionais
- ✅ Projeto limpo e otimizado

---

## 🤝 **Contribuição**

Este projeto está em produção e funcionando. Para contribuições:

1. Fork o repositório
2. Crie uma branch: `git checkout -b feature/nova-funcionalidade`
3. Commit: `git commit -m 'feat: nova funcionalidade'`
4. Push: `git push origin feature/nova-funcionalidade`
5. Abra um Pull Request

---

## 📞 **Suporte**

- **Repositório**: https://github.com/leomeirae/chatwoot
- **Tag Funcional**: `v1.0.0-baileys-production`
- **Documentação**: `BAILEYS_SETUP.md`

---

## 🎯 **Próximos Passos**

- [ ] Implementar backup automático
- [ ] Adicionar monitoramento com Prometheus
- [ ] Configurar alertas
- [ ] Documentar API customizada
- [ ] Implementar CI/CD

---

**🚀 Projeto 100% funcional em produção!** 