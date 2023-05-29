#!/bin/bash

set -eo pipefail


source ~/miniconda3/bin/activate
conda activate easySFS

set -x

VCF=/SciBorg/dolly/easySFS/amy_219_GQ30_minDP15__mac1_maxmiss07_thin1kb.vcf.gz
POPS=/SciBorg/dolly/easySFS/pop219.popfile.txt

:
: STEP 1 preview projections '(see projections.txt output)'
:

time ./easySFS.py -i "$VCF" -p "$POPS" --preview | tee projections.txt

:
: STEP 2 use pick_max_projections to pick the projection values with maximum segregating sites
:

: time ./pick_max_projections.py projections.txt

:
: STEP 3 pick projections, using the output of Step 2 to build arguments
:

#time ./easySFS.py -i "$VCF" -p "$POPS" --proj=254,14,14
