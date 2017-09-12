# dredger
Dredger is a docker tool to help automate local web development environments. It automatically starts a http proxy on port 80 so you can run multiple environments at once with ease. No more remembering container hashes!

By default, containers are made accessible at `http://{foldername}.*` where `*` could be `localhost` or even (for mobile testing) `{yourip}.xip.io`, for example `http://mysite.192.168.1.100.xip.io`. You can override this by adding a `HOST = ...` to a Makefile.local in your projects root (see [extending](#extending) for an example). 

## Install
Run the command below to install dredger. Tested on Ubuntu 14.04, requires `make` and `netcat`.

`$ wget -qO- https://raw.githubusercontent.com/outeredge/dredger/master/install.sh | sudo bash`

## Upgrade
To upgrade dredger to the latest version, simply run `$ sudo dredger self-update` from your command line.

## Usage

See `$ dredger help`

```sh
Usage: dredger [command]

Commands:

  build		- Build the docker image
  run		- Run at http://{curdir}.*
  bash		- Enter running container with bash
  status	- Show the status of running container
  logs		- Show logs
  restart	- Restarts the running container
  destroy   	- Stops the running container and deletes it
  clean		- Clean up all unused containers and images on this host
  install	- Run install scripts (i.e. composer)
```

#### Custom Arguments
To pass custom arguments to a command that supports it in the Makefile, simply append these to the end of the command like so:

`$ dredger run -e APPLICATION_ENV=staging`

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
