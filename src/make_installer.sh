#!/bin/bash
set -e

must_install_bootstrap="yes"
if [ -f /out/bootstrap/installer.sha256 ]; then
    sha256_installer=$(awk '{print $1}' /out/bootstrap/installer.sha256)
    sha256_latest=$(curl -s https://repo.anaconda.com/miniconda/ \
        | awk 'BEGIN{line=0} /Miniconda3-latest-Linux-x86_64.sh/{line=NR} (line!=0 && NR==line+3){print}' \
        | grep -Eo '[0-9a-fA-F]{64}')
    if [ "$sha256_latest" = "$sha256_installer" ]; then
        must_install_bootstrap=""
    fi
fi

if [ -n "$must_install_bootstrap" ]; then
    echo "--- Must set up the bootstrap environment ---"
    rm -rf /out/bootstrap
    curl -o /out/installer.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    trap 'rm -f /out/installer.sh' EXIT
    sh /out/installer.sh -b -f -p /out/bootstrap
    /out/bootstrap/bin/conda install -p /out/bootstrap --yes make constructor
    sha256sum /out/installer.sh >/out/bootstrap/installer.sha256
else
    echo "Boot strap environment already present."
fi
source /out/bootstrap/bin/activate /out/bootstrap
command -v make
command -v constructor

exec make -f /src/Makefile
 
