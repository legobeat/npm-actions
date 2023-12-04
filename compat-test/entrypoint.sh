#!/bin/sh

set -ex

export local_registry="http://127.0.0.1:4873"
export pkg_name=$(jq -r .name ./package.json)
export pkg_scope=$(echo $pkg_name | grep -o '^@[^/]*'; true)
export VERDACCIO_STORAGE_PATH=$(yarn config get cacheFolder)/_verdaccio/
yarn_version=$(jq '.packageManager|select(test("yarn@"))' package.json -r | cut -d@ -f2); true

# start local registry
mkdir -p $HOME/.config/verdaccio
cat /verdaccio-config.yaml.tmpl | envsubst '$local_registry,$pkg_name,$storage_dir' | tee $HOME/.config/verdaccio/config.yaml
tmp_registry_log=`mktemp`
sh -c "nohup verdaccio --config $HOME/.config/verdaccio/config.yaml &>$tmp_registry_log &"

##### Prepare package manager for publish

if [[ $(echo $yarn_version|cut -d. -f1) -gt "2" ]]; then
  corepack enable
  corepack prepare yarn@${yarn_version} --activate
  yarn config set --home enableTelemetry 0
  yarn install
else
  npm ci
fi

####
# wait for `verdaccio` to boot
tail -s 1 -F $tmp_registry_log | grep -q 'http address'

npm set registry $local_registry
[[ -z "${pkg_scope}" ]] || npm config set ${pkg_scope}:registry $local_registry ; true
# login so we can publish packages
sh -c "npm-auth-to-token -u test -p test -e test@test.com -r $local_registry"

### Publish
npm publish --registry $local_registry $NPM_PUBLISH_ARGS

### NPM
mkdir "$HOME/app"
cd "$HOME/app"
npm init --yes
npm set registry "$local_registry"
npm install "$pkg_name"
jq '[.name, .version]' "./node_modules/${pkg_name}/package.json"

#sh -c "${@}"
