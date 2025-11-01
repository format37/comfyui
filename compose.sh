#!/bin/bash

# ComfyUI Docker Compose and Launch Script
# Handles setup, verification, and daemon launch

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=================================="
echo "ComfyUI Docker Setup & Launch"
echo -e "==================================${NC}"
echo ""

# Check Docker
echo -n "Checking Docker... "
if ! command -v docker &> /dev/null; then
    echo -e "${RED}FAILED${NC}"
    echo "Docker is not installed. Please install Docker first."
    exit 1
fi
echo -e "${GREEN}OK${NC}"

# Check Docker Compose
echo -n "Checking Docker Compose... "
if ! docker compose version &> /dev/null; then
    echo -e "${RED}FAILED${NC}"
    echo "Docker Compose is not available. Please install Docker Compose plugin."
    exit 1
fi
echo -e "${GREEN}OK${NC}"

# Check NVIDIA Container Toolkit
echo -n "Checking NVIDIA Container Toolkit... "
if ! command -v nvidia-ctk &> /dev/null; then
    echo -e "${YELLOW}WARNING${NC}"
    echo "nvidia-ctk not found. GPU support may not work."
    echo "Install with: sudo apt-get install -y nvidia-container-toolkit"
else
    echo -e "${GREEN}OK${NC}"
fi

# Check GPU
echo -n "Checking NVIDIA GPU... "
if ! nvidia-smi &> /dev/null; then
    echo -e "${RED}FAILED${NC}"
    echo "nvidia-smi not found. Please ensure NVIDIA drivers are installed."
    exit 1
fi
echo -e "${GREEN}OK${NC}"

# Create directories
echo -n "Creating directory structure... "
mkdir -p run
mkdir -p data/{models,input,output,user,custom_nodes}
echo -e "${GREEN}OK${NC}"

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}ERROR:${NC} docker-compose.yml not found in current directory!"
    exit 1
fi

# Verify GPU access in Docker
echo -n "Verifying Docker GPU access... "
if docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi &> /dev/null; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
    echo "Docker cannot access GPU. Check NVIDIA Container Toolkit configuration."
    echo "Run: sudo nvidia-ctk runtime configure --runtime=docker"
    echo "Then: sudo systemctl restart docker"
    exit 1
fi

echo ""
echo -e "${BLUE}Starting ComfyUI container...${NC}"
echo ""

# Stop existing container if running
if docker compose ps | grep -q comfyui; then
    echo "Stopping existing container..."
    docker compose down
fi

# Start in daemon mode
docker compose up -d --force-recreate --remove-orphans

# Wait a moment for container to start
sleep 2

# Check if container is running
if docker compose ps | grep -q "Up"; then
    echo ""
    echo -e "${GREEN}=================================="
    echo "ComfyUI Started Successfully!"
    echo -e "==================================${NC}"
    echo ""
    echo -e "${GREEN}Web Interface:${NC} http://localhost:8188"
    echo ""
    echo "Container Status:"
    docker compose ps
    echo ""
    echo -e "${BLUE}Useful Commands:${NC}"
    echo "  View logs:        docker compose logs -f"
    echo "  Stop:             docker compose down"
    echo "  Restart:          docker compose restart"
    echo "  Container shell:  docker compose exec comfyui bash"
    echo ""
    echo -e "${YELLOW}Note:${NC} First startup takes 5-10 minutes for initialization."
    echo "      Monitor with: docker compose logs -f"
    echo ""
else
    echo -e "${RED}=================================="
    echo "Failed to Start Container"
    echo -e "==================================${NC}"
    echo ""
    echo "Check logs with: docker compose logs"
    exit 1
fi
