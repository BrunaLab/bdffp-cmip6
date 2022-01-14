library(tidyverse)
library(units)
library(SPEI)

convert_units <- function(x) {
  water_density <- as_units(1000, "kg m-3")
  x  %>% 
    #set units
    mutate(across(c(hfls, hfss), ~set_units(.x, "W m-2")),
           across(starts_with("tas"), ~set_units(.x, "K")),
           pr = set_units(pr, "kg m-2 s-1")) %>% 
    #do unit conversions
    mutate(across(starts_with("tas"), ~set_units(.x, "degC")),
           d_per_mon = days_in_month(month(time)) %>% set_units("d/month"), 
           pr = set_units((pr/water_density), "mm/d") * d_per_mon) %>% 
    dplyr::select(-d_per_mon)
}


pet_energy_only <- function(hfls, hfss, tas) {
  water_density <- as_units(1000, "kg m-3")
  #latent heat of vaporization of water at temp T
  tas <- set_units(tas, "degC") #just checks that units are in ºC
  Lv <- (2.501 - 0.002361 * as.numeric(tas)) %>% set_units("MJ/kg")
  hfls_mmd <- (hfls / Lv / water_density) %>% set_units("mm/day")
  hfss_mmd <- (hfss / Lv / water_density) %>% set_units("mm/day")
  #PET
  0.8 * (hfls_mmd + hfss_mmd)
}


# For each scenario, need a timeseries including "historical".  Then calc SPEI using historical as reference period, and re-join into one dataset.  Might be a better workflow for this with grouping or something.

calc_spei <- function(x, scale = 3, ref_period = c("observed", "historical")){
  ref_period <- match.arg(ref_period)
  if (ref_period == "observed") {
    ref_start <- c(1980, 4)
    ref_end <- c(2014, 12) #not quite the end, but doesn't overlap with ssp projections
  } else {
    ref_start <- c(1850, 1)
    ref_end <- c(2014, 12)
  }
  
  #split into three dfs and calculate spei
  spei_done <-
    c("ssp126", "ssp245", "ssp585") %>% 
    map(~ x %>% filter(experiment_id %in% c("historical", .x)) %>% arrange(time)) %>% 
    map(~ .x %>%
          mutate(spei = as.numeric(
            spei(
              ts(cb, freq = 12, start = c(year(min(time)), month(min(time)))),
              scale = scale,
              ref.start = ref_start,
              ref.end = ref_end
            )$fitted
          )))
  
  #recombine and deduplicate historical
  bind_rows(spei_done) %>% distinct()
}

#Calculate drought duration as number of consecutive months with SPEI <= -1
calc_drought_duration <- function(tbl) {
  drought_lens <- 
    tbl %>% 
    filter(!is.na(spei)) %>% 
    pull(spei) %>% 
    drought_lens()
  
  tibble(
    mean_n_mon = mean(drought_lens),
    sd_n_mon = sd(drought_lens),
    n_droughts = length(drought_lens)
  )
}

drought_lens <- function(spei) {
  test <- spei <= -1
  x <- numeric(length = length(spei))
  for (i in seq_len(length(spei))) {
    if(i == 1){
      prev <- 0
    } else {
      prev <- x[i-1]
    }
    if(isTRUE(test[i])) { #if a drought month, increment
      x[i] <- prev + 1
    } else { #otherwise, reset counter to 0
      x[i] <- 0
    }
  }
  x<-x[lead(x)==0 & x != 0] #just get the last value for every month
  x[!is.na(x)] #remove NA at the end if it's still a drought
}

