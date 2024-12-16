parse_arguments() {
    echo "-> Parsing arguments"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--domain)
                if [[ -n "$2" ]]; then
                    domain="$2"
                    shift
                else
                    quit 1 "Error: missing domain name after the flag."
                fi
                ;;
            -ip)
                ip=$2
                if [[ -n "$2" ]]; then
                    ip="$2"
                    echo "--> Ip address is $ip"
                    shift
                else
                    quit 1 "Error: missing ip address value after the flag."
                fi
                ;;
            -r|--remote)
                remote=$2
                if [[ -n "$2" ]]; then
                    remote="$2"
                    echo "Remote host server: $remote"
                    shift
                else
                    quit 1 "Error: missing remote host value after the flag."
                fi
                ;;
        esac
        shift
    done
}

add_to_hosts() {
    local container_host_entry="127.0.0.1   $domain"
    local local_host_entry
    local local_host_path="/etc/hosts"
    if [[ -z $ip ]]; then
        local_host_entry="127.0.0.1   $domain"
    else 
        local_host_entry="$ip   $domain"
    fi
    echo "---_>$local_host_entry $local_host_path"
    if check_entry_exists "$local_host_entry" "$local_host_path"; then
        echo "Skipping local DNS mapping on local host machine"
    else 
        printf "\n$local_host_entry" >> /etc/hosts
    fi
    if check_entry_exists "$container_host_entry" "./hosts"; then
        echo "Skipping local DNS mapping on container"
    else 
        printf "\n$container_host_entry" >> "./hosts"
    fi
    
}
check_entry_exists() {
    local entry="$1"
    local hosts_file="$2"
    # echo $hosts_file
    # Check if the entry exists in the hosts file
    echo $1
    echo $2
    echo "---_>$entry - $hosts_file"
    if grep -qF "$entry" "$hosts_file"; then
        echo "Entry exists: $entry"
        return 0
    else
        echo "Entry does not exist: $entry"
        return 1
    fi
}
echo "------Deploying websites------"
echo $(ls "./sites")
parse_arguments $@

#check_build_folder
echo "-> Building docker image"
docker rmi nginx-webserver -f
docker build --no-cache -t nginx-webserver .
echo "-> Stopping running container"
docker stop nginx-webserver
docker rm nginx-webserver
echo "-> Running webserver"
docker run --name nginx-webserver -p 80:80 -d nginx-webserver
echo "✅ Successfully deployed website, ready to ship!!"