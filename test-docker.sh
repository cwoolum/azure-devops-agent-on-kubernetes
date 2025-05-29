#!/bin/bash

# Docker Build Test Script
# This script tests Docker functionality in the Azure DevOps agent container

echo "=== Docker Build Test ==="
echo

# Create a simple test Dockerfile
cat > /tmp/test.Dockerfile << 'EOF'
FROM alpine:latest
RUN echo "Hello from Docker build test!" > /test.txt
CMD ["cat", "/test.txt"]
EOF

echo "Created test Dockerfile:"
cat /tmp/test.Dockerfile
echo

# Test Docker build
echo "Testing Docker build..."
if docker build -f /tmp/test.Dockerfile -t azdo-test:latest /tmp >/dev/null 2>&1; then
    echo "✅ Docker build: SUCCESS"
else
    echo "❌ Docker build: FAILED"
    echo "This is expected if Docker daemon is not running or socket is not mounted"
fi

# Test Docker run (if build succeeded)
echo "Testing Docker run..."
if docker run --rm azdo-test:latest >/dev/null 2>&1; then
    echo "✅ Docker run: SUCCESS"
    # Clean up test image
    docker rmi azdo-test:latest >/dev/null 2>&1
else
    echo "❌ Docker run: FAILED"
    echo "This is expected if Docker daemon is not running or socket is not mounted"
fi

# Test Docker Compose
echo "Testing Docker Compose..."
cat > /tmp/docker-compose.test.yml << 'EOF'
version: '3.8'
services:
  test:
    image: alpine:latest
    command: echo "Docker Compose test successful"
EOF

if docker-compose -f /tmp/docker-compose.test.yml config >/dev/null 2>&1; then
    echo "✅ Docker Compose config: SUCCESS"
else
    echo "❌ Docker Compose config: FAILED"
fi

# Clean up
rm -f /tmp/test.Dockerfile /tmp/docker-compose.test.yml

echo
echo "=== Docker Test Complete ==="
echo "Note: Docker functionality requires the Docker socket to be mounted in Kubernetes"
echo "      See BUILD_TOOLS.md for configuration details"
