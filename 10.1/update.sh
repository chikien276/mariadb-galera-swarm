#!/bin/bash
set -e

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
fi
versions=( "${versions[@]%/}" )

for version in "${versions[@]}"; do
    [[ -d ${version} ]] || mkdir ${version}
    cp -r \
        conf.d \
        *.sh \
        bin \
        primary-component.sql \
        "${version}/"

    sed \
        -e 's!%%MARIADB_VERSION%%!'"$version"'!g' \
        Dockerfile.template \
        > "$version/Dockerfile"
done
