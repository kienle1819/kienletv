```
mkdir /home/gitlab-runner

docker run -d \
  --name gitlab-runner \
  --restart always \
  -v /home/gitlab-runner/config:/etc/gitlab-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  gitlab/gitlab-runner:latest

docker exec --tty gitlab-runner \
  gitlab-runner register -n \
  --url https://gitlab.com/ \
  --registration-token <token project> \
  --executor docker \
  --description "Docker-Runner" \
  --docker-image "docker:latest" \
  --docker-volumes /var/run/docker.sock:/var/run/docker.sock
```  
