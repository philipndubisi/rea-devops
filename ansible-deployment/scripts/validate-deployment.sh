#!/bin/bash
# MongoDB and Node.js Deployment Validation Script
# This script validates the complete backend deployment including MongoDB and Node.js

set -e
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_NC} $1"
}

log_success() {
    echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_NC} $1"
}

log_warning() {
    echo -e "${COLOR_YELLOW}[WARNING]${COLOR_NC} $1"
}

log_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_NC} $1"
}

check_command() {
    if command -v "$1" &> /dev/null; then
        log_success "$1 is installed"
        return 0
    else
        log_error "$1 is not installed"
        return 1
    fi
}

check_service() {
    if systemctl is-active --quiet "$1"; then
        log_success "$1 service is running"
        return 0
    else
        log_error "$1 service is not running"
        return 1
    fi
}

validate_mongodb_config() {
    log_info "Validating MongoDB configuration..."
    
    if [ -f "/etc/mongod.conf" ]; then
        log_success "MongoDB configuration file exists"
        
        # Check if auth is enabled
        if grep -q "authorization: enabled" /etc/mongod.conf; then
            log_success "MongoDB authentication is enabled"
        else
            log_warning "MongoDB authentication is not configured"
        fi
        
        # Check bind IP
        local bind_ip=$(grep -E "^\s*bindIp:" /etc/mongod.conf | awk '{print $2}')
        if [ -n "$bind_ip" ]; then
            log_success "MongoDB bind IP: $bind_ip"
        else
            log_warning "MongoDB bind IP not configured"
        fi
    else
        log_error "MongoDB configuration file not found"
        return 1
    fi
}

validate_nodejs_setup() {
    log_info "Validating Node.js setup..."
    
    # Check Node.js version
    if command -v node &> /dev/null; then
        local node_version=$(node --version)
        log_success "Node.js version: $node_version"
        
        # Check if it's the expected version (18.x)
        if [[ $node_version == v18* ]]; then
            log_success "Node.js version is 18.x as expected"
        else
            log_warning "Node.js version is not 18.x"
        fi
    else
        log_error "Node.js not found"
        return 1
    fi
    
    # Check NPM
    if command -v npm &> /dev/null; then
        local npm_version=$(npm --version)
        log_success "NPM version: $npm_version"
    else
        log_error "NPM not found"
        return 1
    fi
    
    # Check PM2
    if command -v pm2 &> /dev/null; then
        local pm2_version=$(pm2 --version)
        log_success "PM2 version: $pm2_version"
    else
        log_error "PM2 not installed globally"
        return 1
    fi
}

test_mongodb_connection() {
    log_info "Testing MongoDB connection..."
    
    # Test basic connection
    if command -v mongosh &> /dev/null; then
        if mongosh --eval "db.runCommand('ping')" --quiet; then
            log_success "MongoDB connection successful"
        else
            log_error "Cannot connect to MongoDB"
            return 1
        fi
    elif command -v mongo &> /dev/null; then
        if mongo --eval "db.runCommand('ping')" --quiet; then
            log_success "MongoDB connection successful"
        else
            log_error "Cannot connect to MongoDB"
            return 1
        fi
    else
        log_warning "MongoDB client not found, cannot test connection"
        return 1
    fi
}

validate_firewall_rules() {
    log_info "Validating firewall rules..."
    
    if command -v ufw &> /dev/null; then
        local ufw_status=$(ufw status | grep "Status: active" || true)
        if [ -n "$ufw_status" ]; then
            log_success "UFW firewall is active"
            
            # Check SSH rule
            if ufw status | grep -q "22/tcp"; then
                log_success "SSH port 22 is allowed"
            else
                log_warning "SSH port 22 rule not found"
            fi
            
            # Check HTTP/HTTPS rules
            if ufw status | grep -q "80/tcp"; then
                log_success "HTTP port 80 is allowed"
            else
                log_warning "HTTP port 80 rule not found"
            fi
            
            if ufw status | grep -q "443/tcp"; then
                log_success "HTTPS port 443 is allowed"
            else
                log_warning "HTTPS port 443 rule not found"
            fi
        else
            log_warning "UFW firewall is not active"
        fi
    else
        log_warning "UFW not found"
    fi
}

validate_ansible_requirements() {
    log_info "Validating Ansible requirements..."
    
    # Check Python
    if command -v python3 &> /dev/null; then
        local python_version=$(python3 --version)
        log_success "Python: $python_version"
    else
        log_error "Python3 not found"
        return 1
    fi
    
    # Check if running locally or remotely
    if [ -f "ansible-deployment/ansible.cfg" ]; then
        log_success "Ansible configuration found"
        
        # Check inventory files
        if [ -f "ansible-deployment/inventory/staging/hosts" ]; then
            log_success "Staging inventory found"
        else
            log_error "Staging inventory not found"
        fi
        
        if [ -f "ansible-deployment/inventory/production/hosts" ]; then
            log_success "Production inventory found"
        else
            log_error "Production inventory not found"
        fi
        
        # Check playbook
        if [ -f "ansible-deployment/deploy.yml" ]; then
            log_success "Main deployment playbook found"
        else
            log_error "Main deployment playbook not found"
        fi
        
        # Check vault files
        if [ -f "ansible-deployment/group_vars/staging/vault.yml" ]; then
            log_success "Staging vault file found"
        else
            log_error "Staging vault file not found"
        fi
        
        if [ -f "ansible-deployment/group_vars/production/vault.yml" ]; then
            log_success "Production vault file found"
        else
            log_error "Production vault file not found"
        fi
        
        # Check templates
        if [ -f "ansible-deployment/templates/mongod.conf.j2" ]; then
            log_success "MongoDB configuration template found"
        else
            log_error "MongoDB configuration template not found"
        fi
    else
        log_info "Running on target server (not Ansible control node)"
    fi
}

main() {
    echo "======================================"
    echo "MongoDB and Node.js Deployment Validation"
    echo "======================================"
    
    local errors=0
    
    # System validation
    log_info "Checking system requirements..."
    check_command "curl" || ((errors++))
    check_command "wget" || ((errors++))
    check_command "systemctl" || ((errors++))
    
    # Node.js validation
    validate_nodejs_setup || ((errors++))
    
    # MongoDB validation
    check_command "mongod" || ((errors++))
    check_service "mongod" || ((errors++))
    validate_mongodb_config || ((errors++))
    test_mongodb_connection || ((errors++))
    
    # Service validation
    check_service "nginx" || ((errors++))
    
    # Security validation
    validate_firewall_rules || ((errors++))
    
    # Ansible validation (if running from control node)
    validate_ansible_requirements || ((errors++))
    
    echo "======================================"
    if [ $errors -eq 0 ]; then
        log_success "All validations passed! Deployment is ready."
        exit 0
    else
        log_error "Validation completed with $errors error(s). Please check the issues above."
        exit 1
    fi
}

# Run main function
main "$@"