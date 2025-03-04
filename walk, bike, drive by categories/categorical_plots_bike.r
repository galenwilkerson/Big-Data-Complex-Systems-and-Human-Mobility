# load trips

# for each category

# plot trip length, trip duration, inter-event time


##############


rm(list = ls())
library(ggplot2)

##############

# subset events by category, return list of subset data frames
subset.events.category <- function(events, subset.category, cat.values) {

  subsets <- list()

  i <- 1

  for (cat.val in cat.values) {
    
    # get rows by category
    category.events <- subset(events, events[,subset.category] == cat.val)
    subsets[[i]] <- category.events
    i <- i + 1
  }

   return(subsets)
}


##############


data.dir = "/home/username/Dropbox/Active_Projects/Mobility_Article/Data/"
figures.dir = "./Bike_Figs/"

load(paste(data.dir, "trips.Rdata", sep=""))


# subset trips to only biking

trips <- subset(trips, hvm == "Fahrrad")

##############



# get list of categories of interest

# for each category

# split data by value of category

# plot distribution


###############
# TODO: PLOT THESE AS LOG LOG CCDFS

# removed numerical, not categorical variables (must be plotted differently)
# stich.j, stich.wo, w07", "anzpers", "h02", "h04.3", "hhgr06", "hhgr14", "hhgr18", "anzerw", "hp.alter",  "psu.nr"
###############


#cats <- c("hvm", "hp.sex")

# removed these - too much detail
#"w05.1", "w05.2", "w05.3", "w05.4", "w05.5",  "w05.7", "w05.11", "w05.12", "w05.13", "w05.14", "w05.15", "w05.16", "w05.17", "w05.18", "w05.20", "w05.22", "w05.23",  "w072.2", "w072.3", "w072.4", "w072.5", "w072.6", "w072.7", "w072.8", "w072.9", "w072.10", "w073", "s02.1", "s02.2", "s02.3", "s02.4", "s02.5", "s02.6", "s02.7",

#cats <- c("stichtag")
#cats <- c("wsource", "int.typ9", "saison", "st.stdg", "stichtag", "st.dat", "en.dat", "w04", "w04.dzw", "w04.sons", "hwzweck", "w01", "w13", "w044", "mrad.f", "mrad.mf",  "pkw.f", "pkw.mf", "lkw.f", "lkw.mf","hvm.diff", "hvm", "hvm.oev", "vm.kombi", "w061", "w062", "w063", "w071", "w072.1",  "w074", "begleit",  "hheink", "oek.stat", "hhtyp", "hp.sex", "hp.altg1", "hp.altg2", "hp.altg3", "hp.besch", "hp.pkwfs", "pergrup", "pergrup1", "p070", "lebensph",  "gesein", "ov.seg", "s03", "s04", "s01", "bland", "westost", "polgk", "rtyp", "rtypd7", "ktyp", "ktyp.zsg", "sgtyp", "sgtypd") 

cats <- c("hwzweck")
#, "w04.sons",
#cats <- c("wsource", "int.typ9", "saison", "st.stdg", "st.dat", "en.dat", "w04", "hwzweck", "w01", "w13", "w044", "mrad.f", "mrad.mf",  "pkw.f", "pkw.mf", "lkw.f", "lkw.mf","hvm.diff", "hvm", "hvm.oev", "vm.kombi", "w061", "w062", "w063", "w071", "w072.1",  "w074", "begleit",  "hheink", "oek.stat", "hhtyp", "hp.sex", "hp.altg1", "hp.altg2", "hp.altg3", "hp.besch", "hp.pkwfs", "pergrup", "pergrup1", "p070", "lebensph",  "gesein", "ov.seg", "s03", "s04", "s01", "bland", "westost", "polgk", "rtyp", "rtypd7", "ktyp", "ktyp.zsg", "sgtyp", "sgtypd") 


# plot inter-event time, trip length, trip duration subset by trip subsets
 # "wegkm.k", "wegmin.k", "tempo", "co2weg", "kraftweg",
  
 # make trip length histogram for each category, plot log-log




