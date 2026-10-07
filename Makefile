DATA_PATH = /home/eabushak/data
WP_DATA = $(DATA_PATH)/wordpress
DB_DATA = $(DATA_PATH)/mariadb
COMPOSE_FILE = srcs/docker-compose.yml

all: build up

$(WP_DATA):
	mkdir -p $(WP_DATA)

$(DB_DATA):
	mkdir -p $(DB_DATA)


build: $(WP_DATA) $(DB_DATA)
	docker compose -f $(COMPOSE_FILE) build


up: $(WP_DATA) $(DB_DATA)
	docker compose -f $(COMPOSE_FILE) up -d


stop:
	docker compose -f $(COMPOSE_FILE) stop


start:
	docker compose -f $(COMPOSE_FILE) start


down:
	docker compose -f $(COMPOSE_FILE) down

clean: down
	docker system prune -af

fclean: clean
	docker volume prune -af
	sudo rm -rf $(DATA_PATH)


re: fclean all

.PHONY: all build up stop start down clean fclean re