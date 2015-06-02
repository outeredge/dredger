# dredger
Dredger is a docker tool to help automate local dev environments

## Install / Upgrade

`$ wget -qO- https://raw.githubusercontent.com/outeredge/dredger/master/install.sh | sh`

## Usage

See `$ dredger help`

```sh
Usage: dredger [command]

Commands:

  build		- Build the dredger image
  run		- Run at http://dredger.localhost
  bash		- Enter running container with bash
  status	- Show the status of running container
  logs		- Show logs
  restart	- Restarts the running container
  destroy   	- Stops the running container and deletes it
  clean		- Clean up all unused containers and images on this host
  install	- Run install scripts (i.e. composer)
```

## Extending

Add your own commands by creating a `Makefile.local" in your repositories root folder (i.e.):

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
