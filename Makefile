# *DREDGER - THE OUTER/EDGE DOCKER DEV TOOL*
# To see a list of available commands execute "make help"

SHELL   = bash
MOUNT   = $${DREDGER_MOUNT:-$(CURDIR)}
NAME    = $${DREDGER_NAME:-$(shell basename $(MOUNT))}
HOST    = $${DREDGER_HOST:-$(NAME).localhost}
HOST_IP = $${DREDGER_HOST_IP:-172.17.0.1}
VOLUME  = $${DREDGER_VOLUME:-/var/www}
PORT    = $${DREDGER_PORT:-80}
USER    = $${DREDGER_USER:-root}
PWD     = $${DREDGER_PWD:-$(CURDIR)}

.PHONY: help build run bash status restart destroy logs clean install update self-update info inspect

help::
	echo 'Usage: dredger [command]'
	echo ''
	echo 'Commands:'
	echo ''
	echo '  build		- Build the image and copy the built files if no local changes'
	echo '  run		- Run the container and proxy'
	echo '  bash		- Enter running container with bash'
	echo '  status	- Show the status of running container'
	echo '  logs		- Show logs'
	echo '  copy		- Copy files from the container to the local folder'
	echo '  restart	- Restarts the running container'
	echo '  destroy   	- Stops the running container and deletes it'
	echo '  install	- Run app install scripts (defaults to `composer install`)'
	echo '  update	- Run app update scripts (defaults to `composer update`)'
	echo '  info		- Show Dredger environment info'
	echo '  inspect	- Show docker inspect info for the running container'
	echo '  self-update	- Upgrade Dredger to the latest version'
	echo ''

# DEFAULT TARGETS

build::
	docker build --pull -t $(NAME) $(PWD);
	echo "Copying build files to working directory...";
	if [ -d .git ] && [ -z "$$(git -C $(PWD) status --porcelain)" ]; then \
            docker run --rm --entrypoint="" -v $(MOUNT):/copy $(NAME) bash -c "rm -f .gitignore && cp -rup . /copy"; \
        else \
            read -p "Git working directory not clean, do you want to override local changes with built files? " -n 1 -r && echo && if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
                docker run --rm --entrypoint="" -v $(MOUNT):/copy $(NAME) bash -c "rm -f .gitignore && cp -rup . /copy"; \
            fi; \
        fi

run::
	if ! nc -z 0.0.0.0 $(PORT) && ! grep -q docker /proc/1/cgroup; then \
            docker pull containous/traefik:latest && \
            docker run --restart=unless-stopped -d -p $(PORT):80 -v /var/run/docker.sock:/var/run/docker.sock containous/traefik:latest --web --docker --docker.endpoint=unix:///var/run/docker.sock; \
            fi
	if [ -z "$$(docker images -q $(NAME))" ]; then \
            docker build --pull -t $(NAME) $(PWD); \
            echo "Copying build files to working directory..."; \
            if [ -d .git ] && [ -z "$$(git -C $(PWD) status --porcelain)" ]; then \
                    docker run --rm --entrypoint="" -v $(MOUNT):/copy $(NAME) bash -c "rm -f .gitignore && cp -rup . /copy"; \
                else \
                    read -p "Git working directory not clean, do you want to override local changes with built files? " -n 1 -r && echo && if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
                        docker run --rm --entrypoint="" -v $(MOUNT):/copy $(NAME) bash -c "rm -f .gitignore && cp -rup . /copy"; \
                    fi; \
                fi \
            fi
	if [ ! "$$(docker ps -aq --filter name=^/$(NAME)$$)" ]; then \
            docker run --rm \
	        $(shell if [ "$$DREDGER_FOREGROUND" != true ]; then echo '-d'; fi) \
                -v $(MOUNT):$(VOLUME) \
                -e VIRTUAL_HOST=$(HOST) \
                -e XDEBUG_HOST=$(HOST_IP) \
                -e DOCKER_HOST_IP=$(HOST_IP) \
                -l traefik.frontend.rule=HostRegexp:$(HOST) \
                -l traefik.port=80 \
                -l traefik.enable=true \
                $(ENV) \
                $(ARGS) \
                --name $(NAME) $(NAME); \
         else \
            docker restart $(NAME); \
         fi

copy::
	echo "Copying build files to working directory...";
	if [ -d .git ] && [ -z "$$(git -C $(PWD) status --porcelain)" ]; then \
            docker run --rm --entrypoint="" -v $(MOUNT):/copy $(NAME) bash -c "rm -f .gitignore && cp -rup . /copy"; \
        else \
            read -p "Git working directory not clean, do you want to override local changes with built files? " -n 1 -r && echo && if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
                docker run --rm --entrypoint="" -v $(MOUNT):/copy $(NAME) bash -c "rm -f .gitignore && cp -rup . /copy"; \
            fi; \
        fi

bash::
	-docker exec -it --user=$(USER) $(NAME) bash

status::
	-docker exec -it --user=root $(NAME) /usr/bin/supervisorctl status

restart::
	-docker restart $(NAME)

destroy::
	-docker rm -f -v $(NAME) 2>/dev/null || echo "Container does not exist"

logs::
	-docker logs -f $(NAME)

install::
	docker exec -it --user=$(USER) $(NAME) composer install --no-interaction --prefer-dist

update::
	docker exec -it --user=$(USER) $(NAME) composer update --no-interaction --prefer-dist

self-update::
	-wget -qO- https://raw.githubusercontent.com/outeredge/dredger/master/install.sh | bash

info::
	echo "Mount:  $(MOUNT)"
	echo "Name:   $(NAME)"
	echo "Host:   $(HOST)"
	echo "Volume: $(VOLUME)"

inspect::
	-docker inspect $(NAME)

-include Makefile.local
