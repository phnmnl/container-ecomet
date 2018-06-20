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
if (length(args) < 2) {
	print("Error! No or not enough arguments given.")
	print("Usage: $0 polarity output.rdata")
	quit(save="no", status=1, runLast=FALSE)
}

# Load libraries
library(parallel)        # Detect number of cpu cores
library(xcms)            # Swiss army knife for metabolomics
library(multtest)        # For diffreport
library(CAMERA)          # Metabolite Profile Annotation
library(RColorBrewer)    # For colors



# ---------- Global variables ----------
# Global variables for the experiment
nSlaves <- detectCores(all.tests=FALSE, logical=TRUE)
polarity <- args[1]
pol <- substr(x=polarity, start=1, stop=3)
rt_range <- c(20,1020)
ppm <- 30
peakwidth <- c(5,12)
prefilter <- c(2,20)
mzwidth <- 0.0065
minfrac <- 0.5
bwindow <- 4
snthresh <- 2
fitgauss <- TRUE
verbose.columns <- TRUE

# Optimized variables
ppm <- 35
peakwidth <- c(4,21)
prefilter <- c(5,50) # quantile(xcmsRaw(mzml_files[1])@env$intensity) # 3 scans = 1 sec
mzwidth <- 0.01 # IPO recommendation was 0.0282
minfrac <- 0.5 # 2/3 peaks in one group (species/season) must be present
bwindow <- 4
snthresh <- 10 # hist(peaks(peak_xset)[,"sn"], breaks=100000, xlim=c(0,200)); summary(peaks(peak_xset)[,"sn"])

# Preparations for plotting
par(mfrow=c(1,1), mar=c(4,4,4,1), oma=c(0,0,0,0), cex.axis=0.9, cex=0.8)

# Data directory
mzml_dir <- "./input/"

# These variables will be exported globally
isa_tab <- NULL
mzml_files <- NULL
mzml_names <- NULL

species <- NULL          # Override BiocGenerics function
seasons <- NULL
seasonal_species <- NULL
spesearep <- NULL
species_names <- NULL
species_colors <- NULL
species_symbols <- NULL
seasons_names <- NULL
seasons_colors <- NULL
seasons_symbols <- NULL
species_samples_colors <- NULL
seasons_samples_colors <- NULL
species_samples_symbols <- NULL
seasons_samples_symbols <- NULL

peak_xset <- NULL
peak_xcam <- NULL
peak_maf <- NULL

bina_list <- NULL
uniq_list <- NULL
diff_list <- NULL
peak_list <- NULL
feat_list <- NULL



# ---------- Load mzML files ----------
# Load files
mzml_files <- list.files(mzml_dir, pattern="*.mzML", recursive=T, full.names=T)

# Exclude blanks
mzml_files <- mzml_files[grep("MM8", mzml_files, invert=T)]
mzml_files <- mzml_files[grep("ACN", mzml_files, invert=T)]
mzml_files <- mzml_files[grep("extrBuff", mzml_files, invert=T)]

# Filter for polarity specific files
mzml_files <- mzml_files[grep(pol, mzml_files, invert=F)]

# Basenames of files without path and without extension
mzml_names <- gsub('(.*)\\..*', '\\1', gsub('( |-|,)', '.', basename(mzml_files)))



# ---------- Define sample classes ----------
# Sample classes: species
species <- as.factor(sapply(strsplit(as.character(mzml_names), "_"), function(x) {
	nam <- x[3];
	nam;
}))

# Sample classes: seasons
seasons <- as.factor(sapply(strsplit(as.character(mzml_files), " "), function(x) {
	if (grepl("summer",x)) nam <- "summer";
	if (grepl("autumn",x)) nam <- "autumn";
	if (grepl("winter",x)) nam <- "winter";
	if (grepl("spring",x)) nam <- "spring";
	nam;
}))

# Sample classes: seasonal species
seasonal_species <- as.factor(sapply(strsplit(as.character(mzml_files), "_"), function(x) {
	se <- as.factor(sapply(strsplit(as.character(x[2]), "/"), function(x) { x[1]; }))
	sp <- as.factor(sapply(strsplit(as.character(x[2]), "/"), function(x) { x[2]; }))
	nam <- paste(se, '_', sp, sep='')
	nam;
}))

# Sample classes: unique species-seasons-replicate
spesearep <- as.factor(sapply(strsplit(as.character(mzml_files), "_"), function(x) {
	se <- as.factor(sapply(strsplit(as.character(x[2]), "/"), function(x) { x[1]; }))
	sp <- as.factor(sapply(strsplit(as.character(x[2]), "/"), function(x) { x[2]; }))
	nam <- paste(sp, '_', se, sep='')
	nam;
}))
spesearep <- make.names(as.character(spesearep), unique=TRUE)

# Define species names, colors, symbols
species_names <- unique(species)
species_colors <- c("yellowgreen", "mediumseagreen", "darkorange1", "firebrick3", "darkolivegreen4", "dodgerblue4", "chocolate", "darkviolet", "darkkhaki")
species_symbols <- c(15, 16, 0, 1, 17, 8, 2, 5, 18)

# Define seasons names, colors, symbols
seasons_names <- unique(seasons)
seasons_colors <- c("darkgoldenrod3", "firebrick3", "deepskyblue3", "chartreuse3")
seasons_symbols <- c(1, 15, 16, 0)

# Define samples colors
species_samples_colors <- sapply(species, function(x) { x <- species_colors[which(x==species_names)] } )
seasons_samples_colors <- sapply(seasons, function(x) { x <- seasons_colors[which(x==seasons_names)] } )

# Define samples symbols
species_samples_symbols <- sapply(species, function(x) { x <- species_symbols[which(x==species_names)] } )
seasons_samples_symbols <- sapply(seasons, function(x) { x <- seasons_symbols[which(x==seasons_names)] } )



# ---------- Save chromatograms ----------
# Save chromatograms and intensities in list
xchroms <- list()
for (i in 1:length(mzml_files)) {
	chroma <- xcmsRaw(mzml_files[i])
	x <- chroma@scantime
	#y <- scale(chroma@tic, center=FALSE)
	y <- chroma@tic
	int <- sum(chroma@env$intensity)
	xchrom <- data.frame(x, y, int)
	colnames(xchrom) <- c("rt", "tic", "int")
	xchroms[[i]] <- xchrom
}



# ---------- Save R environment ----------
save.image(file=args[2])

