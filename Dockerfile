FROM container-registry.phenomenal-h2020.eu/phnmnl/camera:dev_v1.33.3_cv0.8.52

MAINTAINER PhenoMeNal-H2020 Project (phenomenal-h2020-users@googlegroups.com)

LABEL software="Eco-Metabolomics"
LABEL software.version="1.0"
LABEL version="0.1"
LABEL Description="Eco-Metabolomics: Process mass-spec data in an ecological context. Container contains several bundled R packages."
LABEL website="https://github.com/phnmnl/container-ecomet"
LABEL documentation="https://github.com/phnmnl/container-ecomet/blob/master/README.md"
LABEL license="https://github.com/phnmnl/container-midcor/blob/master/License.txt"
LABEL tags="Metabolomics"

# Install packages for compilation
RUN apt-get -y update && DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install make gcc gfortran g++ libnetcdf-dev libxml2-dev libblas-dev liblapack-dev libssl-dev r-base-dev pkg-config git xorg xorg-dev libglu1-mesa-dev libgl1-mesa-dev && \
    R -e 'source("https://bioconductor.org/biocLite.R"); biocLite("multtest")' && \
    R -e 'install.packages(c("RColorBrewer","Hmisc","gplots","multcomp","rgl","mixOmics","vegan","ape","pvclust","dendextend","cba","nlme"), repos="https://mirrors.ebi.ac.uk/CRAN/")' && \
    apt-get -y --purge --auto-remove remove make gcc gfortran g++ libblas-dev liblapack-dev r-base-dev libssl-dev pkg-config git xorg-dev libglu1-mesa-dev libgl1-mesa-dev && \
    apt-get -y clean && apt-get -y autoremove && rm -rf /var/lib/{cache,log}/ /tmp/* /var/tmp/*

# Add scripts to container
ADD scripts/*.r /usr/local/bin/
RUN chmod +x /usr/local/bin/*.r

# Add testing to container
ADD runTest1.sh /usr/local/bin/runTest1.sh

