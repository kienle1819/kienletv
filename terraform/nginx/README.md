# terraform docker nginx quick-start

This runs a nginx container with terraform

## Deploy

Deploy the docker container with Terraform:

```
terraform init
terraform plan
terraform apply
```

## Test

View containers:

```bash
docker ps
CONTAINER ID   IMAGE                       COMMAND                  CREATED          STATUS                 PORTS                   NAMES
6fa52d3be18b   eb4a57159180                "/docker-entrypoint.…"   44 seconds ago   Up 43 seconds          0.0.0.0:8000->80/tcp    nginx
```

Make a GET request against the nginx web server:

```bash
curl -I http://localhost:8000
HTTP/1.1 200 OK
Server: nginx/1.25.1
Date: Wed, 14 Jun 2023 21:26:53 GMT
Content-Type: text/html
Content-Length: 615
Last-Modified: Tue, 13 Jun 2023 15:08:10 GMT
Connection: keep-alive
ETag: "6488865a-267"
Accept-Ranges: bytes
```

## Cleanup

Delete the container with Terraform

```bash
terraform destroy
```
