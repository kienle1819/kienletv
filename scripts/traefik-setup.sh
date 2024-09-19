#!/bin/bash

# Function to check if a variable is empty
check_variable() {
    if [ -z "$2" ]; then
        echo "Error: $1 is required."
        exit 1
    fi
}

# Input variables
read -p "Enter the path for docker compose file directory for Traefik: " TRAEFIK_DIR
check_variable "Traefik directory" "$TRAEFIK_DIR"

read -p "Enter the Traefik domain (e.g., traefik.domain.com): " TRAEFIK_DOMAIN
check_variable "Traefik domain" "$TRAEFIK_DOMAIN"

read -p "Enter the Traefik dashboard username: " TRAEFIK_USER
check_variable "Traefik dashboard username" "$TRAEFIK_USER"

read -s -p "Enter the Traefik dashboard password: " TRAEFIK_PASS
echo
check_variable "Traefik dashboard password" "$TRAEFIK_PASS"

read -p "Enter your email address for Let's Encrypt notifications: " LETSENCRYPT_EMAIL
check_variable "Let's Encrypt email" "$LETSENCRYPT_EMAIL"

echo "
IMPORTANT: Ensure that the domain $TRAEFIK_DOMAIN is pointing to this server's IP address before proceeding.
If it's not, the SSL certificate generation may fail.
"
read -p "Press Enter to continue or Ctrl+C to exit..."

# Install Docker
echo "Installing Docker..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  jammy stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-compose

# Create directories
echo "Creating directories..."
sudo mkdir -p "$TRAEFIK_DIR"
cd "$TRAEFIK_DIR"

# Create docker-compose.yml
echo "Creating docker-compose.yml..."
cat << EOF > docker-compose.yml
services:
  traefik:
    image: traefik:v3.1
    container_name: traefik
    restart: unless-stopped
    command:
      - --api.dashboard=true
      - --providers.docker=true
      - --providers.docker.exposedbydefault=false
      - --entrypoints.http.address=:80
      - --entrypoints.http.http.redirections.entrypoint.to=https
      - --entrypoints.http.http.redirections.entrypoint.scheme=https
      - --entryPoints.https.address=:443
      - --certificatesresolvers.letsencrypt.acme.tlschallenge=true
      - --certificatesresolvers.letsencrypt.acme.email=$LETSENCRYPT_EMAIL
      - --certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json
    security_opt:
      - no-new-privileges:true
    networks:
      - traefik-net
    ports:
      - 80:80
      - 443:443
    environment:
      TRAEFIK_DASHBOARD_CREDENTIALS: \${TRAEFIK_DASHBOARD_CREDENTIALS}
    env_file: .env
    volumes:
      - ./letsencrypt:/letsencrypt
      - /var/run/docker.sock:/var/run/docker.sock:ro
    labels:
      - traefik.enable=true
      - traefik.http.routers.traefik-secure.rule=Host(\`$TRAEFIK_DOMAIN\`)
      - traefik.http.routers.traefik-secure.entrypoints=https
      - traefik.http.routers.traefik-secure.service=api@internal
      - traefik.http.routers.traefik-secure.tls.certresolver=letsencrypt
      - traefik.http.routers.traefik-secure.middlewares=traefik-auth
      - traefik.http.middlewares.traefik-auth.basicauth.users=\${TRAEFIK_DASHBOARD_CREDENTIALS}
      - traefik.http.routers.traefik-secure.tls=true
networks:
  traefik-net:
    external: true
EOF

# Create Docker Network
echo "Creating Docker network..."
docker network create traefik-net

# Install apache2-utils
echo "Installing apache2-utils..."
sudo apt update
sudo apt install -y apache2-utils

# Create .env file with TRAEFIK_DASHBOARD_CREDENTIALS
echo "Creating .env file..."
CREDENTIALS=$(htpasswd -nb $TRAEFIK_USER $TRAEFIK_PASS | sed -e s/\\$/\\$\\$/g)
echo "TRAEFIK_DASHBOARD_CREDENTIALS=$CREDENTIALS" > .env

# Start the Docker Compose file with force rebuild
echo "Starting Docker Compose..."
docker compose up -d --force-recreate

# Check logs
echo "Checking Traefik logs..."
docker logs traefik

echo "Traefik setup complete. Access the dashboard at https://$TRAEFIK_DOMAIN"
