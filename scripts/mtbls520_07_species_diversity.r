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
	print("Usage: $0 input.rdata diversity.csv output.rdata")
	quit(save="no", status=1, runLast=FALSE)
}

# Load R environment
load(file=args[1])
args <- commandArgs(trailingOnly=TRUE)

# Load libraries
library(xcms)
library(vegan)
library(multcomp)               # For Tukey test
library(Hmisc)                  # For correlation test
library(VennDiagram)            # For Venn Diagrams

# These variables will be exported globally
model_div <- NULL



# ---------- Shannon Diversity ----------
shannon.diversity <- function(p) {
    # Based on Li et al. (2016)
    # Function is obsolete, as it returns same values than vegan::diversity(x, index="shannon")
    # Since we do not expect features with negative intensity,
    # we exclude negative values and take the natural logarithm
    if (min(p) < 0 || sum(p) <= 0) 
        return(NA)
    pij <- p[p>0] / sum(p) 
    -sum(pij * log(pij)) 
}



# ---------- Tukey-Test ----------
tukey.test <- function(model) {
    div_anova <- aov(model)
    div_mc <- multcomp::glht(div_anova, multcomp::mcp(species="Tukey"))
    div_cld <- multcomp::cld(summary(div_mc), decreasing=TRUE, level=0.05)
    div_tukey <- data.frame("tukey_groups"=div_cld$mcletters$Letters)
    return(div_tukey)
}



# ---------- Tukey-Test ----------
seasons.tukey.test <- function(model) {
    div_anova <- aov(model)
    div_mc <- multcomp::glht(div_anova, multcomp::mcp(seasons="Tukey"))
    div_cld <- multcomp::cld(summary(div_mc), decreasing=TRUE, level=0.05)
    div_tukey <- data.frame("tukey_groups"=div_cld$mcletters$Letters[match(seasons_names, names(div_cld$mcletters$Letters))])
    return(div_tukey)
}



# ---------- Create diversity data frame ----------
# Create data frame
model_div               <- data.frame(features=apply(X=bina_list, MARGIN=1, FUN=function(x) { sum(x) } ))
model_div$unique        <- apply(X=uniq_list, MARGIN=1, FUN=function(x) { sum(x) } )
model_div$diversity     <- apply(X=uniq_list, MARGIN=1, FUN=function(x) { shannon.diversity(x) })
model_div$shannon       <- apply(X=bina_list, MARGIN=1, FUN=function(x) { vegan::diversity(x, index="shannon") })
model_div$simpson       <- apply(X=bina_list, MARGIN=1, FUN=function(x) { vegan::diversity(x, index="simpson") })
model_div$inverse       <- apply(X=bina_list, MARGIN=1, FUN=function(x) { vegan::diversity(x, index="inv") })
model_div$fisher        <- apply(X=bina_list, MARGIN=1, FUN=function(x) { fisher.alpha(x) })
model_div$concentration <- apply(X=as.data.frame(seq(1,length(mzml_files))), MARGIN=1, FUN=function(x) { x <- sum(xchroms[[x]]$int) } )

# Remove NAs if present
model_div[is.na(model_div)] <- 0

# Write csv with results
write.csv(model_div, file=args[2], row.names=TRUE)



# ---------- Save R environment ----------
save.image(file=args[3])

