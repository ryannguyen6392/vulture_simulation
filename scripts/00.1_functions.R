# FUNCTION DEFINITIONS
# To be used in the rest of the workflow for this project.
library(dplyr)
library(lubridate)
library(data.table)
library(spatsoc)
library(proxy)
library(purrr)
library(Polychrome) # for color palettes
#devtools::install_github("kaijagahm/vultureUtils")
# library(vultureUtils)

# 1. simulateAgents -------------------------------------------------------
## this code generates data for testing the method of social network randomizations ###
## the code generates a population of agents with given movement rules ###
## currently it is set on the paired agents scenario, see details below for switching between different scenarios or exploring the parameter spcae fo other values
## writen by Orr Spiegel Jan 2016. contact me at orr.spiegel@mail.huji.ac.il if you need further help ###
# Edited by Ryan Nguyen and Kaija Gahm
# XXXK are notations by Kaija to indicate confusion/questions.
#
# Simulation 1 (static bias):
# set sim_3 to F and HRChangeRadius to 0
# agents will be biased towards a constant bias point throughout the simulation
#
# Simulation 2 (local bias):
# set sim_3 to F and HRChangeRadius to desired value
# bias points will change at a radius of HRChangeRadius per day
#
# Simulation 3 (directional bias):
# set sim_3 to T and corresponding movement parameters HREtaCRW, HRKappa_ind, HRStpSize, HRStpStd to desired values
# bias points will move according to a CRW with those parameters
simulateAgents <- function(N = 6, # Number of individuals in the population 
                           Days = 10, # Number of days to simulate
                           DayLength = 50, # Number of time steps per day (currently it is limited to 59 since i considered it as minutes within an hour)
                           Soc_Percep_Rng = 2000, #detection range (in meters) - indivduals within this range will be considered in the bias point in the relevant scenario of sociable agents. set to 0 if you want socially indifferent agents (or in the fixed pairs scenario) 
                           Scl = 2000, # scale of starting coords 
                           seed = NULL,
                           EtaCRW = 0.7, # The weight of the CRW component in the BCRW used to model the Indiv movement
                           StpSize_ind = 7, # Mean step lengths of individuals;
                           StpStd_ind = 5, # Standard deviations of step lengths of individuals 
                           Kappa_ind = 4, # Concentration parameters of von Mises directional distributions used for individuals' movement
                           quiet = F, 
                           sim_3 = F, # directional movement
                           HRChangeRadius = 0, # Radius in which new HR center is to be selected from the next day (local movement)
                           HREtaCRW = 0.7, # Weight towards previous direction
                           HRKappa_ind = 4, # controls how strongly vm distribution is centered on mu
                           HRStpSize = 0.01, # Mean step lengths of HRs
                           HRStpStd = 0.01,  # STD of step lengths of HRs
                           socialWeight = 0, # how much to bias toward another individual, versus toward the home range point. Default is biasing toward the mean between the home range center and the other individual's location. If socialWeight is 1, will bias just toward the other individual. If socialWeight is 0, will not bias toward the other individual.
                           sameStartingAngle = 0, # 0 or 1 flag to determine if all the agents should start moving in the same direction (sim3)
                           asocial = F,
                           spatialAttractors = NULL, # Roost locations
                           roostThreshhold = 0.7, # % of day before finding roost
                           spherical = F,
                           carcasses = F, # carcass simulation
                           carcassPercepRange = 200, # range to detect carcass
                           carcassWeight = 0.5, # how much to bias toward carcass
                           meanCarcassLength = 2.5, # average number of days a carcass should last
                           carcassesPerDay = 6, # number of carcasses to spawn per day
                           carcassChance = 0.5, # chance to spawn a carcass
                           
){
  
  # 1. Set the seed, if one is provided ----------------------------------------
  if(!is.null(seed)){
    set.seed(seed)
  }
  
  # 2. Prepare variables for storing data --------------------------------------
  # Calculate number of time steps
  N_timesteps <- Days*DayLength # Total number of time steps that will be simulated for each iteration
  
  # 3. Set starting conditions -------------------------------------------------
  startIndx <- 1
  Phi_ind <- rep(0, N) # Direction of the last step for the individuals
  XYind <- vector(mode = "list") # This list will store the matrices of locations of all individuals
  HRCent <- matrix(data = NA, nrow = N, ncol = 3) # Empty matrix that will store home range centers
  HRCent[,3] <- rep(c(1,2), length.out = nrow(HRCent)) # Assign sex 
  HRcenterDist <- rep(0, N/2) # Initial distance between pairs of agents
  carcassTotal <- data.frame()

  # 4. Set initial conditions for individuals ----------------------------------
  # Loop on individuals: set initial conditions
  for (k in 1:N) {
    # Place agents in their initial positions
    XYind[[k]] <- matrix(rep(NA, 2*N_timesteps), ncol = 2) # This matrix will store the location of each individual
    # Set random X and Y locations and log the HR center
    if(class(spatialAttractors) == "data.frame"){
      XYind[[k]][1, ] <- as.numeric(spatialAttractors[ceiling(runif(n=1, max=nrow(spatialAttractors))), ])
    } else {
      XYind[[k]][1, ] <-  c(runif(n=1, min=-Scl/3, max=Scl/3), 
                            runif(n=1, min=-Scl/3, max=Scl/3 )) 
    }
    HRCent[k, 1:2] <- XYind[[k]][1, ]
    
  } # End loop on individuals 
  
  # 5. Set initial HR storage and carcass storage -------
  # If the HR's are going to be changing (sim2 or sim3), create a list to store daily HR centers, and set the initial values from HRCent above.
  HRCentPerDay <- vector(mode = "list", length = Days)
  HRCentPerDay[[1]] <- HRCent
  if(sim_3){
    if (sameStartingAngle > 0){        # set same starting angle
      angle <- runif(1, min=0, 2 * pi)
      HRCentPerDay[[1]][, 3] <- angle
    }
    else # set different starting angles
      HRCentPerDay[[1]][, 3] <- runif(N, min=0, 2 * pi)
    HRPhi_ind <- rep(0, N) # Direction of the last step for the HRs
  }
  
  if(carcasses)
    # Nx4 matrix of carcasses that will store x,y and timeToStart and timeToDecay
    carcassStorage <- data.frame(x=double(), y=double(), timeToStart=integer(), timeToDecay=integer())
  
  # 6. Run the simulation ----------------------------------
  # Loop on time steps and individuals to run the simulation
  dayCount <- 1 # start on day 1
  for(Curr_timestep in 1:(N_timesteps-1)){
    # A. IF NEW DAY:
    # move HR center (sim2 and sim3)
    if(T){
      newDay <- Curr_timestep %% DayLength == 0 ## && and %% are for scalars not vectors, change every day
      if(newDay){ # If this is the start of a new day... 
        dayCount <- dayCount + 1
        if(HRChangeRadius > 0 && !sim_3){ # uniform radius HR change (sim 2)
          randomAngles <- runif(N, min = 0, 2 * pi) # sample angle from 0-2pi per individual
          randomLengths <- HRChangeRadius * sqrt(runif(N)) # https://stackoverflow.com/questions/5837572/generate-a-random-point-within-a-circle-uniformly #
          # get random XY to add to existing HR to move
          randomX <- randomLengths * cos(randomAngles)
          randomY <- randomLengths * sin(randomAngles)
          randomXY <- cbind(randomX, randomY) 
          HRCentPerDay[[dayCount]] <- HRCentPerDay[[dayCount-1]]
          HRCentPerDay[[dayCount]][, 1:2] <- HRCentPerDay[[dayCount]][, 1:2] + randomXY # move HR centers
        }else if(sim_3){ # vm HR change
          mu <- HRCentPerDay[[dayCount - 1]][, 3] # get list of old mus
          HRmu.av <- Arg(HREtaCRW * exp(HRPhi_ind * (0+1i)) + (1 - HREtaCRW) * exp(mu * (0+1i))) # averages between old direction and new mu based on HREtaCRW
          HRPhi_ind <- sapply(HRmu.av, function(x){CircStats::rvm(n = 1, mean = x, k = HRKappa_ind)}) # sample new mus
          stepLengths <- stats::rgamma(N, shape = HRStpSize^2/HRStpStd^2,  
                                       scale = HRStpStd^2/HRStpSize) # https://math.stackexchange.com/questions/1810257/gamma-functions-mean-and-standard-deviation-through-shape-and-rate
          steps <- stepLengths * c(Re(exp((0+1i) * HRPhi_ind)), 
                                   Im(exp((0+1i) * HRPhi_ind)))
          HRCentPerDay[[dayCount]] <- HRCentPerDay[[dayCount-1]]
          HRCentPerDay[[dayCount]][, 1:2] <- HRCentPerDay[[dayCount]][, 1:2] + steps # move HRS
          HRCentPerDay[[dayCount]][, 3] <- HRPhi_ind # set new mus for next day
        }else{ # if neither of these situations, keep the home range the same.
          HRCentPerDay[[dayCount]] <- HRCentPerDay[[dayCount-1]]
        }
        
        # A2. Optionally add carcasses:
        if(carcasses){
          for(i in 1:carcassesPerDay){ # For each agent:
            chance <- runif(1, 0, 1)
            if(chance < carcassChance){ # Random chance for carcass spawn
              # Create carcass with time to spawn from start of day and time before disappearing
              # Set with parameters
              carcass <- data.frame(x=runif(1, -Scl + Scl/8, Scl - Scl/8), y=runif(1, -Scl + Scl/8, Scl - Scl/8), 
                                    timeToStart=runif(1, 1, DayLength), timeToDecay=rnorm(1, mean=meanCarcassLength * DayLength, sd=sqrt(DayLength)),day=dayCount)
              carcassStorage <- rbind(carcassStorage, carcass) # Add carcass to global carcasses
              carcassTotal <- rbind(carcassTotal, carcass) # Add carcass to return carcasses
            }
          }
        }
      }
      # A3. Advance carcass timers and remove decayed carcasses
      if(carcasses){
        carcassStorage$timeToStart <- carcassStorage$timeToStart + ifelse(carcassStorage$timeToStart > 0, -1, 0) # advance start timer if carcass has not appeared yet
        carcassStorage$timeToDecay <- carcassStorage$timeToDecay + ifelse(carcassStorage$timeToStart <= 0 & carcassStorage$timeToDecay > 0, -1, 0) # advance decay timer if carcass has appeared
        carcassStorage <- carcassStorage[carcassStorage$timeToDecay > 0, ] # remove decayed carcasses
      }
    } # end daily moving of HR center
    
    # B. All time steps: 
    # For each individual, set bias point and calculate its next step.
    for(Curr_indv in 1:N){
      # Compute distance of this individual to all other individuals
      
      # If flight to roost is planned, no need to do anything
      if(!is.na(XYind[[Curr_indv]][Curr_timestep + 1, 1]) && !is.na(XYind[[Curr_indv]][Curr_timestep + 1, 2]))
        next
      
      Dist <- rep(NA, N) 
      for(Other_indv in 1:N){
        Dist[Other_indv] <- stats::dist(rbind(XYind[[Other_indv]][Curr_timestep,],
                                              c(XYind[[Curr_indv]][Curr_timestep,])))
      }
      Dist[Dist == 0] <- NA # Remove distance to self
      
      if(carcasses){ # Get distance to carcasses
        carcassDist <- rep(NA, nrow(carcassStorage)) 
        if(carcasses && nrow(carcassStorage) > 0){
          for(i in 1:nrow(carcassStorage)){
            carcass <- carcassStorage[i]
            if(carcass$timeToStart > 0) # don't consider carcasses that haven't appeared yet today
              next
            carcassDist[i] <- stats::dist(rbind(carcassStorage[i, 1:2],
                                                  c(XYind[[Curr_indv]][Curr_timestep,])))
          }
        }
      }
      
      # Calculating the direction to the initial location (bias point )+ now with drift for the current step
      # Set individual bias points in different ways depending on method
      if(HRChangeRadius > 0 || sim_3 > 0){
        BiasPoint <- HRCentPerDay[[dayCount]][Curr_indv, 1:2] # if HR changes per day, set bias point to that day's home range
      }else{
        BiasPoint <- HRCentPerDay[[1]][Curr_indv, 1:2] # otherwise, bias toward the original home range center
      }
      
      # If another individual is within social perception range...
      if(min(Dist, na.rm = T) < Soc_Percep_Rng){
        if(socialWeight < 0 | socialWeight >1){stop("socialWeight must be a number between 0 and 1.")}
          otherIndivLoc <- XYind[[which.min(Dist)]][Curr_timestep,] # get the other individual's location
          ownHRCent <- HRCentPerDay[[dayCount]][Curr_indv, 1:2]
        if(!asocial){
          # Take the mean between the home range center and the closest other individual's location, and bias towards that mean
          meanpoint <- (socialWeight*otherIndivLoc + (1-socialWeight)*ownHRCent)
          BiasPoint <- meanpoint
        }
        else # asocial scenario: bias away from individuals and towards bias
        {
          toOther <- otherIndivLoc - XYind[[Curr_indv]][Curr_timestep, ]
          awayOther <- -1 * toOther
          awayPoint <- XYind[[Curr_indv]][Curr_timestep, ] + awayOther
          
          meanpoint <- (socialWeight*awayPoint + (1-socialWeight) * ownHRCent)
          BiasPoint <- meanpoint
        }
      }
      
      ## CARCASS PHASE
      # If there are available carcasses, and within range...
      if(carcasses && length(carcassDist) > 0 && min(carcassDist) < carcassPercepRange){
        if(carcassWeight < 0 | carcassWeight >1){stop("socialWeight must be a number between 0 and 1.")}
        carcass <- as.numeric(carcassStorage[which.min(carcassDist), 1:2]) # get carcass location
        ownHRCent <- HRCentPerDay[[dayCount]][Curr_indv, 1:2]
        # Take the mean between current bias and the closest carcass location, and bias towards that mean
        meanpoint <- (carcassWeight*carcass + (1-carcassWeight)*BiasPoint)
        BiasPoint <- meanpoint
      }
      
      ## ROOST PHASE
      ## If there are set roosts, and it's time for the agents to find a roost
      if(class(spatialAttractors) == "data.frame" && Curr_timestep %% DayLength >= DayLength * roostThreshhold){
        distToAttractors <- rep(NA, nrow(spatialAttractors)) # Get distance to each roost
        for(spatialAttractor in 1:nrow(spatialAttractors)){
          distToAttractors[spatialAttractor] <- stats::dist(rbind(spatialAttractors[spatialAttractor, ],
                                                                  c(XYind[[Curr_indv]][Curr_timestep,])))
        }
        
        timeLeft <- DayLength - (Curr_timestep %% DayLength) # Time left to get to roost
        # Distance vector to get to closest roost
        travel <- as.numeric(spatialAttractors[which.min(distToAttractors), ]) - XYind[[Curr_indv]][Curr_timestep, ]
        step <- travel / timeLeft # A step in the direction of the roost
        
        for(t in 1:timeLeft){ # Plan out future movements to roost
          XYind[[Curr_indv]][Curr_timestep+t, ] <- XYind[[Curr_indv]][Curr_timestep+t-1, ] + step
        }
      }
      # Set direction to the chosen bias point
      coo <- BiasPoint - XYind[[Curr_indv]][Curr_timestep, ] 
      # Set direction:
      mu <- Arg(coo[1] + (0+1i) * coo[2]) # XXXK what is this? Direction, I think.
      # Make sure direction is not negative:
      if(mu < 0){
        mu <- mu + 2 * pi  
      } 
      
      # Bias to initial location + CRW to find the von mises center for the next step
      mu.av <- Arg(EtaCRW * exp(Phi_ind[Curr_indv] * (0+1i)) + (1 - EtaCRW) * exp(mu * (0+1i)))

      # if(Curr_timestep %% DayLength >= DayLength * roostThreshhold){
      #   Phi_ind[Curr_indv] <- mu
      # } else
        # Choose current step direction from von Mises centered around the direction selected above 
        Phi_ind[Curr_indv] <- CircStats::rvm(n=1, mean = mu.av, k = Kappa_ind)
      
      # Perform the step
      # Selection of step size for this indiv in this state from the specific gamma          
      step.len <- stats::rgamma(1, shape = StpSize_ind^2/StpStd_ind^2, 
                                scale = StpStd_ind^2/StpSize_ind)
      step <- step.len * c(Re(exp((0+1i) * Phi_ind[Curr_indv])), 
                           Im(exp((0+1i) * Phi_ind[Curr_indv])))
      # Save the individual's next location
      XYind[[Curr_indv]][Curr_timestep + 1, ] <- XYind[[Curr_indv]][Curr_timestep, ] + step
      
      # TESTING: spherical plane
      if(spherical){
        if(XYind[[Curr_indv]][Curr_timestep + 1, 1] > Scl){ # if past right edge
          XYind[[Curr_indv]][Curr_timestep + 1, 1] <- -Scl + (XYind[[Curr_indv]][Curr_timestep, 1] - Scl) # wrap to left
        } else if(XYind[[Curr_indv]][Curr_timestep + 1, 1] < -Scl){ # if past left edge
          XYind[[Curr_indv]][Curr_timestep + 1, 1] <- Scl + (XYind[[Curr_indv]][Curr_timestep, 1] - Scl) # wrap to right
        }
        if(XYind[[Curr_indv]][Curr_timestep + 1, 2] > Scl){ # if past top edge
          XYind[[Curr_indv]][Curr_timestep + 1, 2] <- -Scl + (XYind[[Curr_indv]][Curr_timestep, 2] - Scl) # wrap to bottom
        } else if(XYind[[Curr_indv]][Curr_timestep + 1, 2] < -Scl){ # if past bottom edge
          XYind[[Curr_indv]][Curr_timestep + 1, 2] <- Scl + (XYind[[Curr_indv]][Curr_timestep, 2] - Scl) # wrap to top
        }
      }
    } # End loop on individuals
    if(!quiet){print(c("done with timestep", Curr_timestep, "out of", N_timesteps))}
  } # End loop on time steps
  
  # C. Save data
  
  # Create a list for output with three slots: hr centers, and xy coordinates
  rName <- paste("sim", N_timesteps, N, 100*EtaCRW, StpSize_ind, ".rdata", sep = "_")
  matlabName <- "xyFromSimulationForSNanalysis.mat" # keeping the old format for compatibility with Orr's old code
  
  # determine which form of HR centers to return #
  # Reformat HR centers to be per individual instead of per day
  if(HRChangeRadius > 0 || sim_3 > 0){
    HRCentPerIndiv <- vector(mode = "list", length = N)
    for(i in 1:N){
      out <- as.data.frame(do.call(rbind, map(HRCentPerDay, ~.x[i,])))
      names(out) <- c("X", "Y", "angle")
      out$day <- 1:nrow(out)
      HRCentPerIndiv[[i]] <- out
    } 
    HRCentPerIndiv <- HRCentPerIndiv %>% purrr::list_rbind(names_to = "indiv")
    HRCentPerIndiv$indiv <- as.character(HRCentPerIndiv$indiv)
    HRReturn <- HRCentPerIndiv
  }
  else{
    HRReturn <- HRCent
  }
  
  # Reformat XYind as a data frame
  XYind <- map(XYind, ~{
    .x <- as.data.frame(.x)
    .x$timestep = 1:nrow(.x)
    .x$day = rep(1:Days, each = DayLength)
    .x$StepInDay <- rep(1:DayLength, Days)
    return(.x)
  }) %>% purrr::list_rbind(names_to = "indiv")
  XYind$indiv <- as.character(XYind$indiv)
  names(XYind)[names(XYind) == "V1"] <- "X"
  names(XYind)[names(XYind) == "V2"] <- "Y"
  out <- list("rName" = rName, "matlabName" = matlabName, "HRCent" = HRReturn, "XY" = XYind, carcasses = carcassTotal)
  return(out)
}

