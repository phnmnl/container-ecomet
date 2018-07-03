FROM container-registry.phenomenal-h2020.eu/phnmnl/camera:v1.33.3_cv0.10.59

MAINTAINER PhenoMeNal-H2020 Project (phenomenal-h2020-users@googlegroups.com)

LABEL software="Eco-Metabolomics"
LABEL software.version="1.1"
LABEL version="0.1"
LABEL Description="Eco-Metabolomics: Process ecological metabolomics data"
LABEL website="https://github.com/phnmnl/container-ecomet"
LABEL documentation="https://github.com/phnmnl/container-ecomet/blob/master/README.md"
LABEL license="https://github.com/phnmnl/container-midcor/blob/master/License.txt"
LABEL tags="Metabolomics,Ecology"

RUN apt-get -y update && DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install apt-transport-https \
    make \
    gcc \
    gfortran \
    g++ \
    libnetcdf-dev \
    libxml2-dev \
    libblas-dev \
    liblapack-dev \
    libssl-dev \
    pkg-config \
    git \
    xorg \
    xorg-dev \
    libglu1-mesa-dev \
    libgl1-mesa-dev \
    wget \
    zip \
    unzip \
    perl-base && \
    R -e 'install.packages(c("irlba","igraph","XML","intervals"), repos="https://cran.r-project.org/")' && \
    R -e 'install.packages("devtools", repos="https://cran.r-project.org/")' && \
    R -e 'library(BiocInstaller); biocLite("multtest")' && \
    R -e 'install.packages(c("RColorBrewer","Hmisc","gplots","multcomp","rgl","mixOmics","vegan","cba","nlme","ape","pvclust","dendextend","phangorn","VennDiagram"), repos="https://cran.r-project.org/")' && \
    apt-get -y remove --purge \
                g++ \
                gcc \
                gfortran && \
    apt-get -y clean && apt-get -y autoremove && rm -rf /var/lib/{cache,log}/ /tmp/* /var/tmp/*

# Add scripts to container
ADD scripts/* /usr/local/bin/
RUN chmod +x /usr/local/bin/*

# Add testing to container
ADD runTest1.sh /usr/local/bin/runTest1.sh

