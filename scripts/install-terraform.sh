#!/bin/bash
# Script to install Terraform

TERRAFORM_VERSION="1.5.0"
TERRAFORM_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"

# Create directories if they don't exist
mkdir -p ~/.local/bin

# Download Terraform
echo "Downloading Terraform ${TERRAFORM_VERSION}..."
curl -s -o /tmp/terraform.zip ${TERRAFORM_URL}

# Unzip and install
echo "Installing Terraform..."
unzip -o /tmp/terraform.zip -d /tmp
mv /tmp/terraform ~/.local/bin/
chmod +x ~/.local/bin/terraform

# Add to PATH if not already there
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
  export PATH="$HOME/.local/bin:$PATH"
fi

# Verify installation
terraform --version

echo "Terraform ${TERRAFORM_VERSION} installed successfully!"