for (this.cat in cats) {

  print(this.cat)
  
  cat.vals <- as.vector(unique(trips[,this.cat]))

  # the category name, used for legend and plotting
  Legend <- trips[,this.cat]

  # plot density
  qplot(timestamp.event, data = trips, geom = "density", adjust = 1/10, color = Legend) +
    ggtitle(paste(this.cat, "time frequency")) 

  ggsave(paste(figures.dir, this.cat, "time_frequency.pdf" , sep = "_"), width = 297, height = 210, units = "mm")

  
   
# REMOVE BAD/SPECIAL VALUES

  trips.subset <- subset(trips, wegkm.k <= 950)
  Legend <- trips.subset[,this.cat]


## ######################### FIND log-log CCDF #############################

# for each subset of cat, find the ccdf

  df <- data.frame()
  
  for(cat.val in cat.vals) {

    trips.subset.cat <- subset(trips.subset, trips.subset[,this.cat] == cat.val)
  

## # use hist for finding breaks
    h.inter <- hist(trips.subset.cat$wegkm.k, breaks = 100000, plot = F)
    
## # find xvalues, log x values, log ccdf
    my.breaks <-  h.inter$breaks
    trip.lengths <- my.breaks[-1]
    log10.trip.length <- log10(trip.lengths)

## # find CDF, use for CCDF, log CCDF
    cdf <- ecdf(trips.subset.cat$wegkm.k)
    CDF <- cdf(trip.lengths)
    CCDF1 <- 1 - CDF
    log10.ccdf <- log10(CCDF1)

## # keep track of results in data frame by category for plotting later
    df <- rbind(df, data.frame(log10.trip.length, log10.ccdf, cat.val))

}

  
  # plot trip length
  qplot(log10.trip.length, log10.ccdf, data = df, geom="line", color = cat.val) +
    ggtitle(paste(this.cat, "log log trip length (km)"))
 

  ggsave(paste(figures.dir, this.cat, "trip_length.pdf" , sep = "_"), width = 297, height = 210, units = "mm")
 
############## duration
  
 ##  trips.subset <- subset(trips, wegmin.k <= 480)
##   Legend <- trips.subset[,this.cat]




  df <- data.frame()
  
  for(cat.val in cat.vals) {

    trips.subset.cat <- subset(trips.subset, trips.subset[,this.cat] == cat.val)
  

## # use hist for finding breaks
    h.inter <- hist(trips.subset.cat$wegmin.k, breaks = 100000, plot = F)
    
## # find xvalues, log x values, log ccdf
    my.breaks <-  h.inter$breaks
    trip.durations <- my.breaks[-1]
    log10.trip.duration <- log10(trip.durations)

## # find CDF, use for CCDF, log CCDF
    cdf <- ecdf(trips.subset.cat$wegmin.k)
    CDF <- cdf(trip.durations)
    CCDF1 <- 1 - CDF
    log10.ccdf <- log10(CCDF1)

## # keep track of results in data frame by category for plotting later
    df <- rbind(df, data.frame(log10.trip.duration, log10.ccdf, cat.val))

}

##   # plot trip duration

  qplot(log10.trip.duration, log10.ccdf, data = df, geom="line", color = cat.val) +
    ggtitle(paste(this.cat, "log log trip duration (min)"))


  
  


  ggsave(paste(figures.dir, this.cat, "trip_duration.pdf" , sep = "_"), width = 297, height = 210, units = "mm")


  
#  trips.subset <- subset(trips, tempo <= 639.96)
#  Legend <- trips.subset[,this.cat]


  ## # plot trip speed
  ## qplot(tempo, data = trips.subset, geom="density", color = Legend, log="xy") +
  ##   ggtitle(paste(this.cat, "log log trip speed (km/h)"))

  ## ggsave(paste(figures.dir, this.cat, "trip_speed.pdf" , sep = "_"), width = 297, height = 210, units = "mm")



  
  ## trips.subset <- subset(trips, co2weg <= 193449)
  ## Legend <- trips.subset[,this.cat]
  
  ## # plot trip co2
  ## qplot(co2weg, data = trips.subset, geom="density", color = Legend, log="xy") +
  ##   ggtitle(paste(this.cat, "log log trip CO2 (kg)"))

  ## ggsave(paste(figures.dir, this.cat, "trip_CO2.pdf" , sep = "_"), width = 297, height = 210, units = "mm")


  
  ## trips.subset <- subset(trips, kraftweg <= 62730)
  ## Legend <- trips.subset[,this.cat]

  
  ## # plot trip fuel
  ## qplot(kraftweg, data = trips.subset, geom="density", color = Legend, log="xy") +
  ##   ggtitle(paste(this.cat, "log log trip fuel (Liter)"))

  ## ggsave(paste(figures.dir, this.cat, "trip_fuel.pdf" , sep = "_"), width = 297, height = 210, units = "mm")
  
  # get inter-event times

  ## trips.subsets <- list()

  ## i <- 1

  ## for (cat.val in cat.vals) {
    
  ##   # get rows by category
  ##   category.events <- subset(trips, trips[,this.cat] == cat.val)
  ##   trips.subsets[[i]] <- category.events
  ##   i <- i + 1
  ## }
  
  #trips.subsets <- subset.events.category(trips, this.cat, cat.vals)


  ## new.trips <- data.frame()
  
  ## for (trips.subset in trips.subsets) {
    
  ##   # make sure sorted in order of event
  ##   trips.subset <- trips.subset[order(trips.subset$timestamp.event),]

  ##   inter.event.times <- as.numeric(diff(trips.subset$timestamp.event))
  ##   inter.event.times.mins <- inter.event.times/60

  ##   trips.subset$inter.event.times.mins <- inter.event.times.mins

  ##   new.trips <- rbind(new.trips, trips.subset)

  ## }


  ## qplot(inter.event.times.mins, data = new.trips.subset, geom = "density", color = trips[,this.cat])
}



## # create factors with value labels
## mtcars$gear <- factor(mtcars$gear,levels=c(3,4,5),
##    labels=c("3gears","4gears","5gears"))
## mtcars$am <- factor(mtcars$am,levels=c(0,1),
##    labels=c("Automatic","Manual"))
## mtcars$cyl <- factor(mtcars$cyl,levels=c(4,6,8),
##    labels=c("4cyl","6cyl","8cyl"))

## # Kernel density plots for mpg
## # grouped by number of gears (indicated by color)
## qplot(mpg, data=mtcars, geom="density", fill=gear, alpha=I(.5),
##    main="Distribution of Gas Milage", xlab="Miles Per Gallon",
##    ylab="Density")
