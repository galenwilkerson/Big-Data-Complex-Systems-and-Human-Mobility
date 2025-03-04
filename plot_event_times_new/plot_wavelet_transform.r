# load data

# decompose by category

# wavelet transform



########################################################

rm(list = ls())
library(ggplot2)
library(scales)
library(wavelets)


########################################################


# subset events by time period, return data frame within time period (inclusive)
# times are POSIXlt
subset.events.time.period <- function(events, time.column.name, start.time, end.time) {

  
  subset.events <- subset(events, events[,time.column.name] >= start.time & events[,time.column.name] <= end.time)
   
  
  return(subset.events)
}


# subset events by category, return list of subset data frames
subset.events.category <- function(events, subset.category, categories) {

  subsets <- list()

  i <- 1

  for (cat in categories) {
    
    # get rows by category
    category.events <- subset(events, events[,subset.category] == cat)
    subsets[[i]] <- category.events
    i <- i + 1
  }

   return(subsets)
}


# get frequency of events by time scale
# return data frame with timestamp and frequency columns
get.frequency.by.timescale <- function(events, time.stamp.column.name, timescale) {

  event.table <- table(cut(events[,time.stamp.column.name], breaks = timescale))
  event.frequency <- data.frame(event.table)
  colnames(event.frequency) <- c("timestamp", "frequency")
  
  return(event.frequency)
}



# return data frame with original events and 'unclassed' timestamp information
get.unclassed.data.frame.by.timescale <- function(events, time.stamp.column.name, timescale.name) {

  # break apart timestamp into components
  df.unclassed <- data.frame(events, unclass(as.POSIXlt(events[,time.stamp.column.name])))
 # h <- hist(df.unclassed[,timescale.name], plot = F)
      
  return(df.unclassed)
}

############################################################################


data.dir = "/home/username/Dropbox/Active_Projects/Mobility_Article/Data/"
figures.dir = "./Figures/"

load(paste(data.dir, "trips.Rdata", sep=""))


# get events within time range
start.time <- as.POSIXlt("2008-04-01 00:00:00 CEST")
end.time <- as.POSIXlt("2008-12-31 23:59:59 CEST")
events.within.period <- subset.events.time.period(trips, time.column.name = "timestamp.event", start.time = start.time, end.time = end.time)


# get categories, remove 'bad' categories
categories <- as.character(unique(trips$hvm))
categories <- categories[-length(categories)]

# get list of events in each category
category.column.name <- "hvm"
events.by.category <- subset.events.category(events.within.period, category.column.name, categories)

################################# WAVELET TRANSFORM ################################

#for each category, plot frequency of events over entire time period
category.index <- 1
for(events.this.category in events.by.category) {
 #events.this.category <- events.by.category[[1]] # TEST

  category <- categories[category.index]
  print(categories[category.index])

  # get events
  timescale <- "min"
  time.series.df <- get.frequency.by.timescale(events.this.category, "timestamp.event", timescale)
  time.series <- as.ts(time.series.df$frequency)
  dwt1 <- dwt(time.series)

  filen <- paste(figures.dir, "wavelet transform:", gsub(" ", "_", categories[category.index]), ".pdf", sep="_")

  pdf(filen)

     
  
  plot(dwt1, main = "Discrete Wavelet Transform, All Modes")
  dev.off()
}
