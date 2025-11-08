## ---------------------------------------------------------
## Comando base para docker-compose
## ---------------------------------------------------------

DOCKER_COMPOSE = docker compose -f ./.docker/docker-compose.yml
APP_DIR = /var/www/html

## ---------------------------------------------------------
## Inicialización de la Aplicación
## ---------------------------------------------------------

.PHONY: init-app
init-app: copy-env create-symlink up prepare-storage composer-install migracion npm-install compile print-urls

.PHONY: copy-env
copy-env:
	@ [ ! -f .env ] && cp .env.example .env || true

.PHONY: create-symlink
create-symlink:
	@ [ -L .docker/.env ] || ln -s ../.env .docker/.env

.PHONY: up
up:
	$(DOCKER_COMPOSE) up -d

.PHONY: prepare-storage
prepare-storage:
	$(DOCKER_COMPOSE) exec php_apache_red_social bash -c "mkdir -p $(APP_DIR)/storage/framework/{cache,data,sessions,views} $(APP_DIR)/storage/logs && chmod -R 777 $(APP_DIR)/storage $(APP_DIR)/bootstrap"

.PHONY: composer-install
composer-install:
	$(DOCKER_COMPOSE) exec php_apache_red_social bash -c "cd $(APP_DIR) && composer install --no-interaction --prefer-dist"

.PHONY: migracion
migracion:
	@echo "⏳ Esperando a que MySQL esté disponible..."
	@sleep 5
	$(DOCKER_COMPOSE) exec php_apache_red_social bash -c "cd $(APP_DIR) && php artisan migrate --seed"
	@echo "Migraciones aplicadas!"

.PHONY: npm-install
npm-install:
	$(DOCKER_COMPOSE) exec php_apache_red_social bash -c "cd $(APP_DIR) && npm install"

.PHONY: compile
compile:
	$(DOCKER_COMPOSE) exec php_apache_red_social bash -c "cd $(APP_DIR) && npm run build"

.PHONY: print-urls
print-urls:
	@echo "## Acceso a la Aplicación:   http://localhost:8081/"
	@echo "## Acceso a PhpMyAdmin:      http://localhost:8082/"

## ---------------------------------------------------------
## Gestión de contenedores
## ---------------------------------------------------------

.PHONY: down
down:
	$(DOCKER_COMPOSE) down

.PHONY: restart
restart:
	$(DOCKER_COMPOSE) restart

.PHONY: ps
ps:
	$(DOCKER_COMPOSE) ps

.PHONY: logs
logs:
	$(DOCKER_COMPOSE) logs

.PHONY: build
build:
	$(DOCKER_COMPOSE) build

.PHONY: stop
stop:
	$(DOCKER_COMPOSE) stop

.PHONY: shell
shell:
	$(DOCKER_COMPOSE) exec --user pablogarciajc php_apache_red_social /bin/sh -c "cd $(APP_DIR); exec bash -l"

.PHONY: rollback
rollback:
	$(DOCKER_COMPOSE) exec php_apache_red_social bash -c "cd $(APP_DIR) && php artisan migrate:rollback"

.PHONY: test
test:
	$(DOCKER_COMPOSE) exec php_apache_red_social bash -c "cd $(APP_DIR) && php artisan test"

## ---------------------------------------------------------
## Limpieza de cache
## ---------------------------------------------------------
.PHONY: clean-cache
clean-cache:
	$(DOCKER_COMPOSE) exec php_apache_red_social bash -c "rm -rf $(APP_DIR)/storage/framework/cache/data/* $(APP_DIR)/bootstrap/cache/*"




.PHONY: clean-docker
clean-docker:
	sudo docker rmi -f $$(sudo docker images -q) || true
	sudo docker volume rm $$(sudo docker volume ls -q) || true
	sudo docker network prune -f || true