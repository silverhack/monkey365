---
author: Juan Garrido
---

# Overview

The docker image is an Ubuntu for Linux and Windows Server Core for Windows that comes with all pre-requisite components required to run Monkey365. These are non-root container images.

# Running the Container

To run this image, use the ```build.ps1``` script located in the root folder:

``` powershell
.\build.ps1 -Name monkey365 -version latest -Path .\docker\Dockerfile_linux
```

This will create a new Monkey365 Docker image based on Ubuntu for Linux.

The following command can be used to create a Windows-based container:

``` powershell
.\build.ps1 -Name monkey365 -version latest -Path .\docker\Dockerfile_windows
```

Once container is created, you can run monkey365 container using ```docker run -it monkey365```

# Supported environment variables

The following environment variables are supported:

* MONKEY_ENV_MONKEY_USER
* MONKEY_ENV_MONKEY_PASSWORD
* MONKEY_ENV_TENANT_ID
* MONKEY_ENV_SUBSCRIPTIONS
* MONKEY_ENV_COLLECT
* MONKEY_ENV_EXPORT_TO
* MONKEY_ENV_WRITELOG
* MONKEY_ENV_VERBOSE
* MONKEY_ENV_DEBUG

You can also use the -e, --env, and --env-file flags to set simple environment variables in the container.

``` bash
docker run -it --env-file monkey.env monkey365 pwsh "/home/monkey365/monkey365/monkey365.ps1"
```

In case you want to map a directory to a docker container directory, you can use the --volume flag, as shown below:

``` bash
docker run -it --env-file monkey.env `
               -volume=C:\temp:/home/monkey365/monkey365/monkey-reports `
               monkey365 pwsh "/home/monkey365/monkey365/monkey365.ps1"
```