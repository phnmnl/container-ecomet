#!/bin/bash

if [[ $# -lt 2 ]]; then
	echo "Error! Not enough arguments given."
	echo "Usage: \$0 mtbls-id download.zip (mtbls-token)"
fi

# Parameters
MTBLS_ID="${1}"
DOWNLOAD="${2}"
MTBLS_TOKEN="${3}"

# Download entire study
if [[ ${MTBLS_TOKEN} == "" ]]; then
	wget -O "${DOWNLOAD}" "https://www.ebi.ac.uk/metabolights/MTBLS${MTBLS_ID}/files/MTBLS${MTBLS_ID}"
else
# Download whole private study
	wget -O "${DOWNLOAD}" "https://www.ebi.ac.uk/metabolights/MTBLS${MTBLS_ID}/files/MTBLS${MTBLS_ID}?token=${MTBLS_TOKEN}"
fi

# Check file size
FILESIZE="$(wc -c < "${DOWNLOAD}")"

if [[ $MTBLS_ID -ne 520 ]] || [[ $FILESIZE -lt 13326196452 ]]; then
	echo "Error: Study has not been downloaded completely. Please re-run tool."
	exit 1
else
	echo "Study seems to have correct size."
fi
