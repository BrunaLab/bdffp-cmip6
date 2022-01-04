library(epwshiftr)
library(tidyverse)
library(lubridate)
library(here)

hist <- esgf_query(
  activity = "CMIP",
  variable = c("tas", "tasmin", "tasmax", "pr", "hfss", "hfls"),
  experiment = "historical",
  frequency = "mon",
  source = NULL,
  resolution = NULL,
  type = "File"
) %>% #remove duplicated variables that appear in multiple "tables"
  group_by(source_id, variable_id) %>%
  filter(table_id == first(table_id)) %>% 
  ungroup()


hist_incomp <-
  hist %>% 
  group_by(source_id) %>% 
  summarize(n_var = length(unique(variable_id))) %>%  #should be 6
  filter(n_var != 6) %>%
  pull(source_id)

hist <- hist %>% 
  filter(!source_id %in% hist_incomp)

ssps <- esgf_query(
  activity = "ScenarioMIP",
  variable = c("tas", "tasmin", "tasmax", "pr", "hfss", "hfls"),
  experiment = c("ssp126", "ssp245", "ssp370", "ssp585"),
  frequency = "mon",
  source = NULL,
  resolution = NULL,
  type = "File"
) %>% #remove duplicated variables that appear in multiple "tables"
  group_by(experiment_id, source_id, variable_id) %>%
  filter(table_id == first(table_id)) %>%
  ungroup() %>%
  # some projections go to 2300.  Remove those files
  #TODO: double-check that all models that go to 2300 have a file that ends in 2100
  filter(datetime_end <= ymd("2100-12-01"))

ssps_incomp <-
  ssps %>% 
  group_by(source_id, experiment_id) %>% 
  summarize(n_var = length(unique(variable_id))) %>% #should be 6
  filter(n_var != 6)

ssps <- anti_join(ssps, ssps_incomp)

idx <- bind_rows(hist, ssps)

idx_incomp <-
  idx %>% 
  group_by(source_id) %>% 
  summarize(n_experiment = length(unique(experiment_id))) %>% 
  filter(n_experiment != 5) %>%  #require that all 5 experiments are present
  pull(source_id)

idx <-
  idx %>% 
  filter(!source_id %in% idx_incomp) %>% 
# Remove high res if duplicate resolutions
  filter(source_id != "EC-Earth3-Veg") %>% 
  filter(source_id != "MPI-ESM1-2-HR") %>% 
  filter(!(source_id == "FIO-ESM-2-0" & nominal_resolution == "10000 km"))
 #INM-CM4-8 and INM-CM5-0 might also be duplicates with different resolutions.  Can't tell yet from documentation.

unique(idx$source_id)
length(unique(idx$source_id))

#8 models with all the variables for both historical and projections

write_csv(idx, here("metadata", "cmip6_index.csv"))
