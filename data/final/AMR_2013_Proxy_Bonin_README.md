AMR_2013_Proxy_Bonin.csv

Based on: AMR_2013_Proxy.csv. All existing variables and values remain unchanged.

Added variable: mw_luecke from the user-provided mlkamrpanel.csv
located in the replication folder. The datasets are merged exclusively
using the numeric AMR identifier amr.

257 regions, one observation per AMR, no missing values, and no regions removed.

mw_luecke is constant within each AMR across all panel periods.
For each region, this constant value was retained once rather than averaged over time.

The original scale is preserved; no conversion to percentages was applied.

Important: The wage proxy refers to December 31, 2013.
mw_luecke is Bonin et al.'s 2014 wage gap used for the proxy validation.
It is not a newly calculated wage gap for 2013.

CSV format: UTF-8, comma-separated, decimal point.

proxy_2013 <- read.csv(
  "AMR_2013_Proxy_Bonin.csv",
  fileEncoding = "UTF-8"
)