# 2. fix_times ------------------------------------------------------------
# changes day and step to posix. This used to be load_data. You now have to do the loading by yourself. It's too weird to include the process of loading a .Rda file in a function because of the weird naming thing. See implementation of this in workflow.R
# The input data is the $XY portion of the list returned by simulateAgents().

# XXXK: need to talk to Orr about this sampling interval. Here is what was written in Ryan's code:
# SAMPLING_INTERVAL <- 10 # "minutes", from matlab code; 10 minutes per timestep with 50 timesteps gives about 8hrs of data
# KG 2023-09-01 For now I have added sampling_interval as a parameter in this function.
# XXXK

fix_times <- function(simulation_data, sampling_interval = 10){
  start_time <- as.POSIXct("2023-08-11 23:50")  # note simulation data starts on day 1 step 1 so the mindate will be 8-13 00:00
  simulation_data <- simulation_data %>% # start date is arbitrarily chosen so that posix can be used by spatsoc
    dplyr::mutate(datetime = start_time + lubridate::days(day) + lubridate::minutes(StepInDay * sampling_interval)) %>%
    dplyr::select(indiv, X, Y, datetime)
  return(simulation_data)
}

# 3. get_edgelist ---------------------------------------------------------
# gets network graph
get_edgelist <- function(data, idCol, dateCol){
  if(is.data.frame(data))
    data <- data.table::setDT(data)
  timegroup_data <- spatsoc::group_times(data, datetime = dateCol, threshold = "10 minutes") # could be 4 minutes; see Window variable in matlab code
  spatsoc::edge_dist(timegroup_data, threshold = 14, id = idCol, coords = c('X','Y'), timegroup = "timegroup", returnDist = FALSE, fillNA = FALSE) # 14 units is twice mean step length of indivs
}

