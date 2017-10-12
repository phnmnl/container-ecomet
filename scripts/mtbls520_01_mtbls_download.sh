#!/bin/bash

if [[ $# -lt 3 ]]; then
	echo "Error! Not enough arguments given."
	echo "Usage: \$0 mtbls-id mtbls-token download.zip"
fi

# Parameters
MTBLS_ID="${1}"
MTBLS_TOKEN="${2}"
DOWNLOAD="${3}"

# Download whole private study
wget -O "${DOWNLOAD}" "https://www.ebi.ac.uk/metabolights/MTBLS${MTBLS_ID}/files/MTBLS${MTBLS_ID}?token=${MTBLS_TOKEN}"


