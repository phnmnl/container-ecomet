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
library(vegan)
library(multcomp)
library(Hmisc)



# ---------- Variability of species profiles in response to seasons ----------
# Variability of species profiles
model_corr <- data.frame()

# Calculate Pearson's r correlation coefficients for the species profiles
for (i in levels(species)) {
	cr <- rcorr(t(bina_list[which(species==i),]), type="pearson")
	cc <- cr$r[upper.tri(cr$r, diag=FALSE)]
	cc <- log(1 + cc)
	model_corr <- rbind(model_corr, cc)
}

rownames(model_corr) <- species_names
colnames(model_corr) <- as.character(c(1:ncol(model_corr)))

model_corr <- data.frame(corr=as.numeric(t(model_corr)), species=as.character(rep(species_names,each=ncol(model_corr))))

# Show histogram
pdf(file=args[2], encoding="ISOLatin1", pointsize=10, width=5, height=5, family="Helvetica")
hist(model_corr$corr)
dev.off()

# Tukey test
model_anova <- aov(corr ~ species, data=model_corr)
model_mc <- multcomp::glht(model_anova, multcomp::mcp(species="Tukey"))
model_cld <- multcomp::cld(summary(model_mc), decreasing=TRUE, level=0.05)
model_tukey <- data.frame("tukey_groups"=model_cld$mcletters$Letters)

# Boxplot
pdf(file=args[3], encoding="ISOLatin1", pointsize=10, width=5, height=5, family="Helvetica")
boxplot(model_corr$corr ~ model_corr$species, col=species_colors, names=NA, main="Species variability", xlab="Species", ylab="Pearson's r correlation coefficients")
text(1:length(species_names), par("usr")[3]-(par("usr")[4]-par("usr")[3])/14, srt=-22.5, adj=0.5, labels=species_names, xpd=TRUE, cex=0.9)
text(1:length(species_names), par("usr")[4]+(par("usr")[4]-par("usr")[3])/40, adj=0.5, labels=model_tukey[,1], xpd=TRUE, cex=0.8)
dev.off()


