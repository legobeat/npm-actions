#!/bin/sh

set -ex

local_registry="http://127.0.0.1:4873"

# start local registry
tmp_registry_log=`mktemp`
sh -c "mkdir -p $HOME/.config/verdaccio"
sh -c "cp --verbose /config.yaml $HOME/.config/verdaccio/config.yaml"
sh -c "nohup verdaccio --config $HOME/.config/verdaccio/config.yaml &>$tmp_registry_log &"
# wait for `verdaccio` to boot
# FIXME: this throws a syntax error, but would be great to make it run
# grep -q 'http address' <(tail -f $tmp_registry_log)
# login so we can publish packages
sh -c "npm-auth-to-token -u test -p test -e test@test.com -r $local_registry"
# Run npm command
sh -c "npm publish --registry $local_registry $1"


## NPM

mkdir "$HOME/app"
cd "$HOME/app"
npm init
npm set registry "$local_registry"
npm install "$1"
ls "./node_modules/$1/package.json"

#sh -c "${@}"
