#!/bin/bash

# this file is meant to be sourced. it defines common parameters used
# by the different scripts in this folder.

#
# Input files (absolute paths)
#
VCF=~/dolly/easySFS/amy_219_GQ30_minDP15__mac1_maxmiss07.vcf.gz
POPS=~/dolly/easySFS/pop219.popfile.txt


EASY_SFS_ARGS=(
    -p "$POPS"
    --dtype int
    -a
    --proj=254,14,14
)

# ========== BASIC VALIDATION ===========
if [[ ! -f "$VCF" ]]; then
    echo "Invalid VCF file: $VCF" >&2
    exit 1
fi

if [[ ! -f "$POPS" ]]; then
    echo "Invalid populations definition file: $POPS" >&2
    exit 1
fi

