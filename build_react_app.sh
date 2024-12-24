#!/bin/bash
set -e
echo "------Building react app------";
quit() {
    echo "❗ $2"
    exit $1
}

parse_arguments() {
    echo "-> Parsing arguments"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -u|--url)
                if [[ -n "$2" ]]; then
                    git_url="$2"
                    shift
                else
                    quit 1 "Error: missing project url after the flag"
                fi
                ;;
            -p|--pathl)
                if [[ -n "$2" ]]; then
                    path="$2"
                    shift
                else
                    quit 1 "Error: missing project path after the flag"
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
        esac
        shift
    done
}
validate_arguments() {
    echo "-> Validating arguments"
    if [[ -z $git_url && -z $path ]]; then 
        quit 1 "Either the path (-p or --path) or the Git URL (-u or --url) must be provided."
    fi
}
clone_repository() {
    echo "-> Cloning project: $git_url"
    rm -rf ./react-app
    $(git clone $git_url react-app || quit 1 "Failed to clone repository")
    echo "✅ Successfully cloned project to $(pwd)/react-app"
}

build_website() {
    local project_path="$work_dir/react-app"
    if [[ $path ]]; then
        project_path=$path
    fi
    echo "-> Building react project"
    echo "- Changing directory to $project_path"
    cd $project_path
    modify_base_url
    echo "- npm installing dependencies"
    npm install
    echo "- running react build command"
    npm run build
    if [[ -d "./build" ]]; then
        rm -rf "./dist"
        mv -f "./build" "./dist"
    fi
    cd $work_dir
    echo "✅ Successfully built react app"
}

modify_base_url() {
    if [[ $route ]]; then
        echo "- Injecting the base url - [$route]"
        sudo perl -i -pe "if (!\$done && s|{|{\n  \\\"homepage\\\": \\\"$route\\\",|) { \$done = 1 }" package.json
    fi
}

work_dir=$(pwd)
build_path="$work_dir/react-app/dist"
echo $build_path
parse_arguments $@
validate_arguments
if [[ $path ]]; then
    build_path="$path/dist"
else 
    echo "-> Cloning"
    clone_repository
fi
build_website
./build_website.sh -p $build_path $@