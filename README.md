# dredger
Dredger is a docker tool to help automate local web development environments. It automatically starts a http proxy on port 80 so you can run multiple environments at once with ease. No more remembering container hashes!

## Install / Upgrade

`$ wget -qO- https://raw.githubusercontent.com/outeredge/dredger/master/install.sh | sh`

## Usage

See `$ dredger help`

```sh
Usage: dredger [command]

Commands:

  build		- Build the docker image
  run		- Run at http://{curdir}.localhost
  bash		- Enter running container with bash
  status	- Show the status of running container
  logs		- Show logs
  restart	- Restarts the running container
  destroy   - Stops the running container and deletes it
  clean		- Clean up all unused containers and images on this host
  install	- Run install scripts (i.e. composer)
```

#### Custom Arguments
To pass custom arguments to a command that supports it in the Makefile, use the ARGS syntax like so:

`$ dredger ARGS="-e APPLICATION_ENV=staging" run`

## Extending

Add your own commands by creating a `Makefile.local` in your repositories root folder (i.e.):

```sh
HOST = *.$(NAME).localhost

.PHONY: test

help::
	@echo ''
	@echo 'Custom targets:'
	@echo ''
	@echo '  test		- Run unit tests'

test:
	@docker exec -i -t $(NAME) sudo -u www-data bash -c "phpunit --stop-on-failure"
```

## License
Distributed under the [MIT license](LICENSE)
