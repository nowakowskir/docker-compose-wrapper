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

### Displaying list of available environments

```
dc list
project-a     /home/user/project-a/docker-composer.yml
project-b     /home/user/project-b/docker-composer.yml
```
