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
	print("Usage: $0 input.rdata moss_phylo.tre procrustes.pdf phylogeny.pdf")
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
library(phangorn)



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

# pos-mode: Manually rotate "Polstr" + "Plaund" branches
if (polarity == "positive") {
	feat_oclust <- reorder(feat_oclust, c(1, 2, 4, 5, 3, 9, 6, 8, 7))
}
# neg-mode: Manually rotate branches
if (polarity == "negative") {
	feat_oclust <- reorder(feat_oclust, c(1, 2, 3, 6, 4, 8, 7, 5, 9))
}


# Procrustes analysis
model_procrust <- protest(X=phylo_dist, Y=feat_dist, permutations=10000)

pdf(file=args[3], encoding="ISOLatin1", pointsize=10, width=5, height=5, family="Helvetica")
plot(model_procrust)
dev.off()

# Mantel test
model_mantel <- mantel(xdis=phylo_dist, ydis=feat_dist, method="pearson", permutations=10000)

# Correlation tests
model_cor <- cor(phylo_dist, feat_dist, method="pearson")
model_cop <- cor_cophenetic(hclust(phylo_dist), hclust(feat_dist), method="pearson")

# Robinson-Foulds metric
RF.dist(phylo_tree, as.phylo(feat_oclust), normalize=TRUE, check.labels=TRUE, rooted=TRUE)


# Plot phylogenetic tree
pdf(args[4], encoding="ISOLatin1", pointsize=12, width=8, height=5, family="Helvetica")
par(mfrow=c(1,2), mar=c(1,1,2,1), cex=1.0)
plot(phylo_tree, type="phylogram", direction="rightwards", x.lim=c(0,11), label.offset=0.4, use.edge.length=TRUE, show.tip.label=TRUE, tip.color=species_colors[phylo_index], font=2, main="")
mtext(text="(a)", adj=0, line=0.5, font=2, cex=1.2)
plot(as.phylo(feat_oclust), type="phylogram", direction="leftwards", x.lim=c(0,0.5), label.offset=0.01, use.edge.length=TRUE, show.tip.label=TRUE, tip.color=species_colors[phylo_index], font=2, main="")
mtext(text="(b)", adj=0, line=0.5, font=2, cex=1.2)
dev.off()


# r = Mantel
print(paste("Mantel statistic:", round(model_mantel$statistic,3)))

# c = cor_cophenetic
print(paste("Correlation:", round(model_cop,3)))

# rf = Robinson-Foulds
print(paste("Robinson-Foulds metric:", round(RF.dist(phylo_tree, as.phylo(feat_oclust), normalize=TRUE, check.labels=TRUE, rooted=TRUE), 3)))


