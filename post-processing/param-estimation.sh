#!/usr/bin/env bash

set -exuo pipefail

# https://speciationgenomics.github.io/fastsimcoal2/
#
# > Now we would run the parameter estimation under the best model 100
# times with each of these boostrapped SFS. This would take very long.
#
#
# You will need to have fastsimcoal2 installed:
#   conda install -c bioconda fastsimcoal2

HERE=$(cd "$(dirname "$0")" && pwd)

#
# Read configuration parameters
#
. "$HERE"/inputs.sh


############################

run_fastsimcoal2 () {
    # in conda, the latest package from miniconda installs this binary
    fsc27093 "$@"
}

# pass the output folder from block_bootstrapping.sh
WORKDIR="${1:?missing input folder. use the output folder from block_bootstrapping}"

BS_RUNS=( "$WORKDIR"/bootstrap/bs_* )

FSC_RUNS=100

for bs_dir in "${BS_RUNS[@]}"; do
    bs_num="${bs_dir##*_}" # numeric suffix for the run

    # Run fastsimcoal 100 times:
    for i in `seq 1 ${FSC_RUNS}`; do
	rnum=$(printf "%03d" "$i")
	rdir="${bs_dir}/fastsimcoal2/run_fsc_${rnum}"
	mkdir -p "$rdir"
	(
	    cd "$rdir"
	    for datafile in ../*.obs; do
		ln -s "$datafile"
	    done
	    # FIXME -- missing TPL template and EST files
	    run_fastsimcoal2 `: '-t ${PREFIX}.bs.$bs.tpl -e ${PREFIX}.bs.$bs.est' ` \
			     -m       `: computes minor site frequency spectrum` \
			     -0       `: do not take into account monomorphic sites for SFS likelihood computation` \
			     -C 10    `: minimum observed SFS entry count taken into account in likelihood computation` \
			     -n 10000 `: number of simulations to perform` \
			     -L 40    `: number of loops (ECM cycles) to perform during lhood maximization. Default is 20` \
			     -s0      `: output DNA as SNP data, and specify maximum no. of SNPs to output (use 0 to output all SNPs)` \
			     -M       `: perform parameter estimation by max lhood from SFS values between iterations` \
			     -q       `: quiet`
	)
    done
    # Find the best run:
    (
	cd "${bs_dir}/fastsimcoal2/"
	"$HERE/fsc-selectbestrun.sh"
    )
done
