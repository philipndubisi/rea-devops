# REA DevOps - Stage 5: Advanced Configuration Management

[![Deployment Status](https://img.shields.io/badge/Stage%205-Complete-green.svg)]
[![Backend API](https://img.shields.io/badge/Backend-Node.js%20API-blue.svg)]
[![Ansible](https://img.shields.io/badge/Ansible-Configuration%20Management-red.svg)]

## 🎯 Project Overview

This repository contains the **Stage 5 Advanced Configuration Management** implementation for the REA Interactive Bible Backend API. The system uses a unified Ansible-based deployment strategy that manages both staging and production environments through a single universal playbook with dynamic environment detection.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Controller    │    │   Staging API   │    │  Production API │
│   (Ansible)     │───▶│   Environment   │    │   Environment   │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────── Vault ───────┴───────────────────────┘
                 Encrypted
```

### Core Components
- **Backend API**: Node.js application with RESTful endpoints
- **Process Management**: PM2 with clustering and auto-restart
- **Reverse Proxy**: Nginx with SSL termination and health checks
- **Monitoring**: CloudWatch centralized logging (no SSH required)
- **Security**: Ansible Vault encryption for all secrets
- **SSL**: Automated Let's Encrypt certificate management

## 🚀 Quick Start

### Prerequisites
- Ansible 2.9+
- SSH access to target servers
- AWS credentials (for CloudWatch)
- Domain names configured

### Initial Setup
```bash
# Clone repository
git clone https://github.com/philipndubisi/rea-devops.git
cd rea-devops/ansible-deployment

# Validate configuration
bash scripts/validate.sh

# Set up vault password
./scripts/vault.sh create
```

### Configuration
1. **Update Server Details**: Edit `inventory/staging/hosts` and `inventory/production/hosts`
2. **Add SSH Key**: Update `group_vars/all/vault.yml` with your deployment key
3. **Configure Secrets**: Update `secrets/staging.env` and `secrets/prod.env`
4. **Encrypt Vault**: Run `ansible-vault encrypt group_vars/all/vault.yml`

### Deploy
```bash
# Deploy to staging
./scripts/deploy.sh staging

# Deploy to production
./scripts/deploy.sh production
```

## 📁 Project Structure

```
ansible-deployment/
├── 📄 deploy.yml                     # Universal deployment playbook
├── ⚙️ ansible.cfg                   # Ansible configuration
├── 📋 runbook.md                    # Comprehensive operations guide
├── 📊 scripts/
│   ├── deploy.sh                    # Automated deployment script
│   ├── vault.sh                     # Vault management utilities
│   └── validate.sh                  # Configuration validator
├── 🗂️ inventory/
│   ├── staging/hosts               # Staging server inventory
│   └── production/hosts            # Production server inventory
├── ⚡ group_vars/
│   ├── all/
│   │   ├── all.yml                 # Common variables
│   │   └── vault.yml               # Encrypted secrets (SSH keys)
│   ├── staging/
│   │   ├── vars.yml                # Staging configuration
│   │   └── vault.yml               # Staging secrets
│   └── production/
│       ├── vars.yml                # Production configuration
│       └── vault.yml               # Production secrets
├── 🔐 secrets/
│   ├── staging.env                 # Staging environment variables
│   └── prod.env                    # Production environment variables
├── 📝 templates/
│   ├── nginx.conf.j2               # Nginx reverse proxy template
│   ├── ecosystem.config.js.j2      # PM2 process configuration
│   └── cloudwatch-config.json.j2   # CloudWatch agent setup
└── 🔧 roles/
    ├── application/                # Backend API deployment
    ├── nginx/                      # Reverse proxy setup
    ├── cloudwatch/                 # Monitoring configuration
    └── common/                     # Shared server setup
```

## ⚡ Key Features

### 🔄 Universal Deployment
- **Single Playbook**: One `deploy.yml` handles both environments
- **Dynamic Detection**: Automatic environment identification
- **Environment Isolation**: Separate configurations and secrets

### 🔐 Security First
- **Vault Encryption**: All sensitive data encrypted with Ansible Vault
- **SSH Key Management**: Secure deployment key handling
- **No Plain Text Secrets**: Environment variables managed securely

### 🚀 Production Ready
- **PM2 Clustering**: Multi-process application management
- **Auto-restart**: SystemD integration for server reboots
- **Health Monitoring**: Built-in health check endpoints
- **SSL Automation**: Let's Encrypt with auto-renewal

### 📊 Observability
- **CloudWatch Integration**: Centralized log aggregation
- **No SSH Required**: Complete debugging without server access
- **Multiple Log Streams**: Application, error, nginx, and system logs
- **Performance Metrics**: CPU, memory, and disk monitoring

## 🛠️ API Endpoints

### Health Checks
- **Staging**: `https://api-staging.seisho.emerj.net/api/v1/health`
- **Production**: `https://api.seisho.emerj.net/api/v1/health`

### Backend API
- **Base URL (Staging)**: `https://api-staging.seisho.emerj.net/api/v1`
- **Base URL (Production)**: `https://api.seisho.emerj.net/api/v1`

## 🔍 Monitoring & Logs

### CloudWatch Log Groups
- **Staging**: `/aws/ec2/rea-bible-app/staging`
- **Production**: `/aws/ec2/rea-bible-app/production`

### Log Streams
- `{instance_id}-app-logs`: Application output
- `{instance_id}-error-logs`: Error logs
- `{instance_id}-nginx-access`: HTTP access logs
- `{instance_id}-nginx-error`: Nginx error logs
- `{instance_id}-syslog`: System logs

### Monitoring Commands
```bash
# View application logs
aws logs get-log-events --log-group-name "/aws/ec2/rea-bible-app/staging" \
    --log-stream-name "i-1234567890-app-logs"

# Check PM2 status
ansible all -i inventory/staging/hosts -m shell -a "pm2 list" --ask-vault-pass

# Monitor system health
curl -f https://api-staging.seisho.emerj.net/api/v1/health
```

## 📋 Compliance & Standards

### ✅ Stage 5 Requirements Met
- ✅ **No CI/CD Pipelines**: Pure configuration management approach
- ✅ **One Playbook Rule**: Single universal deployment playbook
- ✅ **No SSH Debugging**: CloudWatch centralized logging only
- ✅ **Strict Naming**: Consistent file paths and log group conventions

### 🔒 Security Standards
- ✅ All secrets encrypted with Ansible Vault
- ✅ Private keys never stored unencrypted
- ✅ Environment isolation through group variables
- ✅ Proper file permissions and user management

## 🆘 Support

### Quick Help
```bash
# Validate setup
bash scripts/validate.sh

# Check connectivity
ansible all -i inventory/staging/hosts -m ping --ask-vault-pass

# Run deployment test
ansible-playbook deploy.yml -i inventory/staging/hosts --ask-vault-pass --check
```

### Documentation
- **Full Operations Guide**: See [runbook.md](ansible-deployment/runbook.md)
- **Implementation Details**: See [STAGE5_IMPLEMENTATION_SUMMARY.md](STAGE5_IMPLEMENTATION_SUMMARY.md)

### Troubleshooting
- Check [runbook.md](ansible-deployment/runbook.md#troubleshooting) for common issues
- Use `-vvv` flag for verbose Ansible output
- Monitor CloudWatch logs for application issues

## 👥 Team

- **Repository**: [philipndubisi/rea-devops](https://github.com/philipndubisi/rea-devops)
- **Branch**: `kolawole`
- **Stage**: 5 - Advanced Configuration Management
- **Status**: ✅ Complete and Production Ready

---

## 📊 Deployment Status

| Environment | Status | Last Deployed | Health Check |
|-------------|--------|---------------|-------------|
| Staging | 🟢 Ready | - | `https://api-staging.seisho.emerj.net/api/v1/health` |
| Production | 🟢 Ready | - | `https://api.seisho.emerj.net/api/v1/health` |

---

**REA DevOps Stage 5 - Advanced Configuration Management**  
*Backend API deployment with unified Ansible configuration*

🚀 **Ready for Production Deployment** 🚀
