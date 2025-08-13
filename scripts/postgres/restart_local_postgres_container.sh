docker stop postgres || true && docker rm postgres || true

echo 'Stopped and removed the old db container (if any)'

docker run --name postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_HOST_AUTH_METHOD=trust -p 5432:5432 postgres:17.2 &