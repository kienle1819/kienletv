---
# LAB DEMO NGINX SERVER
- OS: Ubuntu 22.04 LTS
- Docker, docker compose
# STEP BY STEP
## Install Nginx
```
sudo apt update
sudo apt install nginx
systemctl status nginx
```
## Install Docker docker compose
```
sudo apt update
sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
apt-cache policy docker-ce
sudo apt install docker-ce
sudo systemctl status docker
sudo usermod -aG docker ${USER}
su - ${USER}
sudo usermod -aG docker username

mkdir -p ~/.docker/cli-plugins/
curl -SL https://github.com/docker/compose/releases/download/v2.3.3/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
chmod +x ~/.docker/cli-plugins/docker-compose
docker compose version

```
## Run docker create web1 & web2
```
cd nginx
docker compose up -d
docke compose ps
```
## Public web1 & web2 with subdomain
```
cd /etc/nginx/sites-available

vim web1
'server {
  server_name  web1.tova17.site;

  error_log /var/log/nginx/web1.tova17.site-error.log;
  access_log /var/log/nginx/web1.tova17.site-access.log;

  fastcgi_buffers 16 16k;
  fastcgi_buffer_size 32k;
  client_max_body_size 128m;

  location / {
    proxy_pass http://127.0.0.1:8080;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_http_version 1.1;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header Host $host;
  }
}'

vim web2
'server {
  server_name  web2.tova17.site;

  error_log /var/log/nginx/web2.tova17.site-error.log;
  access_log /var/log/nginx/web2.tova17.site-access.log;

  fastcgi_buffers 16 16k;
  fastcgi_buffer_size 32k;
  client_max_body_size 128m;

  location / {
    proxy_pass http://127.0.0.1:8081;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_http_version 1.1;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header Host $host;
  }
}'

cd /etc/nginx/sites-enable
ln -sf ../sites-available/web1 .
ln -sf ../sites-available/web2 .
ngin -t
nginx -s reload
```
## Point domain on Cloudflare
- web1.tova17.site -> IP VPS
- web2.tova17.site -> IP VPS
## Test web1 & web2
Access browser and see content. Check certificate on web1 & web2 
- web1.tova17.site
- web2.tova17.site 