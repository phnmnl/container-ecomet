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



# ---------- Plot total features ----------
pdf(file=args[2], encoding="ISOLatin1", pointsize=10, width=5, height=5, family="Helvetica")
boxplot(model_div$features ~ species, col=species_colors, names=NA, main="Number of features", xlab="Species", ylab="number of features")
text(1:length(species_names), par("usr")[3]-(par("usr")[4]-par("usr")[3])/14, srt=-22.5, adj=0.5, labels=species_names, xpd=TRUE, cex=0.9)
div_tukey <- tukey.test(model = model_div$features ~ species)
text(1:length(species_names), par("usr")[4]+(par("usr")[4]-par("usr")[3])/40, adj=0.5, labels=div_tukey[,1], xpd=TRUE, cex=0.8)
dev.off()


