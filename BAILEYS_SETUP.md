# 🚀 Guia de Setup do Baileys API no Portainer

## 📋 Pré-requisitos

1. Portainer instalado e funcionando
2. Rede Docker `chatwoot-network` criada (onde seu Chatwoot já está rodando)

## 🔧 Passo 1: Gerar Variáveis de Ambiente

### 🔑 BAILEYS_API_KEY
Esta é uma chave de autenticação que você cria para comunicação entre Chatwoot e Baileys:

```bash
# Opção 1: Usando openssl
openssl rand -hex 32

# Opção 2: Usando uuidgen
uuidgen

# Opção 3: String personalizada (mínimo 32 caracteres)
# Exemplo: baileys_api_key_2024_super_secure_string_123456789
```

### 🔒 REDIS_PASSWORD
Senha para proteger o Redis do Baileys:

```bash
# Gerar senha segura
openssl rand -base64 32

# Ou criar uma senha personalizada forte
# Exemplo: MyRedisPassword2024!@#$%
```

### 🌐 CHATWOOT_URL
URL do seu Chatwoot (onde ele está rodando):

```bash
# Exemplo se estiver no mesmo servidor:
CHATWOOT_URL=http://chatwoot:3000

# Ou se tiver domínio próprio:
CHATWOOT_URL=https://meu-chatwoot.com.br
```

## 🐳 Passo 2: Deploy no Portainer

### 1. Acesse seu Portainer
- Vá em **Stacks** → **Add Stack**

### 2. Configure a Stack
- **Name**: `baileys-api`
- **Build method**: `Web editor`
- Cole o conteúdo do arquivo `docker-compose.baileys.yml`

### 3. Configure as Variáveis de Ambiente
Na seção **Environment variables**, adicione:

```env
REDIS_PASSWORD=SuaSenhaRedisAqui123!@#
BAILEYS_API_KEY=SuaChaveBaileysAqui456def789ghi012jkl345mno
CHATWOOT_URL=http://chatwoot:3000
```

### 4. Deploy
- Clique em **Deploy the stack**

## ⚙️ Passo 3: Configurar Canal no Chatwoot

### 1. Acesse o Admin do Chatwoot
- Vá em **Settings** → **Inboxes** → **Add Inbox**

### 2. Selecione WhatsApp
- Escolha **WhatsApp** como canal

### 3. Configure o Provider
- **Provider**: Selecione `baileys`
- **Phone Number**: Seu número com código do país (ex: +5511999999999)
- **API Key**: A mesma `BAILEYS_API_KEY` que você gerou
- **Base URL**: `http://baileys-api:3025` (se estiver na mesma rede Docker)

### 4. Webhook Configuration
- **Webhook URL**: Será configurado automaticamente pelo Chatwoot
- O Baileys enviará eventos para: `http://chatwoot:3000/webhooks/whatsapp`

## 🔗 Passo 4: Conectar WhatsApp

### 1. Acesse o Baileys API
- Abra: `http://seu-servidor:3025/swagger`
- Ou use a API diretamente

### 2. Criar Conexão
```bash
curl -X POST "http://seu-servidor:3025/connections/+5511999999999" \
  -H "x-api-key: SuaChaveBaileysAqui456def789ghi012jkl345mno" \
  -H "Content-Type: application/json"
```

### 3. Escanear QR Code
- O QR code aparecerá nos logs do container `baileys-api`
- Escaneie com seu WhatsApp

## 🔍 Verificação

### 1. Verificar Status dos Containers
```bash
docker ps | grep baileys
```

### 2. Verificar Logs
```bash
docker logs baileys-api
docker logs baileys-redis
```

### 3. Testar API
```bash
curl -H "x-api-key: SuaChaveBaileysAqui" http://seu-servidor:3025/status
```

## 🚨 Troubleshooting

### Container não inicia
- Verifique se a rede `chatwoot-network` existe
- Confirme se as variáveis de ambiente estão corretas

### Não consegue conectar WhatsApp
- Verifique logs: `docker logs baileys-api`
- Confirme se o número está no formato correto (+5511999999999)

### Chatwoot não recebe mensagens
- Verifique se o webhook está configurado corretamente
- Confirme se os containers estão na mesma rede

## 📞 Exemplo Completo de Variáveis

```env
# Gere suas próprias chaves!
REDIS_PASSWORD=MySecureRedisPass2024!@#$%^&*
BAILEYS_API_KEY=baileys_super_secure_api_key_123456789abcdef
CHATWOOT_URL=http://chatwoot:3000
```

## ✅ Próximos Passos

Após o setup:
1. ✅ Baileys API rodando
2. ✅ WhatsApp conectado via QR code
3. ✅ Chatwoot recebendo mensagens
4. ✅ Envio de mensagens funcionando

**Pronto! Seu Chatwoot agora está integrado com WhatsApp via Baileys! 🎉** 