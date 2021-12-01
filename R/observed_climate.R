#'Wrangling data from:
#'Xavier AC, King CW, Scanlon BR (2016) Daily gridded meteorological variables
#'in Brazil (1980–2013). International Journal of Climatology 36:2644–2659.
#'https://doi.org/10.1002/joc.4518
#'
#'Actual data available at https://utexas.app.box.com/v/Xavier-etal-IJOC-DATA/folder/40983701074
#'


# Load packages -----------------------------------------------------------

library(stars)
library(tidyverse)
library(here)
library(units)


# Read in files ------------------------------------------------------------

pr_mon <- read_stars(here("data_raw", "prec_monthly_UT_Brazil_v2_198001_201312.nc")) %>% st_set_crs("WGS84")
tmin_mon <- read_stars(here("data_raw", "Tmin_monthly_UT_Brazil_v1_198001_201312.nc"))
#evapotranspiration calculated with Penman-Monteith method.
eto_mon <- read_stars(here("data_raw", "ETo_monthly_UT_Brazil_v1_198001_201312.nc"))


# Aggregate spatially ----------------------------------------------

circle <-
  st_point(c(-59.833, -2.41)) %>% 
  st_sfc() %>%
  st_set_crs("WGS84") %>% 
  st_buffer(units::set_units(200, "km")) %>% 
  st_sfc()

ggplot() +
  geom_stars(data = pr_mon[,,,13]) +
  geom_sf(data = circle, fill = NA, color = "red")

pr_tbl <-
  aggregate(pr_mon, by = circle, FUN = mean, join = st_intersects, exact = FALSE) %>% #exact = TRUE doesn't work for some reason
  as_tibble() 

pr_tbl %>% 
  mutate(month = month(time), .after = time) %>% 
  group_by(month) %>% 
  summarize(mean_pr = as.numeric(mean(prec))) %>% 
  ggplot(aes(x = month, y = mean_pr)) + geom_col(fill = "blue")
