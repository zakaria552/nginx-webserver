#!/bin/bash
echo "------Building website------";

quit() {
    echo "❗ $2"
    exit $1
}

parse_arguments() {
    echo "-> Parsing arguments"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--domain)
                if [[ -n "$2" ]]; then
                    domain="$2"
                    echo "- Domain is $domain"
                    shift
                else
                    quit 1 "Error: missing domain name after the flag."
                fi
                ;;
              -r|--route)
                if [[ -n "$2" ]]; then
                    route="$2"
                    echo "- route is $route"
                    shift
                else
                    quit 1 "Error: missing route after the flag."
                fi
                ;;
            -p|--path)
                if [[ $path ]]; then
                    shift
                elif [[ -n "$2" ]]; then
                    path="$2"
                    echo "- Build path is $path"
                    shift
                else
                    quit 1 "Error: missing build path value after the flag."
                fi
                ;;
        esac
        shift
    done
}
validate_arguments() {
    echo "-> Validating arguments"
    if [[ -z $domain  ]]; then 
        quit 1 "The domain name (-d or --domain) must be provided";
    elif [[ -z $path ]]; then
        quit 1 "The path  of the static files (-p or --path must be provided";
    fi
}
create_nginx_server() {
    echo "-> Setting up nginx server configuration"
    local location="/"
    local server_block
    local root="/usr/share/nginx/html/${domain}"
    local directive="root"
    local serve_static_from_route=""
    echo $location
    if [[ -n $route ]]; then
        echo "route $route"
        location=$route
        directive="alias"
        root="/usr/share/nginx/html/${domain}${location//\//-}/"
        echo $root
        serve_static_from_route="try_files \$uri \$uri/ =404;"
    fi
    mkdir -p ./conf.d
    rm ./conf.d/default.conf
    printf "server {
    listen 80 default_server;
    server_name _;

    root /usr/share/nginx/html/default;
    index index.html;

    location / {
        return 404;
    }
}" >> ./conf.d/default.conf
    if ! [[ -e "./conf.d/$domain.conf" ]]; then
        echo "- Adding new nginx configuration for $domain"
        printf "server {
    listen 80;
    server_name $domain www.$domain;

    location $location {
        $directive $root;
        index index.html;
        $serve_static_from_route
    }

}" >> "./conf.d/$domain.conf"
        return
    fi
    if grep -q "location $location " "./conf.d/$domain.conf"; then
        echo ""
    else 
        echo "- Adding new location $location"
        sed -i '$d' "./conf.d/$domain.conf"
        server_block=$(sed '$d' "./conf.d/$domain.conf")
        printf "$server_block

    location $location {
        $directive $root;
        index index.html;
        $serve_static_from_route
    }

}" > "./conf.d/$domain.conf"
    fi

}
copy_build_folder() {
    echo "-> Copying build folder"
    local dir_name=$2
    if [[ $route ]]; then
        dir_name="${2}${3//\//-}"
    fi
    rm -rf "./sites/$dir_name"
    mkdir -p "./sites/$dir_name"
    cp -r $1/* "./sites/$dir_name"
    echo "- Copied to ./sites/$dir_name"
}

$domain
$path

parse_arguments $@
validate_arguments
copy_build_folder "$path" "$domain" "$route"
create_nginx_server
echo "✅ Successfully website, ready to ship!!"
