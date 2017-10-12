#!/bin/bash

# Check parameters
if [[ $# -lt 4 ]]; then
	echo "Error! Not enough arguments given."
	echo "Usage: \$0 polarity study.folder a.txt s.txt"
	exit 1
fi

# Input parameters
POLARITY="${1}"
STUDY_DIR="${2}"
ISA_A="${3}"
ISA_S="${4}"

# Grab factors out of ISA-Tab
MZML_FILES="$(cat ${ISA_A} | awk -F $'\t' '{ print $29 }' | sed -e "s/\"//g" | grep mzML | grep -v MM8)"
MZML_FILES=(${MZML_FILES})
SPECIES="$(cat ${ISA_A} | awk -F $'\t' '{ print $29 }' | sed -e "s/\"//g" | grep mzML | grep -v MM8 | sed -e "s/pos_[0-9][0-9]_//" | sed -e "s/_.*//" | awk '!a[$0]++')"
SPECIES=(${SPECIES})
SEASONS="$(cat ${ISA_A} | awk -F $'\t' '{ print $1 }' | sed -e "s/\"//g" | grep -v Sample | sed -e "s/_.*//" | sed -e 's/\(.*\)/\L\1/' | grep -v qc | awk '!a[$0]++')"
SEASONS=(${SEASONS})
SEASON_DATES="$(cat ${ISA_S} | awk -F $'\t' '{ print $29 }' | sed -e "s/\"//g" | grep -v Date | awk '!a[$0]++')"
SEASON_DATES=(${SEASON_DATES})

# Create directories
for ((i=0; i<=${#SEASONS[@]}; i++)); do
	for ((j=0; j<=${#SPECIES[@]}; j++)) do
		mkdir -p input/${SEASON_DATES[${i}]}-${SEASONS[${i}]}/${SPECIES[${j}]}
	done
done

# Convert variables to arrays
SPECIES="$(cat ${ISA_A} | awk -F $'\t' '{ print $29 }' | sed -e "s/\"//g" | grep mzML | grep -v MM8 | sed -e "s/pos_[0-9][0-9]_//" | sed -e "s/_.*//")"
SPECIES=(${SPECIES})
SEASONS="$(cat ${ISA_A} | awk -F $'\t' '{ print $1 }' | sed -e "s/\"//g" | grep -v Sample | sed -e "s/_.*//" | sed -e 's/\(.*\)/\L\1/' | grep -v qc)"
SEASONS=(${SEASONS})
SEASON_DATES="$(cat ${ISA_S} | awk -F $'\t' '{ print $29 }' | grep -v \"\" | sed -e "s/\"//g" | grep -v Date)"
SEASON_DATES=(${SEASON_DATES})
NUMBER=${#MZML_FILES[@]}

# Move files to directories
for ((i=0; i<${NUMBER}; i++)); do
	mv "${STUDY_DIR}/${MZML_FILES[${i}]}" "input/${SEASON_DATES[${i}]}-${SEASONS[${i}]}/${SPECIES[${i}]}/${MZML_FILES[${i}]}"
done



