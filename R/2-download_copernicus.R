# Downloads CMIP6 data from Copernicus (https://cds.climate.copernicus.eu/).
# Copernicus provides a Python package for accessing their API which allows for
# spatial cropping. This R script wraps their Python function and iterates it
# over the index of datasets needed generated in `build_index.R`.  Not all
# datasets are available, and even those available are not all successfully
# downloaded because of missing combinations of variables and scenarios.


# Load packages -----------------------------------------------------------
library(reticulate)
library(here)
library(tidyverse)
library(glue)
library(here)
use_virtualenv(here("r-reticulate"))

# Wrap python function to work in R
source_python(here("R", "download_cmip6.py"))
# Usage:
# download_cmip6(
#   experiment_id = "historical",
#   variable_long_name = "precipitation",
#   source_id = "awi_cm_1_1_mr",
#   path = "test.zip"
# )

# Read in index -----------------------------------------------------------
idx_raw <- read_csv(here("data_raw", "metadata", "cmip6_index.csv"))


# Summarize index ---------------------------------------------------------

#index has multiple entries for some combinations where data is spread across multiple files in ESGF
idx <- idx_raw %>%
  group_by(across(mip_era:variable_units)) %>% 
  summarize(datetime_start = min(datetime_start),
            datetime_end = max(datetime_end),
            file_size = sum(file_size),
            .groups = "drop")

# Set up query ------------------------------------------------------------
dl_df <- idx %>% 
  group_by(experiment_id, variable_long_name, variable_id, source_id) %>% 
  count() %>% #just a way of getting only unique values
  ungroup() %>% 
  select(-n) %>% 
  #match style used by API
  rename(variable_long_name0 = variable_long_name,
         source_id0 = source_id) %>% 
  mutate(variable_long_name = tolower(variable_long_name0) %>%
           str_replace_all("[-\\s]", "_"),
         source_id = tolower(source_id0) %>%
           str_replace_all("[-\\s]", "_") )%>% 
  # Create download paths and file names
  mutate(dir = here(
    "data_raw",
    experiment_id,
    source_id),
    file_name = glue("{variable_id}_{experiment_id}_{source_id}.zip"),
    path = here(dir, file_name))

# Models (source_id) available on Copernicus:
on_portal <- c("access_cm2", "access_esm1-5", "awi_cm-1-1-mr", "awi_esm-1-1-lr", 
           "bcc_csm2-mr", "bcc_esm1", "cams_csm1-0", "canesm5", "canesm5_canoe", 
           "cesm2", "cesm2_fv2", "cesm2_waccm", "cesm2_waccm-fv2", "ciesm", 
           "cmcc_cm2-hr4", "cmcc_cm2-sr5", "cmcc_esm2", "cnrm_cm6-1", "cnrm_cm6-1-hr", 
           "cnrm_esm2-1", "e3sm_1-0", "e3sm_1-1", "e3sm_1-1-eca", "ec_earth3", 
           "ec_earth3-aerchem", "ec_earth3-cc", "ec_earth3-veg", "ec_earth3-veg-lr", 
           "fgoals_f3-l", "fgoals_g3", "fio_esm-2-0", "gfdl_esm4", "giss_e2-1-g", 
           "giss_e2-1-h", "hadgem3_gc31-ll", "hadgem3_gc31-mm", "iitm_esm", 
           "inm_cm4-8", "inm_cm5-0", "ipsl_cm5a2-inca", "ipsl_cm6a-lr", 
           "kace_1-0-g", "kiost_esm", "mcm_ua-1-0", "miroc6", "miroc_es2h", 
           "miroc_es2l", "mpi_esm-1-2-ham", "mpi_esm1-2-hr", "mpi_esm1-2-lr", 
           "mri_esm2-0", "nesm3", "norcpm1", "noresm2_lm", "noresm2_mm", 
           "sam0_unicon", "taiesm1", "ukesm1_0-ll")

avail <- 
  dl_df %>%
  count(source_id) %>%
  filter(source_id %in% on_portal) %>% 
  pull(source_id)
# avail
# Only 9 of the models we are looking for are available through this portal

dl_avail <- 
  dl_df %>% 
  filter(source_id %in% avail)

# Create download directories ---------------------------------------------
dirs_to_make <- dl_avail$dir[!map_lgl(dl_avail$dir, dir.exists)]
walk(unique(dirs_to_make), ~dir.create(.x, recursive = TRUE))


# Download .zip files -----------------------------------------------------
safe_dl <- safely(download_cmip6) #make download function fail gracefully

dl_avail %>%
  select(experiment_id, variable_long_name, source_id, path) %>%
  filter(!file.exists(path)) %>% #only ones that haven't been downloaded yet
  pwalk(safe_dl)


# Extract .nc files -------------------------------------------------------
# I only need the .nc files in the .zip files.

dl_exists <- dl_avail %>% filter(file.exists(path))

walk2(dl_exists$path, dl_exists$dir, ~{
  file_nc <- 
    unzip(.x, list = TRUE) %>% 
    filter(str_detect(Name, "\\.nc$")) %>% 
    pull(Name)
  
  unzip(.x, files = file_nc, exdir = here(.y))
})


dl_remaining <- dl_df %>% filter(!file.exists(path))
dl_remaining %>% count(source_id)
# a few models are just missing a couple of files (variable x scenario), but others are missing entirely.
write_csv(dl_remaining, here("data_raw", "not_in_copernicus.csv"))
