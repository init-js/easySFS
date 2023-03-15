#!/bin/bash

#
# You only have to run this once.
# It will create a conda environment called 

set -exo pipefail
MINICONDA=https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh

tmpdir=$(readlink -f $(mktemp -d install.easySFS.XXXX))

cleanup () {
    rm -rf -- "$tmpdir"
}


trap cleanup EXIT

if ! which conda >/dev/null ; then
    if [[ ! -d ~/miniconda3/ ]]; then
        (
            cd "$tmpdir"
            curl -o $(basename "$MINICONDA") "$MINICONDA"
            bash "$(basename "$MINICONDA")"
        )
    fi
fi

source ~/miniconda3/bin/activate

if ! conda env list | grep '^easySFS '; then
    conda create -n tmp-easySFS -y
    conda install -y -n tmp-easySFS -c conda-forge numpy pandas scipy dadi
    conda rename -n tmp-easySFS easySFS
fi

:
:
: 'Activate easySFS environment with `conda activate easySFS`'
:
: