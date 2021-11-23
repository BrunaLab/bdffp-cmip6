#I had to download some files manually and I used this simple script to crop them in the same way other files are cropped.

library(stars)
library(tidyverse)
library(ClimateOperators)
library(here)

need_crop <- list.files(here("needs_cropping"), pattern = ".nc")
infile <- here("needs_cropping", need_crop)
outfile <- here("cropped", need_crop)
walk2(infile, outfile, ~cdo("-sellonlatbox,-65,-50,-5,0", .x, .y))


