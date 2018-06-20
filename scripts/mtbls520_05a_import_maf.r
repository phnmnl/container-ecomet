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
	print("Usage: $0 input.rdata import.maf output.rdata")
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



# ---------- Import ReducedPeaklist used for statistics as MAF ----------
# Import ReducedPeaklist used for statistics as MAF
peak_maf <- read.table(file=args[2], header=TRUE, quote="\"", sep="\t")



# ---------- Preprocess binary features list ----------
# Get Reduced Peaklist
#xcam_report <- getReducedPeaklist(peak_xcam, method="median", default.adduct.info="first", cleanup=FALSE)
xcam_report <- peak_maf

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
sclass <- species
if (all(as.character(sclass) == as.character(species))) { #species
	uniq_list <- apply(X=bina_list, MARGIN=1,
					   FUN=function(x) { if (length(unique(species[grepl("1", x)])) == 1) x else rep(0, length(x)) } )
} else { #seasons
	uniq_list <- apply(X=bina_list, MARGIN=1,
					   FUN=function(x) { if (length(unique(seasons[grepl("1", x)])) == 1) x else rep(0, length(x)) } )
}
uniq_list <- t(uniq_list)
colnames(uniq_list) <- colnames(bina_list)

# Return global variables (cols: features, rows: samples)
bina_list <- t(bina_list)
uniq_list <- t(uniq_list)



# ---------- Preprocess features list ----------
# Get Reduced Peaklist
#xcam_report <- getReducedPeaklist(peak_xcam, method="median", default.adduct.info="first", cleanup=TRUE)
xcam_report <- peak_maf

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

