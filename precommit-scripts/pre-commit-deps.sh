#!/bin/bash

# Check if the user is root
if [[ $EUID -eq 0 ]]; then
   echo "This script should not be run as root. Please run it without using sudo."
   exit 1
fi

# Update the system with sudo
sudo apt update

# Install dependencies with sudo
sudo apt install -y build-essential curl file git

# Download and run the Linuxbrew installation script
sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"

# Add configuration lines to the shell configuration
echo 'eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)' >> ~/.bashrc
echo 'eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)' >> ~/.profile

# Reload the shell configuration
source ~/.bashrc

# Check if Homebrew is installed correctly
brew --version

# Install chart-testing (ct) using Homebrew
brew install chart-testing

# Check if chart-testing is installed correctly
ct version

# Upgrade pre-commit
pip3 install pre-commit --upgrade

# Install tflint
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Install tfsec
curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash
