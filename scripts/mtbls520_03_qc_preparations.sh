#!/bin/bash

# Check parameters
if [[ $# -lt 3 ]]; then
	echo "Error! Not enough arguments given."
	echo "Usage: \$0 polarity a.txt s.txt"
	exit 1
fi

# Input parameters
POLARITY="${1}"
ISA_A="${2}"
ISA_S="${3}"

# Grab factors out of ISA-Tab
MZML_FILES="$(cat ${ISA_A} | awk -F $'\t' '{ print $29 }' | sed -e "s/\"//g" | grep mzML | grep MM8)"
MZML_FILES=(${MZML_FILES})
SEASONS="$(cat ${ISA_A} | awk -F $'\t' '{ print $1 }' | sed -e "s/\"//g" | grep -v Sample | grep QC | sed -e "s/_[0-9][0-9]$//" | sed -e "s/.*_//" | awk '!a[$0]++')"
SEASONS=(${SEASONS})
SEASON_DATES="$(cat ${ISA_S} | awk -F $'\t' '{ print $29 }' | grep -v \"\" | sed -e "s/\"//g" | grep -v Date | awk '!a[$0]++')"
SEASON_DATES=(${SEASON_DATES})

# Create fake directories
for ((i=0; i<${#SEASONS[@]}; i++)); do
	mkdir -p input/${SEASON_DATES[${i}]}-${SEASONS[${i}]}/QC
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
SEASONS_DATES="$(cat ${ISA_A} | awk -F $'\t' '{ print $1 }' | sed -e "s/\"//g" | grep -v Sample | grep QC | sed -e "s/_[0-9][0-9]$//" | sed -e "s/.*_//" | sed -e "s/${SEASONS[0]}/${SEASON_DATES[0]}/" | sed -e "s/${SEASONS[1]}/${SEASON_DATES[1]}/" | sed -e "s/${SEASONS[2]}/${SEASON_DATES[2]}/" | sed -e "s/${SEASONS[3]}/${SEASON_DATES[3]}/")"
SEASONS_DATES=(${SEASONS_DATES})
SEASONS="$(cat ${ISA_A} | awk -F $'\t' '{ print $1 }' | sed -e "s/\"//g" | grep -v Sample | grep QC | sed -e "s/_[0-9][0-9]$//" | sed -e "s/.*_//")"
SEASONS=(${SEASONS})
NUMBER=${#MZML_FILES[@]}

# Move links to directories
for ((i=0; i<${NUMBER}; i++)); do
        mv "${MZML_FILES[${i}]}" "input/${SEASONS_DATES[${i}]}-${SEASONS[${i}]}/QC/"
done

