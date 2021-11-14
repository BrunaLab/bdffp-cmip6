library(reticulate)
library(here)
library(tidyverse)
library(glue)
library(here)
use_virtualenv(here("r-reticulate"))

# Read in indexes
idx <- read_csv(here("data_raw", "metadata", "cmip6_index.csv"))

# Wrap python function to work in R
source_python(here("R", "download_cmip6.py"))


# download_cmip6(
#   experiment_id = "historical",
#   variable_long_name = "daily_maximum_near_surface_air_temperature",
#   source_id = "awi_cm_1_1_mr",
#   path = "/Users/scottericr/Documents/heliconia-cmip/data_raw/historical/awi_cm_1_1_mr/tasmax_historical_awi_cm_1_1_mr.zip"
# )

#some requests apparently take a lot longer than others

dl_df <- idx %>% 
  group_by(experiment_id, variable_long_name, variable_id, source_id) %>% 
  count() %>% #just a way of getting only unique values
  ungroup() %>% 
  select(-n) %>% 
  mutate(across(
    where(is.character),
    ~tolower(.x) %>% str_replace_all("[-\\s]", "_")
  )) %>% 
  mutate(dir = here(
    "data_raw",
    experiment_id,
    source_id),
    file_name = glue("{variable_id}_{experiment_id}_{source_id}.zip"),
    path = here(dir, file_name))

# View(dl_df)

#did we get the snakecase conversion right?

# dl_df %>% count(source_id) %>% View()

#available on portal:
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

avail <- dl_df %>% count(source_id) %>% filter(source_id %in% on_portal) %>% pull(source_id)
avail
dl_df <- dl_df %>% 
  filter(source_id %in% avail)
#shit, only 9 are actually available through this portal

dirs_to_make <- dl_df$dir[!map_lgl(dl_df$dir, dir.exists)]
walk(unique(dirs_to_make), ~dir.create(.x, recursive = TRUE))


dl_df %>%
  select(experiment_id, variable_long_name, source_id, path) %>%
  # head(2) %>% #for testing
  pwalk(download_cmip6)

#TODO: make download_cmip6 fail gracefully, only download files that don't already exist
