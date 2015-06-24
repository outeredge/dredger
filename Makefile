# *DREDGER - THE OUTER/EDGE DOCKER DEV TOOL*
# To see a list of available commands execute "make help"

NAME    = $(shell basename $(CURDIR))
HOST    = $(NAME).localhost
VOLUME  = /var/www
OWNER   = www-data

.PHONY: help build run bash status restart destroy logs clean install update

help::
	@echo 'Usage: dredger [command]'
	@echo ''
	@echo 'Commands:'
	@echo ''
	@echo '  build		- Build the $(NAME) image and copy the built files if no local changes.'
	@echo '  run		- Run at http://$(HOST)'
	@echo '  bash		- Enter running container with bash'
	@echo '  status	- Show the status of running container'
	@echo '  logs		- Show logs'
	@echo '  restart	- Restarts the running container'
	@echo '  destroy   	- Stops the running container and deletes it'
	@echo '  clean		- Clean up all unused containers and images on this host'
	@echo '  install	- Run install scripts (i.e. composer)'

# DEFAULT TARGETS

build::
	@docker build --pull -t $(NAME) .
	@if [ -z $(git status -s) ]; then docker run --rm -i -t -v $(CURDIR):/copy $(NAME) bash -c "chown -R $(OWNER):$(OWNER) . && cp -r --preserve=ownership . /copy" && git-timestamps; fi

run::
	@if ! nc -z 127.0.0.1 80; then docker pull outeredge/edge-docker-localproxy && docker run --restart=always -d -p 80:80 -v /var/run/docker.sock:/tmp/docker.sock outeredge/edge-docker-localproxy; fi;
	@if [ "$$(docker inspect -f {{.State.Running}} $(NAME) 2> /dev/null)" = "<no value>" ]; then \
            docker run -d \
                -v $(CURDIR):$(VOLUME) \
                -v /tmp/composer:/root/.composer \
                -e VIRTUAL_HOST=$(HOST) \
                $(ENV) \
                $(ARGS) \
                --name $(NAME) $(NAME); \
         else \
            docker restart $(NAME); \
         fi
	@echo 'Container now running at http://$(HOST)'

bash::
	@docker exec -i -t $(NAME) bash -c "export TERM=xterm && bash"

status::
	@docker ps
	@docker exec -i -t $(NAME) /usr/bin/supervisorctl status

restart::
	@docker restart $(NAME)

destroy::
	@-docker kill $(NAME)
	@-docker rm $(NAME)

logs::
	@docker logs -f $(NAME)

clean::
	@docker ps -a -q --filter status=exited | xargs -r docker rm
	@docker images -q --filter dangling=true | xargs -r docker rmi

install::
	@docker exec -i -t $(NAME) sudo -u www-data bash -c "composer install --no-interaction --prefer-dist"

update::
	@docker exec -i -t $(NAME) sudo -u www-data bash -c "composer update --no-interaction --prefer-dist"

-include Makefile.local