# 4. rotate_data_table ------------------------------------------------------------
# Note: this no longer actually takes a data_table, just keeping the name for consistency with previous.
# Unlike the previous function, this one requires that you separate the dates and times into separate columns beforehand.
rotate_data_table <- function(dataset, shiftMax, idCol = "indiv", dateCol = "date", timeCol = "time"){
  indivList <- dataset %>%
    group_by(.data[[idCol]]) %>%
    group_split(.keep = T)
  joined <- vector(mode = "list", length = length(indivList))
  for(indiv in 1:length(indivList)){
    x <- indivList[[indiv]]
    shift <- sample(-(shiftMax):shiftMax, size = 1)
    #cat(shift, "\n")
    # get all unique days that show up
    days <- sort(unique(x[[dateCol]]))
    
    # get min and max dates to shift around (the "poles" of the conveyor)
    selfMinDate <- min(days, na.rm = T)
    selfMaxDate <- max(days, na.rm = T)
    
    # create a total sequence of dates to select from
    daysFilled <- seq(lubridate::ymd(selfMinDate), lubridate::ymd(selfMaxDate), by = "day")
    # converting to numbers so we can use %%--which dates are the ones we started with?
    vec <- which(daysFilled %in% days)
    shiftedvec <- vec + shift # shift
    new <- (shiftedvec - min(vec)) %% (max(vec)-min(vec)+1)+1 # new dates as numbers
    shiftedDates <- daysFilled[new] # select those dates from the possibilities
    
    # Make a data frame to hold the old and new dates
    daysDF <- bind_cols({{dateCol}} := days, 
                        "newDate" = shiftedDates,
                        shift = shift)
    nw <- left_join(x, daysDF, by = dateCol)
    
    if(!is.null(timeCol)){
      nw$newdatetime <- lubridate::ymd_hms(paste(nw$newDate, nw[[timeCol]]))
    }
    joined[[indiv]] <- nw
  }
  out <- purrr::list_rbind(joined)
  return(out)
}

