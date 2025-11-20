# REA DevOps Advanced Configuration Management Runbook

## Overview
This runbook provides comprehensive instructions for deploying applications using our unified Ansible-based configuration management system that handles both staging and production environments.

## Architecture
- **Controller Node**: Central Ansible server managing deployments
- **Target Environments**: Staging and Production servers
- **Security**: Ansible Vault for secrets, SSH key authentication
- **Observability**: Centralized CloudWatch logging, no SSH debugging

## Prerequisites
1. Access to the Ansible Controller Server
2. Vault password from Team Lead
3. Validated SSH key pair for target servers
4. AWS credentials for CloudWatch (if using)

## Security Setup

### 1. SSH Key Encryption
```bash
# Encrypt the deployment private key (REQUIRED)
ansible-vault encrypt group_vars/all/vault.yml

# Encrypt environment-specific secrets
ansible-vault encrypt group_vars/staging/vault.yml
ansible-vault encrypt group_vars/production/vault.yml
   cd rea-devops/ansible-deployment
   ```

2. **Set up inventory**
   - Staging: `inventory/staging/host.ini`
   - Production: `inventory/production/host.ini`

3. **Configure SSH**
   Ensure your SSH key is added to the agent:
   ```bash
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/your_deploy_key
   ```

## Vault Management

### Create/Edit Vault
```bash
# Edit vault file
./scripts/vault.sh edit

# View vault contents
./scripts/vault.sh view
```

### Encrypting Secrets
```bash
# Encrypt a string
ansible-vault encrypt_string 'your_secret' --name 'vault_secret_name' --vault-password-file .vault_pass
```

## Common Operations

### Test Connectivity
```bash
# Test connection to all hosts
ansible all -m ping -i inventory/staging/

# Test connection to a specific group
ansible app_servers -m ping -i inventory/production/
```

### Run Playbooks
```bash
# Run deployment playbook for staging
ansible-playbook deploy.yml -i inventory/staging/ -e "env=staging" --vault-password-file .vault_pass

# Run with tags (e.g., only nginx tasks)
ansible-playbook deploy.yml -i inventory/production/ -e "env=production" --tags "nginx"
```

### Common Tags
- `setup`: Initial server setup
- `deploy`: Application deployment
- `nginx`: Nginx configuration
- `ssl`: SSL certificate management
- `restart`: Restart services

## Troubleshooting

### Common Issues
1. **SSH Connection Issues**
   - Verify SSH key is added to the agent
   - Check inventory file for correct IPs and usernames
   - Test SSH connection manually: `ssh user@host`

2. **Vault Decryption Errors**
   - Ensure `.vault_pass` file exists and is readable
   - Verify vault password is correct
   - Try re-encrypting the vault file

3. **Permission Denied**
   - Use `-b` or `--become` for privileged operations
   - Ensure sudo access is configured on target hosts

### Debugging
```bash
# Increase verbosity
ansible-playbook -vvv deploy.yml -i inventory/staging/

# Check host variables
ansible -m setup hostname -i inventory/staging/
```

### Logs
- Ansible logs: Check the console output
- Application logs: `/var/log/your-app/`
- System logs: `journalctl -u your-service`

## Best Practices
- Always test in staging before production
- Use tags to run specific parts of the playbook
- Keep vault password secure and never commit it
- Document all custom variables in `group_vars/`
- Use `--check` mode for dry runs

---
*Last Updated: $(date +%Y-%m-%d)*