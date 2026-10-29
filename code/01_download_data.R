##==============================================================================
## 01_download_data.R
## Download the raw daily price series and save them in data/raw/ as
## two-column CSV files (date, value). All sources are free, no login needed:
##   Coin Metrics : Bitcoin reference price in USD (community data on GitHub)
##   FRED         : fed funds rate, USD/EUR, USD/GBP, broad trade-weighted USD
##   Yahoo Finance: FTSE 100, MSCI World, COMEX gold futures (front month)
## Baur, Dimpfl and Kuck (2018) used coindesk.com and Datastream instead,
## which I do not have access to. See README.md for the differences.
## Run from the repository root.
##==============================================================================

dir.create("data/raw", recursive = TRUE, showWarnings = FALSE);
start_date = "2010-07-01";        # a few days before the paper's first date

##------------------------------------------------------------------------------
## save_series(): drop missing values, sort by date and write data/raw/<name>.csv
##------------------------------------------------------------------------------
save_series = function(df, name){
  df = df[!is.na(df$value), ];
  df = df[order(df$date), ];
  write.csv(df, file.path("data/raw", paste0(name, ".csv")), row.names = FALSE);
  cat(sprintf("%-9s %5d obs, %s to %s\n", name, nrow(df), min(df$date), max(df$date)));
}

##------------------------------------------------------------------------------
## get_fred(): one FRED series. FRED marks missing days (holidays) with "."
##------------------------------------------------------------------------------
get_fred = function(id){
  url = paste0("https://fred.stlouisfed.org/graph/fredgraph.csv?id=", id,
               "&cosd=", start_date);
  x = read.csv(url, na.strings = c(".", ""));
  data.frame(date = as.Date(x[, 1]), value = as.numeric(x[, 2]));
}

##------------------------------------------------------------------------------
## get_yahoo(): daily closing prices from the Yahoo Finance chart API.
## Timestamps are converted to dates in the exchange's own time zone.
##------------------------------------------------------------------------------
get_yahoo = function(symbol){
  p1  = as.numeric(as.POSIXct(start_date, tz = "UTC"));
  p2  = as.numeric(Sys.time());
  url = sprintf(paste0("https://query1.finance.yahoo.com/v8/finance/chart/%s",
                       "?period1=%.0f&period2=%.0f&interval=1d"),
                URLencode(symbol, reserved = TRUE), p1, p2);
  tmp = tempfile(fileext = ".json");
  download.file(url, tmp, quiet = TRUE, headers = c("User-Agent" = "Mozilla/5.0"));
  res = jsonlite::fromJSON(tmp, simplifyVector = FALSE)$chart$result[[1]];

  tz    = res$meta$exchangeTimezoneName;
  ts    = unlist(res$timestamp);
  close = sapply(res$indicators$quote[[1]]$close,
                 function(v) if (is.null(v)) NA else v);
  data.frame(date  = as.Date(as.POSIXct(ts, origin = "1970-01-01", tz = tz), tz = tz),
             value = close);
}

##==============================================================================
## Bitcoin
##==============================================================================
btc = read.csv("https://raw.githubusercontent.com/coinmetrics/data/master/csv/btc.csv");
btc = data.frame(date = as.Date(btc$time), value = btc$PriceUSD);
save_series(btc[btc$date >= as.Date(start_date), ], "btc");

##==============================================================================
## FRED
##==============================================================================
fred_ids = c(fedfunds = "DFF",        # effective federal funds rate, percent
             usdeur   = "DEXUSEU",    # US dollars per euro
             usdgbp   = "DEXUSUK",    # US dollars per pound
             usdindex = "DTWEXBGS");  # nominal broad USD index, Jan 2006 = 100
for (k in names(fred_ids)) save_series(get_fred(fred_ids[k]), k);

##==============================================================================
## Yahoo Finance
##==============================================================================
yahoo_ids = c(ftse     = "^FTSE",
              msci     = "^990100-USD-STRD",   # MSCI World, price index in USD
              gold_fut = "GC=F");
for (k in names(yahoo_ids)) save_series(get_yahoo(yahoo_ids[k]), k);

writeLines(paste("Downloaded on", Sys.Date()), "data/raw/download_log.txt");
