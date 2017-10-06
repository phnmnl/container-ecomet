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
	print("Usage: $0 input.rdata moss_phylo.tre plot.pdf")
	quit(save="no", status=1, runLast=FALSE)
}

# Load R environment
load(file=args[1])
args <- commandArgs(trailingOnly=TRUE)

# Load libraries
library(vegan)
library(ape)
library(pvclust)
library(dendextend)
library(cba)



# ---------- Phylogeny ----------
# Read phylogenetic tree
phylo_tree <- read.tree(args[2])

# Replace names with species codes
phylo_index <- match(substr(phylo_tree$tip.label,1,3), as.character(lapply(X=species_names, FUN=function(x) { x <- substr(x,1,3) })))
phylo_tree$tip.label <- as.character(species_names[phylo_index])

# Cophenetic distance matrix, needed for mpd and mntd calculations below
phylo_dist <- cophenetic.phylo(phylo_tree)

# Distance matrix of phylogenetic tree using Bray-Curtis
phylo_dist <- vegdist(phylo_dist, method="bray")

# Hierarchical clustering
phylo_hclust <- hclust(phylo_dist, method="complete")


# Merge feat_list for species from samples
feat_list_species <- NULL
for (i in species_names) feat_list_species <- rbind(feat_list_species, apply(X=feat_list[species==i,], MARGIN=2, FUN=function(x) { median(x) } ))
rownames(feat_list_species) <- species_names

# Reorder rows according to phylogenetic tree order
feat_list_species <- feat_list_species[phylo_index,]

# Distance matrix of feat_list using Bray-Curtis
feat_dist <- vegdist(feat_list_species, method="bray")

# Hierarchical clustering
feat_hclust <- hclust(feat_dist, method="complete")

# Optimal order
feat_opti <- order.optimal(feat_dist, feat_hclust$merge)
feat_oclust <- feat_hclust
feat_oclust$merge <- feat_opti$merge
feat_oclust$order <- feat_opti$order

# Does not allow custom distance matrix: Bootstrap PVClust
#model_pvclust <- pvclust(t(feat_list_species), method.hclust="complete", method.dist="correlation", parallel=TRUE)


# Procrustes analysis
#model_procrust <- protest(X=phylo_dist, Y=feat_dist, permutations=10000)
#plot(model_procrust)

# Mantel test
model_mantel <- mantel(xdis=phylo_dist, ydis=feat_dist, method="pearson", permutations=10000)

# Correlation tests
model_cor <- cor(phylo_dist, feat_dist, method="pearson")
model_cop <- cor_cophenetic(hclust(phylo_dist), hclust(feat_dist), method="spearman")


# Plot phylogenetic tree
pdf(file=args[3], encoding="ISOLatin1", pointsize=10, width=5, height=5, family="Helvetica")
par(mfrow=c(2,1), cex=0.8)
plot(phylo_tree, direction="downwards", mar=c(0,0,0,0), main="phylogenetic tree")
#plot(phylo_hclust, mar=c(0,0,0,0), main="phylogenetic tree")
plot(feat_oclust, hang=-1, mar=c(0,0,0,0), main=paste("feat_list tree (r=",round(model_mantel$statistic,2),", p=",round(model_mantel$signif,2),", c=",round(model_cop,2),")",sep=""))
#plot(model_pvclust, main=paste("feat_list tree (r=",round(model_mantel$statistic,2),", p=",round(model_mantel$signif,2),", c=",round(model_cop,2),")",sep=""))
dev.off()