# 5. get_stats ------------------------------------------------------------
# get degree, mean sri, and strength per individual
get_stats <- function(edgelist, data, idCol){
  indivs <- unique(data[[idCol]])
  
  degree <- edgelist %>%
    dplyr::group_by(ID1) %>%
    dplyr::summarise(degree = n_distinct(ID2), .groups = "drop") # count distinct edges
  if(length(indivs[!(indivs %in% degree$ID1)]) > 0){
    toadd_d <- data.frame(ID1 = indivs[!(indivs %in% degree$ID1)], degree = 0)
    degree <- bind_rows(degree, toadd_d)
  }
  
  sri_per_edge <- calcSRI(dataset = data, edges = edgelist, idCol = "indiv", timegroupCol = "timegroup") # calculate SRI
  
  strength <- sri_per_edge %>% # get mean sri and strength
    dplyr::group_by(ID1) %>%
    dplyr::summarise(strength = sum(sri, na.rm = T), .groups = "drop")
  if(length(indivs[!(indivs %in% strength$ID1)]) > 0){
    toadd_s <- data.frame(ID1 = indivs[!(indivs %in% strength$ID1)], strength = 0)
    strength <- bind_rows(strength, toadd_s)
  }
  
  stats <- dplyr::inner_join(degree, strength, by=dplyr::join_by(ID1))
  return(stats)
}

