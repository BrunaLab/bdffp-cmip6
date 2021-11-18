# Converts .nc files to tibble with data aggregated over a 200km radius around the rough center of BDFFP


# Load Packages -----------------------------------------------------------

library(tidyverse)
library(stars)
library(here)
library(units)
library(lubridate)

# Read in .nc files -------------------------------------------------------

files <- list.files(here("data_raw", "ssp126", "access_cm2"), pattern = ".nc", full.names = TRUE)

scenarios <- list.dirs(here("data_raw"), recursive = FALSE, full.names = FALSE)
scenarios <- scenarios[scenarios != "metadata"]

dirs_to_map <- dir(here("data_raw", scenarios), full.names = TRUE)

#return NA in case of error (e.g. due to empty directory)
safe_read_stars <- possibly(read_stars, otherwise = NULL)

stars_list <- 
  dirs_to_map %>%
  map(~list.files(.x, pattern = ".nc$", full.names = TRUE)) %>% 
  map(possibly(read_stars, NULL)) %>%
  # name objects by path
  set_names(dirs_to_map) %>% 
  # remove errors (e.g. no files in directory)
  compact() %>% 
  map(
    ~.x %>%
      # set crs
      st_set_crs("WGS84") %>% 
      # fix variable names using first part of filename
      set_names(str_extract(names(.x), "^[:alpha:]+(?=_)"))
    )

# stars_list

# Create 200km radius -----------------------------------------------------

circle <-
  st_point(c(-59.833, -2.41)) %>% 
  st_sfc() %>%
  st_set_crs("WGS84") %>% 
  st_buffer(units::set_units(200, "km")) %>% 
  st_sfc()


# Aggregate ---------------------------------------------------------------
# aggregate spatially over area of circle.  exact=TRUE weights pixels that are
# only partially inside the circle to get a weighted average (I think).

stars_agg <-
  map(stars_list, ~{
    aggregate(
      .x,
      circle,
      FUN = mean,
      join = st_intersects,
      exact = TRUE
    )
  })

# Convert to tibble -------------------------------------------------------
#TODO: put units back.  For some reason aggregating strips units?
out <- 
  stars_agg %>% 
  map_df(~as_tibble(.x) %>%
           select(-sfc) %>%
           mutate(time = as.POSIXct(time)),
         .id = "filepath")
# nrow(out)

# out$filepath[1:5] %>% str_split("/")

#columns for model and scenario from the file paths
out <- out %>% 
  mutate(source_id = str_split(filepath, "/", simplify = TRUE)[,8],
         experiment_id = str_split(filepath, "/", simplify = TRUE)[,7])

# out %>% 
#   group_by(source_id, experiment_id) %>% 
#   summarise(start_time = min(time), end_time = max(time))

#some go out to 2300, but all go to 2100
out <- out %>% filter(time <= ymd_hms("2100-12-16 12:00:00"))

ggplot(out, aes(x = time, y = tas, color = scenario)) +
  geom_line(alpha = 0.5) +
  geom_smooth() +
  facet_wrap(~model) 
