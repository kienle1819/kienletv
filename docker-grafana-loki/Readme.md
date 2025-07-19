### How to
```
sudo mkdir -p ./data/grafana/data
sudo chown -R 472:472 ./data/grafana/data
docker-compose -f docker-compose-loki.yml up -d
docker-compose -f docker-compose-fluentbit.yml up -d
docker-compose -f docker-compose-app.yml up -d
curl http://localhost:8080/

```
### Full
```
docker-compose up -d

```
