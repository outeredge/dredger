# *DREDGER - THE OUTER/EDGE DOCKER DEV TOOL*
# To see a list of available commands execute "make help"

MOUNT   = $${DREDGER_MOUNT:-$(CURDIR)}
NAME    = $${DREDGER_NAME:-$(shell basename $(MOUNT))}
HOST    = $${DREDGER_HOST:-$(NAME).*}
VOLUME  = $${DREDGER_VOLUME:-/var/www}

.PHONY: help build run bash status restart destroy logs clean install update self-update info

help::
	@echo 'Usage: dredger [command]'
	@echo ''
	@echo 'Commands:'
	@echo ''
	@echo '  build		- Build the image and copy the built files if no local changes.'
	@echo '  run		- Run the container and proxy'
	@echo '  bash		- Enter running container with bash'
	@echo '  status	- Show the status of running container'
	@echo '  logs		- Show logs'
	@echo '  restart	- Restarts the running container'
	@echo '  destroy   	- Stops the running container and deletes it'
	@echo '  clean		- Clean up all unused containers and images on this host'
	@echo '  install	- Run app install scripts (defaults to `composer install`)'
	@echo '  update	- Run app update scripts (defaults to `composer update`)'
	@echo '  info		- Show Dredger environment info'
	@echo '  self-update	- Upgrade Dredger to the latest version'
	@echo ''

# DEFAULT TARGETS

build::
	@docker build --pull -t $(NAME) .
	@if [ -z $(git status -s) ]; then docker run --rm -v $(MOUNT):/copy $(NAME) bash -c "rm -f .gitignore && cp -rp . /copy"; fi

run::
	@if ! nc -z 0.0.0.0 80 && ! grep -q docker /proc/1/cgroup; then docker pull outeredge/edge-docker-localproxy && docker run --restart=always -d -p 80:80 -v /var/run/docker.sock:/tmp/docker.sock outeredge/edge-docker-localproxy; fi;
	@if [ -z "$$(docker images -q $(NAME))" ]; then docker build --pull -t $(NAME) .; \
            if [ -z $(git status -s) ]; then docker run --rm -v $(MOUNT):/copy $(NAME) bash -c "rm -f .gitignore && cp -rp . /copy"; fi; \
            fi
	@if [ ! "$$(docker ps -aqf name=$(NAME))" ]; then \
            docker run -d \
                -v $(MOUNT):$(VOLUME) \
                -e VIRTUAL_HOST=$(HOST) \
                $(ENV) \
                $(ARGS) \
                --name $(NAME) $(NAME); \
         else \
            docker restart $(NAME); \
         fi
	@echo "Container now running at http://$(HOST)"

bash::
	@docker exec -it $(NAME) bash -c "export TERM=xterm && bash"

status::
	@docker ps
	@docker exec $(NAME) /usr/bin/supervisorctl status

restart::
	@docker restart $(NAME)

destroy::
	@-docker kill $(NAME) 2>/dev/null || echo Container not running
	@-docker rm $(NAME) 2>/dev/null || echo Image does not exist

logs::
	@docker logs -f $(NAME)

clean::
	@docker ps -aq --filter status=exited | xargs -r docker rm
	@docker images -q --filter dangling=true | xargs -r docker rmi

install::
	@docker exec -u www-data $(NAME) composer install --no-interaction --prefer-dist

update::
	@docker exec -u www-data $(NAME) composer update --no-interaction --prefer-dist

self-update::
	@wget -qO- https://raw.githubusercontent.com/outeredge/dredger/master/install.sh | sh

info::
	@echo "MOUNT  = $(MOUNT)"
	@echo "NAME   = $(NAME)"
	@echo "HOST   = $(HOST)"
	@echo "VOLUME = $(VOLUME)"

-include Makefile.local
