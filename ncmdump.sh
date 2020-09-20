#!/bin/bash

# docker: hsghost/ncmdump
# Version f9f6e2f-e
# Updated: 09/15/2020
# Maintainer: 15333619+hsghost@users.noreply.github.com

if [[ "$1" == "-r" ]] ; 
then
    declare -a full_list filtered_list
    readarray -d '' full_list < <(find /ncmworking/ -iname "*.ncm" -print0)
    for file in "${full_list[@]}"
    do : 
        filepath=${file%.*}
        if [[ ! -f "$filepath"".mp3" && ! -f "$filepath"".flac" ]] ; 
        then
            filtered_list+=("$file")
        fi
    done
    if [[ ${#filtered_list[@]} -lt 1 ]] ; 
    then
        echo -e "\n[ncmdump] No new NCM file found in the directory.\n"
        exit 1
    fi
    for file in "${filtered_list[@]}"
    do : 
        cd "$(dirname "$file")"
        ncmdump "$file"
    done
    cd /ncmworking
    exit 0
elif [[ $# -gt 0 ]] ; 
then
    exec ncmdump "$@"
    exit 0
else
    for file in /ncmworking/*.ncm ; 
    do
        if [[ -f "$file" ]] ; 
        then
            ncmdump "$file"
        else
            echo -e "\n[ncmdump] No NCM file found in the directory.\n"
            exit 1
        fi
    done
fi
