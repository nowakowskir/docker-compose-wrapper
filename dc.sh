#!/bin/bash

DC_DIR=~/.dc/
CONFIG_PATH=$DC_DIR"config"

function getopt {

	OPTIND="${@: -1}"
	OPTION="${@: -2:1}"
	
	while getopts $OPTION RES 2>/dev/null; do
    		case "${RES}" in
			${OPTION})
				echo "${OPTION}"
			;;
    		esac
	done

}

function env_name_validate {
        if ! [[ $1 =~ ^[0-9a-zA-Z_-]+$ ]]; then
		echo "Invalid environment name"
                
		exit
        fi
}


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

function cfgdata {
        echo "ENV_CURR=${ENV_CURR}"
        echo "declare -A CONF=()"
	for K in "${!CONF[@]}"; do
        	echo "CONF[$K]=${CONF[$K]}"
	done
}

function writecfg {
	echo "$(cfgdata)" > $CONFIG_PATH
}

if [ -f "$CONFIG_PATH" ]; then
	source $CONFIG_PATH
fi

function check_curr_env {
	[ -z "$ENV_CURR" ] && {
		echo "No active environment"

		exit 1;
	}

}

function env_exists {
        [ -z "${CONF[$1]}" ] && {
		return 1
        } || return 0
}

function check_env_exists {
	if ! env_exists "$1"; then
                echo "Environment $1 does not exist"

                exit 1
        fi
}

function use {
        [ -z "$1" ] && { echo "Environment has not been specified"; exit 1; }

	check_env_exists $1

	INITIAL_ENV=$ENV_CURR
	ENV_CURR=$1
	writecfg
	[ "$INITIAL_ENV" = "$ENV_CURR" ] && echo "Already at $ENV_CURR" || echo "Switched to $ENV_CURR (${CONF[$ENV_CURR]})"
}

function env {
	[ -z "$ENV_CURR" ] && echo "You did not choose active environment. Please use $0 list to check available environments and $0 use <environment> to switch to given environment" || echo "Currently at $ENV_CURR environment"
}

function env_list {
	for K in "${!CONF[@]}"; do
		LIST="${LIST}$K;"
		if [ -z $1 ]; then
			[ "$K" = "$ENV_CURR" ] && LIST="${LIST};*;" || LIST="${LIST}; ;"
			LIST="${LIST}${CONF[$K]}\n"
		else
			LIST="${LIST}\n"
		fi
	done
	echo -e $LIST | column -t -s ";"
}

function add {
	[ -z "$1" ] && { echo "Environment has not been specified"; exit 1; }
	env_name_validate $1
	[ -z "$2" ] && { echo "Composer file has not been specified"; exit 1; }

	if env_exists $1; then
		echo "Environment $1 already exists"

		exit 1
	fi

	check_file $2

	CONF[$1]=$2
	writecfg

        echo "Environment $1 has been created ($2)"

	[ -n $3 ] && [ ${#3} -gt 0 ] && use $1
}

function change {
        if ! env_exists $1; then
                echo "Environment $1 does not exist"

                exit 1
        fi

        [ -z "$2" ] && { echo "Composer file has not been specified"; exit 1; }

	check_file $2

        CONF[$1]=$2
        writecfg

        echo "Environment $1 has been updated ($2)"
}

function rme {
	if ! env_exists $1; then
		echo "Environment $1 does not exist, nothing to delete"

		return
	fi

	unset CONF[$1]
	echo "Environment $1 has been deleted"
	
	[ "$1" = "$ENV_CURR" ] && {
		ENV_CURR=""
		echo "Current environment has been reset due to active environment removal ($1)"
	}
	writecfg
}

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

case "$1" in

        switch)
                use ${2,}
        ;;

        add)
		SWITCH=$(getopt "$@" "s" 4)
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
		SHORT=$(getopt "$@" "q" 2)

		env_list $SHORT
	;;

        *)
		[ $# -eq 0 ] && usage
        	check_curr_env
        	check_env_exists "$ENV_CURR"
		check_file "${CONF[$ENV_CURR]}"

	        echo "Executing command \"docker-compose -f ${CONF[${ENV_CURR}]} ${@: +1}\" on environment $ENV_CURR"
                docker-compose -f "${CONF[${ENV_CURR}]}" "${@: +1}"
        ;;
esac

