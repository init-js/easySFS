#!/usr/bin/env bash

set -euxo pipefail

# https://speciationgenomics.github.io/fastsimcoal2/
#
# > Now that we know which of the models is the best one, we can do some
# bootstrapping to figure out how certain we are in our parameter
# estimates. We will use block-bootstrapping to account for linkage
# between SNPs:
#

HERE=$(cd "$(dirname "$0")" && pwd)

#
# Read common configuration parameters
#
. "$HERE"/inputs.sh


# number of bootstrapping runs
BS_RUNS=50


####################################

run_easy_sfs () {
    local infile="$1" # this is a vcf.gz pathname
    shift
    "$HERE/../easySFS.py" -i "$infile" "${EASY_SFS_ARGS[@]}" "$@"
}


OUTDIR="${1:?missing output directory argument}"   
PREFIX=$(basename "$VCF" .vcf.gz)
allsites=$OUTDIR/$PREFIX.allSites
header=$OUTDIR/$PREFIX.header
sitecount=$OUTDIR/$PREFIX.sitecount

mkdir -p "$OUTDIR"

:
: Get all lines with genomic data
:
if [[ ! -f "$allsites" ]]; then
    zgrep -v "^#" "$VCF" > "$allsites".tmp
    mv "$allsites"{.tmp,}
fi

:
: Get the header
:
if [[ ! -f "$header" ]]; then
    zgrep "^#" $VCF > "$header".tmp
    mv "$header"{.tmp,}
fi

:
: Count sites
:
if [[ ! -f "$sitecount" ]]; then
    wc -l "$allsites" | cut -d' ' -f1 > "$sitecount".tmp
    mv "$sitecount"{.tmp,}
fi

# if you change this number, you need to delete the blocks
NUM_BLOCKS=100
sites_per_block=$(( $(cat "$sitecount") / NUM_BLOCKS ))
num_block_files=$(( ($(cat "$sitecount") + (NUM_BLOCKS -1)) / NUM_BLOCKS ))

mkdir -p "$OUTDIR/blocks"
block_prefix="$OUTDIR/blocks/$PREFIX.sites."
block_files=( "$block_prefix"* )

if [[ "${#block_files[@]}" != "$num_block_files" ]]; then 
    split -l "$sites_per_block" -d -a 4 "$allsites" "$block_prefix"
fi

# Generate 50 files each with randomly concatenated blocks and compute the SFS for each:
for i in `seq 1 $BS_RUNS`
do
    
    # Make a new folder for each bootstrapping iteration:
    iter_num=$(printf "%03d" "$i")  # the iteration number padded with zeroes. e.g. 005
    iter_out="$OUTDIR/bootstrap/bs_${iter_num}"
    iter_vcf=$iter_out/$PREFIX.bs.${iter_num}.vcf
    iter_blocks=$iter_out/blocks.txt
    mkdir -p "$iter_out"

    if [[ ! -f "$iter_blocks" ]]; then
	# Add the header to our new bootstrapped vcf file
	echo "$header" > "$iter_blocks.tmp"

	# Randomly add blocks (with replacement)
	(
	    set +x
	    for r in `seq 1 $NUM_BLOCKS`
	    do
		echo $(shuf -n1 -e "$block_prefix"*) >> "$iter_blocks.tmp"
	    done
	)
	mv "$iter_blocks"{.tmp,}
    fi

    if [[ ! -f "$iter_vcf".gz ]]; then
	counter=1
	while read file_part; do
	    let counter=counter+1
	    : "building run $i vcf. component  $counter / $NUM_BLOCKS"
	    cat "$file_part"
	done < "$iter_blocks" | gzip -c > "$iter_vcf".gz.tmp
	mv "$iter_vcf".gz.tmp "$iter_vcf".gz
    fi

    # Make an SFS from the new bootstrapped file
    time run_easy_sfs "$iter_vcf".gz -o "$iter_out/"

    #
    # In the easysfs' output/fastsimcoal2/ folder there are many files:
    #
    # /cdv_MAFpop0.obs
    # /ndv_MAFpop0.obs
    # /sdv_MAFpop0.obs
    # /amy_219_GQ30_minDP15__mac1_maxmiss07_jointMAFpop1_0.obs
    # /amy_219_GQ30_minDP15__mac1_maxmiss07_jointMAFpop2_0.obs
    # /amy_219_GQ30_minDP15__mac1_maxmiss07_jointMAFpop2_1.obs
    # /amy_219_GQ30_minDP15__mac1_maxmiss07_MSFS.obs  ---- This one
    #
    # FIXME Original command doesn't quite fit:
    #   cp ../${PREFIX}_jointDAFpop1_0.obs  ${PREFIX}.bs.${i}_jointDAFpop1_0.obs

    : "$iter_vcf".gz ready
    : done $i out of $BS_RUNS
done