# 6. mean_stats -----------------------------------------------------------
# gets the mean stats for the entire network graph, given a data frame of the network's stats from get_stats
mean_stats <- function(stats){
  mean_stats <- stats %>%
    dplyr::summarise(mean_associations = mean(associations), 
                     mean_degree = mean(degree), 
                     mean_sri = mean(mean_sri), 
                     mean_strength =mean(strength),
                     .groups = "drop")
  return(mean_stats)
}


# 7. get_realization_data -------------------------------------------------
# runs n realizations of the permutation method and returns stats per sim
get_realization_data <- function(simulation_data, n, quiet = F){ #XXXK: need to generalize idCol and dateCol, but I don't know how to do that with data.table.
  realization_data <- data.frame()
  time_to_rotate <- Sys.time()
  for(x in 1:n){
    if(quiet == FALSE){
      print(paste("Working on realization", x))
    }
    
    rotated_data <- rotate_data_table(simulation_data, idCol = "indiv", dateCol = "datetime") # rotate sim data
    rotated_edgelist <- get_edgelist(rotated_data, idCol = "indiv", dateCol = "datetime") # get edgelist of rotated data
    stats <- get_stats(rotated_edgelist) # get stats 
    average_stats <- mean_stats(stats)
    realization_data <- rbind(realization_data, average_stats) # record stats of all realizations
  }
  print(Sys.time() - time_to_rotate)
  return(realization_data)
}

