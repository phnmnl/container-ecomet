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
	print("Usage: $0 input.rdata splsda_model.csv splsda.pdf splsda_valid.pdf")
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
library(mixOmics)



# ---------- Analyse the "top 8" traits ----------
# Test all factors for their explained variation
model_splsda_factors <- data.frame(X=rep(0,ncol(charist)), Y=rep(0,ncol(charist)), Z=rep(0,ncol(charist)))
rownames(model_splsda_factors) <- colnames(charist)
for (i in 1:ncol(charist)) {
	model_splsda <- splsda(X=feat_list, Y=charist[,i], multilevel=seasons, ncomp=2, mode="regression", keepX=TRUE, scale=TRUE)
	model_splsda_factors[i,1] <- model_splsda$explained_variance$X[1]
	model_splsda_factors[i,2] <- model_splsda$explained_variance$X[2]
}
model_splsda_factors$Z <- model_splsda_factors$X + model_splsda_factors$Y
model_splsda_factors <- model_splsda_factors[order(model_splsda_factors$Z, decreasing=TRUE),]
model_splsda_factors
write.csv(model_splsda_factors, file=args[2], row.names=TRUE)

# Plot 8 most relevant non-collinear SPLS-DA models
pdf(args[3], encoding="ISOLatin1", pointsize=10, width=5*2, height=5*4, family="Helvetica")
par(mfrow=c(4,2), cex=0.8)
for (i in c("Mean.spore.size","SubstrateSoil, Loose rocks","Reaction.index","Growth.formMat","Life.strategycolonist","Habitat.typeWoods, Shrubs","Light.index","Sexual.reproduction.frequencycommon")) {
	model_splsda <- splsda(X=feat_list, Y=charist[,i], multilevel=seasons, ncomp=2, mode="canonical", keepX=TRUE, scale=TRUE)
	
	#plotIndiv(model_splsda, ind.names=TRUE, ellipse=FALSE, legend=TRUE)
	plot(model_splsda$variates$X, pch=seasons_samples_symbols, col=species_samples_colors, cex=0.9,
		 main=as.character(i),
		 xlab=paste("X-variate 1 (",round(model_splsda$explained_variance$X[1]*100,2),"%)",sep=''),
		 ylab=paste("X-variate 2 (",round(model_splsda$explained_variance$X[2]*100,2),"%)",sep=''))
}
dev.off()

# Validate 8 most relevant non-collinear SPLS-DA models
pdf(args[4], encoding="ISOLatin1", pointsize=10, width=5*2, height=5*4, family="Helvetica")
par(mfrow=c(4,2), cex=0.8)
for (i in c("Mean.spore.size","SubstrateSoil, Loose rocks","Reaction.index","Growth.formMat","Life.strategycolonist","Habitat.typeWoods, Shrubs","Light.index","Sexual.reproduction.frequencycommon")) {
	model_splsda <- splsda(X=feat_list, Y=charist[,i], multilevel=seasons, ncomp=2, mode="canonical", keepX=TRUE, scale=TRUE)
	valid_splsda <- perf(object=model_splsda, nrepeat=1, validation="loo", auc=TRUE, cpus=nSlaves, progressBar=FALSE)
	
	#auroc_splsda <- auroc(object=model_splsda, ncomp=2, plot=FALSE)
	#plot(valid_splsda$auc.all)
	auroc_splsda <- cbind(matrix(valid_splsda$auc.all$`comp 1`$nrep.1, ncol=2), matrix(valid_splsda$auc.all$`comp 1`$nrep.1, ncol=2))
	colnames(auroc_splsda) <- c("1","p.value","2","p.value")
	bp <- barplot(c(auroc_splsda[,1],auroc_splsda[,3]), names.arg=FALSE, ylim=c(0,1), main=as.character(i), xlab="Levels of Components", ylab="Area Under Curve")
	text(as.numeric(bp), c(auroc_splsda[,1],auroc_splsda[,3]), adj=0, pos=3, xpd=TRUE, cex=0.8, labels=round(c(auroc_splsda[,1],auroc_splsda[,3]),3))
}
dev.off()


