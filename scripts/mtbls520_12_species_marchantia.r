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
	print("Usage: $0 input.rdata plot.pdf")
	quit(save="no", status=1, runLast=FALSE)
}

# Load R environment
load(file=args[1])
args <- commandArgs(trailingOnly=TRUE)
library(xcms)



# ---------- Marchantia profile ----------
# Third Marpol sample of summer
sampind <- which(mzml_files==mzml_files[seasons=="summer" & species=="Marpol"][3])

# Plot TIC
pdf(args[2], encoding="ISOLatin1", pointsize=11, width=10, height=7, family="Helvetica")
par(mar=c(4,4,1,1))
plot(x=xchroms[[sampind]]$rt, y=xchroms[[sampind]]$tic, type="l", lwd=1, col="black",
     xlab="Retention Time [s]", xlim=c(190,950), ylab="Total Ion Count", ylim=c(200000,max(xchroms[[sampind]]$tic)))

text(273, 650000+115000, "  Isoscutellarein +", pos=1, cex=0.8)
text(273, 650000+75000, "Glucuronides", pos=1, cex=0.8)
segments(226, 600000, 226, 650000, lwd=2)
segments(226, 650000, 320, 650000, lwd=2)
segments(320, 600000, 320, 650000, lwd=2)

text(400, 1000000+75000, "Thunberginol A", pos=1, cex=0.8)
arrows(400, 1000000, 409.0, 450000, col="black", lwd=2, length=0.1)

text(500, 2150000+75000, "Lunularic acid", pos=1, cex=0.8)
arrows(500, 2150000, 442.5, 1870000, col="black", lwd=2, length=0.1)

text(488, 420000+75000, "Marchantin G", pos=1, cex=0.8)
segments(456, 370000, 456, 420000, lwd=2)
segments(456, 420000, 520, 420000, lwd=2)
segments(520, 370000, 520, 420000, lwd=2)

text(520, 1000000+75000, "Marchantin B", pos=1, cex=0.8)
arrows(520, 1000000, 533.1, 850000, col="black", lwd=2, length=0.1)

text(560, 900000+75000, "Paleatin A", pos=1, cex=0.8)
arrows(560, 900000, 562.8, 280000, col="black", lwd=2, length=0.1)

text(550, 1700000+75000, "Marchantin A", pos=1, cex=0.8)
arrows(550, 1700000, 592.9, 1200000, col="black", lwd=2, length=0.1)

text(620, 1450000+75000, "Perrottetin E", pos=1, cex=0.8)
arrows(620, 1450000, 631.1, 390000, col="black", lwd=2, length=0.1)

text(670, 1100000+75000, "Marchantin C", pos=1, cex=0.8)
arrows(670, 1100000, 663.1, 950000, col="black", lwd=2, length=0.1)

text(671, 1350000+75000, "Thujopsenone", pos=1, cex=0.8)
segments(635, 1300000, 635, 1350000, lwd=2)
segments(635, 1350000, 707, 1350000, lwd=2)
segments(707, 1300000, 707, 1350000, lwd=2)

text(715, 1500000+75000, "(-)-delta-Cuprenene", pos=1, cex=0.8)
segments(672, 1450000, 672, 1500000, lwd=2)
segments(672, 1500000, 758, 1500000, lwd=2)
segments(758, 1450000, 758, 1500000, lwd=2)

text(900, 1600000+75000, "Pheophorbide A", pos=1, cex=0.8)
arrows(900, 1600000, 919.3, 1350000, col="black", lwd=2, length=0.1)
dev.off()


