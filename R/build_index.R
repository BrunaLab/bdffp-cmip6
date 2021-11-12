library(tidyverse)
library(glue)
library(epwshiftr)
library(lubridate)
library(here)

add_paths <- function(idx){
  idx %>% 
    mutate(download_dir = here("data_raw", experiment_id, source_id),
           file_name = glue("{variable_id}_{experiment_id}_{source_id}_{datetime_start}_{datetime_end}.nc"),
           full_path = here(download_dir, file_name))
}

#build CMIP6 data indexes
#historical
idx_historical <- 
  init_cmip6_index(
    activity = "CMIP",
    variable = c("tas", "tasmin", "tasmax", "pr", "hfss", "hfls"),
    frequency = "mon",
    experiment = "historical",
    variant = "r1i1p1f1"
  ) %>% 
  filter(source_id != "CESM2") %>% #doesn't have SSP data
  add_paths() %>% 
  filter(!duplicated(full_path)) %>%  #some files are in multiple "tables", this removes duplicates.
  write_csv(here("data_raw", "metadata", "idx_hist.csv"))

#ssps
idx_ssps <-
  init_cmip6_index(
    activity = "ScenarioMIP",
    variable = c("tas", "tasmin", "tasmax", "pr", "hfss", "hfls"),
    frequency = "mon",
    experiment = c("ssp126", "ssp245", "ssp585"),
    variant = "r1i1p1f1"
  ) %>%
  filter(datetime_end <= ymd("2100-12-01")) %>% 
  add_paths() %>% 
  filter(!duplicated(full_path)) %>%  #some files are in multiple "tables", this removes duplicates.
  write_csv(here("data_raw", "metadata", "idx_ssps.csv"))
