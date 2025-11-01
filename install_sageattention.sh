#!/bin/bash

# SageAttention Installation Script for ComfyUI Docker
# This script installs SageAttention in the ComfyUI container

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=================================="
echo "SageAttention Installation"
echo -e "==================================${NC}"
echo ""

# Check if container is running
echo -n "Checking if ComfyUI container is running... "
if ! docker compose ps | grep -q "comfyui.*Up"; then
    echo -e "${RED}FAILED${NC}"
    echo "ComfyUI container is not running. Please start it first with:"
    echo "  ./compose.sh"
    exit 1
fi
echo -e "${GREEN}OK${NC}"

echo ""
echo -e "${BLUE}Installing SageAttention in container...${NC}"
echo ""

# Execute installation commands in the container
docker compose exec comfyui bash -c '
set -e

echo "=== Cloning SageAttention repository ==="
cd /tmp
if [ -d "SageAttention" ]; then
    echo "Removing existing SageAttention directory..."
    rm -rf SageAttention
fi

git clone https://github.com/thu-ml/SageAttention.git
cd SageAttention

echo ""
echo "=== Installing SageAttention ==="
python3 -m pip install . --no-build-isolation

echo ""
echo "=== Verifying installation ==="
python3 -c "import sageattention; print(f\"SageAttention version: {sageattention.__version__ if hasattr(sageattention, \"__version__\") else \"installed\"}\")"

echo ""
echo "=== Cleaning up ==="
cd /tmp
rm -rf SageAttention

echo ""
echo "Installation complete!"
'

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}=================================="
    echo "SageAttention Installed Successfully!"
    echo -e "==================================${NC}"
    echo ""
    echo -e "${YELLOW}Important:${NC} You need to restart ComfyUI to use SageAttention:"
    echo "  docker compose restart"
    echo ""
    echo -e "${YELLOW}Note:${NC} To enable SageAttention, add the flag to your docker-compose.yml:"
    echo "  COMFY_CMDLINE_EXTRA=--preview-method auto --cache-none --use-sage-attention"
    echo ""
else
    echo ""
    echo -e "${RED}=================================="
    echo "Installation Failed"
    echo -e "==================================${NC}"
    echo ""
    echo "Check the error messages above for details."
    exit 1
fi