# 8. calcSRI -----------------------------------------------------------------
# Calculate SRIs of edgelist
# XXX This is pasted in from vultureUtils for now because I was having trouble installing it. Need to fix that.
calcSRI <- function(dataset, edges, idCol = "Nili_id", timegroupCol = "timegroup", dateCol = "datetime"){
  if(!(timegroupCol %in% names(dataset))){
    if(is.data.frame(dataset))
      dataset <- data.table::setDT(dataset)
    dataset <- spatsoc::group_times(dataset, datetime = dateCol, threshold = "10 minutes")
  }
  
  # setup for time warning
  # cat("\nComputing SRI... this may take a while if your dataset is large.\n")
  start <- Sys.time()
  
  # arg checks
  checkmate::assertSubset(timegroupCol, names(dataset))
  checkmate::assertSubset(idCol, names(dataset))
  checkmate::assertDataFrame(dataset)
  checkmate::assertDataFrame(edges)
  
  edges <- dplyr::as_tibble(edges)
  
  ## get individuals per timegroup as a list
  # Info about timegroups and individuals, for SRI calculation
  timegroupsList <- dataset %>%
    dplyr::select(tidyselect::all_of(c(timegroupCol, idCol))) %>%
    dplyr::mutate({{idCol}} := as.character(.data[[idCol]])) %>%
    dplyr::distinct() %>%
    dplyr::group_by(.data[[timegroupCol]]) %>%
    dplyr::group_split() %>%
    purrr::map(~.x[[idCol]])
  
  ## get unique set of timegroups
  timegroups <- unique(dataset[[timegroupCol]])
  
  ## get all unique pairs of individuals
  inds <- as.character(unique(dataset[[idCol]]))
  allPairs <- expand.grid(ID1 = as.character(inds), ID2 = as.character(inds), stringsAsFactors = F) %>%
    dplyr::filter(ID1 < ID2)
  
  # wide data
  datasetWide <- dataset %>%
    sf::st_drop_geometry() %>%
    dplyr::select(tidyselect::all_of(c(timegroupCol, idCol))) %>%
    dplyr::distinct() %>%
    dplyr::mutate(val = TRUE) %>%
    tidyr::pivot_wider(id_cols = tidyselect::all_of(timegroupCol), names_from = tidyselect::all_of(idCol),
                       values_from = "val", values_fill = FALSE)
  
  ## get SRI information
  dfSRI <- purrr::pmap_dfr(allPairs, ~{
    a <- .x
    b <- .y
    colA <- datasetWide[,a]
    colB <- datasetWide[,b]
    nBoth <- sum(colA & colB)
    x <- nrow(unique(edges[edges$ID1 %in% c(a, b) & edges$ID2 %in% c(a, b), timegroupCol]))
    yab <- nBoth - x
    sri <- x/(x+yab)
    if(is.infinite(sri)){
      sri <- 0
    }
    dfRow <- data.frame("ID1" = a, "ID2" = b, "sri" = sri)
    return(dfRow)
  })
  
  # complete the time message
  end <- Sys.time()
  duration <- difftime(end, start, units = "secs")
  cat(paste0("SRI computation completed in ", round(duration, 3), " seconds.\n"))
  return(dfSRI)
}

