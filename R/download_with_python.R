library(reticulate)
library(here)
library(tidyverse)
library(glue)
library(here)
library(snakecase)

# Read in indexes
idx_ssps <- read_csv(here("data_raw", "metadata", "idx_ssps.csv"))
idx_historical <- read_csv(here("data_raw", "metadata", "idx_hist.csv"))

# Wrap python function to work in R
source_python(here("R", "download_cmip6.py"))


download_cmip6(
  experiment = "historical",
  variable = "precipitation",
  model = "mri_esm2_0",
  path = here("data_raw", "test.zip")
)


idx_historical %>%
  group_by(experiment_id, variable_long_name, variable_id, source_id) %>% 
  count() %>% #just a way of getting only unique values
  ungroup() %>% 
  select(-n) %>% 
  mutate(across(where(is.character), to_snake_case))

#now, make new download path column, then map download_cmip6() function across those rows.

