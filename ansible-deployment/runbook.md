# REA DevOps Stage 5: Advanced Configuration Management Runbook

## Overview
This runbook provides comprehensive instructions for deploying the REA Interactive Bible Backend API using our unified Ansible-based configuration management system. The system handles both staging and production environments through a single universal playbook with dynamic environment detection.

## Architecture
- **Controller Node**: Central Ansible server managing deployments
- **Target Environments**: Staging and Production API servers
- **Backend Focus**: Node.js API with PM2 process management
- **Security**: Ansible Vault encryption for all secrets and SSH keys
- **Observability**: Centralized CloudWatch logging (no SSH debugging required)
- **SSL**: Automated Let's Encrypt certificate management
- **Load Balancing**: Nginx reverse proxy with health checks

## Prerequisites
1. Access to the Ansible Controller Server
2. Vault password from Team Lead
3. SSH deployment key with GitHub repository access
4. AWS credentials for CloudWatch integration
5. Domain names configured (staging and production)

## Quick Start

### Initial Setup
```bash
# Clone and navigate to deployment directory
git clone <repository>
cd rea-devops/ansible-deployment

# Validate setup
bash scripts/validate.sh

# Configure vault password
./scripts/vault.sh create
```

### Environment Configuration
1. **Update Server IPs**:
   ```bash
   # Edit inventory files with your actual server details
   nano inventory/staging/hosts     # Replace YOUR_STAGING_SERVER_IP
   nano inventory/production/hosts  # Replace YOUR_PRODUCTION_SERVER_IP
   ```

2. **Configure SSH Key**:
   ```bash
   # Add your GitHub deployment key to vault
   nano group_vars/all/vault.yml
   # Replace the placeholder SSH key with your actual private key
   ```

3. **Encrypt Vault Files** (REQUIRED):
   ```bash
   ansible-vault encrypt group_vars/all/vault.yml
   ansible-vault encrypt group_vars/staging/vault.yml
   ansible-vault encrypt group_vars/production/vault.yml
   ```

## Deployment Procedures

### Staging Deployment
```bash
# Quick deployment
./scripts/deploy.sh staging

# Manual deployment with verbose output
ansible-playbook -i inventory/staging/hosts deploy.yml --ask-vault-pass -v

# Test-only deployment (dry run)
ansible-playbook -i inventory/staging/hosts deploy.yml --ask-vault-pass --check
```

### Production Deployment
```bash
# Automated deployment with safety checks
./scripts/deploy.sh production

# Manual production deployment (requires confirmation)
ansible-playbook -i inventory/production/hosts deploy.yml --ask-vault-pass --diff
```

## Vault Management

### Vault Operations
```bash
# Create vault password file
./scripts/vault.sh create

# Edit encrypted vault file
./scripts/vault.sh edit

# View vault contents
./scripts/vault.sh view

# Run playbook with vault
./scripts/vault.sh run -i inventory/staging/hosts deploy.yml
```

### Environment Secrets
```bash
# Update staging environment variables
nano secrets/staging.env

# Update production environment variables
nano secrets/prod.env

# Encrypt individual strings
ansible-vault encrypt_string 'your_secret' --name 'vault_variable'
```

## Health Monitoring

### Application Status
```bash
# Check PM2 processes
ansible all -i inventory/staging/hosts -m shell -a "pm2 list" --ask-vault-pass

# Check application health endpoint
curl https://api-staging.seisho.emerj.net/api/v1/health

# View application logs via CloudWatch
aws logs get-log-events --log-group-name "/aws/ec2/rea-bible-app/staging" \
    --log-stream-name "i-1234567890-app-logs"
```

### System Health
```bash
# Check Nginx status
ansible all -i inventory/production/hosts -m shell -a "systemctl status nginx" --ask-vault-pass

# Verify SSL certificates
ansible all -i inventory/production/hosts -m shell -a "certbot certificates" --ask-vault-pass

# Check disk space and system resources
ansible all -i inventory/staging/hosts -m shell -a "df -h && free -m" --ask-vault-pass
```

## Available Deployment Tags
- `app`: Application deployment and dependencies
- `nginx`: Nginx configuration and reverse proxy
- `ssl`: SSL certificate management
- `cloudwatch`: Logging and monitoring setup
- `pm2`: Process management configuration
- `security`: Security settings and firewall rules