# 9. get_tortuosity ------------------------------------------------------------
# Returns the tortuosity per individual path, given sim XY data
# Each row represents an individual
get_tortuosity <- function(data){
  tortuosity <- data.frame()
  for(i in unique(data$indiv)){
    i_points <- data[data$indiv == i, ]
    i_points_lead <- i_points
    i_points_lead <- i_points_lead %>%
      mutate(X = lead(i_points_lead$X, 1), Y = lead(i_points_lead$Y, 1))
    length <- proxy::dist(i_points[c("X", "Y")], i_points_lead[c("X", "Y")], method="Euclidean", by_rows=T) %>%
      diag() %>%
      sum(na.rm = T)
    end_points <- rbind(i_points[1, ], i_points[nrow(i_points), ])[c("X", "Y")]
    displacement <- proxy::dist(end_points, method="Euclidean", by_rows=T)
    i_tortuosity <- length / displacement
    tortuosity <- rbind(tortuosity, i_tortuosity)
  }
  colnames(tortuosity)[1] <- "Tortuosity"
  tortuosity
}


# Custom theme for ggplots ------------------------------------------------
library(extrafont)
theme_vulturePerm <- function(){ 
  font <- "Calibri"   #assign font family up front
  
  theme_minimal() %+replace%    #replace elements we want to change
    
    theme(
      
      #grid elements
      panel.grid.major = element_blank(),    #strip major gridlines
      panel.grid.minor = element_blank(),    #strip minor gridlines
      axis.ticks = element_blank(),          #strip axis ticks
      
      #since theme_minimal() already strips axis lines, 
      #we don't need to do that again
      
      #text elements
      plot.title = element_text(             #title
        family = font,            #set font family
        size = 20,                #set font size
        face = 'bold',            #bold typeface
        hjust = 0,                #left align
        vjust = 2),               #raise slightly
      
      plot.subtitle = element_text(          #subtitle
        family = font,            #font family
        size = 14),               #font size
      
      plot.caption = element_text(           #caption
        family = font,            #font family
        size = 9,                 #font size
        hjust = 1),               #right align
      
      axis.title = element_text(             #axis titles
        family = font,            #font family
        size = 10),               #font size
      
      axis.text = element_text(              #axis text
        family = font,            #axis famuly
        size = 9),                #font size
      
      axis.text.x = element_text(            #margin for axis text
        margin=margin(5, b = 10))
      
      #since the legend often requires manual tweaking 
      #based on plot content, don't define it here
    )
}

