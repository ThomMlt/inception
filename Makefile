NAME = inception
COMPOSE = docker compose
SRC_DIR = srcs
COMPOSE_FILE = $(SRC_DIR)/docker-compose.yml

all: up

up:
	$(COMPOSE) -f $(COMPOSE_FILE) up -d --build

down:
	$(COMPOSE) -f $(COMPOSE_FILE) down

stop:
	$(COMPOSE) -f $(COMPOSE_FILE) stop

start:
	$(COMPOSE) -f $(COMPOSE_FILE) start

restart: down up

clean:
	$(COMPOSE) -f $(COMPOSE_FILE) down -v

fclean: clean
	docker system prune -af

re: fclean up

.PHONY: all up down stop start restart clean fclean re
