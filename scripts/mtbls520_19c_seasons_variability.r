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
	print("Usage: $0 input.rdata histogram.pdf plot.pdf")
	quit(save="no", status=1, runLast=FALSE)
}

# Load R environment
load(file=args[1])
args <- commandArgs(trailingOnly=TRUE)

# Load libraries
library(RColorBrewer)
library(vegan)
library(multcomp)
library(Hmisc)
library(gplots)



# ---------- Variability of profiles in the seasons ----------
# Variability of profiles in the seasons
model_corr <- data.frame()

# Calculate Pearson's r correlation coefficients for the profiles
for (i in levels(seasons)) {
	cr <- rcorr(t(bina_list[which(seasons==i),]), type="pearson")
	cc <- cr$r[upper.tri(cr$r, diag=FALSE)]
	cc <- log(1 + cc)
	model_corr <- rbind(model_corr, cc)
}

rownames(model_corr) <- seasons_names
colnames(model_corr) <- as.character(c(1:ncol(model_corr)))

model_corr <- data.frame(corr=as.numeric(t(model_corr)), seasons=as.character(rep(seasons_names,each=ncol(model_corr))))

# Show histogram
pdf(args[2], encoding="ISOLatin1", pointsize=10, width=5, height=5, family="Helvetica")
hist(model_corr$corr)
dev.off()

# Tukey test
model_anova <- aov(corr ~ seasons, data=model_corr)
model_mc <- multcomp::glht(model_anova, multcomp::mcp(seasons="Tukey"))
model_cld <- multcomp::cld(summary(model_mc), decreasing=TRUE, level=0.05)
model_tukey <- data.frame("tukey_groups"=model_cld$mcletters$Letters[match(seasons_names, names(model_cld$mcletters$Letters))])

# R-bug: prevent sorting when using formula
model_boxplot <- data.frame(summer=model_corr$corr[seasons=="summer"],
							autumn=model_corr$corr[seasons=="autumn"],
							winter=model_corr$corr[seasons=="winter"],
							spring=model_corr$corr[seasons=="spring"])
# Boxplot
pdf(args[3], encoding="ISOLatin1", pointsize=10, width=5, height=5, family="Helvetica")
boxplot(x=model_boxplot, col=seasons_colors, main="Seasons variability", xlab="Species", ylab="Pearson's r correlation coefficients")
#text(1:length(species_names), par("usr")[3]-(par("usr")[4]-par("usr")[3])/14, srt=-22.5, adj=0.5, labels=species_names, xpd=TRUE, cex=0.9)
text(1:length(species_names), par("usr")[4]+(par("usr")[4]-par("usr")[3])/40, adj=0.5, labels=model_tukey[,1], xpd=TRUE, cex=0.8)
dev.off()


