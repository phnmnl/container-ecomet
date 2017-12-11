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
	print("Usage: $0 input.rdata plot.pdf")
	quit(save="no", status=1, runLast=FALSE)
}

# Load R environment
load(file=args[1])
args <- commandArgs(trailingOnly=TRUE)
library(vegan)



# ---------- Determine traits that explain most of the variance ----------
# Variance partitioning (result depending on curtis distance)
pdf(file=args[2], encoding="ISOLatin1", pointsize=10, width=6, height=4, family="Helvetica")

model_vp <- varpart(feat_list, ~ traits$Season, ~ traits$Code)
plot(model_vp, Xnames=c("seasons","species"), cutoff=0, cex=1.2, id.size=1.2, digits=1, bg=c("darkgreen","darkblue"))

dev.off()



