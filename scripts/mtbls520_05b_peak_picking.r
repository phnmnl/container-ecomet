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
	print("Usage: $0 input.rdata export.maf output.rdata")
	quit(save="no", status=1, runLast=FALSE)
}

# Load R environment
load(file=args[1])
args <- commandArgs(trailingOnly=TRUE)

# Load libraries
library(xcms)            # Swiss army knife for metabolomics
library(multtest)        # For diffreport
library(CAMERA)          # Metabolite Profile Annotation
library(RColorBrewer)    # For colors



# ---------- Create features list ----------
# Find Peaks in grouped phenoData according to directory structure
xset <- xcmsSet(files=mzml_files, method="centWave", BPPARAM=MulticoreParam(nSlaves),
				ppm=ppm, peakwidth=peakwidth, snthresh=snthresh, prefilter=prefilter,
				fitgauss=fitgauss, verbose.columns=verbose.columns)

# Remove values outside of RT range
xset_peaks <- as.data.frame(xset@peaks)
xset@peaks <- as.matrix(xset_peaks[which(xset_peaks$rt>rt_range[1] & xset_peaks$rt<rt_range[2]), ])

# Transform intensities
xset@peaks[,7:8] <- log(xset@peaks[,7:8])

# Normalize filenames
phenodata_old <- xset@phenoData
phenodata_new <- xset@phenoData
phenodata_new[,1] <- as.factor(sapply(phenodata_new[,1], function(x) { gsub(".*_","",x); } ))
xset@phenoData <- phenodata_new

# Group peaks from different samples together
xset2 <- group(xset, mzwid=mzwidth, minfrac=minfrac, bw=bwindow)

# Filling in missing peaks
#xset3 <- fillPeaks(xset2, method="chrom", BPPARAM=MulticoreParam(nSlaves))
xset3 <- xset2

# Retention time correction
xset4 <- retcor(xset3, method="loess", family="gaussian", plottype="mdevden",
				missing=10, extra=1, span=2)

# Peak re-grouping
xset5 <- group(xset4, mzwid=mzwidth, minfrac=minfrac, bw=bwindow)

# Peak picking with CAMERA
xcam <- xsAnnotate(xset5, polarity=polarity)
xcam <- groupFWHM(xcam, perfwhm=0.6)
xcam <- findIsotopes(xcam, ppm=5, mzabs=0.005)
xcam <- groupCorr(xcam, calcIso=TRUE, calcCiS=TRUE, calcCaS=TRUE, graphMethod="lpc", pval=0.05, cor_eic_th=0.75)
xcam <- findAdducts(xcam, polarity=polarity)

# Return xcmsSet and CAMERA objects
peak_xset <- xset2
peak_xcam <- xcam



# ---------- Export ReducedPeaklist used for statistics as MAF ----------
# Export ReducedPeaklist used for statistics as MAF
xcam_report <- getReducedPeaklist(xcam, method="median", default.adduct.info="first", cleanup=FALSE)
l <- nrow(xcam_report)

# These columns are defined by MetaboLights mzTab
maf <- apply(data.frame(database_identifier = character(l),
                        chemical_formula = character(l),
                        smiles = character(l),
                        inchi = character(l),
                        metabolite_identification = character(l),
                        mass_to_charge = xcam_report$mz,
                        fragmentation = character(l),
                        modifications = character(l),
                        charge = character(l),
                        retention_time = xcam_report$rt,
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
                        xcam_report,
                        stringsAsFactors=FALSE),
              2, as.character)

# Export MAF
write.table(maf, file=args[2], row.names=FALSE, col.names=colnames(maf), quote=TRUE, sep="\t", na="\"\"")

# Return variables (cols: features, rows: samples)
peak_maf <- maf



# ---------- Preprocess binary features list ----------
# Get Reduced Peaklist
xcam_report <- getReducedPeaklist(peak_xcam, method="median", default.adduct.info="first", cleanup=FALSE)
#xcam_report <- peak_maf

# Diff report
diff_list <- xcam_report
diff_list <- diff_list[order(diff_list$pcgroup, decreasing=FALSE),]
diff_list$pcgroup <- paste(pol, "_", diff_list$pcgroup, sep="")

# Create peak list
peak_list <- xcam_report
peak_list <- peak_list[order(peak_list$pcgroup, decreasing=FALSE),]
pcgroup <- peak_list$pcgroup
peak_list <- peak_list[, which(colnames(peak_list) == mzml_names[1]) : which(colnames(peak_list) == mzml_names[length(mzml_names)])]

# Create single 0/1 matrix
bina_list <- peak_list
bina_list[is.na(bina_list)] <- 0
bina_list[bina_list != 0] <- 1
rownames(bina_list) <- paste(pol, "_", unique(pcgroup), sep="")

# Only unique compounds in one group and not the others
uniq_list <- apply(X=bina_list, MARGIN=1,
		   FUN=function(x) { if (length(unique(species[grepl("1", x)])) == 1) x else rep(0, length(x)) } )
uniq_list <- t(uniq_list)
colnames(uniq_list) <- colnames(bina_list)

# Return global variables (cols: features, rows: samples)
bina_list <- t(bina_list)
uniq_list <- t(uniq_list)



# ---------- Preprocess features list ----------
# Get Reduced Peaklist
xcam_report <- getReducedPeaklist(peak_xcam, method="median", default.adduct.info="first", cleanup=TRUE)
#xcam_report <- peak_maf

# Diff report
diff_list <- xcam_report
diff_list <- diff_list[order(diff_list$pcgroup, decreasing=FALSE),]
diff_list$pcgroup <- paste(pol, "_", diff_list$pcgroup, sep="")

# Create feature list (with filled peaks)
peak_list <- xcam_report
peak_list <- peak_list[order(peak_list$pcgroup, decreasing=FALSE),]
pcgroup <- peak_list$pcgroup
peak_list <- peak_list[, which(colnames(peak_list) == mzml_names[1]) : which(colnames(peak_list) == mzml_names[length(mzml_names)])]

feat_list <- peak_list
rownames(feat_list) <- paste(pol, "_", unique(pcgroup), sep="")

# Cleanup values in peak list: Remove NAs, negative abundances, constant features (rows)
feat_list[is.na(feat_list)] <- 0
feat_list[feat_list < 0] <- 0
feat_list <- feat_list[!apply(feat_list, MARGIN=1, function(x) max(x,na.rm=TRUE) == min(x,na.rm=TRUE)),]

# Return variables (cols: features, rows: samples)
diff_list <- t(diff_list)
peak_list <- t(peak_list)
feat_list <- t(feat_list)



# ---------- Save R environment ----------
save.image(file=args[3])

