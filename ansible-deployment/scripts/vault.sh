#!/bin/bash
# Helper script for managing Ansible Vault

VAULT_FILE="group_vars/all/vault.yml"
VAULT_PASSWORD_FILE=".vault_pass"

# Create a new vault password file if it doesn't exist
create_vault_pass() {
    if [ ! -f "$VAULT_PASSWORD_FILE" ]; then
        echo "Creating new vault password file..."
        openssl rand -base64 32 > "$VAULT_PASSWORD_FILE"
        chmod 600 "$VAULT_PASSWORD_FILE"
        echo "Created $VAULT_PASSWORD_FILE with random password"
    else
        echo "Vault password file already exists at $VAULT_PASSWORD_FILE"
    fi
}

# Edit the vault file
edit_vault() {
    ansible-vault edit "$VAULT_FILE" --vault-password-file "$VAULT_PASSWORD_FILE"
}

# Show vault contents
view_vault() {
    ansible-vault view "$VAULT_FILE" --vault-password-file "$VAULT_PASSWORD_FILE"
}

# Run ansible-playbook with vault
run_playbook() {
    ansible-playbook "$@" --vault-password-file "$VAULT_PASSWORD_FILE"
}

# Main script
case "$1" in
    create)
        create_vault_pass
        ;;
    edit)
        edit_vault
        ;;
    view)
        view_vault
        ;;
    run)
        shift
        run_playbook "$@"
        ;;
    *)
        echo "Usage: $0 {create|edit|view|run [playbook-args]}"
        exit 1
        ;;
esac
