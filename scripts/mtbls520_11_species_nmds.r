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
	print("Usage: $0 input.rdata stress.pdf procrustes.pdf nmds.pdf")
	quit(save="no", status=1, runLast=FALSE)
}

# Load R environment
load(file=args[1])
args <- commandArgs(trailingOnly=TRUE)
library(vegan)



# ---------- Plot species vs. features ----------
# Check highest rank correlations for distance function
model_ri <- rankindex(veg=feat_list, grad=charist[,c(50:58)], method="pearson")
print(paste("Recommended distance function: ",names(model_ri[which(model_ri==max(model_ri))]),sep=''))

# NMDS
model_nmds <- metaMDS(feat_list, wascores=TRUE, k=3, distance="bray")

nmds_scores_sites <- scores(model_nmds, display="sites", choices=1:2) 
nmds_scores_species <- scores(model_nmds, display="species", choices=1:2)

# Goodness of Fit and Shepard Plot for Nonmetric Multidimensional Scaling
pdf(args[2], encoding="ISOLatin1", pointsize=10, width=10, height=6, family="Helvetica")
stressplot(model_nmds, main="Stress plot")
dev.off()

# Procrustes analysis
# Aim: test the significance of factors "dissimilarity" between two data sets
# The longer the arrows the higher the dissimilarity
model_procrust <- protest(X=model_nmds, Y=charist[,c(50:58)], scale=FALSE, symmetric=FALSE, permutations=10000)

pdf(args[3], encoding="ISOLatin1", pointsize=10, width=10, height=6, family="Helvetica")
plot(model_procrust, kind=0, main=paste("Procrustes errors for species (correlation=",round(model_procrust$t0,4),")",sep=''),
	 xlab=paste("Dimension 1 (",round(model_procrust$svd$d[1]*100,2),"%)",sep=''),
	 ylab=paste("Dimension 2 (",round(model_procrust$svd$d[2]*100,2),"%)",sep=''))
points(model_procrust$X[,c(1,2)], pch=16, col=species_samples_colors, cex=1.4)
points(model_procrust$Yrot[,c(1,2)], pch=15, col=species_samples_colors, cex=1.4)
arrows(model_procrust$Yrot[,1], model_procrust$Yrot[,2], model_procrust$X[,1], model_procrust$X[,2], col=species_samples_colors, lwd=1, length=0.1)
dev.off()

# Plot NMDS
pdf(file=args[4], encoding="ISOLatin1", pointsize=10, width=10, height=6, family="Helvetica")
ordiplot(model_nmds, type="n")
mtext(side=3, line=2, "meta NMDS", cex=1, font=2)
points(nmds_scores_species, pch=16, col="gray", cex=0.3)
points(nmds_scores_sites, pch=seasons_samples_symbols, col=species_samples_colors, cex=0.9)
#text(nmds_scores_sites, labels=species, col=species_samples_colors, cex=0.6)
legend("topleft", bty="n", legend=c(as.character(seasons_names), as.character(species_names)),
	   pch=c(seasons_symbols, rep(20,length(species_names))),
	   col=c(rep("black",length(seasons_names)), species_colors),
	   pt.cex=0.8, cex=0.8, y.intersp=0.7, text.width=0.5)
dev.off()


