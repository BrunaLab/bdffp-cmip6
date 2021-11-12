library(tidyverse)
library(glue)
library(here)


# Read in indexes
idx_ssps <- read_csv(here("data_raw", "metadata", "idx_ssps.csv"))
idx_historical <- read_csv(here("data_raw", "metadata", "idx_hist.csv"))

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
fails <- tibble(url = NA, path = NA)
for (i in 1:30) {
  x <- try(download.file(url = dl_url[i], destfile = dl_dest[i]))
  if(inherits(x, "try-error")) {
    fails <- fails %>% add_row(url = dl_url[i], path = dl_dest[i])
  }
  Sys.sleep(3)
}
write_csv(fails %>% filter(!is.na(path)), here("data_raw", "failed_downloads.csv"))

#404
download.file(url = dl_url[1], destfile = dl_dest[1])

#hangs, but no 404
download.file(url = dl_url[10], destfile = dl_dest[10])


#with httr
library(httr)