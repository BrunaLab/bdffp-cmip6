
# Load packages -----------------------------------------------------------

library(epwshiftr)
library(tidyverse)


# Read data ---------------------------------------------------------------

not_in_copernicus <- read_csv(here("data_raw", "not_in_copernicus.csv"))

# Find files that still need to be downloaded -----------------------------

#wrap function to include defaults and absorb extra arguments so it works with pwalk()
build_index <- function(activity, variable_id, experiment_id, source_id, ...) {
  esgf_query(
    activity = activity,
    variable = variable_id,
    experiment = experiment_id,
    frequency = "mon",
    source = source_id,
    resolution = NULL,
    type = "File"
  )
}

esgf_query(
  activity = "CMIP",
  variable = "pr",
  experiment = "historical",
  frequency = "mon",
  source = "CIESM",
  resolution = NULL,
  type = "File"
)


dl_remaining <-
  not_in_copernicus %>% 
  count(experiment_id, variable_id, source_id) %>% 
  mutate(activity = if_else(experiment_id == "historical", "CMIP", "ScenarioMIP")) %>%
  pmap_df(build_index)


