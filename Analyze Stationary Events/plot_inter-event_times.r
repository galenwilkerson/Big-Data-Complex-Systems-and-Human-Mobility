
# load data

# subset by stationary time window
# subset by categorical variable(s)

# remove error/special values

# calculate inter-event times, durations, trip lengths
# plot CCDFs



########################################################

rm(list = ls())
library(ggplot2)
library(scales)


########################################################


# subset events by time period, return data frame within time period (inclusive)
# times are POSIXlt
subset.events.time.period <- function(events, time.column.name, start.time, end.time) {

  
  subset.events <- subset(events, events[,time.column.name] >= start.time & events[,time.column.name] <= end.time)
   
  
  return(subset.events)
}


# subset events by (inclusive) weekday(s) (0-6 starting on Sunday)
# return data frame on this day, also containing unclassed time columns
# times are POSIXlt
subset.events.day.of.week <- function(events, time.column.name, my.start.wday, my.end.wday) {
  
  new.df <- get.unclassed.data.frame.with.timescale(events, time.column.name)
  
  subset.events <- subset(new.df, wday >= my.start.wday, wday <= my.end.wday)
  
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
get.unclassed.data.frame.with.timescale <- function(events, time.stamp.column.name) {

  # break apart timestamp into components
  df.unclassed <- data.frame(events, unclass(as.POSIXlt(events[,time.stamp.column.name])))
 # h <- hist(df.unclassed[,timescale.name], plot = F)
      
  return(df.unclassed)
}


# divide data into groups by date
# takes in df having a timestamp column
# returns the same df, with a new column "date.group", only to day resolution
#   starting at 0, going until num.groups - 1
# assumes timestamp column is called "timestamp.event"
group.data.by.date <- function(events, start.date, end.date, num.groups) {

    grouped.events <- data.frame()
    
    # get numeric start and stop date
    # divide by number of groups
    # find beginning, end of each group
    # iterate through groups, labeling data frame accordingly,
    # building new data frame

    start.date <- as.POSIXlt(start.date)
    end.date  <- as.POSIXlt(end.date)
    date.diff <- end.date - start.date

    group.size <- date.diff/num.groups

    for (group in 0:(num.groups - 1)) {
      ith.start.date <- trunc(start.date + group * group.size, units = "days")
      ith.end.date <- trunc(start.date + ((group + 1) * group.size) - 1, units = "days")
 
      print(ith.start.date)
      print(ith.end.date)

      events.this.group <- subset(events, timestamp.event >= ith.start.date & timestamp.event <= ith.end.date)

      # add group
      events.this.group$date.group <- group

      # create new data frame
      grouped.events <- rbind(grouped.events, data.frame(events.this.group))
    }

    return(grouped.events)
  }



  
############################################################################



data.dir = "/home/username/Dropbox/Active_Projects/Mobility_Article/Data/"
figures.dir = "./Figures/"

load(paste(data.dir, "trips.Rdata", sep=""))

# get events within time range ########################################

## - from June 1 to Oct. 1, 2008
## - on a weekday
## - between 9am and 2pm
start.time <- as.POSIXlt("2008-06-01 00:00:00 CEST")
end.time <- as.POSIXlt("2008-10-01 00:00:00 CEST")
events.within.period <- subset.events.time.period(trips, time.column.name = "timestamp.event", start.time = start.time, end.time = end.time)

events.within.period$timestamp.event <- as.POSIXlt(events.within.period$timestamp.event)
temp.events <- unclass(events.within.period$timestamp.event)
temp.df <- data.frame(events.within.period, temp.events)
events.on.day <- subset(temp.df, wday >= 1 & wday <= 5)

events.in.range <- subset(events.on.day, hour >= 9 & hour <= 14)

events <- events.in.range

######################### FIND log-log CCDF #############################

# make sure sorted in order of event
events <- events[order(events$timestamp.event),]

inter.event.times <- as.numeric(diff(events$timestamp.event))
inter.event.times.mins <- inter.event.times/60


# REMOVE INTER-EVENT TIMES RESULTING FROM REMOVING EVENTS (ABOVE)
# CAN SAFELY REMOVE INTER-EVENT TIMES RESULTING FROM REMOVING WEEKENDS
# CAN ALSO REMOVE INTER-EVENT TIMES RESULTING FROM REMOVING NIGHTS
# JUST REMOVE ALL INTER-EVENT TIMES > 9AM - 2PM
# 9 - 14 (PREVIOUS DAY) = 23 - 5 = 18 HOURS

invalid.times <- subset(inter.event.times.mins, inter.event.times.mins >= 18 * 60)
valid.times <- subset(inter.event.times.mins, inter.event.times.mins < 18 * 60) 


# use hist for finding breaks
h.inter <- hist(valid.times, breaks = 100000, plot = F)

# keep the original break values, find xvalues, log x values, log ccdf
orig.breaks <-  h.inter$breaks

# the breaks are inter-event time intervals
inter.event.time <- orig.breaks[-1]
#log10.inter.event.time <- log10(inter.event.time)

histogram <- h.inter$counts
PDF <- h.inter$density

# find CDF, use for CCDF, log CCDF

# creates the cdf function using the data
cdf <- ecdf(valid.times)

# the actual values using the breaks from the histogram above
CDF <- cdf(inter.event.time)
CCDF1 <- 1 - CDF
log10.ccdf <- log10(CCDF1)

category <- "all_modes"

# keep track of results in data frame by category for plotting later
#df <- data.frame(log10.inter.event.time, log10.ccdf, category)
df <- data.frame(inter.event.time, histogram, PDF, CDF, category)
 
############################ PLOT BY CATEGORY ############################

## # get categories, remove 'bad' categories #############################
all.categories <- as.character(unique(trips$hvm))
bad.category <- all.categories[length(all.categories)]
good.categories <- all.categories[-length(all.categories)]
events.good.categories <- subset(events, hvm != bad.category)


# subset events by category
events.in.cat <- list()
index <- 1
for (category in good.categories) {
  events.in.cat[[index]] <- subset(events.good.categories, hvm == category)
  index <- index + 1
}

# for each subset, get the events, find the interarrival time
# add results to a data frame by category

index <- 1
for (events in events.in.cat) {
  category <- good.categories[index]
  
  inter.event.times <- as.numeric(diff(events$timestamp.event))
  inter.event.times.mins <- inter.event.times/60

  # remove inter event times > 18 hours
  invalid.times <- subset(inter.event.times.mins, inter.event.times.mins >= 18 * 60)
  print(length(invalid.times))
  
  valid.times <- subset(inter.event.times.mins, inter.event.times.mins < 18 * 60) 

  # use hist for finding breaks
  h.inter <- hist(valid.times, breaks = 100000, plot = F)

  # keep the original break values, find xvalues, log x values, log ccdf
  my.breaks <-  h.inter$breaks

  # the breaks are inter-event time intervals
  inter.event.time <- my.breaks[-1]
  
  histogram <- h.inter$counts
  PDF <- h.inter$density

  # the cdf function
  cdf <- ecdf(valid.times)

  # the actual values using the breaks from the original histogram above
  CDF <- cdf(inter.event.time)
  
  df <- rbind(df, data.frame(inter.event.time, histogram, PDF, CDF, category))
  
  index <- index + 1
}

# find CCDF, logs
df$CCDF <- 1 - df$CDF
df$log10.inter.event.time <- log10(df$inter.event.time)
df$log10.CDF <- log10(df$CDF)
df$log10.CCDF <- log10(df$CCDF)


################ PLOT #################





qplot(inter.event.time, PDF, data=df, color=category, geom="line") +
  ggtitle("Full Period - PDF Inter-event Time (mins)")

ggsave(paste(figures.dir, "Full_period_PDF_inter_event_time.pdf", sep=""))



qplot(inter.event.time, CDF, data=df, color=category, geom="line") +
  ggtitle("Full_period_CDF Inter-event Time (mins)")
  
ggsave(paste(figures.dir, "Full_period_CDF_inter_event_time.pdf", sep=""))



p.ccdf2 <- ggplot(data=df, aes(x = log10.inter.event.time, y = log10.CCDF, color=category)) +
  geom_line() +
  ggtitle("Full_period_Log-Log CCDF Inter-event Time (mins)")

ggsave(paste(figures.dir, "Full_period_Log-Log_CCDF_inter_event_time.pdf", sep=""))




p.cdf2 <- ggplot(data=df, aes(x = log10.inter.event.time, y = log10.CDF, color=category)) +
  geom_line() +
  ggtitle("Full_period_Log-Log CDF Inter-event Time (mins)")

ggsave(paste(figures.dir, "Full_period_Log-Log_CDF_inter_event_time.pdf", sep=""))





####################### DIVIDE INTO DATE GROUPS, PLOT ###################

# divide events by date
start.date <- start.time
end.date <- end.time
num.groups <- 5

events.grouped <- group.data.by.date(events.good.categories, start.date, end.date, num.groups)

#for (group in 0:num.groups) {
group <- 0

                                        # subset events by category
  events.in.cat <- list()
  index <- 1
  for (category in good.categories) {
    events.in.cat[[index]] <- subset(events.grouped, hvm == category)
    index <- index + 1
  }

                                        # for each subset, get the events, find the interarrival time
                                        # add results to a data frame by category

  index <- 1
  #for (events in events.in.cat) {
   events <- events.in.cat[[1]]
    category <- good.categories[index]
    
    inter.event.times <- as.numeric(diff(events$timestamp.event))
    inter.event.times.mins <- inter.event.times/60

                                        # remove inter event times > 18 hours
    invalid.times <- subset(inter.event.times.mins, inter.event.times.mins >= 18 * 60)
    print(length(invalid.times))
    
    valid.times <- subset(inter.event.times.mins, inter.event.times.mins < 18 * 60) 

                                        # use hist for finding breaks
    h.inter <- hist(valid.times, breaks = 100000, plot = F)

                                        # keep the original break values, find xvalues, log x values, log ccdf
    my.breaks <-  h.inter$breaks

                                        # the breaks are inter-event time intervals
    inter.event.time <- my.breaks[-1]
    
    histogram <- h.inter$counts
    PDF <- h.inter$density

                                        # the cdf function
    cdf <- ecdf(valid.times)

                                        # the actual values using the breaks from the original histogram above
    CDF <- cdf(inter.event.time)
    
    df <- rbind(df, data.frame(inter.event.time, histogram, PDF, CDF, category))
    
    index <- index + 1
  }

                                        # find CCDF, logs
  df$CCDF <- 1 - df$CDF
  df$log10.inter.event.time <- log10(df$inter.event.time)
  df$log10.CDF <- log10(df$CDF)
  df$log10.CCDF <- log10(df$CCDF)


