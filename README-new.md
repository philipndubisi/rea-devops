# REA DevOps - Dynamic Nginx SSL Automation with Ansible

Advanced Ansible deployment system for the REA Interactive Bible Backend with **dynamic Jinja2 templating**, **automated SSL certificate management**, and **environment-specific configuration**.

## 🚀 Key Features Implemented

### ✅ Dynamic Variable Population
- **Environment-conditional domains**: Automatically resolves `staging.seisho.emerj.net` vs `seisho.emerj.net`
- **Dynamic port mapping**: Frontend/backend ports adapt based on environment
- **SSL path resolution**: Certificate paths automatically match resolved domains
- **Conditional logging**: JSON format for production, standard format for staging

### ✅ SSL/TLS Automation  
- **Automated Certbot installation** via snap package manager
- **Certificate generation** for both frontend and backend domains
- **Automatic renewal** with cron job scheduling (daily at 12:00 PM)
- **Dry-run testing** to validate renewal process
- **HTTPS redirection** with proper security headers

### ✅ Advanced Jinja2 Templates
- **nginx-main.conf.j2**: Dynamic main configuration with environment-specific settings
- **site-config.conf.j2**: Frontend/backend separation with dynamic domains and SSL
- **logrotate.j2**: Environment-specific log rotation policies

### ✅ Enhanced Security
- **Rate limiting** with environment-specific burst controls
- **CORS configuration** with dynamic origin matching
- **Security headers** including HSTS, CSP, and frame protection
- **SSL protocols** TLS 1.2/1.3 with strong cipher suites

## 📁 Project Structure

```
ansible-deployment/
├── deploy.yml                          # ✅ Main deployment playbook
├── inventory.example                   # ✅ Server configuration template
├── group_vars/                         # ✅ Dynamic variables
│   ├── all/all.yml                    # ✅ Common variables with Jinja2 logic  
│   ├── staging/vars.yml               # ✅ Staging overrides
│   └── production/vars.yml            # ✅ Production overrides
└── roles/nginx/                       # ✅ Complete Nginx role
    ├── tasks/main.yml                 # ✅ SSL automation & configuration
    ├── handlers/main.yml              # ✅ Service management
    └── templates/                     # ✅ Dynamic Jinja2 templates
        ├── nginx-main.conf.j2         # ✅ Main nginx configuration
        ├── site-config.conf.j2        # ✅ Site-specific configuration  
        └── logrotate.j2               # ✅ Log rotation setup
```

## 🎯 Dynamic Variable Examples

### Domain Resolution
```yaml
# Automatically resolves based on env_name
frontend_domain: "{{ 'seisho.emerj.net' if env_name == 'production' else 'staging.seisho.emerj.net' }}"
backend_domain: "{{ 'api.seisho.emerj.net' if env_name == 'production' else 'api.staging.seisho.emerj.net' }}"
```

### SSL Automation  
```yaml
# Dynamic certificate paths
ssl_cert_path: "/etc/letsencrypt/live/{{ frontend_domain }}/fullchain.pem"
ssl_key_path: "/etc/letsencrypt/live/{{ frontend_domain }}/privkey.pem"
```

### Environment-Specific Settings
```yaml
# Production: Strict rate limiting, JSON logs, aggressive caching
# Staging: Relaxed limits, debug logs, no caching
api_rate_limit: "{{ '10r/s' if env_name == 'production' else '100r/s' }}"
log_level: "{{ 'error' if env_name == 'production' else 'debug' }}"
enable_api_cache: "{{ true if env_name == 'production' else false }}"
```

## ⚡ Quick Deployment

### 1. Configure Inventory
```bash
cp inventory.example inventory
# Edit inventory with your server details
```

### 2. Deploy to Staging
```bash
ansible-playbook -i inventory deploy.yml --extra-vars "env_name=staging"
```

### 3. Deploy to Production  
```bash
ansible-playbook -i inventory deploy.yml --extra-vars "env_name=production"
```

## 🔐 SSL Certificate Management

