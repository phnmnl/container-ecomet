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
if (length(args) < 14) {
	print("Error! No or not enough arguments given.")
	print("Usage: $0 polarity export.maf rtcor.pdf mzdevtime.pdf mzdevsample.pdf rtdevsample.pdf MM8_chromatograms.pdf plot_normal.pdf plot_stacked.pdf histograms.pdf MM8_variation.pdf MM8_compounds.pdf pca.pdf output.rdata")
	quit(save="no", status=1, runLast=FALSE)
}

# Load libraries
library(xcms)            # Swiss army knife for metabolomics
library(multtest)        # For statistics
library(nlme)            # For lmer test
library(multcomp)        # For tukey test



# ---------- Global variables ----------
# Global variables for the experiment
nSlaves <- 1
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
qc_files <- NULL
qc_names <- NULL
qc_standard <- NULL
qc_batch <- NULL
qc_batch_names <- NULL
qc_batch_colors <- NULL
qc_batch_symbols <- NULL
qc_batch_samples_colors <- NULL
qc_xset <- NULL
qc_list <- NULL



# ---------- Load mzML files ----------
# Load files
qc_files <- list.files(mzml_dir, pattern="*.mzML", recursive=T, full.names=T)

# Only include MM8 blanks
qc_files <- qc_files[grep("MM8", qc_files, invert=F)]
qc_files <- qc_files[grep(pol, qc_files, invert=F)]

# Basenames of files without path and without extension
qc_names <- gsub('(.*)\\..*', '\\1', gsub('( |-|,)', '.', basename(qc_files)))

# Return global variables
qc_files <- qc_files
qc_names <- qc_names



# ---------- Define sample classes ----------
# Sample classes: standards (ACN + MM8)
qc_standard <- as.factor(sapply(strsplit(as.character(qc_names), "_"), function(x) {
	nam <- x[2];
	nam;
}))

# Sample classes: batch
qc_batch <- as.factor(sapply(strsplit(as.character(qc_files), " "), function(x) {
	if (grepl("summer",x)) nam <- "summer";
	if (grepl("autumn",x)) nam <- "autumn";
	if (grepl("winter",x)) nam <- "winter";
	if (grepl("spring",x)) nam <- "spring";
	nam;
}))

# Define seasons names, colors, symbols
qc_batch_names <- unique(qc_batch)
qc_batch_colors <- c("darkgoldenrod3", "firebrick3", "deepskyblue3", "chartreuse3")
qc_batch_symbols <- c(1, 15, 16, 0)
qc_batch_samples_colors <- sapply(qc_batch, function(x) { x <- qc_batch_colors[which(x==qc_batch_names)] } )



# ---------- Peak picking on QC samples ----------
# Find Peaks in grouped phenoData according to directory structure
xset <- xcmsSet(files=qc_files, method="centWave", BPPARAM=MulticoreParam(nSlaves),
		ppm=ppm, peakwidth=peakwidth, snthresh=snthresh, prefilter=prefilter,
		fitgauss=fitgauss, verbose.columns=verbose.columns)

# Normalize phenoData
phenodata_old <- xset@phenoData
phenodata_new <- xset@phenoData
phenodata_new[,1] <- as.factor(sapply(phenodata_new[,1], function(x) { gsub(".*_","",x); } ))
phenodata_new[,1] <- as.factor(sapply(phenodata_new[,1], function(x) { gsub("/","_",x); } ))
xset@phenoData <- phenodata_new

# Group peaks from different samples together
xset2 <- group(xset)

# Retention time correction
pdf(args[3], encoding="ISOLatin1", pointsize=10, width=8, height=8, family="Helvetica")
par(cex=0.8)
xset4 <- retcor(xset2, method="loess", family="gaussian", plottype="mdevden",
				missing=10, extra=1, span=2)
dev.off()

# Peak re-grouping
xset5 <- group(xset4, bw=10)

