# OMP (Open Monograph Press) - PKP - Container/Docker

Open Monograph Press is an open source software platform for managing the editorial workflow required to see monographs, edited volumes and, scholarly editions through internal and external review, editing, cataloguing, production, and publication. OMP can operate, as well, as a press website with catalog, distribution, and sales capacities.

This container was built based on [buildpkg.sh](https://github.com/pkp/ocs/blob/ocs-3_1_0-1/tools/buildpkg.sh) from own pkp-ocs, so all the dependencies are already included and the software is ready to run. Also is built on top of [Alpine Linux](https://alpinelinux.org/) which is incredible lightweight.

## How to use

```bash
docker run --name omp \
           -p 8080:80 -p 8443:443 \
           -e SERVERNAME=... \
           -v /etc/localtime:/etc/localtime \
           -d lucasdiedrich/omp
```

Now just access http://127.0.0.1:8080/index/install and continue through web installation and finish your install and configs.
To install automatically when the container init you can use **PKP_CLI_INSTALL=1**, and use the others environment variables to automatize the process.

## Versions

All version tags can be found at [Docker Hub Tags tab](https://hub.docker.com/r/lucasdiedrich/omp/tags/).

## Environment Variables

|  NAME  | Default | Info |
|:------:|:-------:|:-------:|
|   SERVERNAME  | localhost | Used to generate httpd.conf and certificate |
| PKP_CLI_INSTALL |  0  | Used to install omp automatically when start container |
|   PKP_DB_HOST  | localhost | Database host |
|   PKP_DB_USER  | omp | Database username |
|   PKP_DB_PASSWORD  | omp | Database password |
|   PKP_DB_NAME  | omp | Database name |

## Special Volumes

|  Volume  | Info |
|:------:|:-------:|
| /var/www/html/public | All public files |
| /var/www/html/config.inc.php  | If not provided a new one will be created |
| /var/www/files  | All uploaded files |
| /etc/ssl/apache2/server.pem  | SSL **crt** certificate |
| /etc/ssl/apache2/server.key  | SSL **key** certificate |
| /var/log/apache2  | Apache2 Logs |
| /var/www/html/.htaccess  | Apache2 HTAccess |
| /usr/local/etc/php/conf.d/custom.ini  | PHP5 custom.init |
| /etc/localtime  | To set container clock as the host clock |

## Upgrading OMP

The update process is easy and straightforward, once the container running the new version just run the exec command below, and it will upgrade the OMP database and files.

```bash
docker exec -it omp /usr/local/bin/omp-upgrade
```

After the upgrade diff your **config.inc.php** with the version of the new OMP version, in some new version new variables can be added to the file.

## Docker-compose

There is an example docker-compose [docker-compose](./docker-compose.yml), to run it download the raw file to an folder and exec the command below:

```bash
docker-compose up
```

## SSL

By default at the start of Apache one script will check if the SSL certificate is valid and its CN matches your SERVERNAME, if don't it will generate a new one. The certificate can be overwrite using the volume mount.

## index.php

By default the restful_url are enable and apache its already configured, so there is no need to use index.php over url.

## php.ini

Any custom php configuration can be made at */etc/php7/conf.d/0-omp.ini*, there are some optimized variables already, you can check at [php.ini](./files/php.ini).

## License

MIT © [Lucas Diedrich](https://github.com/lucasdiedrich)
