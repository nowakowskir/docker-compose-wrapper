#!/bin/bash

DC_DIR=~/.dc/
CONFIG_PATH=$DC_DIR"config"

# Check if given option exists
function option {

	# Slice input arguments and get option offset
	OPTIND="${@: -1}"
	# Slice input arguments and get option shortcut
	OPTION="${@: -2:1}"
	
	while getopts $OPTION RES 2>/dev/null; do
    		case "${RES}" in
			${OPTION})
				echo "${OPTION}"
			;;
    		esac
	done

}

# Check if given environment name is valid
function env_name_validate {
	if ! [[ $1 =~ ^[0-9a-zA-Z_-]+$ ]]; then
		echo "Invalid environment name"

		exit 1
	fi
}

# Check if composer file exists and is readable
function check_file {
	if [ ! -f $1 ]; then
		echo "Composer file does not exist ($1)"

		exit 1
	fi

	if [ ! -r $1 ]; then
		echo "Can not read composer file ($1): Permission denied"

		exit 1
	fi
}

# Display configuration data based on current state
# This output will be used to store current configuration in config file
function config_data {
	echo "ENV_CURR=${ENV_CURR}"
	echo "declare -A CONF=()"
	for K in "${!CONF[@]}"; do
		echo "CONF[$K]=${CONF[$K]}"
	done
}

# Write current configuration to config file
function write_config {
	echo "$(config_data)" > $CONFIG_PATH 2>/dev/null
	if [ $? -ne 0 ]; then
		echo "Can not create config file ($CONFIG_PATH)"
			
		exit 1;
	fi
}

# Check if there is active environment
function check_curr_env {
	[ -z "$ENV_CURR" ] && {
		echo "No active environment"

		exit 1;
	}
}

# Get information if environment with given name exists or not
function env_exists {
	[ -z "${CONF[$1]}" ] && {
		return 1
	} || return 0
}

# Do environment existence check
function check_env_exists {
	if ! env_exists "$1"; then
		echo "Environment $1 does not exist"
		
		exit 1
	fi
}

# Perform environment switch action
function switch {
	# Check if environment name was provided
	[ -z "$1" ] && { echo "Environment has not been specified"; exit 1; }

	# Do environment existence check
	check_env_exists $1

	# Check if new environment was provided
	INITIAL_ENV=$ENV_CURR
	ENV_CURR=$1
	[ "$INITIAL_ENV" = "$ENV_CURR" ] && echo "Already at $ENV_CURR" || {
		# Write active environment to config file 
		write_config
		echo "Switched to $ENV_CURR (${CONF[$ENV_CURR]})"
	}
}

# Show active environment
function env {
	[ -z "$ENV_CURR" ] && echo "You did not choose active environment. Please use $0 list to check available environments and $0 switch <environment> to switch to given environment" || echo "Currently at $ENV_CURR environment"
}

# List environments
function env_list {
	# Process configuration
	for K in "${!CONF[@]}"; do
		LIST="${LIST}$K;"
		if [ -z $1 ]; then
			# In normal mode, display both environment name and compose file path
			# If given environment is the active one, put asterisk on the list
			[ "$K" = "$ENV_CURR" ] && LIST="${LIST};*;" || LIST="${LIST}; ;"
			LIST="${LIST}${CONF[$K]}\n"
		else
			# In quiet mode, display only environment name
			LIST="${LIST}\n"
		fi
	done
	# Format output data into columns
	echo -e $LIST | column -t -s ";"
}

