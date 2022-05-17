
<!-- README.md is generated from README.Rmd. Please edit that file -->

# heliconia-cmip

<!-- badges: start -->

[![DOI](https://zenodo.org/badge/426372968.svg)](https://zenodo.org/badge/latestdoi/426372968)

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

Observed historical data used for validation of CMIP6 models was
provided by [Xavier et al. (2016)](https://doi.org/10.1002/joc.4518).
The raw data files are accessed through
<http://careyking.com/data-downloads/> (direct link:
<https://utexas.app.box.com/v/Xavier-etal-IJOC-DATA>). The following
files were downloaded to `/data_raw/Xavier/`

    #>  [1] "ETo_daily_UT_Brazil_v2_19800101_19891231.nc"    
    #>  [2] "ETo_daily_UT_Brazil_v2_19900101_19991231.nc"    
    #>  [3] "ETo_daily_UT_Brazil_v2_20000101_20061231.nc"    
    #>  [4] "ETo_daily_UT_Brazil_v2_20070101_20131231.nc"    
    #>  [5] "ETo_daily_UT_Brazil_v2_20140101_20170731_s1.nc" 
    #>  [6] "prec_daily_UT_Brazil_v2.2_19800101_19891231.nc" 
    #>  [7] "prec_daily_UT_Brazil_v2.2_19900101_19991231.nc" 
    #>  [8] "prec_daily_UT_Brazil_v2.2_20000101_20091231.nc" 
    #>  [9] "prec_daily_UT_Brazil_v2.2_20100101_20151231.nc" 
    #> [10] "Tmax_daily_UT_Brazil_v2_19800101_19891231.nc"   
    #> [11] "Tmax_daily_UT_Brazil_v2_19900101_19991231.nc"   
    #> [12] "Tmax_daily_UT_Brazil_v2_20000101_20061231.nc"   
    #> [13] "Tmax_daily_UT_Brazil_v2_20070101_20131231.nc"   
    #> [14] "Tmax_daily_UT_Brazil_v2_20140101_20170731_s1.nc"
    #> [15] "Tmin_daily_UT_Brazil_v2_19800101_19891231.nc"   
    #> [16] "Tmin_daily_UT_Brazil_v2_19900101_19991231.nc"   
    #> [17] "Tmin_daily_UT_Brazil_v2_20000101_20061231.nc"   
    #> [18] "Tmin_daily_UT_Brazil_v2_20070101_20131231.nc"   
    #> [19] "Tmin_daily_UT_Brazil_v2_20140101_20170731_s1.nc"

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

| colname       | longname                                   | type      | units      |
|:--------------|:-------------------------------------------|:----------|:-----------|
| dir           | directory                                  | character | NA         |
| source_id     | source ID                                  | character | NA         |
| experiment_id | experiment ID                              | character | NA         |
| time          | time                                       | POSIXct   | NA         |
| hfls          | Surface Upward Latent Heat Flux            | numeric   | W m-2      |
| hfss          | Surface Upward Sensible Heat Flux          | numeric   | W m-2      |
| pr            | Precipitation                              | numeric   | kg m-2 s-1 |
| tas           | Near-Surface Air Temperature               | numeric   | K          |
| tasmin        | Daily Maximum Near-Surface Air Temperature | numeric   | K          |
| tasmax        | Daily Minimum Near-Surface Air Temperature | numeric   | K          |

# Reproducibility

To reproduce download and analysis run the scripts in `R/` sequentially.
Please note that this will take a very long time (possibly 24+ hrs)
because of the purposefully slow download script (to avoid bans due to
rate limits). Downloads from Copernicus use a modified Python script to
access their API loaded into R using the `reticulate` package. To access
the Compernicus API, you’ll need to go through the steps described here:
<https://cds.climate.copernicus.eu/api-how-to>

# QA/QC

See [data validation](https://brunalab.github.io/heliconia-cmip/) for
reports and plots of the data. See also the errata for CMIP6 to check
for known issues with particular models, scenarios, and variables
(<https://errata.es-doc.org/static/index.html>)
