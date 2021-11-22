
# Load packages -----------------------------------------------------------

library(epwshiftr)
library(tidyverse)
library(here)
library(glue)
library(httr)
library(ClimateOperators)

# Read data ---------------------------------------------------------------

not_in_copernicus <- read_csv(here("metadata", "not_in_copernicus.csv"))
idx <- read_csv(here("metadata", "cmip6_index.csv"))

# Find files that still need to be downloaded -----------------------------

esgf_dl <-
  right_join(idx, not_in_copernicus, 
             by = c("source_id" = "source_id0", "experiment_id", "variable_id"))

# some combos are 1 file per, some are up to 165 files per (1 per year)
esgf_dl %>% 
  count(source_id, experiment_id, variable_id) %>% filter(n!=1)


# Create download directories ---------------------------------------------
dirs_to_make <- esgf_dl$dir[!map_lgl(esgf_dl$dir, dir.exists)]
walk(unique(dirs_to_make), ~dir.create(.x, recursive = TRUE))


# Download files ----------------------------------------------------------
# first, fix path to be .nc and to account for multiple files

esgf_dl <-
  esgf_dl %>% 
  mutate(
    file_name = glue(
      "{variable_id}_{experiment_id}_{source_id}_{datetime_start}--{datetime_end}.nc"
    ),
    path = here(dir, file_name)
  )

#check if any files exist already

to_get <- esgf_dl %>% filter(!file.exists(path))

# Loop through files to download slowly so IP doesn't get banned.  This loop also crops files spatially as they are read in, so they are the same extent as those downloaded from Copernicus.
safe_GET <- possibly(GET, NULL)
for(i in 1:nrow(to_get)) {
  print(glue("downloading {to_get$file_name[i]}: {i} of {nrow(to_get)}"))
  orig <- to_get$path[i]
  dl_path <- paste0(orig, "_full")
  y <- safe_GET(to_get$file_url[i], write_disk(dl_path), timeout(60))
  if (is.null(y)) {
    warning("Timeout reached (probably)")
    file.remove(dl_path)
  } else if (!http_error(y)) {
    #crop file and delete original
    cdo("-sellonlatbox,-65,-50,-5,0", dl_path, orig)
    file.remove(dl_path)
    print("Success!")
  } else {
    warn_for_status(y)
  }
  Sys.sleep(1.5)
}
failed <- esgf_dl %>% filter(!file.exists(path))
write_csv(failed, here("data_raw", "esgf_dl_failed.csv"))

# failed %>% 
#   group_by(source_id, experiment_id) %>% 
#   summarize(n_var_missing = length(unique(variable_id))) %>% View()
