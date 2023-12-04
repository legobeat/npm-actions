#!/bin/sh

set -ex

local_registry="http://127.0.0.1:4873"
pkg_name=$(jq -r .name ./package.json)
pkg_scope=$(echo $pkg_name | grep -o '^@[^/]*'; true)

# start local registry
tmp_registry_log=`mktemp`
sh -c "mkdir -p $HOME/.config/verdaccio"
sh -c "cp --verbose /config.yaml $HOME/.config/verdaccio/config.yaml"
sh -c "nohup verdaccio --config $HOME/.config/verdaccio/config.yaml &>$tmp_registry_log &"
# wait for `verdaccio` to boot
# FIXME: this throws a syntax error, but would be great to make it run
# grep -q 'http address' <(tail -f $tmp_registry_log)

npm set registry $local_registry
[[ -z "${pkg_scope}" ]] || npm config set ${pkg_scope}:registry $local_registry ; true

# login so we can publish packages
sh -c "npm-auth-to-token -u test -p test -e test@test.com -r $local_registry"

yarn_version=$(jq '.packageManager|select(test("yarn@"))' package.json -r | cut -d@ -f2); true
if [[ $(echo $yarn_version|cut -d. -f1) -gt "2" ]]; then
  corepack enable
  corepack prepare yarn@${yarn_version} --activate
  yarn install
else
  npm ci
fi

### Publish
npm publish --registry $local_registry $NPM_PUBLISH_ARGS

### NPM
mkdir "$HOME/app"
cd "$HOME/app"
npm init --yes
npm set registry "$local_registry"
npm install "$pkg_name"
ls "./node_modules/$1/package.json"

#sh -c "${@}"
