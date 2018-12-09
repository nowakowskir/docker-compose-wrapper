# docker-compose-wrapper

## About

docker-compose-wrapper lets you to work with docker-compose with multiple environments.

Although docker-compose lets you to work on different configurations by specifying ```-f``` option, it could be cumbersome doing so each time you run any docker-compose command. You may want to use docker-compose from any other directory than your compose file exists.

To avoid such problems, and improve user experience, you can bind given compose file with environment name and use it as a reference.

This script lets you create predefined list of config-environment pairs. You can set given environment as active and skip its name in any docker compose command until you need to switch to other environment.

## Installation

You can create a symlink to install this script globally. You need to be root user or use ```sudo```.

```ln -s $(pwd)/dc.sh /usr/bin/dc```

If you don't want to install it globally, you should update your ```$PATH``` environment variable adding path to script location.

## Usage

### Creating new environment

```
dc add project-a /home/user/project-a/docker-compose.yml
Environment project-a has been created (/home/user/project-a/docker-compose.yml)
```

```
dc add project-b /home/user/project-b/docker-compose.yml
Environment project-b has been created (/home/user/project-b/docker-compose.yml)
```

If you wish to switch to given environment just after it's created, use ```-s``` flag

```
dc add project-c /home/user/project-b/docker-compose.yml -s
Environment project-c has been created (/home/user/project-c/docker-compose.yml)
Switched to project-c (/home/user/project-c/docker-compose.yml)
```

### Displaying list of available environments

```
dc list
project-a     /home/user/project-a/docker-composer.yml
project-b     /home/user/project-b/docker-composer.yml
```

### Switching to given environment

```
dc switch project-a
Switched to project-a (/home/user/project-a/docker-compose.yml)
```

### Checking active environment

```
dc env
Currently at project-a environment
```

```
dc list
project-a     *	/home/user/project-a/docker-composer.yml
project-b     	/home/user/project-b/docker-composer.yml
```

### Changing configuration file for given environment

```
dc change project-b /home/user/project-b/composer.yml
```

### Removing environment

```
dc rme project-b
```

### Removing all environments

```
dc rme $(dc list -q)
```

### Running docker-compose commands

If you already set up your environment, you can use docker-compose from any location.

```
dc up -d
Executing command "docker-compose -f /home/user/project-a/docker-compose.yml up -d" on environment project-a

docker-compose output here...
```

```
dc stop
Executing command "docker-compose -f /home/user/project-a/docker-compose.yml stop" on environment project-a

docker-compose output here...
```

As you can see, wrapper passes command and arguments to docker-compose appending your active environment configuration path on the fly.
You are informed what command is being run internally.
