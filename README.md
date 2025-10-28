# ComfyUI Docker Setup for Video Processing

Quick setup for ComfyUI with Docker and NVIDIA GPU support for video style transfer and generation.

## Requirements

- Docker installed
- NVIDIA GPU with driver 525.60.13+
- NVIDIA Container Toolkit

## Installation

### 1. Clone or create project directory

```bash
mkdir -p ~/projects/comfy
cd ~/projects/comfy
```

### 2. Create directory structure

```bash
mkdir -p run data/{models,input,output,user,custom_nodes}
```

### 3. Create `docker-compose.yml`

```yaml
services:
  comfyui:
    image: mmartial/comfyui-nvidia-docker:ubuntu24_cuda12.6.3-latest
    container_name: comfyui
    ports:
      - "8188:8188"
    volumes:
      - ./run:/comfy/mnt
      - ./data:/basedir
    restart: unless-stopped
    environment:
      - WANTED_UID=1000  # Change to your UID: id -u
      - WANTED_GID=1000  # Change to your GID: id -g
      - BASE_DIRECTORY=/basedir
      - SECURITY_LEVEL=normal
      - COMFY_CMDLINE_EXTRA=--preview-method auto
      - NVIDIA_VISIBLE_DEVICES=all
    deploy:
      resources:
        limits:
          memory: 32G
        reservations:
          memory: 16G
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu, compute, utility]
```

### 4. Verify GPU access

```bash
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi
```

### 5. Launch ComfyUI

```bash
docker compose up -d
docker compose logs -f  # Monitor startup (first time: 5-10 minutes)
```

**Access UI**: http://localhost:8188

## Usage

### Container Management

```bash
# Start
docker compose up -d

# Stop
docker compose down

# Restart
docker compose restart

# View logs
docker compose logs -f

# Update image
docker compose pull
docker compose up -d
```

### Directory Structure

```
.
├── docker-compose.yml
├── run/                    # ComfyUI installation (auto-generated)
└── data/                   # Persistent data
    ├── models/            # Place models here
    ├── input/             # Input videos/images
    ├── output/            # Generated outputs
    ├── user/              # User settings
    └── custom_nodes/      # Custom extensions
```

## Workflows & Models

### Pre-built Workflows

Check these resources for ready-to-use workflows with model download instructions:

- **Wan2.2 Animate Workflow**: https://www.reddit.com/r/comfyui/comments/1nle575/wan22_animate_workflow_model_downloads_and_demos/
- **ComfyUI Examples**: https://comfyanonymous.github.io/ComfyUI_examples/
- **OpenArt Workflows**: https://openart.ai/workflows/home
- **CivitAI**: https://civitai.com/ (search for ComfyUI workflows)

### Installing Custom Nodes

1. Access http://localhost:8188
2. Click **"Manager"** button
3. **"Install Custom Nodes"** → Search and install
4. **"Restart"** when done
5. Refresh browser

### Essential Extensions

- **ComfyUI-Manager**: Extension manager (usually pre-installed)
- **ComfyUI-VideoHelperSuite**: Video I/O
- **ComfyUI-AnimateDiff-Evolved**: Video generation
- **comfyui_controlnet_aux**: ControlNet preprocessors

## Performance (RTX 4090)

- AnimateDiff (512×512, 16 frames): 2-3 minutes
- Stable Video Diffusion (576×1024, 25 frames): <2 minutes
- VRAM usage: 8-16GB typical (24GB available)

## Troubleshooting

### Check GPU access in container

```bash
docker compose exec comfyui nvidia-smi
```

### Permission issues

Update `WANTED_UID` and `WANTED_GID` in `docker-compose.yml` to match your user:

```bash
id -u  # Your UID
id -g  # Your GID
```

### Out of memory

- Reduce batch size / frame count
- Lower resolution (512×512 recommended)
- Check VRAM: `nvidia-smi`

### Container won't start

```bash
# Check logs
docker compose logs

# Rebuild
docker compose down
docker compose up -d
```

## Notes

- First startup takes 5-10 minutes (dependencies installation)
- Models in `./data/models/` persist between restarts
- Output files appear in `./data/output/`
- For workflows and models, refer to community resources (Reddit, OpenArt, CivitAI)

## Resources

- **ComfyUI**: https://github.com/comfyanonymous/ComfyUI
- **Docker Image**: https://github.com/mmartial/comfyui-nvidia-docker
- **NVIDIA Container Toolkit**: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html