## Troubleshooting

### Common Issues

#### 1. SSH Connection Failures
```bash
# Test SSH connectivity
ssh -i ~/.ssh/deployment_key ubuntu@YOUR_SERVER_IP

# Debug SSH agent
ssh-add -l  # List loaded keys
eval "$(ssh-agent -s)" && ssh-add ~/.ssh/deployment_key

# Test Ansible connectivity
ansible all -i inventory/staging/hosts -m ping --ask-vault-pass
```

#### 2. Vault Decryption Issues
```bash
# Verify vault file encryption
head -1 group_vars/all/vault.yml  # Should show $ANSIBLE_VAULT

# Re-encrypt if needed
ansible-vault rekey group_vars/all/vault.yml

# Test vault access
ansible-vault view group_vars/all/vault.yml
```

#### 3. Application Deployment Failures
```bash
# Check Node.js version
ansible all -i inventory/staging/hosts -m shell -a "node --version" --ask-vault-pass

# Verify repository access
ansible all -i inventory/staging/hosts -m shell -a "ssh -T git@github.com" --ask-vault-pass

# Check PM2 status
ansible all -i inventory/staging/hosts -m shell -a "pm2 status" --ask-vault-pass
```

#### 4. SSL Certificate Issues
```bash
# Check certificate status
certbot certificates

# Test certificate renewal
certbot renew --dry-run

# Manually request certificate
certbot --nginx -d api-staging.seisho.emerj.net --non-interactive --agree-tos
```

#### 5. Nginx Configuration Problems
```bash
# Test Nginx configuration
nginx -t

# Check Nginx logs
tail -f /var/log/nginx/error.log

# Restart Nginx
systemctl restart nginx
```

### Debugging Commands
```bash
# Run with maximum verbosity
ansible-playbook -vvvv deploy.yml -i inventory/staging/hosts --ask-vault-pass

# Check all host variables
ansible-inventory -i inventory/staging/hosts --list

# Test specific tasks only
ansible-playbook deploy.yml -i inventory/staging/hosts --ask-vault-pass --tags "nginx"
```

### Log Locations
- **Ansible Logs**: `./ansible.log`
- **Application Logs**: `/var/log/rea-bible-app/`
- **Nginx Logs**: `/var/log/nginx/`
- **PM2 Logs**: `~/.pm2/logs/`
- **System Logs**: `journalctl -u nginx`, `journalctl -u amazon-cloudwatch-agent`

## Emergency Procedures

### Application Recovery
```bash
# Restart application quickly
ansible all -i inventory/production/hosts -m shell -a "pm2 restart rea-bible-app" --ask-vault-pass

# Rollback to previous version (if needed)
ansible all -i inventory/production/hosts -m shell -a "cd /opt/bible-app/rea-bible-app && git checkout HEAD~1" --ask-vault-pass

# Check application health
curl -f https://api.seisho.emerj.net/api/v1/health
```

### SSL Emergency Fix
```bash
# Temporary HTTP fallback (emergency only)
ansible all -i inventory/production/hosts -m lineinfile -a "path=/etc/nginx/sites-available/rea-bible-app_production line='return 301 https://$server_name$request_uri;' state=absent" --ask-vault-pass
```

## Best Practices

### Security
- ✅ Always encrypt vault files before committing
- ✅ Never store passwords in plain text
- ✅ Use unique SSH keys for deployment
- ✅ Regularly rotate API keys and secrets
- ✅ Monitor CloudWatch logs instead of SSH access

### Deployment
- ✅ Always test in staging before production
- ✅ Use `--check` mode for dry runs
- ✅ Deploy during low-traffic periods
- ✅ Monitor application health after deployment
- ✅ Keep deployment logs for audit trails

### Maintenance
- ✅ Regular SSL certificate renewal verification
- ✅ Monitor disk space and system resources
- ✅ Update dependencies and security patches
- ✅ Backup configuration and secrets
- ✅ Document all manual changes

---
## Support Contacts
- **Team Lead**: Vault password and deployment authorization
- **DevOps**: Infrastructure and deployment issues
- **Backend Team**: Application-specific problems

---
*Last Updated: November 20, 2025*
*REA DevOps Stage 5 - Advanced Configuration Management*