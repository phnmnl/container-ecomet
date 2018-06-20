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
	print("Usage: $0 input.rdata dbrda_envfit.csv plot.pdf")
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



# ---------- Distance-based Redundancy Analysis for Species ----------
# Choose a model by permutation tests in constrained ordination
# Example without scope.
charact <- as.data.frame(charist[,c(18:23,35:38,39:45,46:50,51,52:54,30:34,55:58)])
model_0 <- capscale(formula=feat_list ~ 1, comm=feat_list, data=charact, distance="bray", metaMDSdist=TRUE)    # Model with intercept only
model_1 <- capscale(formula=feat_list ~ ., comm=feaT_list, data=charact, distance="bray", metaMDSdist=TRUE)    # Model with all explanatory variables
model_step <- ordistep(object=model_0, scope=formula(model_1), direction="both", perm.max=200)
model_step_scores <- scores(model_step)
model_step_constraints <- summary(model_step)$constr.chi / summary(model_step)$tot.chi

# Ordistepped dbRDA
model_cap <- capscale(formula=as.formula(model_step$terms), data=charact, distance="bray", metaMDSdist=TRUE)
ef_formula <- update(as.formula(model_step$terms), model_cap ~ .)
ef_factors <- as.factor(sapply(strsplit(as.character(ef_formula)[[3]], "\\+"), function(x) { x <- gsub("(\\`|^ | $)","",x) }))
model_cap_ef <- envfit(formula=ef_formula, data=charact, perm=10000)
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
	 main=paste("dbRDA: Characteristics"," (explained variance = ",round(model_cap_constraints,3),")",sep=''), type="n")
points(model_cap, display="sites", pch=16, col=species_samples_colors)
plot(model_cap_ef, cex=0.6, p.max=1, col="black")
legend("topleft", bty="n", pch=16, col=species_colors, pt.cex=0.8, cex=0.8, y.intersp=0.7, text.width=0.5, legend=sort(unique(species)))
dev.off()



