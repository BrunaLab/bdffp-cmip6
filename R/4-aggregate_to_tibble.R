# Converts .nc files to tibble with data aggregated over a 200km radius around the rough center of BDFFP


# Load Packages -----------------------------------------------------------

library(tidyverse)
library(stars)
library(PCICt)
library(exactextractr)
library(here)
library(units)
library(lubridate)


# Create 200km radius -----------------------------------------------------

circle <-
  st_point(c(-59.833, -2.41)) %>% 
  st_sfc() %>%
  st_set_crs("WGS84") %>% 
  st_buffer(units::set_units(200, "km")) %>% 
  st_sfc()


# Functions ---------------------------------------------------------------

# read_stars() but return NULL instead of erroring
safe_read_stars <- possibly(read_stars, NULL)

## Lowest level (source x scenario) ----------------------------------------

# read in files for a single source and scenario (e.g. accesss_cm2 historical)
read_stars_scenario <- function(dir) {
  message(paste("reading files in", dir))
  scenario_files <- list.files(dir, pattern = ".nc$", full.names = TRUE)
  #extract variable names from file names
  vars <- unique(str_extract(scenario_files, "([^/]*)$") %>% str_extract("[^_]*(?=_)"))
  map(paste0(vars, "_"), ~scenario_files[str_detect(scenario_files, .x)]) %>%
    set_names(vars) %>% 
    safe_read_stars(proxy = FALSE)
}

# for a single scenario, aggregate a stars object and convert to a tibble, do some wrangling.
agg_to_tibble <- function(stars_scenario, by) {
  stars_scenario %>% 
    st_set_crs("WGS84") %>% 
    aggregate(by = circle, FUN = mean, join = st_intersects, exact = TRUE) %>% 
    as_tibble() %>% 
    dplyr::select(-sfc) %>%
    mutate(time = as.POSIXct(time)) %>% 
    #extract short variable names to replace long ones
    rename_with(~str_extract(.x,"^\\w+(?=\\.)"), .cols = -time)
}


## Low level (source) ------------------------------------------------------

# read in .nc files, aggregate spatially, combine all scenarios into a tibble, and write to .csv file.
aggregate_write <- function(source_id, by) {
  dirs_to_map <- dir(here("data_raw", "CMIP6", source_id), full.names = TRUE)
  out_df <-
    dirs_to_map %>% 
    map(read_stars_scenario) %>% 
    set_names(dirs_to_map) %>% 
    compact() %>% #removes any NULLs
    map_df(~agg_to_tibble(.x, by = by), .id = "dir") %>% 
    mutate(source_id = str_match(dir, "/([^/]+)/([^/]+)$" )[,2],
           experiment_id = str_match(dir, "/([^/]+)/([^/]+)$")[,3],
           .after = dir) %>% 
    select(-dir)
  out_path <- here("data", paste(source_id, "data.csv", sep = "_"))
  message(paste("writing to", out_path))
  write_csv(out_df, out_path)
}
# E.g.:
# aggregate_write("canesm5", by = circle)


# Convert all data --------------------------------------------------------

# do the aggregate_write() function for all sources

sources <- dir(here::here("data_raw", "CMIP6"))
walk(sources, ~aggregate_write(.x, by = circle))
