#!/bin/bash

export_env_vars() {
    echo "Exporting environment variables..."
    printenv | grep -E '^RUNPOD_|^PATH=|^_=' | awk -F = '{ print "export " $1 "=\"" $2 "\"" }' >> /etc/rp_environment
    echo 'source /etc/rp_environment' >> ~/.bashrc

    # Export RUNPOD_S3_* variables as S3_* variables
    printenv | grep -E '^RUNPOD_S3_' | while IFS='=' read -r key value; do
        s3_key="${key#RUNPOD_S3_}"
        export "S3_${s3_key}"="${value}"
        echo "export S3_${s3_key}=\"${value}\"" >> /etc/rp_environment
    done

    echo 'source /etc/rp_environment' >> ~/.bashrc
}

# System setup script
# Installs required packages and configures git-lfs

set -e

export_env_vars

if [ -f "/app/proxy.py" ]; then
    echo "/app/proxy.py exists, skipping download and unpack steps..."
else
    
    echo "Updating package lists..."
    apt-get update
    
    echo "Installing packages..."
    apt-get install -y \
        git \
        make \
        build-essential \
        libssl-dev \
        zlib1g-dev \
        libbz2-dev \
        libreadline-dev \
        libsqlite3-dev \
        wget \
        curl \
        llvm \
        libncursesw5-dev \
        xz-utils \
        tk-dev \
        libxml2-dev \
        libxmlsec1-dev \
        libffi-dev \
        liblzma-dev \
        git-lfs \
        ffmpeg \
        libsm6 \
        libxext6 \
        cmake \
        libgl1-mesa-glx \
        libopengl0 \
        python3-opengl
    
    echo "Cleaning up apt cache..."
    rm -rf /var/lib/apt/lists/*
    
    echo "Installing git-lfs..."
    git lfs install
    
    echo "Creating /app directory..."
    mkdir -p /app
    
    echo "Creating Python virtual environment..."
    cd /app
    python3.11 -m venv installvenv

    echo "Activating virtual environment..."
    source installvenv/bin/activate

    echo "Installing Python packages..."
    pip install tqdm
    pip install boto3

    echo "Downloading s3_download.py script..."
    wget -O /app/s3_download.py https://raw.githubusercontent.com/Wolverinoid/runpods-comfy/refs/heads/main/s3_download.py
    chmod +x /app/s3_download.py

    /app/installvenv/bin/python /app/s3_download.py runpods/comfy-latest.tar.gz /app/ --workers 12 --chunk-size 64

    cd /app

    tar -zxvf comfy-latest.tar.gz

    deactivate

    rm comfy-latest.tar.gz
    
    python3.11 -m venv --upgrade venv
fi



echo "Setup complete!"

cd /app
./start.sh