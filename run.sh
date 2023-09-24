#!/bin/bash

set -eo pipefail


source ~/miniconda3/bin/activate
conda activate easySFS

set -x

VCF=/SciBorg/dolly/easySFS/amy_219_GQ30_minDP15__mac1_maxmiss07_thin1kb.vcf.gz
POPS=/SciBorg/dolly/easySFS/pop219.popfile.txt

workdir=$(mktemp -d "easy_sfs.$(date --iso-8601).XXXXXX.tmp")

# cleanup tmpdir on exit
trap 'rm -rf -- "$workdir" || :' EXIT

(
    cd "$workdir"
    sha1sum "$VCF" "$POPS" | tee "inputs.sha1sum"

    :
    : STEP 1 preview projections '(see projections.txt output)'
    :

    STEP_1_OUTPUT="step1_preview_projections.output.txt"

    cmd=(
	../easySFS.py -i "$VCF" -p "$POPS" --preview
    )

    (
	set +x
	echo "# date: $(date)"
	echo "# inputs: "
	while read LINE; do
	    echo "#   $LINE"
	done < "inputs.sha1sum"
	echo "# cmd: ${cmd[@]}"

	# run command
	time "${cmd[@]}"
    ) | tee "$STEP_1_OUTPUT"
 
    :
    : STEP 2 use pick_max_projections to pick the projection values with maximum segregating sites
    :

    STEP_2_OUTPUT="step2_pick_max_projections.output.txt"
    time ../pick_max_projections.py "$STEP_1_OUTPUT" | tee "$STEP_2_OUTPUT"

    max_proj_args=$(egrep -o -- "--proj=[0-9,]+" < "$STEP_2_OUTPUT")

    :
    : STEP 3 pick projections, using the output of Step 2 to build arguments
    :

    mkdir step3
    time ../easySFS.py -i "$VCF" -p "$POPS" -o step3 "${max_proj_args}"

    :
    : STEP 4. re-run with a slightly different set of args
    :
    time ../easySFS.py \
	 -i "$VCF" \
	 -p "$POPS" \
	 --dtype int `: data type in output` \
	 -a          `: keep all SNPs within each rad locus` \
	 "${max_proj_args[@]}" `: params from step 2` \
	 -o step4

) 2>&1 | tee "$workdir/run.log"


:
: NAME OUTPUT FOLDER
:

: files generated:

output_dir=easy_sfs.$(date +%Y-%m-%d_%H:%M:%S%z)
mv "$workdir" "$output_dir"
zip -r "$output_dir".zip "$output_dir"
