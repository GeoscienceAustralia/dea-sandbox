# Build the default sudo image using Docker Compose
build:
	docker-compose build

# Start up an environment with a database
up:
	docker-compose up

# Start up an environment without a database
up-k8s:
	docker-compose -f docker-compose.yml up
