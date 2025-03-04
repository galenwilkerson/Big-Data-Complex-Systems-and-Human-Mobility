# load data


# calculate arrivals per day

##########################################################################

rm(list = ls())

load("./tripdata.Rdata")

trip.modes <- as.character(unique(trips$mode))

#remove last element (no response for 'mode')
trip.modes <- trip.modes[-length(trip.modes)]

start.date <- as.POSIXlt("2008-04-01 00:00:00") 
end.date <- as.POSIXlt("2008-12-31 00:00:00")


#subset data by date
trips <- subset(trips, timestamp.arrival >= start.date & timestamp.arrival <= end.date)


################# ALL MODES: plot arrivals at daily intervals ########################

dev.new(width=14, height=7)

breaks.interval <- "days"

mode.trips <- trips


  # change timestamp to date.time
  mode.trips$timestamp.arrival <- as.POSIXlt(mode.trips$timestamp.arrival)

  # sort by timestamp
  mode.trips.ordered <- mode.trips[order(as.POSIXlt(mode.trips$timestamp.arrival)),]

  # bin by day
  my.table <- table(cut(mode.trips.ordered$timestamp.arrival, breaks = breaks.interval))

 
  print(length(my.table))

  plot(my.table, type = "s", col = "black", xlab="Date", ylab="Number of Arrivals", main=paste("Arrivals (all modes) ", breaks.interval))


################# EACH MODE: plot arrivals at daily intervals ########################

index = 1
colors <- c(2:(length(trip.modes)+1))

dev.new(width=14, height=7)

breaks.interval <- "days"

trip.mode <- trip.modes[1]

 #subset data by mode
  mode.trips <- subset(trips, mode == trip.mode)
  
  # change timestamp to date.time
  mode.trips$timestamp.arrival <- as.POSIXlt(mode.trips$timestamp.arrival)

  # sort by timestamp
  mode.trips.ordered <- mode.trips[order(as.POSIXlt(mode.trips$timestamp.arrival)),]

  # bin by day
  my.table <- table(cut(mode.trips.ordered$timestamp.arrival, breaks = breaks.interval))

  print(trip.mode)
  print(length(my.table))

  plot(my.table, type = "s", col = colors[index], xlab="Date", ylab="Number of Arrivals", main=paste("Arrivals:", breaks.interval))

  index <- index + 1



trip.modes.abbrev <- trip.modes[-1]

for (trip.mode in trip.modes.abbrev) {

#trip.mode <- trip.modes[5]

  #subset data by mode
  mode.trips <- subset(trips, mode == trip.mode)
  
  # change timestamp to date.time
  mode.trips$timestamp.arrival <- as.POSIXlt(mode.trips$timestamp.arrival)

  # sort by timestamp
  mode.trips.ordered <- mode.trips[order(as.POSIXlt(mode.trips$timestamp.arrival)),]

  # bin by day
  my.table <- table(cut(mode.trips.ordered$timestamp.arrival, breaks = breaks.interval))

  print(trip.mode)
  print(length(my.table))

  lines(my.table, type = "s", col = colors[index])

  index <- index + 1
}


legend("topleft",  legend = trip.modes, pch = 1, col = colors)



rm(list = ls())