# Add new environment
function add {
	# Check if environment name was provided
	[ -z "$1" ] && { echo "Environment has not been specified"; exit 1; }
	# Check iv environment name is valid
	env_name_validate $1
	# Check if compose file was provided
	[ -z "$2" ] && { echo "Compose file has not been specified"; exit 1; }

	# Check if given environment name is already in use
	if env_exists $1; then
		echo "Environment $1 already exists"

		exit 1
	fi

	# Check if compose file exists
	check_file $2

	# Add environment to the list
	CONF[$1]=$2
	
	# Rebuild configuration
	write_config

	echo "Environment $1 has been created ($2)"

	# If -s flag was set, switch to the new environment automatically
	[ -n $3 ] && [ ${#3} -gt 0 ] && use $1
}

# Change compose file for given environment 
function change {
	if ! env_exists $1; then
		echo "Environment $1 does not exist"
		
		exit 1
	fi

	# Check if compose file path was provided
	[ -z "$2" ] && { echo "Compose file has not been specified"; exit 1; }

	# Check if new compose file exists
	check_file $2

	# Set net compose file path
	CONF[$1]=$2
	
	# Rebuild configuration
	write_config

	echo "Environment $1 has been updated ($2)"
}

# Remove environment or set of environments
function rme {
	# Check if environment exists
	if ! env_exists $1; then
		echo "Environment $1 does not exist, nothing to delete"

		# We don't want to exit here, as there may be multiple environments in the input
		# We should warn the user but continue with next environments
		return
	fi

	# Remove environment from the list
	unset CONF[$1]
	echo "Environment $1 has been deleted"
	
	[ "$1" = "$ENV_CURR" ] && {
		# Reset configuration
		ENV_CURR=""
		echo "Current environment has been reset due to active environment removal ($1)"
	}
	
	# When finished, rebuild configuration
	write_config
}

# Init configuration
function init {

	# Check if configuration directory exists
	if [ ! -d "$DC_DIR" ]; then

		# If config directory does not exist, try to create it
		echo "Creating configuration directory $DC_DIR"
		mkdir $DC_DIR 2>/dev/null
		
		if [ $? -ne 0 ]; then
			echo "Can not create config directory ($DC_DIR)"
			
			exit 1;
		fi
	fi

	# In case directory exists, but config file is missing, try to create it
	if [ ! -f "$CONFIG_PATH" ]; then

		echo "Creating configuration file $CONFIG_PATH"
		touch $CONFIG_PATH 2>/dev/null
		
		if [ $? -ne 0 ]; then
			echo "Can not create config file ($CONFIG_PATH)"
			
			exit 1;
		fi
		
		chmod 600 $CONFIG_PATH
		write_config
	fi

}

# Usage
usage() {
	echo "Usage: "$(basename $0)" <command> [<args>]"
	echo -e "\nList of commands:"

	echo -e "
	add;<environment> <path>;Register docker-compose yaml file under given environment name
	;[-s];Automatically switch to given environment after creation
	;;
	change;<environment> <path>;Change docker-compose yaml file location for given environment
	;;
	list; ;List environments
	;[-q];Show only environment names
	;;
        switch;<environment>;Switch to environment
        ;;
	rme;<environment> [<environment> ...];Remove environment(s)" | column -t -s ";"

	echo -e "\nUsage with docker-compose: "$(basename $0)" <docker_compose_command> [<args>]"
	echo -e "\nGiven docker-compose command will be executed with currently active environment"
	echo -e "You can change the active environment running:"
	echo -e "\t"$(basename $0)" switch <environment>"

	exit 1
}

# Initialize configuration
init

source $CONFIG_PATH 2>/dev/null

if [ $? -ne 0 ]; then
	echo "Can not read config file ($CONFIG_PATH)"
	
	exit 1
fi

# Check what to do
case "$1" in

	switch)
		use ${2,}
	;;

	add)
		SWITCH=$(option "$@" "s" 4)
		add $2 $3 $SWITCH
	;;

	rme)
		[ $# -gt 1 ] && {
			for denv in "${@: +2}"
			do
				rme "$denv"
			done
		} || { echo "Please provide at least one environment to delete"; exit 1; }
	;;

	change)
		change $2 $3
	;;

	env)
		env
	;;

	list)
		QUIET=$(option "$@" "q" 2)

		env_list $QUIET
	;;

	*)
		# Run docker-compose command if no internal command was run
		[ $# -eq 0 ] && usage
		check_curr_env
		check_env_exists "$ENV_CURR"
		check_file "${CONF[$ENV_CURR]}"

		echo "Executing command \"docker-compose -f ${CONF[${ENV_CURR}]} ${@: +1}\" on environment $ENV_CURR"
		docker-compose -f "${CONF[${ENV_CURR}]}" "${@: +1}"
	;;
	
esac
