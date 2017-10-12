<?xml version='1.0' encoding='UTF-8'?>
<!--Proposed Tool Section: [Eco-Metabolomics]-->
<tool id="mtbls520_01_mtbls_download_maf" name="mtbls520_01_mtbls_download" version="0.1">
  <requirements>
    <container type="docker">container-registry.phenomenal-h2020.eu/phnmnl/ecomet</container>
  </requirements>
  <description>Download private MTBLS study via https.</description>
  <command><![CDATA[
export MTBLS_ID="$mtbls_id";
export MTBLS_TOKEN="$mtbls_token";
wget -O $outfile1 "https://www.ebi.ac.uk/metabolights/MTBLS${MTBLS_ID}/files/MTBLS${MTBLS_ID}?token=${MTBLS_TOKEN}";
  ]]>
  </command>
  <inputs>
    <param name="mtbls_id" type="text" value="520" label="MetaboLights ID" help="Enter the MetaboLights ID here, e.g. 520." />
    <param name="mtbls_token" type="text" label="MetaboLights Token" help="Enter the Secret MetaboLights Token here, e.g. aabbccdd-1122-4455-66ff-f0e0d0c0b0a0." />
  </inputs>
  <outputs>
    <data name="outfile1" type="data" format="zip" label="ZIP file containing the whole MTBLS study." />
  </outputs>
  <help><![CDATA[
This is the MTBLS520 study.
The study will be published soon. This code is work-in-progress. Do not redistribute unless study published.
Copyright (C) 2017 Kristian Peters - IPB Halle
----
More updates soon
  ]]></help>
</tool>

