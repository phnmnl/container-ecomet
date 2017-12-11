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
if (length(args) < 12) {
	print("Error! No or not enough arguments given.")
	print("Usage: $0 input.rdata Brarut.pdf Calcus.pdf Fistax.pdf Gripul.pdf Hypcup.pdf Marpol.pdf Plaund.pdf Polstr.pdf Rhysqu.pdf pleuro.pdf acro.pdf")
	quit(save="no", status=1, runLast=FALSE)
}

# Load R environment
load(file=args[1])
args <- commandArgs(trailingOnly=TRUE)
argc <- 1
library(vegan)
library(multcomp)
library(Hmisc)
library(VennDiagram)



# ---------- Venn Diagrams for seasonal variability ----------
species_names_long <- c("Brachythecium rutabulum", "Calliergonella cuspidata",
						"Fissidens taxifolius", "Grimmia pulvinata",
						"Hypnum cupressiforme", "Marchantia polymorpha",
						"Plagiomnium undulatum", "Polytrichum strictum",
						"Rhytidiadelphus squarrosus")

for (i in species_names) {
	# Create list with unique features
	seasons_venn <- list(summer=colnames(bina_list)[which(apply(X=bina_list[which(seasons=="summer" & species==i),], MARGIN=2, FUN=function(x) { if (sum(x)>=2) x<-1 else x<-0 })==1)],
						 autumn=colnames(bina_list)[which(apply(X=bina_list[which(seasons=="autumn" & species==i),], MARGIN=2, FUN=function(x) { if (sum(x)>=2) x<-1 else x<-0 })==1)],
						 winter=colnames(bina_list)[which(apply(X=bina_list[which(seasons=="winter" & species==i),], MARGIN=2, FUN=function(x) { if (sum(x)>=2) x<-1 else x<-0 })==1)],
						 spring=colnames(bina_list)[which(apply(X=bina_list[which(seasons=="spring" & species==i),], MARGIN=2, FUN=function(x) { if (sum(x)>=2) x<-1 else x<-0 })==1)] )
	
	# Plot Venn Diagram
	model_venn <- venn.diagram(x=seasons_venn, filename=NULL, col="transparent", fill=seasons_colors,
							   alpha=0.5, cex=1.0, cat.cex=1.0, cat.pos=0.1, cat.dist=c(0.1,0.1,0.04,0.03),
							   cat.fontface="bold", rotation.degree=0, margin=c(0,0,0,0),
							   cat.fontfamily="Helvetica", fontfamily="Helvetica")
	argc <- argc + 1
	pdf(args[argc], encoding="ISOLatin1", pointsize=10, width=5, height=5, family="Helvetica")
	plot.new()
	grid.draw(model_venn)
	mtext(text=species_names_long[which(species_names==i)], adj=0.5, line=2, font=3, cex=1.2)
	dev.off()
}

# Create list for all pleurocarps
seasons_venn <- list(summer=colnames(bina_list)[which(apply(X=bina_list[which(seasons=="summer" & (species=="Brarut" | species=="Calcus" | species=="Hypcup" | species=="Rhysqu")),], MARGIN=2, FUN=function(x) { if (sum(x)>=2) x<-1 else x<-0 })==1)],
					 autumn=colnames(bina_list)[which(apply(X=bina_list[which(seasons=="autumn" & (species=="Brarut" | species=="Calcus" | species=="Hypcup" | species=="Rhysqu")),], MARGIN=2, FUN=function(x) { if (sum(x)>=2) x<-1 else x<-0 })==1)],
					 winter=colnames(bina_list)[which(apply(X=bina_list[which(seasons=="winter" & (species=="Brarut" | species=="Calcus" | species=="Hypcup" | species=="Rhysqu")),], MARGIN=2, FUN=function(x) { if (sum(x)>=2) x<-1 else x<-0 })==1)],
					 spring=colnames(bina_list)[which(apply(X=bina_list[which(seasons=="spring" & (species=="Brarut" | species=="Calcus" | species=="Hypcup" | species=="Rhysqu")),], MARGIN=2, FUN=function(x) { if (sum(x)>=2) x<-1 else x<-0 })==1)] )

# Plot Venn Diagram
model_venn <- venn.diagram(x=seasons_venn, filename=NULL, col="transparent", fill=seasons_colors,
						   alpha=0.5, cex=1.0, cat.cex=1.0, cat.pos=0.1, cat.dist=c(0.1,0.1,0.04,0.03),
						   cat.fontface="bold", rotation.degree=0, margin=c(0,0,0,0),
						   cat.fontfamily="Helvetica", fontfamily="Helvetica")
argc <- argc + 1
pdf(args[argc], encoding="ISOLatin1", pointsize=10, width=5, height=5, family="Helvetica")
plot.new()
grid.draw(model_venn)
mtext(text="Pleurocarpic species", adj=0.5, line=2, font=3, cex=1.2)
dev.off()

# Create list for all acrocarps
seasons_venn <- list(summer=colnames(bina_list)[which(apply(X=bina_list[which(seasons=="summer" & (species=="Fistax" | species=="Gripul" | species=="Plaund" | species=="Polstr")),], MARGIN=2, FUN=function(x) { if (sum(x)>=2) x<-1 else x<-0 })==1)],
					 autumn=colnames(bina_list)[which(apply(X=bina_list[which(seasons=="autumn" & (species=="Fistax" | species=="Gripul" | species=="Plaund" | species=="Polstr")),], MARGIN=2, FUN=function(x) { if (sum(x)>=2) x<-1 else x<-0 })==1)],
					 winter=colnames(bina_list)[which(apply(X=bina_list[which(seasons=="winter" & (species=="Fistax" | species=="Gripul" | species=="Plaund" | species=="Polstr")),], MARGIN=2, FUN=function(x) { if (sum(x)>=2) x<-1 else x<-0 })==1)],
					 spring=colnames(bina_list)[which(apply(X=bina_list[which(seasons=="spring" & (species=="Fistax" | species=="Gripul" | species=="Plaund" | species=="Polstr")),], MARGIN=2, FUN=function(x) { if (sum(x)>=2) x<-1 else x<-0 })==1)] )

# Plot Venn Diagram
model_venn <- venn.diagram(x=seasons_venn, filename=NULL, col="transparent", fill=seasons_colors,
						   alpha=0.5, cex=1.0, cat.cex=1.0, cat.pos=0.1, cat.dist=c(0.1,0.1,0.04,0.03),
						   cat.fontface="bold", rotation.degree=0, margin=c(0,0,0,0),
						   cat.fontfamily="Helvetica", fontfamily="Helvetica")
argc <- argc + 1
pdf(args[argc], encoding="ISOLatin1", pointsize=10, width=5, height=5, family="Helvetica")
plot.new()
grid.draw(model_venn)
mtext(text="Acrocarpic species", adj=0.5, line=2, font=3, cex=1.2)
dev.off()


