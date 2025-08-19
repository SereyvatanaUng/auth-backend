#!/bin/bash
# Backend Status Check

echo "🔧 Backend Service Status"
echo "========================="
echo "🕐 $(date)"

# Check if backend container is running
echo ""
echo "📊 Backend Container:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" --filter "name=chatbot_backend"

echo ""
echo "🔍 Health Check:"
if curl -s http://localhost:3001/health > /dev/null 2>&1; then
    echo "✅ Backend is healthy"
    echo ""
    echo "📊 Health Details:"
    curl -s http://localhost:3001/health | python3 -m json.tool 2>/dev/null
else
    echo "❌ Backend is unhealthy"
    echo ""
    echo "📜 Recent logs:"
    docker logs chatbot_backend --tail=10 2>/dev/null || echo "Container not found"
fi

echo ""
echo "💾 Resource Usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" chatbot_backend 2>/dev/null || echo "Backend container not running"

echo ""
echo "📝 Git Info:"
echo "Commit: $(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
echo "Branch: $(git branch --show-current 2>/dev/null || echo 'unknown')"