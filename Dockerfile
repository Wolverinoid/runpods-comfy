FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

ARG PAT_TOKEN

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=on \
    SHELL=/bin/bash

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

WORKDIR /app

RUN apt-get update && apt-get install -y \
    git \
    make build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev git git-lfs  \
    ffmpeg libsm6 libxext6 cmake libgl1-mesa-glx libopengl0 python3-opengl \
    && rm -rf /var/lib/apt/lists/* \
    && git lfs install

COPY ./requirements.txt /app/requirements.txt
COPY ./start.sh /app/start.sh
COPY ./proxy.py /app/proxy.py
COPY ./config.py /app/config.py
COPY ./models-path.yaml /app/models-path.yaml
COPY ./s3_download.py /app/s3_download.py

RUN python -m venv /app/venv && \
    . /app/venv/bin/activate && \
    pip install -r requirements.txt

RUN git clone https://github.com/comfyanonymous/ComfyUI && cd /app/ComfyUI && git checkout 195e0b063950f585fe584c5ce7b0b689f8d20ff8 && \
    . /app/venv/bin/activate && \
    pip install xformers!=0.0.18 --no-cache-dir -r requirements.txt

RUN ln -s /app/ComfyUI/models/vae /app/ComfyUI/models/VAE && \
    mkdir -p /app/ComfyUI/models/mmaudio


RUN echo "Installing custom nodes..."
RUN cd /app/ComfyUI/custom_nodes && \
    for repo in \
        https://github.com/ltdrdata/ComfyUI-Manager \
        https://github.com/kaibioinfo/ComfyUI_AdvancedRefluxControl \
        https://github.com/Fannovel16/comfyui_controlnet_aux \
        https://github.com/cubiq/ComfyUI_essentials \
        https://github.com/filliptm/ComfyUI_Fill-Nodes \
        https://github.com/ssitu/ComfyUI_UltimateSDUpscale \
        https://github.com/silveroxides/ComfyUI_bnb_nf4_fp4_Loaders \
        https://github.com/Nourepide/ComfyUI-Allor \
        https://github.com/sipherxyz/comfyui-art-venture \
        https://github.com/crystian/ComfyUI-Crystools \
        https://github.com/yolain/ComfyUI-Easy-Use \
        https://github.com/kijai/ComfyUI-Florence2 \
        https://github.com/logtd/ComfyUI-Fluxtapoz \
        https://github.com/city96/ComfyUI-GGUF \
        https://github.com/ltdrdata/ComfyUI-Impact-Pack \
        https://github.com/lrzjason/Comfyui-In-Context-Lora-Utils \
        https://github.com/john-mnz/ComfyUI-Inspyrenet-Rembg \
        https://github.com/Shakker-Labs/ComfyUI-IPAdapter-Flux \
        https://github.com/kijai/ComfyUI-KJNodes \
        https://github.com/sipie800/ComfyUI-PuLID-Flux-Enhanced \
        https://github.com/1038lab/ComfyUI-RMBG \
        https://github.com/kijai/ComfyUI-segment-anything-2 \
        https://github.com/un-seen/comfyui-tensorops \
        https://github.com/Yanick112/ComfyUI-ToSVG \
        https://github.com/Derfuu/Derfuu_ComfyUI_ModdedNodes \
        https://github.com/jags111/efficiency-nodes-comfyui \
        https://github.com/TheMistoAI/MistoControlNet-Flux-dev \
        https://github.com/rgthree/rgthree-comfy \
        https://github.com/XLabs-AI/x-flux-comfyui \
        https://github.com/kijai/ComfyUI-Hunyuan3DWrapper \
        https://github.com/lldacing/ComfyUI_BiRefNet_ll.git \
        https://github.com/kijai/ComfyUI-MMAudio \
        https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite \
        https://github.com/chrisgoringe/cg-use-everywhere \
        https://github.com/Fannovel16/ComfyUI-Frame-Interpolation \
        https://github.com/kijai/ComfyUI-HunyuanVideoWrapper \
        https://github.com/spacepxl/ComfyUI-Image-Filters \
        https://github.com/Smirnov75/ComfyUI-mxToolkit \
        https://github.com/SalahEddineKouiri/comfyui_easyocr \
        https://github.com/ClownsharkBatwing/RES4LYF \
        https://github.com/numz/ComfyUI-SeedVR2_VideoUpscaler \
        https://$PAT_TOKEN@git.neteragen.ai/neteragen/comfyui_neteragen_nodes.git \
    ; do \
        repo_name=$(basename $repo) && \
        git clone $repo && \
        if [ -f "$repo_name/requirements.txt" ]; then \
            . /app/venv/bin/activate; \
            pip install -r "$repo_name/requirements.txt"; \
        fi \
    done

RUN cd /app/ComfyUI/custom_nodes/ComfyUI_UltimateSDUpscale && \
    . /app/venv/bin/activate && \
    git submodule update --init --recursive

RUN cd /app/ComfyUI/custom_nodes/ComfyUI-Frame-Interpolation && \
    . /app/venv/bin/activate && \
    python install.py

RUN echo "Done..."

WORKDIR /app

CMD [ "/app/start.sh" ]