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

# Build directories

dirs <- c(unique(idx_ssps$download_dir), unique(idx_historical$download_dir))
dirs_to_make <- dirs[!map_lgl(dirs, dir.exists)]
map(dirs_to_make, ~dir.create(.x, recursive = TRUE))

# Download files

to_get <- bind_rows(idx_ssps %>% select(file_url, full_path, file_size),
                    idx_historical %>% select(file_url, full_path, file_size)) %>% 
  filter(!file.exists(full_path))

dl_url <- to_get$file_url
dl_dest <- to_get$full_path

if (any(duplicated(dl_url)) | any(duplicated(dl_dest))) {
  stop("duplicated download file paths.  Check file names")
}
size_GB <- sum(to_get$file_size) * 9.31e-10

print(glue("downloading {length(dl_url)} files totaling {round(size_GB,2)}GB"))


# for (i in 1:length(dl_url)) {
for (i in 1:30) {
  download.file(url = dl_url[i], destfile = dl_dest[i])
}
