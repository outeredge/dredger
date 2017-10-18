# *DREDGER - THE OUTER/EDGE DOCKER DEV TOOL*
# To see a list of available commands execute "make help"

MOUNT   = $${DREDGER_MOUNT:-$(CURDIR)}
NAME    = $${DREDGER_NAME:-$(shell basename $(MOUNT))}
HOST    = $${DREDGER_HOST:-$(NAME).localhost}
VOLUME  = $${DREDGER_VOLUME:-/var/www}
PORT    = $${DREDGER_PORT:-80}

.PHONY: help build run bash status restart destroy logs clean install update self-update info inspect

help::
	echo 'Usage: dredger [command]'
	echo ''
	echo 'Commands:'
	echo ''
	echo '  build		- Build the image and copy the built files if no local changes.'
	echo '  run		- Run the container and proxy'
	echo '  bash		- Enter running container with bash'
	echo '  status	- Show the status of running container'
	echo '  logs		- Show logs'
	echo '  restart	- Restarts the running container'
	echo '  destroy   	- Stops the running container and deletes it'
	echo '  clean		- Clean up all unused containers and images on this host'
	echo '  install	- Run app install scripts (defaults to `composer install`)'
	echo '  update	- Run app update scripts (defaults to `composer update`)'
	echo '  info		- Show Dredger environment info'
	echo '  inspect	- Show docker inspect info for the running container'
	echo '  self-update	- Upgrade Dredger to the latest version'
	echo ''

# DEFAULT TARGETS

build::
	docker build --pull -t $(NAME) .
	if [ -z "$$(git status -s)" ]; then \
            echo "Copying build files to working directory" && \
            docker run --rm --entrypoint="" -v $(MOUNT):/copy $(NAME) bash -c "rm -f .gitignore && cp -rup . /copy"; \
        else \
            echo "Git working directory not clean, not copying new build files locally"; \
        fi

run::
	if ! nc -z 0.0.0.0 $(PORT) && ! grep -q docker /proc/1/cgroup; then \
            docker pull containous/traefik:latest && \
            docker run --restart=unless-stopped -d -p $(PORT):80 -v /var/run/docker.sock:/var/run/docker.sock containous/traefik:latest --web --docker --docker.endpoint=unix:///var/run/docker.sock; \
            fi;
	if [ -z "$$(docker images -q $(NAME))" ]; then docker build --pull -t $(NAME) .; \
            if [ -z "$$(git status -s)" ]; then docker run --rm --entrypoint="" -v $(MOUNT):/copy $(NAME) bash -c "rm -f .gitignore && cp -rup . /copy"; fi; \
            fi
	if [ ! "$$(docker ps -aqf name=$(NAME))" ]; then \
            docker run --rm $(shell if [ "$$DREDGER_FOREGROUND" != true ]; then echo '-d'; fi) \
                -v $(MOUNT):$(VOLUME) \
                -e VIRTUAL_HOST=$(HOST) \
                -l traefik.frontend.rule=HostRegexp:$(HOST) \
                -l traefik.port=80 \
                -l traefik.enable=true \
                $(ENV) \
                $(ARGS) \
                --name $(NAME) $(NAME); \
         else \
            docker restart $(NAME); \
         fi

bash::
	-docker exec -it $(NAME) bash -c "export TERM=xterm && bash"

status::
	-docker ps
	-docker exec $(NAME) /usr/bin/supervisorctl status

restart::
	-docker restart $(NAME)

destroy::
	-docker rm -f -v $(NAME) 2>/dev/null || echo "Container does not exist"

logs::
	-docker logs -f $(NAME)

clean::
	-docker system prune -a

install::
	-docker exec $(NAME) composer install --no-interaction --prefer-dist

update::
	-docker exec $(NAME) composer update --no-interaction --prefer-dist

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
