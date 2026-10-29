##==============================================================================
## 00_main.R
## Runs the whole project in order. Set the working directory to the
## repository root first, e.g. setwd("~/Desktop/STAT 5200/bitcoin-gold-dollar")
##==============================================================================

rm(list = ls());                 # refresh memory

## packages used anywhere in the project
needed  = c("jsonlite");
missing = needed[!sapply(needed, requireNamespace, quietly = TRUE)];
if (length(missing) > 0) install.packages(missing, repos = "https://cloud.r-project.org");

## set to TRUE to download the data again (the results then change slightly,
## because the sources revise past values from time to time)
redownload = FALSE;

if (redownload || !file.exists("data/raw/btc.csv")) source("code/01_download_data.R");
source("code/02_clean_data.R");
source("code/03_descriptive_stats.R");

writeLines(capture.output(sessionInfo()), "output/sessionInfo.txt");
