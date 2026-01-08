NAME = inception
COMPOSE = docker compose
SRC_DIR = srcs
COMPOSE_FILE = $(SRC_DIR)/docker-compose.yml
DATA_DIR = /home/tmillot/data

all: up

up:
	mkdir -p $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress
	$(COMPOSE) -f $(COMPOSE_FILE) up -d --build

down:
	$(COMPOSE) -f $(COMPOSE_FILE) down

stop:
	$(COMPOSE) -f $(COMPOSE_FILE) stop

start:
	$(COMPOSE) -f $(COMPOSE_FILE) start

restart: down up

clean:
	$(COMPOSE) -f $(COMPOSE_FILE) down -v --rmi all
	sudo rm -rf $(DATA_DIR)/mariadb/*
	sudo rm -rf $(DATA_DIR)/wordpress/*

fclean: clean
	docker system prune -af
	sudo rm -rf $(DATA_DIR)

re: fclean up

.PHONY: all up down stop start restart clean fclean re
