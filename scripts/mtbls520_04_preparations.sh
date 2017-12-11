#!/bin/bash

# Check parameters
if [[ $# -lt 5 ]]; then
	echo "Error! Not enough arguments given."
	echo "Usage: \$0 polarity studyfile_names.txt studyfile_files.txt a.txt s.txt"
	exit 1
fi

# Input parameters
POLARITY="${1}"
STUDY_NAMES="${2}"
STUDY_FILES="${3}"
ISA_A="${4}"
ISA_S="${5}"

# Grab factors out of ISA-Tab
MZML_FILES="$(cat ${ISA_A} | awk -F $'\t' '{ print $29 }' | sed -e "s/\"//g" | grep mzML | grep -v MM8)"
MZML_FILES=(${MZML_FILES})
SPECIES="$(cat ${ISA_A} | awk -F $'\t' '{ print $29 }' | sed -e "s/\"//g" | grep mzML | grep -v MM8 | sed -e "s/pos_[0-9][0-9]_//" | sed -e "s/_.*//" | awk '!a[$0]++')"
SPECIES=(${SPECIES})
SEASONS="$(cat ${ISA_A} | awk -F $'\t' '{ print $1 }' | sed -e "s/\"//g" | grep -v Sample | sed -e "s/_.*//" | sed -e 's/\(.*\)/\L\1/' | grep -v qc | awk '!a[$0]++')"
SEASONS=(${SEASONS})
SEASON_DATES="$(cat ${ISA_S} | awk -F $'\t' '{ print $29 }' | grep -v \"\" | sed -e "s/\"//g" | grep -v Date | awk '!a[$0]++')"
SEASON_DATES=(${SEASON_DATES})

# Create directories
for ((i=0; i<${#SEASONS[@]}; i++)); do
	for ((j=0; j<${#SPECIES[@]}; j++)) do
		mkdir -p input/${SEASON_DATES[${i}]}_${SEASONS[${i}]}/${SPECIES[${j}]}
	done
done

# Link files
STUDY_NAMES="$(cat /tmp/studyfile_names.txt | perl -pe 's/\,$//g')"
STUDY_NAMES=(${STUDY_NAMES})
STUDY_FILES="$(cat /tmp/studyfile_files.txt | perl -pe 's/\,$//g')"
STUDY_FILES=(${STUDY_FILES})
NUMBER=${#STUDY_FILES[@]}

for ((i=0; i<${NUMBER}; i++)); do
	ln -s "${STUDY_FILES[${i}]}" "${STUDY_NAMES[${i}]}"
done

# Convert variables to arrays
SPECIES="$(cat ${ISA_A} | awk -F $'\t' '{ print $29 }' | sed -e "s/\"//g" | grep mzML | grep -v MM8 | sed -e "s/pos_[0-9][0-9]_//" | sed -e "s/_.*//")"
SPECIES=(${SPECIES})
SEASONS="$(cat ${ISA_A} | awk -F $'\t' '{ print $1 }' | sed -e "s/\"//g" | grep -v Sample | sed -e "s/_.*//" | sed -e 's/\(.*\)/\L\1/' | grep -v qc)"
SEASONS=(${SEASONS})
SEASON_DATES="$(cat ${ISA_S} | awk -F $'\t' '{ print $29 }' | grep -v \"\" | sed -e "s/\"//g" | grep -v Date)"
SEASON_DATES=(${SEASON_DATES})
NUMBER=${#MZML_FILES[@]}

# Move links to directories
for ((i=0; i<${NUMBER}; i++)); do
	mv "${MZML_FILES[${i}]}" "input/${SEASON_DATES[${i}]}_${SEASONS[${i}]}/${SPECIES[${i}]}/"
done

