#!/bin/bash

# Check parameters
if [[ $# -lt 10 ]]; then
	echo "Error! 10 Arguments required."
	echo "Usage: \$0 input.zip polarity study.dir study.maf qc.dir qc.maf traits.txt phylo.tre a.txt s.txt"
	exit 1
fi

# Input parameters
INPUT="${1}"
POLARITY="${2}"

# Output parameters
STUDY_FILES="${3}"
STUDY_MAF="${4}"
QC_FILES="${5}"
QC_MAF="${6}"
TRAITS_FILE="${7}"
PHYLO_FILE="${8}"
A_FILE="${9}"
S_FILE="${10}"

# Only take latest files and unzip whole dataset
mkdir -p output || exit 2
zip ${INPUT} -d '*audit*'
unzip -j -d output ${INPUT} || exit 1

# Create output files and folders (for dataset collections)
mkdir -p ${STUDY_FILES} || exit 3
touch ${STUDY_MAF} || exit 4
mkdir -p ${QC_FILES} || exit 5
touch ${QC_MAF} || exit 6
touch ${TRAITS_FILE} || exit 7
touch ${PHYLO_FILE} || exit 8
touch ${A_FILE} || exit 9
touch ${S_FILE} || exit 10

# Move files to their places
mv output/${POLARITY}_MM8_*.mzML ${QC_FILES}/
mv output/${POLARITY}_[0-9]*.mzML ${STUDY_FILES}/
mv output/m_bryos_metabolite_profiling_mass_spectrometry_${POLARITY}itive_mode.maf.tsv ${STUDY_MAF}
mv output/m_bryos_quality_control_mass_spectrometry_${POLARITY}itive_mode.maf.tsv ${QC_MAF}
mv output/a_bryos_metabolite_profiling_mass_spectrometry_${POLARITY}itive_mode.txt ${A_FILE}
mv output/s_bryos.txt ${S_FILE}
mv output/m_characteristics.csv ${TRAITS_FILE} 
mv output/m_moss_phylo.tre ${PHYLO_FILE}

