# load travels (Reisen)


# for each mode (and "all modes")

# plot log-log histogram of categories
# fit categories


# clear all variables
rm(list = ls())

# plotting
library("ggplot2")

# plfit code
source("plfit.r")
source("plpva.r")

# base directory
data.dir = "/home/username/Dropbox/Active_Projects/Mobility_Article/Data/"
figures.dir = "./Figures/"

# load travel data
load(paste(data.dir, "travels.Rdata", sep=""))


# get uniq list of modes
travel.modes <- as.vector(unique(travels$hvm_r))

# add "all modes" to modes
travel.modes <- c("all_modes", travel.modes)

# remove "no response" and "don't know"
travel.modes <- travel.modes[-length(travel.modes)]
travel.modes <- travel.modes[-length(travel.modes)]

print(travel.modes)


outfile <- paste(figures.dir,"travels_ccdf_each_mode.pdf", sep="")
  
pdf(outfile)



colors.set <- c("black", "red", "orange", "green", "blue", "purple")

colors.index <- 1

legend.labels <- c()

plot(0,#main="CCDF for each mode",
#     xlim=c(1.5,3),  # zoom in
     xlim=c(0.5,4.5), # zoom out
#     xlim=c(log10(x.min),3),  # start at xmin
#     ylim=c(-5,-1), # zoom in
     ylim=c(-5,0), # zoom out
     xlab= expression(log[10](r)),
     ylab= expression(log[10](p(r))),
     col="white")

for (travel.mode in travel.modes) {


print(travel.mode)

############# PREPARATION ############

puf.max.travel.length <- 20000

ifelse(travel.mode == "all_modes",
       puf.travel.lengths <- subset(travels, p1016 <= puf.max.travel.length & p1016 > 0, select=c(p1016))[,1],
       puf.travel.lengths <- subset(travels, hvm_r == travel.mode & p1016 <= puf.max.travel.length & p1016 > 0, select=c(p1016))[,1])

puf.travel.lengths <- na.omit(puf.travel.lengths)

data.size <- length(puf.travel.lengths)

x.interval <- .1

breaks.vector <- seq(0,puf.max.travel.length, by=x.interval)

# remove first entry of breaks vector (for size matching with y values, and to avoid 'zero' problems)
x.values <- breaks.vector[-1]
log10.xvals <- log10(x.values)

## ## # find xmin, alpha
print("fitting")
params <- plfit(puf.travel.lengths)

num.travels <- length(puf.travel.lengths)
x.min <- as.numeric(params[1])
alpha <- as.numeric(params[2])

num.travels
x.min
alpha

############  EMPIRICAL CCDF ################

puf.hist <- hist(puf.travel.lengths,
                 breaks = breaks.vector,	
                 plot = F)


qplot(puf.hist$breaks[-1], puf.hist$counts)


# CCDF
cdf.puf.hist <- ecdf(puf.travel.lengths)
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
travel.mode.stripped <- gsub("[[:punct:]]", "", travel.mode)
travel.mode.stripped <- gsub(" ", "", travel.mode.stripped)

print(travel.mode.stripped)

# save the x.values and ccdf data for offline fitting
write.table(data.frame(x.values, ccdf), paste(data.dir, travel.mode.stripped,"_linlin_ccdf.csv",sep=""))
write.table(data.frame(log10.xvals, log10.ccdf), paste(data.dir, travel.mode.stripped,"_loglog_ccdf.csv",sep=""))


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
label1 <- paste(travel.mode, " xmin = ", round(x.min,digits=2), " alpha = ", round(alpha,digits=2))
legend.labels <- append(legend.labels, label1)

colors.index <- colors.index + 1

}



legend.colors <- colors.set
legend(0.56, -3, legend=c("ccdf", "fit", expression(x[min])),  lwd = c(2.5,2.5,NA), lty=c(1,2, NA), pch=c(NA, NA, 19), cex = .75, bty = "n")

legend(0.5, -3.5, legend.labels ,lty=c(1), lwd= 2.5, col=legend.colors, cex = .75, bty="n")




dev.off()


rm(list = ls())
