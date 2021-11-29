
<!-- README.md is generated from README.Rmd. Please edit that file -->

# heliconia-cmip

<!-- badges: start -->
<!-- badges: end -->

The goal of heliconia-cmip is to download, crop, and spatially aggregate
historical and projected climate data from CMIP6 models for an area
centered around the Biological Dynamics of Forest Fragments Project
(BDFFP).

# Data sources

Original data were downloaded from two sources: The Copernicus data
portal
(<https://cds.climate.copernicus.eu/cdsapp#!/dataset/projections-cmip6>)
that provides the ability to spatially crop before downloading .nc files
and ESGF (<https://esgf-node.llnl.gov/search/cmip6/>) for combinations
of source, experiment, and variable that were not available from
Copernicus. See .csv files in the `metadata/` directory for a list of
files that were not available from Copernicus and were consequently
downloaded directly from ESGF. There were a few that didn’t download
using the scripts in `R/` and I had to download manually and then crop
using the `R/manual_crop.R`.

# Data processing overview

After .nc files were downloaded they were roughly cropped to an area
containing the Biological Dynamics of Forest Fragments Project (BDFFP).

-   xmin: -65ºE
-   xmax: -50ºE
-   ymin: -5ºN
-   ymax: 0ºN

Then values for each variable were aggregated spatially by taking the
mean value for a 200km radius circle around the estimated center of
BDFFP (-59.833ºE, -2.41ºN). This aggregation was “exact”, meaning it
used a weighted mean, weighting raster pixels that were only partially
contained in the circle appropriately.

# Column names and units

The finished data are found in the `data/` directory with one .csv file
per model (AKA `source_id`) with the following structure:

| colname        | longname                                   | type      | units      |
|:---------------|:-------------------------------------------|:----------|:-----------|
| dir            | directory                                  | character | NA         |
| source\_id     | source ID                                  | character | NA         |
| experiment\_id | experiment ID                              | character | NA         |
| time           | time                                       | POSIXct   | NA         |
| hfls           | Surface Upward Latent Heat Flux            | numeric   | W m-2      |
| hfss           | Surface Upward Sensible Heat Flux          | numeric   | W m-2      |
| pr             | Precipitation                              | numeric   | kg m-2 s-1 |
| tas            | Near-Surface Air Temperature               | numeric   | K          |
| tasmin         | Daily Maximum Near-Surface Air Temperature | numeric   | K          |
| tasmax         | Daily Minimum Near-Surface Air Temperature | numeric   | K          |

# Reproducibility

To reproduce download and analysis run the scripts in `R/` sequentially.
Please note that this will take a very long time (possibly 24+ hrs)
because of the purposefully slow download script (to avoid bans due to
rate limits). Downloads from Copernicus use a modified Python script to
access their API loaded into R using the `reticulate` package. To access
the Compernicus API, you’ll need to go through the steps described here:
<https://cds.climate.copernicus.eu/api-how-to>

# QA/QC

See `data_validation` for a simple data validation report and plots of
the raw data. See also the errata for CMIP6 to check for known issues
with particular models, scenarios, and variables
(<https://errata.es-doc.org/static/index.html>)
