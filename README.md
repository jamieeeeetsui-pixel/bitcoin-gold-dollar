# Bitcoin, gold and the US dollar: replication and extension

STAT 5200 final project.

The project replicates the descriptive part of

> Baur, D. G., Dimpfl, T., and Kuck, K. (2018). Bitcoin, gold and the US dollar –
> A replication and extension. *Finance Research Letters*, 25, 103–110.
> https://doi.org/10.1016/j.frl.2017.10.012

and asks whether its main conclusion (Bitcoin is uncorrelated with gold, the US
dollar and stocks, and has its own volatility dynamics) still holds after
2017, when Bitcoin futures (Dec 2017) and US spot Bitcoin ETFs (Jan 2024) brought
institutional investors into the market.

## How to run

Requires R (tested with R 4.6.1) and the package `jsonlite`, which
`00_main.R` installs if it is missing.

```r
setwd("path/to/bitcoin-gold-dollar")   # repository root
source("code/00_main.R")
```

`00_main.R` runs the scripts below in order. The raw data are included in
`data/raw/`, so nothing is downloaded unless `redownload = TRUE` is set in
`00_main.R`.

| Script | What it does | Output |
|---|---|---|
| `code/01_download_data.R` | downloads the raw series | `data/raw/*.csv` |
| `code/02_clean_data.R` | merges them on a 7-day calendar | `data/clean/panel_daily.csv` |
| `code/03_descriptive_stats.R` | summary statistics and correlations | `output/tables/*.csv` |

## Data

Daily data, 19 July 2010 to 22 May 2026.

| Variable | Source | ID |
|---|---|---|
| Bitcoin price (USD) | Coin Metrics community data | `PriceUSD` in `btc.csv` |
| Effective federal funds rate | FRED | `DFF` |
| USD per EUR | FRED | `DEXUSEU` |
| USD per GBP | FRED | `DEXUSUK` |
| Broad trade-weighted USD index | FRED | `DTWEXBGS` |
| FTSE 100 | Yahoo Finance | `^FTSE` |
| MSCI World (USD, price) | Yahoo Finance | `^990100-USD-STRD` |
| COMEX gold futures | Yahoo Finance | `GC=F` |

Differences from the paper's data:

- The paper uses coindesk.com for Bitcoin and Datastream for everything else.
  Neither is freely available, so the sources above are used instead.
- Gold spot (London fixing) is no longer on FRED and has no free daily source,
  so only gold futures are used. In the paper the two have a return correlation
  of 0.88.
- The paper's USD index is the Fed's major-currencies index, which was
  discontinued in 2019; the broad index `DTWEXBGS` is used instead. The EUR
  trade-weighted index is not used.
- The Coin Metrics community repository stopped updating on 24 May 2026, which
  sets the end of the sample.

Weekends and holidays: as in the paper, prices of assets that do not trade on a
given day are carried forward (zero return). Bitcoin statistics use all days;
those of the other assets and all correlations use weekdays only.

## Structure

```
code/          R scripts, run through 00_main.R
data/raw/      downloaded series, one CSV per variable (date, value)
data/clean/    merged daily panel
output/tables/ tables as CSV
output/figures/
```
