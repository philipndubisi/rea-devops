#!/bin/bash

# REA DevOps Backend Deployment Validation Script
# Validates all components are properly configured for backend-only deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

validation_errors=0

# Function to check if file exists
check_file() {
    local file=$1
    local description=$2
    
    if [ -f "$file" ]; then
        print_success "$description: $file"
    else
        print_error "Missing $description: $file"
        ((validation_errors++))
    fi
}

# Function to check if directory exists
check_directory() {
    local dir=$1
    local description=$2
    
    if [ -d "$dir" ]; then
        print_success "$description: $dir"
    else
        print_error "Missing $description: $dir"
        ((validation_errors++))
    fi
}

echo "==========================================="
echo "REA DevOps Backend Deployment Validation"
echo "==========================================="

print_status "Checking core deployment files..."

# Core configuration files
check_file "ansible.cfg" "Ansible configuration"
check_file "deploy.yml" "Main deployment playbook"

# Inventory files
print_status "Checking inventory configuration..."
check_directory "inventory" "Inventory directory"
check_file "inventory/staging/hosts" "Staging inventory"
check_file "inventory/production/hosts" "Production inventory"

# Group variables
print_status "Checking group variables..."
check_directory "group_vars" "Group variables directory"
check_file "group_vars/all/all.yml" "Common variables"
check_file "group_vars/all/vault.yml" "Vault configuration"
check_file "group_vars/staging/vars.yml" "Staging variables"
check_file "group_vars/production/vars.yml" "Production variables"

# Secrets
print_status "Checking secrets configuration..."
check_directory "secrets" "Secrets directory"
check_file "secrets/staging.env" "Staging environment file"
check_file "secrets/prod.env" "Production environment file"

# Templates
print_status "Checking Jinja2 templates..."
check_directory "templates" "Templates directory"
check_file "templates/nginx.conf.j2" "Nginx configuration template"
check_file "templates/ecosystem.config.js.j2" "PM2 configuration template"
check_file "templates/cloudwatch-config.json.j2" "CloudWatch configuration template"

# Roles
print_status "Checking Ansible roles..."
check_directory "roles" "Roles directory"
check_file "roles/common/tasks/main.yml" "Common role tasks"
check_file "roles/application/tasks/main.yml" "Application role tasks"
check_file "roles/nginx/tasks/main.yml" "Nginx role tasks"
check_file "roles/cloudwatch/tasks/main.yml" "CloudWatch role tasks"

# Scripts
print_status "Checking deployment scripts..."
check_directory "scripts" "Scripts directory"
check_file "scripts/deploy.sh" "Main deployment script"
check_file "scripts/vault.sh" "Vault management script"

# Backend-specific validation
print_status "Validating backend-specific configurations..."

# Check if backend_only is set in environment variables
if grep -q "backend_only: true" group_vars/staging/vars.yml && grep -q "backend_only: true" group_vars/production/vars.yml; then
    print_success "Backend-only deployment properly configured"
else
    print_warning "Backend-only deployment flag not found in environment variables"
fi

# Check API endpoints configuration
if grep -q "api_prefix:" group_vars/staging/vars.yml && grep -q "api_prefix:" group_vars/production/vars.yml; then
    print_success "API endpoints properly configured"
else
    print_warning "API endpoint configuration not found"
fi

# Check for frontend-related configurations (should not exist for backend-only)
if grep -q "frontend_enabled: false" group_vars/staging/vars.yml && grep -q "frontend_enabled: false" group_vars/production/vars.yml; then
    print_success "Frontend properly disabled for backend-only deployment"
else
    print_warning "Frontend disable flag not explicitly set"
fi

echo "==========================================="
if [ $validation_errors -eq 0 ]; then
    print_success "✅ All validation checks passed!"
    print_success "Backend deployment structure is ready for use."
    echo ""
    print_status "Next steps:"
    echo "1. Update server IPs in inventory files"
    echo "2. Add your SSH private key to group_vars/all/vault.yml"
    echo "3. Encrypt vault files: ansible-vault encrypt group_vars/all/vault.yml"
    echo "4. Update environment variables in secrets/ directory"
    echo "5. Run deployment: ./scripts/deploy.sh staging"
else
    print_error "❌ Validation failed with $validation_errors errors!"
    print_error "Please fix the missing files/directories before deployment."
    exit 1
fi
echo "==========================================="