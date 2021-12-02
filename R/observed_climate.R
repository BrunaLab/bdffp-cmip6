#'Wrangling data from:
#'Xavier AC, King CW, Scanlon BR (2016) Daily gridded meteorological variables
#'in Brazil (1980–2013). International Journal of Climatology 36:2644–2659.
#'https://doi.org/10.1002/joc.4518
#'
#'Actual data available at https://utexas.app.box.com/v/Xavier-etal-IJOC-DATA/folder/40983701074
#'
#'TODO: If I want to plot average temperature, I'd need to load the daily data
#'and calculate it as the average of Tmin and Tmax, then aggregate monthly.
#'There is no monthly mean temp file and this is how it was done in the paper
#'
#'If I start with daily data for all, I can also make some nice boxplots that
#'show the range of values expected which would be good for comparing to the
#'CMIP6 timeseries plots.


# Load packages -----------------------------------------------------------

library(stars)
library(tidyverse)
library(here)
library(units)
library(lubridate)
library(patchwork)
theme_set(theme_bw())


# Read in files ------------------------------------------------------------

pr_mon <-
  read_stars(here("data_raw", "prec_monthly_UT_Brazil_v2_198001_201312.nc")) %>%
  st_set_crs("WGS84")
tmin_mon <- 
  read_stars(here("data_raw", "Tmin_monthly_UT_Brazil_v2_198001_201312.nc")) %>% 
  st_set_crs("WGS84")
tmax_mon <- 
  read_stars(here("data_raw", "Tmax_monthly_UT_Brazil_v2_198001_201312.nc")) %>%
  st_set_crs("WGS84")
#evapotranspiration calculated with Penman-Monteith method.
eto_mon <- 
  read_stars(here("data_raw", "ETo_monthly_UT_Brazil_v2_198001_201312.nc")) %>% 
  st_set_crs("WGS84")


# Combine variables -------------------------------------------------------

br_mon <-
  list(pr_mon, tmin_mon, tmax_mon, eto_mon) %>% 
  map(~select(.x, -count, -dist_nearest)) %>% 
  do.call(c, .)

# Aggregate spatially ----------------------------------------------

circle <-
  st_point(c(-59.833, -2.41)) %>% 
  st_sfc() %>%
  st_set_crs("WGS84") %>% 
  st_buffer(units::set_units(200, "km")) %>% 
  st_sfc()

# ggplot() +
#   geom_stars(data = br_mon[3,,,1]) +
#   geom_sf(data = circle, fill = NA, color = "red")

br_tbl <-
  aggregate(br_mon, by = circle, FUN = mean, join = st_intersects, exact = FALSE) %>% 
  #exact = TRUE doesn't work for some reason
  as_tibble() %>% 
  mutate(month = month(time), .after = time) %>% 
  group_by(month) %>% 
  summarize(across(c(prec, Tmin, Tmax), ~as.numeric(mean(.x)), .names = "mean_{.col}")) 


# Plots -------------------------------------------------------------------

br_prec <- 
  br_tbl %>% 
  ggplot(aes(x = month, y = mean_prec)) + 
  geom_col(fill = "blue") +
  scale_x_continuous("", breaks = 1:12, labels = ~month(.x, label = TRUE)) +
  labs(y = "mean pr (mm)")
# br_prec

br_temp <- 
  br_tbl %>% 
  ggplot(aes(x = month, ymin = mean_Tmin, ymax = mean_Tmax)) +
  geom_ribbon(fill = "red", alpha = 0.5) +
  scale_x_continuous("", breaks = 1:12, labels = ~month(.x, label = TRUE)) +
  labs(y = "mean tas (ºC)")
# br_temp

season_plot <- 
  br_prec/br_temp +
  plot_annotation(title = "Observed", subtitle = "1980–2013")


# Save plot ------------------------------------------------------

ggsave(here("fig", "observed_seasonality.png"), season_plot, width = 5, height = 4)

