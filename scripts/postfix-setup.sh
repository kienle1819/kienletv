#!/bin/bash

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a setup.log
}

# Function to check if a command succeeded
check_command() {
    if [ $? -ne 0 ]; then
        log "Error: $1"
        exit 1
    fi
}

# Function to backup a file
backup_file() {
    if [ -f "$1" ]; then
        sudo cp "$1" "${1}.bak"
        check_command "Failed to backup $1"
        log "Backed up $1 to ${1}.bak"
    fi
}

# Step 1: Configure SMTP (This part is manual - might need domain verification)
log "Step 1: Make sure you have already set up your domain with your SMTP provider and added any necessary DNS records (like SPF, DKIM, and CNAME)."

# Prompt user for SMTP credentials
read -p "Enter your SMTP Username: " smtp_username
while [ -z "$smtp_username" ]; do
    read -p "SMTP Username cannot be empty. Please enter it: " smtp_username
done

read -sp "Enter your SMTP Password: " smtp_password
echo
while [ -z "$smtp_password" ]; do
    read -sp "SMTP Password cannot be empty. Please enter it: " smtp_password
    echo
done

read -p "Enter the domain you are using with your SMTP provider (e.g. example.com): " domain
while [ -z "$domain" ]; do
    read -p "Domain cannot be empty. Please enter it: " domain
done

read -p "Enter the sender email address (optional, press Enter to skip): " sender_email

read -p "Enter your Postfix hostname (e.g. yourdomain.com): " postfix_hostname
while [ -z "$postfix_hostname" ]; do
    read -p "Postfix hostname cannot be empty. Please enter it: " postfix_hostname
done

# Prompt user for SMTP server (with port)
read -p "Enter your SMTP server with port (e.g. [smtp.provider.com]:587): " smtp_server
while [ -z "$smtp_server" ]; do
    read -p "SMTP server cannot be empty. Please enter it: " smtp_server
done

# Step 2: Update and Install Postfix if needed
log "Step 2: Updating system and installing Postfix..."
sudo DEBIAN_FRONTEND=noninteractive apt-get update
check_command "Failed to update system"
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mailutils
check_command "Failed to install mailutils"

# Step 3: Configure Postfix
log "Step 3: Configuring Postfix..."
backup_file "/etc/postfix/main.cf"

sudo postconf -e "relayhost = $smtp_server"
sudo postconf -e "smtp_sasl_auth_enable = yes"
sudo postconf -e "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd"
sudo postconf -e "smtp_sasl_security_options = noanonymous"
sudo postconf -e "smtp_tls_security_level = may"
sudo postconf -e "header_size_limit = 4096000"
check_command "Failed to configure Postfix"

# Step 4: Create sasl_passwd file with SMTP credentials
log "Step 4: Creating /etc/postfix/sasl_passwd file with SMTP credentials..."
backup_file "/etc/postfix/sasl_passwd"

sudo bash -c "cat > /etc/postfix/sasl_passwd << EOF
$smtp_server $smtp_username:$smtp_password
EOF"
check_command "Failed to create sasl_passwd file"

# Secure the sasl_passwd file and create the hash database
log "Securing /etc/postfix/sasl_passwd and creating hash..."
sudo postmap /etc/postfix/sasl_passwd
check_command "Failed to create hash database"
sudo chown root:root /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
sudo chmod 0600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
check_command "Failed to secure sasl_passwd files"

# Step 5: Configure or reset sender address settings
log "Step 5: Configuring sender address settings..."
if [ ! -z "$sender_email" ]; then
    log "Configuring sender address for outgoing emails..."
    backup_file "/etc/postfix/sender_canonical"
    backup_file "/etc/postfix/smtp_header_checks"

    sudo postconf -e "sender_canonical_classes = envelope_sender, header_sender"
    sudo postconf -e "sender_canonical_maps = regexp:/etc/postfix/sender_canonical"
    sudo postconf -e "smtp_header_checks = regexp:/etc/postfix/smtp_header_checks"

    sudo bash -c "cat > /etc/postfix/sender_canonical << EOF
/.+/ $sender_email
EOF"
    check_command "Failed to create sender_canonical file"

    sudo bash -c "cat > /etc/postfix/smtp_header_checks << EOF
/From:.*/ REPLACE From: $sender_email
EOF"
    check_command "Failed to create smtp_header_checks file"

    # Create hash databases for the new files
    sudo postmap /etc/postfix/sender_canonical
    sudo postmap /etc/postfix/smtp_header_checks
else
    log "Resetting sender address configuration..."
    sudo postconf -# sender_canonical_classes
    sudo postconf -# sender_canonical_maps
    sudo postconf -# smtp_header_checks
    
    # Remove files if they exist
    sudo rm -f /etc/postfix/sender_canonical /etc/postfix/sender_canonical.db
    sudo rm -f /etc/postfix/smtp_header_checks /etc/postfix/smtp_header_checks.db
fi

# Step 6: Ensure the sending domain is correct in /etc/mailname
log "Step 6: Configuring /etc/mailname..."
backup_file "/etc/mailname"

sudo bash -c "echo $postfix_hostname > /etc/mailname"
check_command "Failed to configure /etc/mailname"

# Step 7: Restart Postfix to apply changes
log "Step 7: Restarting Postfix..."
sudo postfix reload
check_command "Failed to restart Postfix"

log "All done! Postfix has been configured with your SMTP settings."
