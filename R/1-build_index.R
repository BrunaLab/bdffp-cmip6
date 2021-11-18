library(epwshiftr)
library(tidyverse)
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


hist_incomp <- hist %>% 
  group_by(source_id) %>% 
  summarize(n_var = length(unique(variable_id))) %>%  #should be 6
  filter(n_var != 6) %>% 
  pull(source_id)

hist <- hist %>% 
  filter(!source_id %in% hist_incomp)

ssps <- esgf_query(
  activity = "ScenarioMIP",
  variable = c("tas", "tasmin", "tasmax", "pr", "hfss", "hfls"),
  experiment = c("ssp126", "ssp245", "ssp585"),
  frequency = "mon",
  source = NULL,
  resolution = NULL,
  type = "File"
) %>% #remove duplicated variables that appear in multiple "tables"
  group_by(experiment_id, source_id, variable_id) %>%
  filter(table_id == first(table_id)) %>% ungroup()

ssps_incomp <- 
  ssps %>% 
  group_by(source_id, experiment_id) %>% 
  summarize(n_var = length(unique(variable_id))) %>%  
  summarize(n_var = sum(n_var)) %>%  #should be 6*3 = 18
  filter(n_var != 18) %>% 
  pull(source_id)

ssps <- ssps %>% 
  filter(!source_id %in% ssps_incomp)


idx <- bind_rows(hist, ssps)

idx_incomp <-
  idx %>% 
  group_by(source_id, experiment_id) %>% 
  summarize(n_var = length(unique(variable_id))) %>% 
  summarize(n_var = sum(n_var)) %>%   #should be 24
  filter(n_var != 24) %>% 
  pull(source_id)

idx <- idx %>% 
  filter(!source_id %in% idx_incomp)

unique(idx$source_id)


#21 models with all the variables for both historical and projections

write_csv(idx, here("data_raw", "metadata", "cmip6_index.csv"))