# QC plots
pdf(args[4], encoding="ISOLatin1", pointsize=10, width=5, height=5, family="Helvetica")
plotQC(xset5, what="mzdevtime")
dev.off()

pdf(args[5], encoding="ISOLatin1", pointsize=10, width=5, height=5, family="Helvetica")
par(cex.axis=0.6, mar=c(8,4,4,1))
plotQC(xset5, what="mzdevsample", sampColors=qc_batch_samples_colors)
title(main="Median m/z deviation")
dev.off()

pdf(args[6], encoding="ISOLatin1", pointsize=10, width=5, height=5, family="Helvetica")
par(cex.axis=0.6, mar=c(8,4,4,1))
plotQC(xset5, what="rtdevsample", sampColors=qc_batch_samples_colors)
title(main="Median RT deviation")
dev.off()

# QC peak list
xset_peaks <- peakTable(xset5)

# More meaningful rownames
rownames(xset_peaks) <- paste(pol, "_", rownames(xset_peaks), sep="")

# Log transformation of intensities
xset_peaks[,which(colnames(xset_peaks) %in% qc_names)] <- log(xset_peaks[,which(colnames(xset_peaks) %in% qc_names)])

# Return xcmsSet
qc_xset <- xset5
qc_list <- xset_peaks



# ---------- Export MAF ----------
# Get peaklist from xcmsSet
pl <- peakTable(qc_xset)
l <- nrow(pl)

# Log transformation of intensities
abundance <- log(pl[,c(qc_names)])

# These columns are defined by MetaboLights mzTab
maf <- apply(data.frame(database_identifier = character(l),
			chemical_formula = character(l),
			smiles = character(l),
			inchi = character(l),
			metabolite_identification = character(l),
			mass_to_charge = pl$mz,
			fragmentation = character(l),
			modifications = character(l),
			charge = character(l),
			retention_time = pl$rt,
			taxid = character(l),
			species = character(l),
			database = character(l),
			database_version = character(l),
			reliability = character(l),
			uri = character(l),
			search_engine = character(l),
			search_engine_score = character(l),
			smallmolecule_abundance_sub = character(l),
			smallmolecule_abundance_stdev_sub = character(l),
			smallmolecule_abundance_std_error_sub = character(l),
			abundance, stringsAsFactors=FALSE),
		 2, as.character)

# Export MAF
write.table(maf, file=args[2], row.names=FALSE, col.names=colnames(maf), quote=TRUE, sep="\t", na="\"\"")



# ---------- Perform Quality Control ----------
# Save chromatograms in list
xchroms <- list()
for (i in 1:length(qc_files)) {
	chroma <- xcmsRaw(qc_files[i])
	x <- chroma@scantime
	y <- log(chroma@tic)
	xchrom <- data.frame(x, y)
	colnames(xchrom) <- c("rt", "tic")
	xchroms[[i]] <- xchrom
}

# Plot chromatograms
pdf(args[7], encoding="ISOLatin1", pointsize=10, width=5, height=5, family="Helvetica")
ymax <- NULL
for (i in 1:length(qc_files)) ymax <- c(ymax, xchroms[[i]]$tic)
ymin <- floor(min(ymax))
ymax <- ceiling(max(ymax))
plot(0, 0, type="n", xlim=c(0,1200), ylim=c(ymin,ymax), main="Chromatograms of all MM8", xlab="RT [s]", ylab="log(into)")
for (i in 1:length(qc_files)) 
    lines(xchroms[[i]]$rt, xchroms[[i]]$tic, lwd=1, col=qc_batch_colors[which(qc_batch[i]==qc_batch_names)])
legend("topleft", bty="n", pt.cex=0.5, cex=0.7, y.intersp=0.7, text.width=0.5, pch=20, col=qc_batch_colors, legend=qc_batch_names)
dev.off()

