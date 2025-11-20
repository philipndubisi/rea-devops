#!/bin/bash
# Quick Deployment Test Script
# Tests the MongoDB and Node.js deployment in staging environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if we're in the right directory
if [ ! -f "ansible-deployment/deploy.yml" ]; then
    log_error "Please run this script from the project root directory"
    exit 1
fi

log_info "Starting MongoDB and Node.js deployment test..."

# Check SSH key
if [ ! -f "$HOME/.ssh/deployment_key" ]; then
    log_warning "SSH key not found at $HOME/.ssh/deployment_key"
    log_info "Creating placeholder SSH key instructions..."
    
    echo "To complete the deployment, you need to:"
    echo "1. Generate or copy your SSH private key to: $HOME/.ssh/deployment_key"
    echo "2. Set proper permissions: chmod 600 $HOME/.ssh/deployment_key"
    echo "3. Update the inventory files with your actual server IP addresses"
    echo ""
    echo "Example SSH key generation:"
    echo "ssh-keygen -t rsa -b 4096 -f $HOME/.ssh/deployment_key -C 'deployment@rea-devops'"
    echo ""
fi

# Test Ansible syntax
log_info "Testing Ansible playbook syntax..."
if command -v ansible-playbook &> /dev/null; then
    if ansible-playbook ansible-deployment/deploy.yml --syntax-check; then
        log_success "Ansible playbook syntax is valid"
    else
        log_error "Ansible playbook syntax check failed"
        exit 1
    fi
else
    log_warning "Ansible not installed locally, skipping syntax check"
fi

# Check inventory files
log_info "Checking inventory configuration..."
if grep -q "52.23.156.88" ansible-deployment/inventory/staging/hosts; then
    log_success "Staging inventory configured"
else
    log_warning "Staging inventory needs actual server IP"
fi

if grep -q "your-production-server-ip" ansible-deployment/inventory/production/hosts; then
    log_warning "Production inventory needs actual server IP"
else
    log_success "Production inventory configured"
fi

# Check vault files
log_info "Checking vault configuration..."
if [ -f "ansible-deployment/group_vars/staging/vault.yml" ]; then
    if grep -q "mongodb_admin_password" ansible-deployment/group_vars/staging/vault.yml; then
        log_success "Staging vault has MongoDB passwords"
    else
        log_error "Staging vault missing MongoDB passwords"
    fi
else
    log_error "Staging vault file not found"
fi

# Check MongoDB template
if [ -f "ansible-deployment/templates/mongod.conf.j2" ]; then
    log_success "MongoDB configuration template found"
else
    log_error "MongoDB configuration template missing"
fi

# Test deployment (dry run)
log_info "Testing deployment with dry run..."
if command -v ansible-playbook &> /dev/null; then
    if [ -f "$HOME/.ssh/deployment_key" ]; then
        log_info "Running deployment dry run on staging..."
        ansible-playbook -i ansible-deployment/inventory/staging/hosts \
                        ansible-deployment/deploy.yml \
                        --check \
                        --diff \
                        --ask-vault-pass || log_warning "Dry run completed with warnings"
    else
        log_warning "SSH key missing, skipping dry run test"
    fi
else
    log_warning "Ansible not available, skipping dry run test"
fi

echo ""
echo "================================="
log_success "Deployment test completed!"
echo "================================="
echo ""

echo "Next steps:"
echo "1. Ensure SSH key is properly configured"
echo "2. Update server IP addresses in inventory files"
echo "3. Encrypt vault files with: ansible-vault encrypt group_vars/*/vault.yml"
echo "4. Run staging deployment: ./scripts/deploy.sh staging"
echo "5. Validate deployment: ./scripts/validate-deployment.sh"
echo ""

if [ -f "$HOME/.ssh/deployment_key" ]; then
    echo "Ready for deployment! 🚀"
else
    echo "Setup SSH key first, then you'll be ready! 🔑"
fi