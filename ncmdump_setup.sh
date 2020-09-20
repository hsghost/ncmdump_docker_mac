#!/bin/bash

# docker: hsghost/ncmdump
# Version f9f6e2f-e
# Updated: 09/20/2020
# Maintainer: 15333619+hsghost@users.noreply.github.com

ncmdump_size="140 MB"
homebrew_size="200 MB"
docker_size="1.40 GB"

# Helper function rm_func to remove existing ncmdump functions.
rm_func () {
    unset -f "$1"
    fullpath="$(cd "$(dirname "$2")"; pwd -P)/$(basename "$2")"
    awk -v fn="$1" '
        BEGIN {
            d = 0 ; 
            FILENAME = file ; 
        }
        
        $0 ~ fn, 0 {
            RS = "\n" ; 
            FS = "" ; 

            for (i=1; i<=NF; i++)
                if ($i == "{") {
                    d++ ; 
                    # if (d == 1) printf "{\n"
                } else
                if ($i == "}") {
                    d-- ; 
                    if (d == 0) next
                }
        } !d
    ' "$fullpath" > "$fullpath".tmp
    mv "$fullpath".tmp "$fullpath"
}

# Pre-installation confirmation.
echo -e "\n [ncmdump Installation] This program will occupy approx. $(tput setaf 7)$ncmdump_size$(tput sgr 0) of disk space. \
And its prerequsite Docker Desktop would require an extra $(tput setaf 7)$docker_size$(tput sgr 0) of disk space, \
and Homebrew approx. $(tput setaf 7)$homebrew_size$(tput sgr 0), in case they're not already installed.\n"
while true; do
    read -p "Continue with the installation?" yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit 1;;
        * ) echo "Please answer ($(tput setaf 7)y$(tput sgr 0))es or ($(tput setaf 7)n$(tput sgr 0))o.";;
    esac
done

# Install Homebrew.
which -s brew
if [[ $? != 0 ]] ; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
else
    brew update
fi

# Install Docker Desktop.
which -s docker
if [[ $? != 0 ]] ; then
    brew cask install docker
fi

# Open Docker Desktop if it is not already running.
if (! docker stats --no-stream >/dev/null 2>&1 ) ; then
    echo "Starting Docker services, please wait..."
    open /Applications/Docker.app
    # Wait for Docker daemon initialisation to complete.
    while (! docker stats --no-stream >/dev/null 2>&1 ) ; do
        sleep 1
    done
fi

# Download the ncmdump docker image.
docker pull hsghost/ncmdump:latest

# Prepare the terminal command.
if [ "$(type -t ncmdump)" == 'function' ] ; then
    rm_func ncmdump ~/.bash_profile
    rm_func ncmdump ~/.zsh
fi
tee -a ~/.bash_profile ~/.zsh >/dev/null << 'EOF'

ncmdump () {
    # docker: hsghost/ncmdump
    # Version f9f6e2f-e
    # Updated: 09/14/2020
    # Maintainer: 15333619+hsghost@users.noreply.github.com
    
    # Arguments validity checking and preparations.
    working_dir="$(pwd)"
    if [[ "$1" == "-r" ]] ; 
    then
        if [[ $# -gt 2 ]] ; 
        then
            echo -e "\n[ncmdump] Unrecognized variable(s): ${@:3}."
            echo -e "\nUsage:\nncmdump [ [ -r ] directory | files... ]\n"
            return 1
        elif [[ -d "$2" ]] ; 
        then
            working_dir="$(cd "$(dirname "$2")"; pwd -P)/$(basename "$2")"
        elif [[ $# == 2 ]] ; 
        then
            echo -e "\n[ncmdump] Directory not found: $2."
            echo -e "\nUsage:\nncmdump [ [ -r ] directory | files... ]\n"
            return 1
        fi
    elif [[ -d "$1" ]] ; 
    then
        if [[ $# -gt 1 ]] ; 
        then
            echo -e "\n[ncmdump] Unrecognized variable(s): ${@:2}."
            echo -e "\nUsage:\nncmdump [ [ -r ] directory | files... ]\n"
            return 1
        else
            working_dir="$(cd "$(dirname "$1")"; pwd -P)/$(basename "$1")"
            shift
        fi
    else
        for arg in "$@"
        do : 
            if [[ ! -f $arg ]] ; 
            then
                echo -e "\n[ncmdump] File not found: $arg."
                echo -e "\nUsage:\nncmdump [ [ -r ] directory | files... ]\n"
                return 1
            fi
        done
    fi
    # Open Docker Desktop if it is not already running.
    if (! docker stats --no-stream >/dev/null 2>&1 ) ; then
        echo "Starting Docker services, please wait..."
        open /Applications/Docker.app
        if [[ $? -gt 0 ]] ; 
        then
            echo -e "\n[ncmdump] Docker services failed to start. Exiting...\n"
            return 1
        fi
        # Wait for Docker daemon initialisation to complete.
        docker_start_count=0
        while (! docker stats --no-stream >/dev/null 2>&1 ) ; do
            sleep 1
            if [[ docker_start_count -gt 300 ]] ; 
            then
                echo -e "\n[ncmdump] Docker services failed to start. Exiting...\n"
                return 1
            fi
            docker_start_count=$((docker_start_count+1))
        done
    fi
    echo "Decrypting file(s)..."
    docker run -it --rm --name ncmdump --mount type=bind,source="$working_dir",target=/ncmworking hsghost/ncmdump "$@"
    return 0
}
EOF
source ~/.bash_profile