### Automatic Features
- ✅ **Certbot installation** via snap
- ✅ **Certificate generation** for frontend/backend domains  
- ✅ **Renewal automation** (cron job at 12:00 PM daily)
- ✅ **Dry-run testing** during deployment
- ✅ **HTTPS redirection** with security headers

### Manual Operations
```bash
# Check certificate status
sudo certbot certificates

# Test renewal process
sudo certbot renew --dry-run

# Manual renewal (if needed)
sudo certbot renew --force-renewal
```

## 📊 Log Management & Rotation

### Dynamic Log Paths
```yaml
# Environment-specific log locations
nginx_access_log: "{{ nginx_log_dir }}/{{ env_name }}-{{ app_name }}-access.log"
nginx_error_log: "{{ nginx_log_dir }}/{{ env_name }}-{{ app_name }}-error.log"
```

### Log Rotation Policy
- **Production**: Daily rotation, 365-day retention, 1GB max size
- **Staging**: Daily rotation, 52-day retention, 500MB max size
- **Error logs**: Separate rotation with shorter retention periods

### Log Formats
```yaml
# Production: Structured JSON logging
# Staging: Human-readable format for debugging
log_format_type: "{{ 'json' if env_name == 'production' else 'main' }}"
```

## 🛡️ Security & Performance

### Rate Limiting (Environment-Specific)
```yaml
# Production: Strict limits
api_rate_limit: "10r/s" (burst: 20)
auth_rate_limit: "3r/m" (burst: 5)

# Staging: Relaxed limits  
api_rate_limit: "100r/s" (burst: 50)
auth_rate_limit: "10r/m" (burst: 10)
```

### Caching Strategy
- **Production**: Aggressive API caching (10min), static assets (1 year)
- **Staging**: No caching for immediate development feedback

### Security Headers
- **HSTS** with preload and subdomain inclusion
- **Content Security Policy** with strict directives
- **X-Frame-Options**, **X-Content-Type-Options**
- **Dynamic CORS** matching frontend domain

## 🔧 Deployment Options

### Environment-Specific
```bash
# Staging deployment
ansible-playbook -i inventory deploy.yml --extra-vars "env_name=staging"

# Production deployment  
ansible-playbook -i inventory deploy.yml --extra-vars "env_name=production"
```

### Component-Specific
```bash
# SSL and Nginx only
ansible-playbook -i inventory deploy.yml --tags "nginx,ssl"

# Database components only
ansible-playbook -i inventory deploy.yml --tags "database"
```

### Verification
```bash
# Test configuration
ansible-playbook -i inventory deploy.yml --tags "verify"
```

## 📋 Post-Deployment Verification

The deployment automatically verifies:

✅ **SSL Certificate Status**: HTTPS accessibility  
✅ **Nginx Configuration**: Syntax validation  
✅ **Service Health**: HTTP/HTTPS response codes  
✅ **Log Rotation**: Logrotate configuration  
✅ **Firewall Rules**: Port 80/443 accessibility  

### Manual Health Checks
```bash
# SSL certificate verification
curl -I https://seisho.emerj.net
curl -I https://api.seisho.emerj.net/health

# Rate limiting test
for i in {1..15}; do curl -I https://api.seisho.emerj.net/api/test; done
```

## 🌐 Access Points

After deployment, your application will be available at:

- **Frontend**: `https://seisho.emerj.net` (production) / `https://staging.seisho.emerj.net` (staging)
- **Backend API**: `https://api.seisho.emerj.net` (production) / `https://api.staging.seisho.emerj.net` (staging)  
- **Health Check**: `https://api.seisho.emerj.net/health`
- **API Docs**: `https://api.seisho.emerj.net/api-docs` (staging only)

---

**Status**: ✅ **Complete Implementation**  
- Dynamic variable population with Jinja2 conditionals
- Automated Certbot SSL certificate generation and renewal  
- HTTPS redirection with comprehensive security headers
- Environment-specific Nginx configuration with rate limiting
- Automated log rotation with retention policies