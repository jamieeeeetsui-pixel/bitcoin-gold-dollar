##==============================================================================
## 02_clean_data.R
## Merge the raw series into one daily panel on a 7-day calendar and save it
## as data/clean/panel_daily.csv.
##
## Bitcoin trades every day, the other assets only on business days. Following
## Dyhrberg (2016) and Baur et al. (2018, footnote 1), prices of the other
## assets are carried forward over weekends and holidays, i.e. their returns
## on those days are zero. Weekday-only samples are taken later by filtering
## on the column 'weekday'.
## Run from the repository root.
##==============================================================================

rm(list = ls());                 # refresh memory

first_date = as.Date("2010-07-19");   # first day of the paper's sample
last_date  = as.Date("2026-05-22");   # last Friday with Coin Metrics data
series     = c("btc", "fedfunds", "usdeur", "usdgbp", "usdindex",
               "ftse", "msci", "gold_fut");

##------------------------------------------------------------------------------
## read_raw(): data/raw/<name>.csv with the value column renamed to <name>
##------------------------------------------------------------------------------
read_raw = function(name){
  x = read.csv(file.path("data/raw", paste0(name, ".csv")));
  x$date = as.Date(x$date);
  names(x)[2] = name;
  x;
}

##------------------------------------------------------------------------------
## locf(): last observation carried forward (leading NAs stay NA)
##------------------------------------------------------------------------------
locf = function(v){
  idx = cummax(seq_along(v) * !is.na(v));
  v[replace(idx, idx == 0, NA)];
}

##==============================================================================
## Build the panel. The merge starts a few days before first_date so that
## carried-forward values exist on the first day.
##==============================================================================
panel = data.frame(date = seq(first_date - 10, last_date, by = "day"));
for (s in series) panel = merge(panel, read_raw(s), by = "date", all.x = TRUE);

for (s in setdiff(series, "btc")) panel[[s]] = locf(panel[[s]]);
panel = panel[panel$date >= first_date, ];

## weekday = 1 for Monday to Friday (format "%u": 1 = Monday, 7 = Sunday)
panel$weekday = as.integer(as.integer(format(panel$date, "%u")) <= 5);

stopifnot(!anyNA(panel[, series]));

dir.create("data/clean", recursive = TRUE, showWarnings = FALSE);
write.csv(panel, "data/clean/panel_daily.csv", row.names = FALSE);
cat(sprintf("panel: %d days (%d weekdays), %s to %s\n",
            nrow(panel), sum(panel$weekday), min(panel$date), max(panel$date)));
