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
	print("Usage: $0 input.rdata rda_envfit.csv plot.pdf")
	quit(save="no", status=1, runLast=FALSE)
}

# Load R environment
load(file=args[1])
args <- commandArgs(trailingOnly=TRUE)

# Load libraries
# ERROR: vegan conflicts with mda and klaR, unload packages before using any of the analyses !!!
if ("package:mda" %in% search()) detach(package:mda, unload=TRUE)
if ("package:klaR" %in% search()) detach(package:klaR, unload=TRUE)
library(RColorBrewer)
library(vegan)



# ---------- Redundancy Analysis for Species ----------
# Perform RDA
model_rda <- rda(X=feat_list, Y=as.matrix(charist[,c(5:58)]), scale=TRUE, na.action=na.exclude)
model_rda_ef <- capture.output(envfit(model_rda, as.matrix(charist[,c(5:58)]), perm=10000))
write.csv(model_rda_ef, file=args[2], row.names=TRUE)

# Constrained RDA for plotting
rda_factors <- as.matrix(charist[,c("Mean.spore.size","SubstrateSoil, Loose rocks","Reaction.index","Growth.formDendroid","Life.strategycolonist","Habitat.typeWoods, Shrubs","Sexual.reproduction.frequencycommon")])
model_rda <- rda(X=feat_list, Y=rda_factors, scale=TRUE, na.action=na.exclude)
model_rda_constraints <- summary(model_rda)$constr.chi / summary(model_rda)$tot.chi
model_rda_scores <- scores(model_rda)
model_rda_ef <- envfit(model_rda, rda_factors, perm=10000)
model_rda_ef

# Plot results
pdf(file=args[3], encoding="ISOLatin1", pointsize=10, width=5, height=5, family="Helvetica")
plot(0, 0, xlim=c(min(model_rda_scores$sites[,1])-1, max(model_rda_scores$sites[,1])+1),
     ylim=c(min(model_rda_scores$sites[,2]), max(model_rda_scores$sites[,2])),
     xlab="RDA1", ylab="RDA2",
     main=paste("RDA: Species"," (explained variance = ",round(model_rda_constraints,2),")",sep=''), type="n")
points(model_rda, display="sites", pch=16, col=species_samples_colors)
plot(model_rda_ef, cex=0.6, p.max=1, col="black")
legend("topleft", bty="n", pch=16, col=species_colors, pt.cex=0.8, cex=0.8, y.intersp=0.7, text.width=0.5, legend=sort(unique(species)))
dev.off()


