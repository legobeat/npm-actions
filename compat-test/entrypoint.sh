#!/bin/sh

set -ex

echo $VERDACCIO_STORAGE_PATH
ls -la $VERDACCIO_STORAGE_PATH

export local_registry="http://127.0.0.1:4873"
export pkg_name=$(jq -r .name ./package.json)
export pkg_scope=$(echo $pkg_name | grep -o '^@[^/]*'; true)
export VERDACCIO_STORAGE_PATH=${VERDACCIO_STORAGE_PATH:-$(yarn config get cacheFolder)/_verdaccio/}
yarn_version=$(jq '.packageManager|select(test("yarn@"))' package.json -r | cut -d@ -f2); true

# start local registry
mkdir -p $HOME/.config/verdaccio
cat /verdaccio-config.yaml.tmpl | envsubst '$local_registry,$pkg_name,$storage_dir' | tee $HOME/.config/verdaccio/config.yaml
tmp_registry_log=`mktemp`
sh -c "nohup verdaccio --config $HOME/.config/verdaccio/config.yaml &>$tmp_registry_log &"

####
# wait for `verdaccio` to boot
tail -s 1 -F $tmp_registry_log | grep -q 'http address'

if [[ -z "${pkg_scope}" ]]; then
  npm config set registry $local_registry
else
  npm config set ${pkg_scope}:registry $local_registry
fi

### NPM
mkdir "$HOME/app"
cd "$HOME/app"
npm init --yes
npm set registry "$local_registry"
npm install "$pkg_name"
jq '[.name, .version]' "./node_modules/${pkg_name}/package.json"

#sh -c "${@}"
