#!/bin/bash

echo "🔧 Deploying Chatwoot with Redis authentication fix..."

# Remove the old stack
echo "🗑️  Removing existing stack..."
docker stack rm chatwoot-baileys-final

# Wait for cleanup
echo "⏳ Waiting for cleanup..."
sleep 10

# Deploy the new stack with Redis authentication
echo "🚀 Deploying new stack with Redis authentication..."
docker stack deploy -c docker-compose-redis-auth-fixed.yaml chatwoot-redis-auth

echo "✅ Deployment complete!"
echo ""
echo "📊 Check service status with:"
echo "docker service ls | grep chatwoot"
echo ""
echo "📋 Check logs with:"
echo "docker service logs chatwoot-redis-auth_chatwoot_db_prepare -f"
echo ""
echo "🌐 Site will be available at: https://chatwoot.darwinai.com.br" 