hist <- esgf_query(
  activity = "CMIP",
  variable = c("tas", "tasmin", "tasmax", "pr", "hfss", "hfls"),
  experiment = "historical",
  frequency = "mon",
  source = NULL,
  resolution = NULL
) %>% #remove duplicated variables that appear in multiple "tables"
  group_by(source_id, variable_id) %>%
  slice(1) %>% ungroup()

hist_incomp <- 
  count(hist, source_id) %>% #should be 6
  filter(n !=6) %>%
  pull(source_id) 

hist <- hist %>% 
  filter(!source_id %in% hist_incomp)

ssps <- esgf_query(
  activity = "ScenarioMIP",
  variable = c("tas", "tasmin", "tasmax", "pr", "hfss", "hfls"),
  experiment = c("ssp126", "ssp245", "ssp585"),
  frequency = "mon",
  source = NULL,
  resolution = NULL
) %>% #remove duplicated variables that appear in multiple "tables"
  group_by(experiment_id, source_id, variable_id) %>%
  slice(1) %>% ungroup()

ssps_incomp <- 
  count(ssps, source_id) %>% #should be 6*3 = 18
  filter(n !=18) %>%
  pull(source_id) 

ssps <- ssps %>% 
  filter(!source_id %in% ssps_incomp)


idx <- bind_rows(hist, ssps)
idx_incomp <-
  count(idx, source_id) %>%  #should be 24
  filter(n != 24) %>% 
  pull(source_id)

idx <- idx %>% 
  filter(!source_id %in% idx_incomp)

idx %>% count(source_id)


#11 models with all the variables for both historical and projections

write_csv(idx, here("data_raw", "metadata", "cmip6_index.csv"))