permutationColors <- c("#25496C", "#FF7F00") # Colors to distinguish random vs. conveyor permutations
snsColors <- c("darkolivegreen", "yellowgreen") # Colors to distinguish between non-social and social
# shiftColors # A continuous scale to illustrate the amount of shift. For now using the default ggplot2 scale
tencolors <- Polychrome::kelly.colors(13)[-1][-1][-7] # remove white and black and gray. Discrete colors for ten individuals
Polychrome::swatch(tencolors) # view the colors
continuousColors <- c("#00243C", "#50BAFF")

# Functions to calculate displacement and distance, taken from the --------
calc_displacements <- function(group) {
  start_point <- dplyr::first(group$geometry)
  group %>%
    dplyr::mutate(
      disp_from_start = as.vector(sf::st_distance(geometry, start_point)),
      dist_to_prev = as.vector(sf::st_distance(geometry, dplyr::lag(geometry, default = dplyr::first(geometry)), by_element = T))
    )
}

calc_metrics <- function(data){
  # split the data by Nili_id and dateOnly
  groups <- data %>%
    dplyr::group_split(Nili_id, dateOnly)
  
  # run the distance calculations
  disp_data <- purrr::map(groups, calc_displacements, .progress = TRUE) %>% 
    purrr::list_rbind()
  
  # group the data by Nili_id and dateOnly, and calculate the metrics
  result <- disp_data %>%
    sf::st_drop_geometry() %>%
    dplyr::group_by(Nili_id, dateOnly) %>%
    arrange(timestamp, .by_group = T) %>%
    mutate(csDist = cumsum(replace_na(dist_to_prev, 0))) %>%
    dplyr::summarize(
      dmd = max(disp_from_start, na.rm = T),
      dd = last(disp_from_start, na.rm = T),
      ddt = sum(dist_to_prev, na.rm = T)
    )
  return(result)
}