# Prepare list for stacked plot
qc_stacked <- as.data.frame(qc_xset@peaks)
qc_stacked$batch <- sapply(qc_stacked[,"sample"], FUN = function(x) { x <- qc_batch[as.numeric(x)] } )
qc_stacked[,"sample"] <- sapply(qc_stacked[,"sample"], FUN = function(x) { x <- qc_names[as.numeric(x)] } )
qc_stacked$into <- log(qc_stacked$into)

# QC stacked plot
pdf(args[8], encoding="ISOLatin1", pointsize=10, width=5, height=5, family="Helvetica")
qc_stacked_samples_colors <- sapply(qc_stacked[,"batch"], function(x) { x <- qc_batch_colors[which(x==qc_batch_names)] } )
plot(qc_stacked[,c("rt","into")], pch=20, cex=0.4, xlab="RT [s]", ylab="log(into)", col=qc_stacked_samples_colors, main="QC plot")
legend("topleft", bty="n", pt.cex=0.5, cex=0.7, y.intersp=0.7, text.width=0.5, pch=20, col=qc_batch_colors, legend=qc_batch_names)
dev.off()

# Stacked QC plot
pdf(args[9], encoding="ISOLatin1", pointsize=10, width=5, height=5, family="Helvetica")
plot(0, 0, type="n", xlim=c(0,max(qc_stacked$rt)*4), ylim=c(min(qc_stacked$into),max(qc_stacked$into)),
	 xaxt="n", xlab="RT [s]", ylab="log(into)", main="Stacked QC plot")
abline(v=c(1200,2400,3600), col='grey')
for (i in qc_batch_names) {
	points(qc_stacked[qc_stacked$batch==i,"rt"]+max(qc_stacked$rt)*(which(qc_batch_names==i)-1), qc_stacked[qc_stacked$batch==i,"into"], pch=20, cex=0.4, col=qc_batch_colors[which(qc_batch_names==i)], xaxt="n")
}
ax <- axis(side=1, srt=-22.5, at=seq(from=0, to=1200*4, by=300), labels=rep("",17))
text(ax, par("usr")[3]-(par("usr")[4]-par("usr")[3])/16, labels=c(0,300,"",900, 0,300,"",900, 0,300,"",900, 0,"",600,"",1200), xpd=TRUE, cex=1)
dev.off()

# Stacked histogram of intensities
pdf(args[10], encoding="ISOLatin1", pointsize=10, width=5, height=5, family="Helvetica")
plot(density(qc_stacked[qc_stacked$batch=="winter","into"]), col=qc_batch_colors[which(qc_batch_names=="winter")], lwd=3, xlim=c(3,15), main="Density plot of log intensities", xlab="log(into)", ylab="Density")
lines(density(qc_stacked[qc_stacked$batch=="summer","into"]), col=qc_batch_colors[which(qc_batch_names=="summer")], lwd=3)
lines(density(qc_stacked[qc_stacked$batch=="autumn","into"]), col=qc_batch_colors[which(qc_batch_names=="autumn")], lwd=3)
lines(density(qc_stacked[qc_stacked$batch=="spring","into"]), col=qc_batch_colors[which(qc_batch_names=="spring")], lwd=3)
legend("topleft", bty="n", lwd=2, cex=0.7, y.intersp=0.7, text.width=0.5, col=qc_batch_colors, legend=qc_batch_names)
dev.off()

# Check whether MM8 compounds have been picked by XCMS
MM8 <- NULL
MM8 <- rbind(MM8, data.frame(compound="2-Phenylglycine",             rt=39,  mz=135.044))
MM8 <- rbind(MM8, data.frame(compound="Kinetin",                     rt=186, mz=216.088))
MM8 <- rbind(MM8, data.frame(compound="Rutin",                       rt=270, mz=611.161))
MM8 <- rbind(MM8, data.frame(compound="O-Methylsalicylic acid",      rt=270, mz=135.044))
MM8 <- rbind(MM8, data.frame(compound="Phlorizin dihydrate",         rt=321, mz=459.126))
MM8 <- rbind(MM8, data.frame(compound="N-(3-Indolyacetyl)-L-valine", rt=375, mz=275.139))
MM8 <- rbind(MM8, data.frame(compound="3-Indolylacetonitrile",       rt=390, mz=130.065))
MM8 <- rbind(MM8, data.frame(compound="Biochanin A",                 rt=534, mz=285.076))
MM8_rt_shift <- 4
MM8_mz_shift <- 0.1

