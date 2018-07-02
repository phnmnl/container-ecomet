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

wget_exit_code=$?

if [[ ${wget_exit_code} != 0 ]]; then
	echo "Error: Study has not been downloaded completely. Please re-run tool." >&2
else
	echo "Download successful" >&2
fi

exit $wget_exit_code
