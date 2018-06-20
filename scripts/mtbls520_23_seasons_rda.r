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
	print("Usage: $0 input.rdata dbrda_envfit.csv plot.pdf")
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



# ---------- Constrained distance-based Redundancy Analysis for Seasons ----------
# Constrained dbRDA
charact <- as.data.frame(charist[,c(59:62)])
model_cap <- capscale(formula=feat_list ~ ., data=charact, distance="bray")
model_cap_ef <- envfit(ord=model_cap, env=charact, perm=10000)
model_cap_constraints <- summary(model_cap)$constr.chi / summary(model_cap)$tot.chi
model_cap_scores <- scores(model_cap)

# Goodness of fit statistic: Squared correlation coefficient
model_fit <- data.frame(r2=c(model_cap_ef$vectors$r,model_cap_ef$factors$r),
			pvals=c(model_cap_ef$vectors$pvals,model_cap_ef$factors$pvals) )
rownames(model_fit) <- c(names(model_cap_ef$vectors$r),names(model_cap_ef$factors$r))
write.csv(model_fit, file=args[2], row.names=TRUE)

# Plot results
pdf(file=args[3], encoding="ISOLatin1", pointsize=10, width=5, height=5, family="Helvetica")
plot(0, 0, xlim=c(min(model_cap_scores$sites[,2])-1, max(model_cap_scores$sites[,1])+1),
	 ylim=c(min(model_cap_scores$sites[,2]), max(model_cap_scores$sites[,2])),
	 xlab="CAP1", ylab="CAP2",
	 main=paste("Constrained dbRDA"," (explained variance = ",round(model_cap_constraints,3),")",sep=''), type="n")
points(model_cap, display="sites", pch=species_samples_symbols, col=seasons_samples_colors)
plot(model_cap_ef, cex=0.6, p.max=1, col="black")
legend("topleft", bty="n", pt.cex=0.8, cex=0.8, y.intersp=0.7, text.width=0.5,
	 pch=c(rep(16,4),species_symbols),
	 col=c(seasons_colors,rep("black",length(species_names))),
	 legend=c(as.character(seasons_names),as.character(species_names)))
dev.off()



