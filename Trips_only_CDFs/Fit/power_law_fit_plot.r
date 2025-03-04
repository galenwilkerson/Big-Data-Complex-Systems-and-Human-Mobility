# plot all modes and there best fit functions

# get and plot several synthetic data sets (from plpva)

# also plot actual empirical data
# run as: NOT IN HOME DIRECTORY, INSTEAD USE /mnt/share/<directory>
#
# > nohup nice --adjustment=+19 R CMD BATCH <program.r> &
# then:
# > ionice -c3 -p<pid>
#
# clear all variables
rm(list = ls())

# plotting
library("ggplot2")

# plfit code
source("plfit.r")
source("plpva.r")
source("synthdata.r")

# base directory
base.data.dir <- "../Data/"
base.figures.dir <- "../Figures/"

# load trip data
load(paste(base.data.dir,"merged_trips.RData", sep=""))

# separate trips into hvm mode

# get uniq list of modes
trip.modes <- as.vector(unique(mergedtrips$hvm))

# add "all modes" to modes
trip.modes <- c("all_modes", trip.modes)

# remove "no response"
trip.modes <- trip.modes[-length(trip.modes)]

print(trip.modes)


outfile <- paste(base.figures.dir,"ccdf_each_mode.pdf", sep="")
  
pdf(outfile)



colors.set <- c("black", "red", "orange", "green", "blue", "purple")

colors.index <- 1

legend.labels <- c()

plot(0,main="CCDF for each mode",
#     xlim=c(1.5,3),  # zoom in
     xlim=c(-2,3), # zoom out
#     xlim=c(log10(x.min),3),  # start at xmin
#     ylim=c(-5,-1), # zoom in
     ylim=c(-5,0), # zoom out
     xlab= expression(log[10](r)),
     ylab= expression(log[10](p(r))),
     col="white")

for (trip.mode in trip.modes) {
#trip.mode <- trip.modes[3]

print(trip.mode)

############# PREPARATION ############

puf.max.trip.length <- 950

ifelse(trip.mode == "all_modes",
       puf.trip.lengths <- subset(mergedtrips, wegkm.k <= puf.max.trip.length & wegkm.k > 0, select=c(wegkm.k))[,1],
       puf.trip.lengths <- subset(mergedtrips, hvm == trip.mode & wegkm.k <= puf.max.trip.length & wegkm.k > 0, select=c(wegkm.k))[,1])

puf.trip.lengths <- na.omit(puf.trip.lengths)

data.size <- length(puf.trip.lengths)

x.interval <- .1

breaks.vector <- seq(0,puf.max.trip.length, by=x.interval)

# remove first entry of breaks vector (for size matching with y values, and to avoid 'zero' problems)
x.values <- breaks.vector[-1]
log10.xvals <- log10(x.values)

## ## # find xmin, alpha
print("fitting")
params <- plfit(puf.trip.lengths)

num.trips <- length(puf.trip.lengths)
x.min <- as.numeric(params[1])
alpha <- as.numeric(params[2])

num.trips
x.min
alpha

############  EMPIRICAL CCDF ################

puf.hist <- hist(puf.trip.lengths,
                 breaks = breaks.vector,	
                 plot = F)


# CCDF
cdf.puf.hist <- ecdf(puf.trip.lengths)
ccdf <- 1 - cdf.puf.hist(x.values)

log10.xvals <- log10(x.values)
log10.ccdf <- log10(ccdf)

log10.ecdf <- log10(cdf.puf.hist(x.values))

#plot(log10.xvals,
lines(log10.xvals,
      log10.ccdf,
      lwd=1.5,
      type="s",
      col=colors.set[colors.index])

#remove special chars and spaces
trip.mode.stripped <- gsub("[[:punct:]]", "", trip.mode)
trip.mode.stripped <- gsub(" ", "", trip.mode.stripped)

print(trip.mode.stripped)

# save the x.values and ccdf data for offline fitting
write.table(data.frame(x.values, ccdf), paste(base.data.dir, trip.mode.stripped,"_linlin_ccdf.csv",sep=""))
write.table(data.frame(log10.xvals, log10.ccdf), paste(base.data.dir, trip.mode.stripped,"_loglog_ccdf.csv",sep=""))


############### PLOT CCDF OF BEST FIT FUNCTION ###############

# using vector of x.values, compute P(X > x) as vector

# P(x) = ((x/x_min)^(1-alpha))
P.X <- ((x.values/x.min)^(1-alpha))

cdf.at.xmin <- cdf.puf.hist(x.min)
ccdf.at.xmin <- 1 - cdf.at.xmin
ccdf.at.xmin

log.ccdf.at.xmin <- log10(ccdf.at.xmin)
log.ccdf.at.xmin

# plot CCDF
log10.x.vals <- log10(x.values) 
log10.P.X <- log10(P.X) + log.ccdf.at.xmin

lines(log10.x.vals,
      log10.P.X,
      type = "l",
      lty = 2,
      lwd = 1.5,
      col=colors.set[colors.index])

# label alpha on fit line
#text(log10(x.min) - .3, log.ccdf.at.xmin, substitute(alpha == alphval, list(alphval = round(alpha, digits = 2))))


#################  Draw vertical line at xmin

points(log10(x.min),
       log.ccdf.at.xmin,
       pch=19,
       col=colors.set[colors.index])

# label xmin location
#text(log10(x.min), -5, substitute(log(x[min]) == xminval, list(xminval =  round(log10(x.min), digits=2))))


# label for legend entry
label1 <- paste(trip.mode, " xmin = ", round(x.min,digits=2), " alpha = ", round(alpha,digits=2))
legend.labels <- append(legend.labels, label1)

colors.index <- colors.index + 1

}


#legend.labels <- c(label1,"synthetic cdf 1", "synthetic cdf 2","synthetic cdf 3","synthetic cdf 4","synthetic cdf 5","empirical cdf")
#legend.labels <- trip.modes

legend.colors <- colors.set
legend(-.05, -4.1, legend.labels ,lty=c(1), lwd= 2.5, col=legend.colors, cex = .75, bty="n")

legend(-.05, -3.5, legend=c("ccdf", "fit", expression(x[min])),  lwd = c(2.5,2.5,NA), lty=c(1,2, NA), pch=c(NA, NA, 19), cex = .75, bty = "n")


dev.off()


rm(list = ls())
