#!/usr/bin/env Rscript

# ---------- Load R environment ----------
# Setup R error handling to go to stderr
options(show.error.messages=F, error=function() { cat(geterrmessage(), file=stderr()); q("no",1,F) } )

# Set proper locale
loc <- Sys.setlocale("LC_MESSAGES", "en_US.UTF-8")
loc <- Sys.setlocale(category="LC_ALL", locale="C")

# Set options
options(encoding="UTF-8")
options(stringAsfactors=FALSE, useFancyQuotes=FALSE)

# Take in trailing command line arguments
args <- commandArgs(trailingOnly=TRUE)
if (length(args) < 3) {
	print("Error! No or not enough arguments given.")
	print("Usage: $0 input.rdata characteristics.csv output.rdata")
	quit(save="no", status=1, runLast=FALSE)
}

# Load R environment
load(file=args[1])
args <- commandArgs(trailingOnly=TRUE)

# Load libraries
library(vegan)

# These variables will be exported globally
traits <- NULL
charist <- NULL
onsite <- NULL



# Import traits from csv
traits <- read.csv(args[2], header=TRUE, sep=";", quote="\"", fill=FALSE, dec=",", stringsAsFactors=FALSE)
traits$Sample.Negative <- gsub('(.*)\\..*', '\\1', gsub('( |-|,)', '.', traits$Sample.Negativ))
traits$Sample.Positive <- gsub('(.*)\\..*', '\\1', gsub('( |-|,)', '.', traits$Sample.Positiv))
if (polarity == "positive") {
	traits <- traits[match(mzml_names, traits$Sample.Positive),]
} else {
	traits <- traits[match(mzml_names, traits$Sample.Negative),]
}

# Create data frame with characteristics
charist <- as.data.frame(traits[,c("Sample","Season","Code","Species","Family","Type")])
charist <- cbind(charist, as.data.frame(model.matrix(~ 0 + Family, data=traits)))
charist <- cbind(charist, as.data.frame(model.matrix(~ 0 + Type, data=traits)))

# Convert Ellenberg factors to ordinal or binary matrix
charist <- cbind(charist, traits[,c("Light.index","Temperature.index","Continentality.index","Moisture.index","Reaction.index","Nitrogen.index")])
charist <- cbind(charist, as.data.frame(model.matrix(~ 0 + Life.form.index, data=traits)))

# Bind factors from Urmi (2010) as binary matrix to characteristics
charist <- cbind(charist, as.data.frame(model.matrix(~ 0 + Growth.form, data=traits)))
charist <- cbind(charist, as.data.frame(model.matrix(~ 0 + Habitat.type, data=traits)))
charist <- cbind(charist, as.data.frame(model.matrix(~ 0 + Substrate, data=traits)))

# Bind Life strategy from During (1992) / Frisvol (1997) as binary matrix to characteristics
charist <- cbind(charist, as.data.frame(model.matrix(~ 0 + Life.strategy, data=traits)))

# Bind factors from Smith et al. (1990) & (2004) as ordinal / binary matrix to characteristics
charist <- cbind(charist, data.frame(Mean.spore.size=traits$Mean.spore.size))
charist <- cbind(charist, as.data.frame(model.matrix(~ 0 + Gametangia.distribution, data=traits)))
charist <- cbind(charist, as.data.frame(model.matrix(~ 0 + Sexual.reproduction.frequency, data=traits)))

# Season
charist <- cbind(charist, as.data.frame(model.matrix(~ 0 + Season, data=traits)))

# Species
charist <- cbind(charist, as.data.frame(model.matrix(~ 0 + Code, data=traits)))

# On-site characteristics (immediate growth conditions)
onsite <- as.data.frame(traits[,c("Sample","Season","Code","Species","Family","Type")])
onsite <- cbind(onsite, as.data.frame(model.matrix(~ 0 + Freshweight, data=traits)))
onsite <- cbind(onsite, as.data.frame(model.matrix(~ 0 + Onsite_Substrate, data=traits)))
onsite <- cbind(onsite, as.data.frame(model.matrix(~ 0 + Onsite_Light, data=traits)))
onsite <- cbind(onsite, as.data.frame(model.matrix(~ 0 + Onsite_Moisture, data=traits)))
onsite <- cbind(onsite, as.data.frame(model.matrix(~ 0 + Onsite_Exposition, data=traits)))
onsite <- cbind(onsite, as.data.frame(model.matrix(~ 0 + Season, data=traits)))
onsite <- cbind(onsite, as.data.frame(model.matrix(~ 0 + Code, data=traits)))



# ---------- Save R environment ----------
save.image(file=args[3])

