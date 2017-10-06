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
if (length(args) < 4) {
	print("Error! No or not enough arguments given.")
	print("Usage: $0 input.rdata stress_plot.pdf procrustes_plot.pdf nmds_plot.pdf")
	quit(save="no", status=1, runLast=FALSE)
}

# Load R environment
load(file=args[1])
args <- commandArgs(trailingOnly=TRUE)

# Load libraries
if ("package:mda" %in% search()) detach(package:mda, unload=TRUE)
if ("package:klaR" %in% search()) detach(package:klaR, unload=TRUE)
library(RColorBrewer)
library(vegan)
library(Hmisc)
library(gplots)



# ---------- Plot seasons vs. features ----------
# NMDS
model_nmds <- metaMDS(feat_list, wascores=TRUE, k=3, distance="bray")
model_nmds_traits <- metaMDS(charist[,c(5:49)], wascores=TRUE, k=3, distance="bray")

nmds_scores_sites <- scores(model_nmds, display="sites", choices=1:2) 
nmds_scores_species <- scores(model_nmds, display="species", choices=1:2)

model_nmds_ef <- envfit(model_nmds, charist[,c(5:49)], permu=10000)
model_nmds_ef

# Goodness of Fit and Shepard Plot for Nonmetric Multidimensional Scaling
pdf(file=args[2], encoding="ISOLatin1", pointsize=10, width=10, height=6, family="Helvetica")
stressplot(model_nmds)
dev.off()

# Procrustes analysis for both NMDS
# Aim: test the significance of factors "dissimilarity" between two data sets
# The longer the arrows the higher the dissimilarity
pdf(file=args[3], encoding="ISOLatin1", pointsize=10, width=10, height=6, family="Helvetica")
model_procrust <- protest(X=model_nmds, Y=model_nmds_traits, scale=TRUE, permutations=10000)
plot(model_procrust, kind=0)
points(model_procrust$X[,c(1,2)])
points(model_procrust$Yrot[,c(1,2)], col="red")
arrows(model_procrust$Yrot[,1], model_procrust$Yrot[,2], model_procrust$X[,1], model_procrust$X[,2], col="blue", lwd=0.5, length=0.1)
dev.off()

# Plot NMDS
pdf(file=args[4], encoding="ISOLatin1", pointsize=10, width=10, height=6, family="Helvetica")
ordiplot(model_nmds, type="n")
mtext(side=3, line=2, "meta NMDS", cex=1, font=2)
points(nmds_scores_species, pch=16, col="gray", cex=0.3)
points(nmds_scores_sites, pch=species_samples_symbols, col=seasons_samples_colors, cex=0.9)
#plot(model_nmds_ef, cex=0.5, p.max=1, col="black")
legend("topleft", bty="n", pt.cex=0.8, cex=0.8, y.intersp=0.7, text.width=0.5,
       pch=c(rep(16,4),species_symbols),
       col=c(seasons_colors,rep("black",length(species_names))),
       legend=c(as.character(seasons_names),as.character(species_names)))
dev.off()


