#!/bin/bash
# Backend Deployment Script for Chatbot Integration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SERVER_PROJECT_DIR="/home/deploy/chatbot-integration"

echo "🚀 Backend Deployment"
echo "===================="
echo "📁 Project: auth-backend"
echo "🕐 Started: $(date)"

# Function to check if we're on server or need to deploy to server
check_environment() {
    if [ -f "$SERVER_PROJECT_DIR/.env.prod" ]; then
        echo "🖥️  Running on server"
        return 0
    else
        echo "💻 Running locally - please run this on the server"
        echo ""
        echo "To deploy to server:"
        echo "1. ssh deploy@172.104.173.81"
        echo "2. cd /home/deploy/chatbot-integration/backend"
        echo "3. ./scripts/deploy.sh"
        exit 1
    fi
}

# Check database connectivity
check_database() {
    echo "🔍 Checking database connectivity..."
    if ! docker exec chatbot_postgres pg_isready -U ${DB_USERNAME} > /dev/null 2>&1; then
        echo "❌ Database is not ready. Please start infrastructure first:"
        echo "   cd $SERVER_PROJECT_DIR"
        echo "   ./scripts/deploy-infrastructure.sh"
        exit 1
    fi
    echo "✅ Database is ready"
}

# Load environment variables
load_environment() {
    if [ -f "$SERVER_PROJECT_DIR/.env.prod" ]; then
        echo "📋 Loading environment variables..."
        set -a
        source "$SERVER_PROJECT_DIR/.env.prod"
        set +a
        echo "✅ Environment loaded"
    else
        echo "❌ Environment file not found: $SERVER_PROJECT_DIR/.env.prod"
        exit 1
    fi
}

# Pull latest code
update_code() {
    echo "📥 Updating backend code..."
    cd "$PROJECT_DIR"
    
    git fetch origin
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/main)
    
    if [ "$LOCAL" != "$REMOTE" ]; then
        echo "📦 New changes detected, pulling..."
        git pull origin main
        echo "✅ Updated to commit: $(git rev-parse --short HEAD)"
    else
        echo "✅ Already up to date: $(git rev-parse --short HEAD)"
    fi
    
    # Verify required files
    if [ ! -f "Dockerfile.prod" ]; then
        echo "❌ Dockerfile.prod not found!"
        exit 1
    fi
    
    if [ ! -f "docker-compose.prod.yml" ]; then
        echo "❌ docker-compose.prod.yml not found!"
        exit 1
    fi
}

# Deploy backend
deploy_backend() {
    echo "🔧 Deploying backend service..."
    cd "$PROJECT_DIR"
    
    # Stop existing backend
    echo "⏹️  Stopping existing backend..."
    docker-compose -f docker-compose.prod.yml down 2>/dev/null || true
    
    # Remove old image to force rebuild
    echo "🗑️  Removing old backend image..."
    docker rmi chatbot-integration/backend:latest 2>/dev/null || true
    
    # Build and start backend
    echo "🔨 Building and starting backend..."
    docker-compose -f docker-compose.prod.yml up -d --build
    
    # Wait for backend to be ready
    echo "⏳ Waiting for backend to be ready..."
    for i in {1..30}; do
        if curl -s http://localhost:3001/health > /dev/null 2>&1; then
            echo "✅ Backend is ready!"
            break
        fi
        if [ $i -eq 30 ]; then
            echo "❌ Backend failed to start within 60 seconds"
            echo "📜 Backend logs:"
            docker-compose -f docker-compose.prod.yml logs --tail=30 backend
            echo ""
            echo "🔍 Container status:"
            docker ps -a --filter "name=chatbot_backend"
            exit 1
        fi
        echo "   Attempt $i/30..."
        sleep 2
    done
}

# Health check
health_check() {
    echo "🔍 Backend health check:"
    HEALTH_RESPONSE=$(curl -s http://localhost:3001/health)
    if [ $? -eq 0 ]; then
        echo "$HEALTH_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$HEALTH_RESPONSE"
    else
        echo "❌ Health endpoint not responding"
        exit 1
    fi
}

# Main execution
main() {
    check_environment
    load_environment
    check_database
    update_code
    deploy_backend
    health_check
    
    echo ""
    echo "🎉 Backend deployed successfully!"
    echo "🔗 Backend API: https://api.chatbot-integration.xyz"
    echo "📝 Git commit: $(git rev-parse --short HEAD)"
    echo "🕐 Completed: $(date)"
}

# Run main function
main "$@"