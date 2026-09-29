# Variables
DATA_PATH = /home/eabushak/data
WP_DATA = $(DATA_PATH)/wordpress
DB_DATA = $(DATA_PATH)/mariadb
COMPOSE_FILE = srcs/docker-compose.yml

# Default target
all: build up

# Create local directories for Docker named volumes
$(WP_DATA):
	mkdir -p $(WP_DATA)

$(DB_DATA):
	mkdir -p $(DB_DATA)

# Build the containers
build: $(WP_DATA) $(DB_DATA)
	docker compose -f $(COMPOSE_FILE) build

# Start the containers in the background
up: $(WP_DATA) $(DB_DATA)
	docker compose -f $(COMPOSE_FILE) up -d

# Stop the containers
stop:
	docker compose -f $(COMPOSE_FILE) stop

# Start existing containers
start:
	docker compose -f $(COMPOSE_FILE) start

# Stop and remove containers and networks
down:
	docker compose -f $(COMPOSE_FILE) down

# Clean up stopped containers, unused networks, and dangling images
clean: down
	docker system prune -af

# Deep clean: remove everything including volumes and local data directories
fclean: clean
	docker volume prune -af
	sudo rm -rf $(DATA_PATH)

# Restart the entire setup from scratch
re: fclean all

.PHONY: all build up stop start down clean fclean re