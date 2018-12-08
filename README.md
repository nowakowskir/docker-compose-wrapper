# docker-compose-wrapper

## About

docker-compose-wrapper lets you to work with docker-compose with multiple environments.

## Installation

```ln -s $(pwd)/dc.sh /usr/bin/dc```

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
dc add project-b /home/user/project-b/docker-compose.yml -s
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
