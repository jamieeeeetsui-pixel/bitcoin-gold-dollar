##==============================================================================
## 03_descriptive_stats.R
## Descriptive statistics and return correlations.
##   output/tables/table1_replication.csv : Table 1 of Baur et al. (2018),
##                                          levels, 2010-07-19 to 2015-05-22
##   output/tables/table4_returns_*.csv   : Table 4 style return statistics,
##                                          for the paper's sample and mine
##   output/tables/corr_btc_*.csv         : correlation of Bitcoin with the
##                                          other assets, by sub-period
## Run from the repository root after 02_clean_data.R.
##==============================================================================

rm(list = ls());                 # refresh memory

panel = read.csv("data/clean/panel_daily.csv");
panel$date = as.Date(panel$date);

## sub-periods
periods = list(
  replication = c("2010-07-19", "2015-05-22"),   # Dyhrberg (2016) sample
  paper_ext   = c("2010-07-19", "2017-07-14"),   # Baur et al. (2018) Section 3
  post_paper  = c("2017-07-17", "2026-05-22"),   # new data, after the paper
  pre_etf     = c("2017-07-17", "2024-01-10"),
  post_etf    = c("2024-01-11", "2026-05-22"));  # US spot Bitcoin ETFs trade

assets = c("btc", "usdeur", "usdgbp", "usdindex", "ftse", "msci", "gold_fut");

##------------------------------------------------------------------------------
## adf_stat(): Dickey-Fuller t-statistic from diff(y) on a constant and the
## lagged level, no augmentation lags (the default of Stata's dfuller, which
## the paper appears to use). 5% critical value about -2.86.
##------------------------------------------------------------------------------
adf_stat = function(y){
  dy   = diff(y);
  ylag = y[-length(y)];
  summary(lm(dy ~ ylag))$coefficients["ylag", "t value"];
}

##------------------------------------------------------------------------------
## describe(): one row of summary statistics for the vector x
##------------------------------------------------------------------------------
describe = function(x){
  x = x[!is.na(x)];
  n = length(x);
  z = (x - mean(x)) / sd(x);
  c(Mean = mean(x), SD = sd(x), Skew = mean(z^3), Kurt = mean(z^4),
    Min = min(x), Max = max(x), AR1 = cor(x[-1], x[-n]), ADF = adf_stat(x),
    Obs = n);
}

##------------------------------------------------------------------------------
## get_period(): rows of the panel inside a period; weekdays_only drops
## Saturdays and Sundays
##------------------------------------------------------------------------------
get_period = function(p, weekdays_only = FALSE){
  d = panel[panel$date >= as.Date(p[1]) & panel$date <= as.Date(p[2]), ];
  if (weekdays_only) d = d[d$weekday == 1, ];
  d;
}

## pct_ret(): percentage log return, 100 * [log(P_t) - log(P_{t-1})]
pct_ret = function(p) 100 * diff(log(p));

dir.create("output/tables", recursive = TRUE, showWarnings = FALSE);

##==============================================================================
## 1. Table 1 of the paper: levels, all calendar days, 2010-07-19 to 2015-05-22
##    (Bitcoin return here is a decimal log return, as in the paper)
##==============================================================================
d  = get_period(periods$replication);
t1 = rbind(Bitcoin          = describe(d$btc),
           LnBitcoin        = describe(log(d$btc)),
           BitcoinReturn    = describe(diff(log(d$btc))),
           FedFunds         = describe(d$fedfunds),
           USDEUR           = describe(d$usdeur),
           USDGBP           = describe(d$usdgbp),
           FTSE100          = describe(d$ftse),
           GoldFutures      = describe(d$gold_fut));
t1 = t1[, c("Mean", "SD", "Min", "Max", "AR1", "ADF", "Obs")];
write.csv(round(t1, 4), "output/tables/table1_replication.csv");
print(round(t1, 2));

##==============================================================================
## 2. Table 4 style: percentage returns. Bitcoin uses all days, the other
##    assets weekdays only; the fed funds rate is kept in levels (percent).
##==============================================================================
return_table = function(p){
  d_all = get_period(p);
  d_wd  = get_period(p, weekdays_only = TRUE);
  out   = rbind(btc = describe(pct_ret(d_all$btc)),
                fedfunds = describe(d_wd$fedfunds));
  for (a in setdiff(assets, "btc")) out = rbind(out, describe(pct_ret(d_wd[[a]])));
  rownames(out) = c("btc", "fedfunds", setdiff(assets, "btc"));
  out;
}

for (p in c("paper_ext", "post_paper")){
  t4 = return_table(periods[[p]]);
  write.csv(round(t4, 4), sprintf("output/tables/table4_returns_%s.csv", p));
  cat("\nReturn statistics,", p, "\n");
  print(round(t4, 3));
}

##==============================================================================
## 3. Correlation of daily (weekday) Bitcoin returns with the other assets,
##    by sub-period. Weekends are excluded as in Table 5 of the paper.
##==============================================================================
corr_btc = sapply(periods[-1], function(p){
  d = get_period(p, weekdays_only = TRUE);
  r = sapply(assets, function(a) pct_ret(d[[a]]));
  cor(r)["btc", -1];
});
write.csv(round(corr_btc, 4), "output/tables/corr_btc_by_period.csv");
cat("\nCorrelation of Bitcoin with other assets (weekday returns)\n");
print(round(corr_btc, 3));
