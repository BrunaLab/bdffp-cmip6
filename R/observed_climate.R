#'Wrangling data from:
#'Xavier AC, King CW, Scanlon BR (2016) Daily gridded meteorological variables
#'in Brazil (1980–2013). International Journal of Climatology 36:2644–2659.
#'https://doi.org/10.1002/joc.4518
#'
#'Actual data available at https://utexas.app.box.com/v/Xavier-etal-IJOC-DATA/folder/4247252285
#'
#'Files downloaded into data_raw/:
#' - ETo_daily_UT_Brazil_v2_19800101_19891231.nc
#' - ETo_daily_UT_Brazil_v2_19900101_19991231.nc
#' - ETo_daily_UT_Brazil_v2_20000101_20061231.nc
#' - ETo_daily_UT_Brazil_v2_20070101_20131231.nc
#' - ETo_daily_UT_Brazil_v2_20140101_20170731_s1.nc
#' - prec_daily_UT_Brazil_v2.2_19800101_19891231.nc
#' - prec_daily_UT_Brazil_v2.2_19900101_19991231.nc
#' - prec_daily_UT_Brazil_v2.2_20000101_20091231.nc
#' - prec_daily_UT_Brazil_v2.2_20100101_20151231.nc
#' - Tmax_daily_UT_Brazil_v2_19800101_19891231.nc
#' - Tmax_daily_UT_Brazil_v2_19900101_19991231.nc
#' - Tmax_daily_UT_Brazil_v2_20000101_20061231.nc
#' - Tmax_daily_UT_Brazil_v2_20070101_20131231.nc
#' - Tmax_daily_UT_Brazil_v2_20140101_20170731_s1.nc
#' - Tmin_daily_UT_Brazil_v2_19800101_19891231.nc
#' - Tmin_daily_UT_Brazil_v2_19900101_19991231.nc
#' - Tmin_daily_UT_Brazil_v2_20000101_20061231.nc
#' - Tmin_daily_UT_Brazil_v2_20070101_20131231.nc
#' - Tmin_daily_UT_Brazil_v2_20140101_20170731_s1.nc

# Load packages -----------------------------------------------------------

library(ClimateOperators)
library(stars)
library(tidyverse)
library(here)
library(units)
library(lubridate)
library(patchwork)
library(tsibble)
library(ggforce)
theme_set(theme_bw())

# Crop files --------------------------------------------------------------
# cropping files to rough area of BDFFP before reading in will make everything a lot faster
all_files <-
  list.files(here("data_raw", "Xavier"), pattern = "daily_.+nc$")

infile <- here("data_raw", "Xavier", all_files)
outfile <- here("data_raw", "Xavier", "cropped", all_files)
walk2(infile, outfile, ~cdo("-sellonlatbox,-65,-50,-5,0", .x, .y))

# Read in files ------------------------------------------------------------

pr_day <-
  read_stars(list.files(
    here("data_raw", "Xavier", "cropped"),
    pattern = "prec_",
    full.names = TRUE
  ), proxy = FALSE)
tasmin_day <-
  read_stars(list.files(
    here("data_raw", "Xavier", "cropped"),
    pattern = "Tmin_",
    full.names = TRUE
  ), proxy = FALSE)
tasmax_day <-
  read_stars(list.files(
    here("data_raw", "Xavier", "cropped"),
    pattern = "Tmax_",
    full.names = TRUE
  ), proxy = FALSE)
eto_day <-
  read_stars(list.files(
    here("data_raw", "Xavier", "cropped"),
    pattern = "ETo_",
    full.names = TRUE
  ), proxy = FALSE)


#precip has shorter time dimension, and different format (ymd_hms)
tasmin_day <- tasmin_day[,,,1:13149]
tasmax_day <- tasmax_day[,,,1:13149]
eto_day    <- eto_day[,,,1:13149]

st_dimensions(tasmax_day) <- st_dimensions(pr_day)
st_dimensions(tasmin_day) <- st_dimensions(pr_day)
st_dimensions(eto_day) <- st_dimensions(pr_day)
# combine and set CRS
br_day <- 
  c(pr_day, tasmin_day, tasmax_day, eto_day) %>%
  st_set_crs("WGS84")

rm(pr_day, tasmin_day, tasmax_day, eto_day)
# set attribute names
names(br_day) <- c("pr", "tasmin", "tasmax", "eto")

# calculate mean temperature as mean of tmin and tmax as done in Xavier et al.
br_day <-
  br_day %>%
  mutate(across(c(tasmin, tasmax), ~set_units(.x, "degC"))) %>%
  mutate(tas = (tasmin+tasmax)/2)

# Aggregate spatially ----------------------------------------------

circle <-
  st_point(c(-59.833, -2.41)) %>% 
  st_sfc() %>%
  st_set_crs("WGS84") %>% 
  st_buffer(units::set_units(200, "km")) %>% 
  st_sfc()

ggplot() +
  geom_stars(data = br_day[1,,,1]) +
  geom_sf(data = circle, fill = NA, color = "red")


br_agg <- 
  br_day %>% 
  aggregate(
    by = circle,
    FUN = mean,
    join = st_intersects,
    exact = FALSE
  )


# Aggregate monthly -------------------------------------------------------

#I could do this with aggregate() but then all variables are aggregated with the same function.  I want monthly total precip (sum) and average temperatures (mean), so I'll do it with dplyr.

br_tbl <-
  br_agg %>%
  as_tibble() %>%
  dplyr::select(-geometry) %>%
  mutate(yearmonth = yearmonth(time), .after = time) %>%
  group_by(yearmonth) %>%
  summarize(across(c(pr, eto), sum), across(starts_with("tas"), mean)) %>%
  #fix units for pr and eto
  mutate(across(c(pr, eto), ~ as_units(as.numeric(.x), "mm/month")))

br_tbl_monthly <- 
  br_tbl %>% 
  mutate(month = month(yearmonth)) %>% 
  group_by(month) %>% 
  summarize(across(c(pr, eto, starts_with("tas")), mean))

# Plots -------------------------------------------------------------------

br_prec <-
  br_tbl_monthly %>%
  ggplot(aes(x = month, y = pr)) +
  geom_col(fill = "blue") +
  scale_x_continuous("",
                     breaks = 1:12,
                     labels = ~ month(.x, label = TRUE))
br_prec

br_temp <- 
  br_tbl_monthly %>% 
  ggplot(aes(x = month)) +
  geom_ribbon(aes(ymin = tasmin, ymax = tasmax),
              fill = "red",
              alpha = 0.5) +
  geom_line(aes(y = tas), color = "red") +
  scale_x_continuous("",
                     breaks = 1:12,
                     labels = ~ month(.x, label = TRUE))
br_temp

season_plot <- 
  br_prec/br_temp +
  plot_annotation(title = "Observed", subtitle = "1980–2015")


# Save plot and data ------------------------------------------------------
write_csv(br_tbl, here("data", "xavier_aggregated.csv"))
ggsave(here("fig", "observed_seasonality.png"),
       season_plot, width = 5, height = 4)