################ PLOT #################





  qplot(inter.event.time, PDF, data=df, color=category, geom="line") +
    ggtitle(paste("Date group ", group, " - PDF Inter-event Time (mins)"))

  ggsave(paste(figures.dir, "Date group", group, "_period_PDF_inter_event_time.pdf", sep=""))



  qplot(inter.event.time, CDF, data=df, color=category, geom="line") +
    ggtitle(paste("Date group ", group, "_CDF Inter-event Time (mins)"))
  
  ggsave(paste(figures.dir, "Date group", group, "_period_CDF_inter_event_time.pdf", sep=""))



  p.ccdf2 <- ggplot(data=df, aes(x = log10.inter.event.time, y = log10.CCDF, color=category)) +
    geom_line() +
      ggtitle(paste("Date group ", group, "Full_period_Log-Log CCDF Inter-event Time (mins)"))

  ggsave(paste(figures.dir, "Date group", group, "Full_period_Log-Log_CCDF_inter_event_time.pdf", sep=""))




  p.cdf2 <- ggplot(data=df, aes(x = log10.inter.event.time, y = log10.CDF, color=category)) +
    geom_line() +
      ggtitle(paste("Date group ", group, "_period_Log-Log CDF Inter-event Time (mins)"))

  ggsave(paste(figures.dir, "Date group ", group, "_period_Log-Log_CDF_inter_event_time.pdf", sep=""))

  
#}













rm(list = ls())