qc_MM8 <- data.frame(matrix(nrow=length(qc_names), ncol=nrow(MM8)))
colnames(qc_MM8) <- MM8$compound
rownames(qc_MM8) <- qc_names

for (i in 1:nrow(MM8)) {
	qc_MM8[,i] <- as.numeric(qc_list[qc_list$rt>=MM8$rt[i]-MM8_rt_shift & qc_list$rt<=MM8$rt[i]+MM8_rt_shift & qc_list$mz>=MM8$mz[i]-MM8_mz_shift & qc_list$mz<=MM8$mz[i]+MM8_mz_shift, which(colnames(qc_list) %in% qc_names)])
}

# Calculate variation of MM8 compound intensities
MM8$median_into <- 0
for (i in 1:nrow(MM8)) MM8[i, "median_into"] <- median(qc_MM8[,i])

MM8$sd_into <- 0
for (i in 1:nrow(MM8)) MM8[i, "sd_into"] <- sd(qc_MM8[,i])

# Plot variation of MM8 compounds in the samples
pdf(args[11], encoding="ISOLatin1", pointsize=10, width=5, height=5, family="Helvetica")
par(mar=c(7,4,4,1))
boxplot(qc_MM8, main="Variation of MM8 compound intensities", xlab="", ylab="log(into)", names=NA)
text(1:ncol(qc_MM8), par("usr")[3]-(par("usr")[4]-par("usr")[3])/24, srt=-40, adj=c(0,1), labels=colnames(qc_MM8), xpd=TRUE, cex=0.8)
title(xlab="Compounds", line=6, cex.lab=1)
dev.off()

# Plot MM8 compounds in each sample
pdf(args[12], encoding="ISOLatin1", pointsize=10, width=20, height=10, family="Helvetica")
par(mfrow=c(2,4), cex=1.2)
rtwin <- 8
for (j in 1:nrow(MM8)) {
	ymax <- NULL
	for (i in 1:length(qc_files)) ymax <- c(ymax, xchroms[[i]][xchroms[[i]]$rt>=MM8[j,"rt"]-rtwin & xchroms[[i]]$rt<=MM8[j,"rt"]+rtwin,"tic"])
	ymin <- floor(min(ymax))
    ymax <- ceiling(max(ymax))
	plot(0, 0, xlim=c(MM8[j,"rt"]-rtwin,MM8[j,"rt"]+rtwin), ylim=c(ymin,ymax), main=paste(MM8[j,"compound"],sep=''), xlab="RT [s]", ylab="log(into)")
	for (i in 1:length(qc_files)) {
		if (i!=24)
		lines(xchroms[[i]]$rt, xchroms[[i]]$tic, lwd=2, col=qc_batch_samples_colors[i])
	}
}
dev.off()

# Basic PCA
pdf(args[13], encoding="ISOLatin1", pointsize=10, width=5, height=5, family="Helvetica")
pca_list <- qc_list[,which(colnames(qc_list) %in% qc_names)]
pca_list[is.na(pca_list)] <- 0
model_pca <- prcomp(x=pca_list, scale=TRUE)
plot(model_pca$x[,c(1:2)], type="n", main="PCA of QC matrix")
points(model_pca$x[,c(1:2)], pch=16, col=qc_batch_samples_colors, cex=1.1)
legend("topleft", bty="n", pch=16, col=qc_batch_colors, pt.cex=0.8, cex=0.8, y.intersp=0.7, text.width=0.5, legend=qc_batch_names)
dev.off()



# ---------- Save R environment ----------
save.image(file=args[14])

