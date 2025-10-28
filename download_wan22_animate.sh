#!/bin/bash

################################################################################
# Wan2.2 Animate Model Downloader
# Downloads all required models for Wan2.2 Animate workflow
# GPU: 40xx+ (fp8_e4m3fn variants)
################################################################################

# Don't use set -e because we handle errors explicitly
set -o pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Base directory
BASE_DIR="/home/alex/projects/comfyui/data"

# Model directories
DIFFUSION_DIR="${BASE_DIR}/models/diffusion_models"
TEXT_ENCODER_DIR="${BASE_DIR}/models/text_encoders"
CLIP_VISION_DIR="${BASE_DIR}/models/clip_vision"
VAE_DIR="${BASE_DIR}/models/vae"
LORA_DIR="${BASE_DIR}/models/loras"
WORKFLOW_DIR="${BASE_DIR}/workflows"

# Download statistics
TOTAL_FILES=0
DOWNLOADED_FILES=0
SKIPPED_FILES=0
FAILED_FILES=0

# Array to track background download PIDs
declare -a DOWNLOAD_PIDS=()
declare -a DOWNLOAD_NAMES=()

################################################################################
# Functions
################################################################################

print_header() {
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Wan2.2 Animate Model Downloader${NC}"
    echo -e "${BLUE}  GPU: 40xx+ (fp8_e4m3fn variants)${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

create_directories() {
    echo -e "${YELLOW}Creating directory structure...${NC}"
    mkdir -p "$DIFFUSION_DIR"
    mkdir -p "$TEXT_ENCODER_DIR"
    mkdir -p "$CLIP_VISION_DIR"
    mkdir -p "$VAE_DIR"
    mkdir -p "$LORA_DIR"
    mkdir -p "$WORKFLOW_DIR"
    echo -e "${GREEN}✓ Directories created${NC}\n"
}

check_existing_file() {
    local filepath="$1"
    local url="$2"

    if [ -f "$filepath" ]; then
        local filesize=$(stat -c%s "$filepath" 2>/dev/null || echo "0")
        if [ "$filesize" -gt 1000000 ]; then  # At least 1MB
            echo -e "${GREEN}✓ Already exists ($(numfmt --to=iec-i --suffix=B $filesize)):${NC} $(basename "$filepath")"
            return 0
        fi
    fi
    return 1
}

download_file() {
    local url="$1"
    local output_path="$2"
    local description="$3"

    ((TOTAL_FILES++))

    echo -e "\n${BLUE}[$TOTAL_FILES] Downloading: ${description}${NC}"
    echo -e "URL: $url"
    echo -e "Output: $output_path"

    # Check if file already exists
    if check_existing_file "$output_path" "$url"; then
        ((SKIPPED_FILES++))
        return 0
    fi

    # Download with resume capability and progress bar
    if wget -c -O "$output_path" "$url" --progress=bar:force 2>&1; then
        echo -e "${GREEN}✓ Download complete: $(basename "$output_path")${NC}"
        ((DOWNLOADED_FILES++))
        return 0
    else
        echo -e "${RED}✗ Download failed: $(basename "$output_path")${NC}"
        ((FAILED_FILES++))
        return 1
    fi
}

download_file_background() {
    local url="$1"
    local output_path="$2"
    local description="$3"
    local log_file="${output_path}.log"

    ((TOTAL_FILES++)) || true

    echo -e "${BLUE}[Queued] ${description}${NC}"

    # Check if file already exists
    if [ -f "$output_path" ]; then
        local filesize=$(stat -c%s "$output_path" 2>/dev/null || echo "0")
        if [ "$filesize" -gt 1000000 ]; then
            echo -e "${GREEN}✓ Already exists ($(numfmt --to=iec-i --suffix=B $filesize)):${NC} $(basename "$output_path")"
            ((SKIPPED_FILES++)) || true
            return 0
        fi
    fi

    # Download in background
    {
        if wget -c -O "$output_path" "$url" --progress=dot:giga 2>&1 | tee "$log_file"; then
            echo "SUCCESS" >> "$log_file"
            exit 0
        else
            echo "FAILED" >> "$log_file"
            exit 1
        fi
    } &

    DOWNLOAD_PIDS+=($!)
    DOWNLOAD_NAMES+=("$description")
}

wait_for_downloads() {
    local total=${#DOWNLOAD_PIDS[@]}

    if [ $total -eq 0 ]; then
        echo -e "${YELLOW}No downloads queued${NC}"
        return 0
    fi

    echo -e "\n${YELLOW}Waiting for $total parallel downloads to complete...${NC}\n"

    local completed=0
    for i in "${!DOWNLOAD_PIDS[@]}"; do
        local pid=${DOWNLOAD_PIDS[$i]}
        local name=${DOWNLOAD_NAMES[$i]}

        if wait $pid; then
            ((completed++)) || true
            ((DOWNLOADED_FILES++)) || true
            echo -e "${GREEN}✓ [$completed/$total] Completed: $name${NC}"
        else
            ((completed++)) || true
            ((FAILED_FILES++)) || true
            echo -e "${RED}✗ [$completed/$total] Failed: $name${NC}"
        fi
    done

    echo -e "\n${GREEN}All parallel downloads finished${NC}\n"

    # Reset arrays for next batch
    DOWNLOAD_PIDS=()
    DOWNLOAD_NAMES=()
}

print_summary() {
    echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Download Summary${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "Total files processed:    $TOTAL_FILES"
    echo -e "${GREEN}Successfully downloaded:  $DOWNLOADED_FILES${NC}"
    echo -e "${YELLOW}Skipped (already exist):  $SKIPPED_FILES${NC}"
    echo -e "${RED}Failed:                   $FAILED_FILES${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"

    if [ $FAILED_FILES -eq 0 ]; then
        echo -e "\n${GREEN}✓ All downloads completed successfully!${NC}\n"
        exit 0
    else
        echo -e "\n${RED}✗ Some downloads failed. Check the output above for details.${NC}\n"
        exit 1
    fi
}

################################################################################
# Main Download Process
################################################################################

print_header
create_directories

echo -e "${YELLOW}Starting downloads...${NC}\n"
echo -e "${YELLOW}Note: Large models will download in parallel for speed${NC}\n"

# Download text encoders in parallel (relatively smaller files)
echo -e "${BLUE}━━━ Text Encoders ━━━${NC}"
download_file_background \
    "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors" \
    "${TEXT_ENCODER_DIR}/clip_l.safetensors" \
    "Text Encoder: clip_l"

download_file_background \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp16.safetensors" \
    "${TEXT_ENCODER_DIR}/umt5_xxl_fp16.safetensors" \
    "Text Encoder: umt5_xxl_fp16"

download_file_background \
    "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors" \
    "${TEXT_ENCODER_DIR}/t5xxl_fp16.safetensors" \
    "Text Encoder: t5xxl_fp16"

# Download CLIP vision
echo -e "\n${BLUE}━━━ CLIP Vision ━━━${NC}"
download_file_background \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors" \
    "${CLIP_VISION_DIR}/clip_vision_h.safetensors" \
    "CLIP Vision: clip_vision_h"

# Download VAE models
echo -e "\n${BLUE}━━━ VAE Models ━━━${NC}"
download_file_background \
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1_VAE_bf16.safetensors" \
    "${VAE_DIR}/Wan2_1_VAE_bf16.safetensors" \
    "VAE: Wan2_1_VAE_bf16"

download_file_background \
    "https://huggingface.co/Comfy-Org/Lumina_Image_2.0_Repackaged/resolve/main/split_files/vae/ae.safetensors" \
    "${VAE_DIR}/ae.safetensors" \
    "VAE: Lumina ae"

# Download LoRA models
echo -e "\n${BLUE}━━━ LoRA Models ━━━${NC}"
download_file_background \
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank128_bf16.safetensors" \
    "${LORA_DIR}/lightx2v_I2V_14B_480p_cfg_step_distill_rank128_bf16.safetensors" \
    "LoRA: lightx2v_I2V_14B"

download_file_background \
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/Wan22_relight/WanAnimate_relight_lora_fp16.safetensors" \
    "${LORA_DIR}/WanAnimate_relight_lora_fp16.safetensors" \
    "LoRA: WanAnimate_relight"

# Wait for smaller files to complete before starting large models
wait_for_downloads

# Download large diffusion models in parallel (these are HUGE)
echo -e "\n${BLUE}━━━ Diffusion Models (Large - may take a while) ━━━${NC}"

download_file_background \
    "https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/Wan22Animate/Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors" \
    "${DIFFUSION_DIR}/Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors" \
    "Wan2.2 Animate 14B (40xx+)"

download_file_background \
    "https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/T2V/Wan2_2-T2V-A14B-LOW_fp8_e4m3fn_scaled_KJ.safetensors" \
    "${DIFFUSION_DIR}/Wan2_2-T2V-A14B-LOW_fp8_e4m3fn_scaled_KJ.safetensors" \
    "Wan2.2 T2V Quality Improvement (40xx+)"

download_file_background \
    "https://huggingface.co/Comfy-Org/FLUX.1-Krea-dev_ComfyUI/resolve/main/split_files/diffusion_models/flux1-krea-dev_fp8_scaled.safetensors" \
    "${DIFFUSION_DIR}/flux1-krea-dev_fp8_scaled.safetensors" \
    "Flux Krea Dev (fp8_scaled)"

# Wait for all large model downloads
wait_for_downloads

# Print summary
print_summary
