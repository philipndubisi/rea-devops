#!/bin/bash

# REA DevOps Deployment Script
# This script handles the deployment to staging and production environments
# Usage: ./deploy.sh [staging|production]

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ANSIBLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VAULT_PASSWORD_FILE="${ANSIBLE_DIR}/.vault_password"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if ansible is installed
    if ! command -v ansible-playbook &> /dev/null; then
        print_error "Ansible is not installed. Please install it first."
        exit 1
    fi
    
    # Check if required files exist
    local required_files=(
        "deploy.yml"
        "group_vars/all/vault.yml"
        "secrets/staging.env"
        "secrets/prod.env"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -f "${ANSIBLE_DIR}/${file}" ]; then
            print_error "Required file ${file} not found!"
            exit 1
        fi
    done
    
    print_success "Prerequisites check passed"
}

# Function to validate environment
validate_environment() {
    local env=$1
    if [[ "$env" != "staging" && "$env" != "production" ]]; then
        print_error "Invalid environment: $env"
        echo "Usage: $0 [staging|production]"
        exit 1
    fi
}

# Function to encrypt vault files (if needed)
setup_vault() {
    print_status "Setting up vault encryption..."
    
    # Check if vault files are encrypted
    if grep -q "ANSIBLE_VAULT" "${ANSIBLE_DIR}/group_vars/all/vault.yml"; then
        print_success "Vault files are already encrypted"
    else
        print_warning "Vault files are not encrypted!"
        read -p "Do you want to encrypt them now? (y/N): " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ansible-vault encrypt "${ANSIBLE_DIR}/group_vars/all/vault.yml"
            ansible-vault encrypt "${ANSIBLE_DIR}/group_vars/staging/vault.yml"
            ansible-vault encrypt "${ANSIBLE_DIR}/group_vars/production/vault.yml"
            print_success "Vault files encrypted successfully"
        fi
    fi
}

# Function to test connectivity
test_connectivity() {
    local env=$1
    print_status "Testing connectivity to $env environment..."
    
    if ansible all -i "inventory/${env}/hosts" -m ping --ask-vault-pass; then
        print_success "Connectivity test passed for $env"
    else
        print_error "Connectivity test failed for $env"
        exit 1
    fi
}

# Function to deploy
deploy() {
    local env=$1
    print_status "Starting deployment to $env environment..."
    
    # Run the deployment playbook
    if ansible-playbook \
        -i "inventory/${env}/hosts" \
        deploy.yml \
        --ask-vault-pass \
        --diff \
        -v; then
        print_success "Deployment to $env completed successfully!"
    else
        print_error "Deployment to $env failed!"
        exit 1
    fi
}

# Function to validate deployment
validate_deployment() {
    local env=$1
    print_status "Validating deployment on $env..."
    
    # Get the server IP from inventory
    local server_ip=$(grep -E "^[^#]*ansible_host=" "inventory/${env}/hosts" | cut -d'=' -f2 | tr -d ' ')
    
    if [ -z "$server_ip" ]; then
        print_warning "Could not determine server IP for validation"
        return 0
    fi
    
    print_status "Testing HTTP endpoint on ${server_ip}..."
    
    # Test the health endpoint
    if curl -f -s "http://${server_ip}/health" > /dev/null; then
        print_success "Health endpoint is responding"
    else
        print_warning "Health endpoint is not responding (this might be expected for new deployments)"
    fi
    
    # Test if PM2 is running the application
    print_status "Checking PM2 process status..."
    if ansible all -i "inventory/${env}/hosts" -m shell -a "pm2 list" --ask-vault-pass; then
        print_success "PM2 status check completed"
    else
        print_warning "Could not check PM2 status"
    fi
}

# Main script logic
main() {
    echo "=============================================="
    echo "REA DevOps Deployment Script"
    echo "=============================================="
    
    # Check if environment is provided
    if [ $# -eq 0 ]; then
        print_error "No environment specified"
        echo "Usage: $0 [staging|production]"
        exit 1
    fi
    
    local environment=$1
    validate_environment "$environment"
    
    print_status "Deploying to: $environment"
    
    # Change to ansible directory
    cd "$ANSIBLE_DIR"
    
    # Run deployment steps
    check_prerequisites
    setup_vault
    test_connectivity "$environment"
    
    # Confirmation for production
    if [ "$environment" = "production" ]; then
        print_warning "You are about to deploy to PRODUCTION!"
        read -p "Are you sure you want to continue? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Deployment cancelled"
            exit 0
        fi
    fi
    
    deploy "$environment"
    validate_deployment "$environment"
    
    print_success "Deployment process completed!"
    echo "=============================================="
}

# Run the main function with all arguments
main "$@"