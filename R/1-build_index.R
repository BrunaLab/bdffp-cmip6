library(epwshiftr)
library(tidyverse)
library(lubridate)
library(here)


# historical experiment is separate query ---------------------------------
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



# SSPs query --------------------------------------------------------------
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



# Combine -----------------------------------------------------------------
idx <- bind_rows(hist, ssps)


# Filter out sources missing data or scenarios ----------------------------
dl <- 
  idx %>% 
  select(source_id, experiment_id, variable_id, file_size)

full_table <-
  expand_grid(
    source_id = unique(dl$source_id),
    experiment_id = c("historical" , "ssp126", "ssp245", "ssp370", "ssp585"),
    variable_id = c("tas", "pr", "hfss", "hfls") 
    #don't actually need tasmin and tasmax for calculations
  )

complete <-
  left_join(full_table, dl) %>% 
  mutate(exists = case_when(file_size > 0 ~ TRUE,
                            TRUE ~ FALSE))

complete_sources <- 
  complete %>% 
  group_by(source_id) %>% 
  filter(all(exists)) %>% 
  pull(source_id) %>% 
  unique()

idx <-
  idx %>% 
  filter(source_id %in% complete_sources) %>% 
# Remove high res if duplicate resolutions
  filter(source_id != "EC-Earth3-Veg") %>% 
  filter(source_id != "MPI-ESM1-2-HR") %>% 
  filter(!(source_id == "FIO-ESM-2-0" & nominal_resolution == "10000 km"))
 #INM-CM4-8 and INM-CM5-0 might also be duplicates with different resolutions.  Can't tell yet from documentation.

# Write to .csv -----------------------------------------------------------

unique(idx$source_id)
length(unique(idx$source_id))

write_csv(idx, here("metadata", "cmip6_index.csv"))
