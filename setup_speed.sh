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
    
    echo "Installing AWS CLI via pip..."
    pip install awscli

    echo "Downloading comfy-latest.tar.gz from S3..."
    mkdir -p /app
    AWS_ACCESS_KEY_ID="${RUNPOD_S3_ACCESS_KEY_ID}" \
    AWS_SECRET_ACCESS_KEY="${RUNPOD_S3_SECRET_ACCESS_KEY}" \
    AWS_DEFAULT_REGION="${RUNPOD_S3_REGION}" \
    aws s3 cp "s3://${RUNPOD_S3_BUCKET}/runpods/comfy-latest.tar.gz" /app/comfy-latest.tar.gz \
        --endpoint-url "${RUNPOD_S3_ENDPOINT}"

    cd /app

    tar -zxvf comfy-latest.tar.gz

    rm comfy-latest.tar.gz
    
    python3.11 -m venv --upgrade venv
fi



echo "Setup complete!"

cd /app
./start.sh