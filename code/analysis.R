###############################################
# Regional Labor Market Developments, 2015–2018
###############################################

# Results are interpreted as associative regional developments rather than causal effects.
# The parallel-trends assumption is not sufficiently supported by the empirical diagnostics.


###############################################
# 0. Packages and Data
###############################################

library(fixest)
library(dplyr)

source("code/functions.R")

proxy_2013 <- read.csv("data/final/AMR_2013_Proxy_Bonin.csv")
panel_data <- read.csv("data/final/Regression_AMR_2015_2018_Final.csv")


###############################################
# 1. Validate Wage-Gap Proxy
###############################################

# Linear relationship
proxy_2013_linear <- lm(
  mw_luecke ~ gewichteter_kreismedian_eur,
  data = proxy_2013
)

print(summary(proxy_2013_linear))

# Quadratic relationship
proxy_2013_quadratic <- lm(
  mw_luecke ~ gewichteter_kreismedian_eur +
    I(gewichteter_kreismedian_eur^2),
  data = proxy_2013
)

print(summary(proxy_2013_quadratic))

# Plot quadratic relationship

png(
  "figures/proxy_validation.png",
  width = 1600,
  height = 1000,
  res = 150
)

plot(
  proxy_2013$gewichteter_kreismedian_eur,
  proxy_2013$mw_luecke,
  xlab = "Employment-weighted district median wage, 2013 (€)",
  ylab = "2014 Wage Gap",
  main = "2013 Wage Proxy and 2014 Wage Gap"
)

x_grid <- seq(
  min(proxy_2013$gewichteter_kreismedian_eur),
  max(proxy_2013$gewichteter_kreismedian_eur),
  length.out = 200
)

quadratic_fit <- predict(
  proxy_2013_quadratic,
  newdata = data.frame(
    gewichteter_kreismedian_eur = x_grid
  )
)

lines(
  x_grid,
  quadratic_fit,
  lty = 2,
  lwd = 2
)

dev.off()

###############################################
# 2. Prepare Variables and Analysis Samples
###############################################

## 2.1 Binary treatment assignment based on the wage proxy

# treatment = 1: Wage proxy is below the median across AMRs,
# corresponding to higher expected minimum-wage exposure.
# treatment = 0: Wage proxy is at or above the median,
# corresponding to lower expected minimum-wage exposure.

m <- median(panel_data$amr_proxy)

panel_data$treatment <- ifelse(
  panel_data$amr_proxy < m,
  1,
  0
)


## 2.2 Quarterly trend

quarter_levels <- c(
  "Q1/2015", "Q2/2015", "Q3/2015", "Q4/2015",
  "Q1/2016", "Q2/2016", "Q3/2016", "Q4/2016",
  "Q1/2017", "Q2/2017", "Q3/2017", "Q4/2017",
  "Q1/2018", "Q2/2018", "Q3/2018", "Q4/2018"
)

panel_data$timeQ <- factor(
  panel_data$timeQ,
  levels = quarter_levels
)

panel_data$trend_quarter <- as.numeric(panel_data$timeQ) - 1


## 2.3 East-West indicator

panel_data$east <- factor(
  panel_data$east,
  levels = c(1, 0),
  labels = c("East", "West")
)


## 2.4 Rescale exposure proxy

# A one-unit increase in exposure_proxy corresponds to a €100 lower
# value of the pre-treatment wage indicator and therefore higher exposure.

panel_data$exposure_proxy <- -(panel_data$amr_proxy / 100)


## 2.5 Restricted sample for Specification 5

q <- quantile(
  panel_data$amr_proxy,
  probs = c(0.1, 0.9),
  na.rm = TRUE
)

trimmed_sample <- panel_data[
  panel_data$amr_proxy > q[1] &
    panel_data$amr_proxy < q[2],
]


## 2.6 Pre-treatment quarters

pre_quarters <- c(
  "Q1/2015",
  "Q2/2015",
  "Q3/2015",
  "Q4/2015",
  "Q1/2016"
)

## 2.7 Pre-treatment coefficient pattern

pretrend_pattern <- paste(pre_quarters, collapse = "|")


## 2.8 Pre-treatment sample

pre_panel_data <- panel_data[
  panel_data$post16 == 0,
]


###############################################
# 3. Descriptive Trends by Exposure Group
###############################################

# Save multi-panel figure
png(
  "figures/descriptive_trends.png",
  width = 1800,
  height = 1200,
  res = 150
)

par(mfrow = c(2, 2))

plot_descriptive_trend(
  panel_data,
  "log_svb_total",
  "(a) Regular employment (in logs)"
)

plot_descriptive_trend(
  panel_data,
  "log_geb_total",
  "(b) Marginal employment (in logs)"
)

plot_descriptive_trend(
  panel_data,
  "log_abs_total",
  "(c) Total unemployment (in logs)"
)


# Fourth panel: shared legend
par(mar = c(0, 0, 0, 0))
plot.new()

legend(
  "center",
  legend = c(
    "Control group (lower exposure)",
    "Treatment group (higher exposure)",
    "Treatment period begins (Q3/2016)",
    "Minimum-wage increase implemented (Q1/2017)"
  ),
  pch = c(1, 16, NA, NA),
  lty = c(1, 1, 2, 1),
  bty = "n",
  cex = 1,
  xpd = NA,
  y.intersp = 1.3
)

dev.off()


###############################################
# 4. Binary Difference-in-Differences Models
###############################################

# Specification 1: AMR and quarter fixed effects
# Specification 2: + East × quarter fixed effects
# Specification 3: + pre-treatment population trend
# Specification 4: + pre-treatment sector-specific trends
# Specification 5: Specification 4 using the trimmed sample


## Panel A: Regular employment

panelA.1 <- feols(
  log_svb_total ~ treatment:post16 | amr + timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)

panelA.2 <- feols(
  log_svb_total ~ treatment:post16 | amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)

panelA.3 <- feols(
  log_svb_total ~ treatment:post16 + pop_share_1864_2015:trend_quarter  | amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)

panelA.4 <- feols(
  log_svb_total ~ treatment:post16 
  + pop_share_1864_2015:trend_quarter 
  + empl_share_agric_2015:trend_quarter
  + empl_share_trade_2015:trend_quarter
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter | amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)

panelA.5 <- feols(
  log_svb_total ~ treatment:post16 
  + pop_share_1864_2015:trend_quarter 
  + empl_share_agric_2015:trend_quarter
  + empl_share_trade_2015:trend_quarter
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter | amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = trimmed_sample
)

## Panel B: Marginal employment

panelB.1 <- feols(
  log_geb_total ~ treatment:post16 | amr + timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)

panelB.2 <- feols(
  log_geb_total ~ treatment:post16 | amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)

panelB.3 <- feols(
  log_geb_total ~ treatment:post16 + pop_share_1864_2015:trend_quarter  | amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)

panelB.4 <- feols(
  log_geb_total ~ treatment:post16 
  + pop_share_1864_2015:trend_quarter 
  + empl_share_agric_2015:trend_quarter
  + empl_share_trade_2015:trend_quarter
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter | amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)

panelB.5 <- feols(
  log_geb_total ~ treatment:post16 
  + pop_share_1864_2015:trend_quarter 
  + empl_share_agric_2015:trend_quarter
  + empl_share_trade_2015:trend_quarter
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter | amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = trimmed_sample
)

## Panel C: Exclusive marginal employment

panelC.1 <- feols(
  log_geb_ausschl ~ treatment:post16 | amr + timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)

panelC.2 <- feols(
  log_geb_ausschl ~ treatment:post16 | amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)

panelC.3 <- feols(
  log_geb_ausschl ~ treatment:post16 + pop_share_1864_2015:trend_quarter  | amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)

panelC.4 <- feols(
  log_geb_ausschl ~ treatment:post16 
  + pop_share_1864_2015:trend_quarter 
  + empl_share_agric_2015:trend_quarter
  + empl_share_trade_2015:trend_quarter
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter | amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)

panelC.5 <- feols(
  log_geb_ausschl ~ treatment:post16 
  + pop_share_1864_2015:trend_quarter 
  + empl_share_agric_2015:trend_quarter
  + empl_share_trade_2015:trend_quarter
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter | amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = trimmed_sample
)

## Panel D: Total employment

panelD.1 <- feols(
  log_svgeb_total ~ treatment:post16 | amr + timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)

panelD.2 <- feols(
  log_svgeb_total ~ treatment:post16 | amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)

panelD.3 <- feols(
  log_svgeb_total ~ treatment:post16 + pop_share_1864_2015:trend_quarter  | amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)

panelD.4 <- feols(
  log_svgeb_total ~ treatment:post16 
  + pop_share_1864_2015:trend_quarter 
  + empl_share_agric_2015:trend_quarter
  + empl_share_trade_2015:trend_quarter
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter | amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)

panelD.5 <- feols(
  log_svgeb_total ~ treatment:post16 
  + pop_share_1864_2015:trend_quarter 
  + empl_share_agric_2015:trend_quarter
  + empl_share_trade_2015:trend_quarter
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter | amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = trimmed_sample
)

## Panel E: Unemployment

panelE.1 <- feols(
  log_abs_total ~ treatment:post16 | amr + timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)

panelE.2 <- feols(
  log_abs_total ~ treatment:post16 | amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)

panelE.3 <- feols(
  log_abs_total ~ treatment:post16 + pop_share_1864_2015:trend_quarter  | amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)

panelE.4 <- feols(
  log_abs_total ~ treatment:post16 
  + pop_share_1864_2015:trend_quarter 
  + empl_share_agric_2015:trend_quarter
  + empl_share_trade_2015:trend_quarter
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter | amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)

panelE.5 <- feols(
  log_abs_total ~ treatment:post16 
  + pop_share_1864_2015:trend_quarter 
  + empl_share_agric_2015:trend_quarter
  + empl_share_trade_2015:trend_quarter
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter | amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = trimmed_sample
)


###############################################
# 5. Binary Event-Study Models
###############################################

# All event-study models use the preferred specification.
# Reference period: Q2/2016.

## Panel A: Regular employment

event_A <- feols(
  log_svb_total ~ i(timeQ, treatment, ref = "Q2/2016")
  + pop_share_1864_2015:trend_quarter 
  + empl_share_agric_2015:trend_quarter 
  + empl_share_trade_2015:trend_quarter 
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter | amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)

## Panel B: Marginal employment

event_B <- feols(
  log_geb_total ~ i(timeQ, treatment, ref = "Q2/2016")
  + pop_share_1864_2015:trend_quarter 
  + empl_share_agric_2015:trend_quarter 
  + empl_share_trade_2015:trend_quarter 
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter | amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)

## Panel C: Exclusive marginal employment

event_C <- feols(
  log_geb_ausschl ~ i(timeQ, treatment, ref = "Q2/2016")
  + pop_share_1864_2015:trend_quarter 
  + empl_share_agric_2015:trend_quarter 
  + empl_share_trade_2015:trend_quarter 
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter | amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)

## Panel D: Total employment

event_D <- feols(
  log_svgeb_total ~ i(timeQ, treatment, ref = "Q2/2016")
  + pop_share_1864_2015:trend_quarter 
  + empl_share_agric_2015:trend_quarter 
  + empl_share_trade_2015:trend_quarter 
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter | amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)

## Panel E: Unemployment

event_E <- feols(
  log_abs_total ~ i(timeQ, treatment, ref = "Q2/2016")
  + pop_share_1864_2015:trend_quarter 
  + empl_share_agric_2015:trend_quarter 
  + empl_share_trade_2015:trend_quarter 
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter | amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)

print(etable(event_A, event_B, event_C, event_D, event_E,
             keep_raw = "^timeQ::", digits = 4))

###############################################
# 6. Binary Model: Pre-Trend Diagnostics
###############################################

## Panel A: Regular employment

# Joint Wald test

wald(
  event_A,
  keep = pretrend_pattern
)

# Leave-one-out Wald tests

leave_out_results_A <- leave_one_out_wald(
  event_A,
  pre_quarters
)

print(leave_out_results_A)

# Linearer Pre-trend test

pretrend_A <- feols(
  log_svb_total ~ treatment:trend_quarter
  + pop_share_1864_2015:trend_quarter 
  + empl_share_agric_2015:trend_quarter
  + empl_share_trade_2015:trend_quarter
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter | amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = pre_panel_data
)

print(pretrend_A)


## Panel B: Marginal employment

# Joint Wald test

wald(
  event_B,
  keep = pretrend_pattern
)

# Leave-one-out Wald tests

leave_out_results_B <- leave_one_out_wald(
  event_B,
  pre_quarters
)

print(leave_out_results_B)

# Linearer Pre-trend test

pretrend_B <- feols(
  log_geb_total ~ treatment:trend_quarter
  + pop_share_1864_2015:trend_quarter 
  + empl_share_agric_2015:trend_quarter
  + empl_share_trade_2015:trend_quarter
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter | amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = pre_panel_data
)

print(pretrend_B)


## Panel C: Exclusive marginal employment

# Joint Wald test

wald(
  event_C,
  keep = pretrend_pattern
)

# Leave-one-out Wald tests

leave_out_results_C <- leave_one_out_wald(
  event_C,
  pre_quarters
)
 
print(leave_out_results_C)

# Linearer Pre-trend test

pretrend_C <- feols(
  log_geb_ausschl ~ treatment:trend_quarter
  + pop_share_1864_2015:trend_quarter 
  + empl_share_agric_2015:trend_quarter
  + empl_share_trade_2015:trend_quarter
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter | amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = pre_panel_data
)

print(pretrend_C)


## Panel D: Total employment

# Joint Wald test

wald(
  event_D,
  keep = pretrend_pattern
)

# Leave-one-out Wald tests

leave_out_results_D <- leave_one_out_wald(
  event_D,
  pre_quarters
)
 
print(leave_out_results_D)

# Linearer Pre-trend test

pretrend_D <- feols(
  log_svgeb_total ~ treatment:trend_quarter
  + pop_share_1864_2015:trend_quarter 
  + empl_share_agric_2015:trend_quarter
  + empl_share_trade_2015:trend_quarter
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter | amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = pre_panel_data
)

print(summary(pretrend_D))


## Panel E: Unemployment

# Joint Wald test

wald(
  event_E,
  keep = pretrend_pattern
)

# Leave-one-out Wald tests

leave_out_results_E <- leave_one_out_wald(
  event_E,
  pre_quarters
)
 
print(leave_out_results_E)

# Linearer Pre-trend test

pretrend_E <- feols(
  log_abs_total ~ treatment:trend_quarter
  + pop_share_1864_2015:trend_quarter 
  + empl_share_agric_2015:trend_quarter
  + empl_share_trade_2015:trend_quarter
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter | amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = pre_panel_data
)

print(summary(pretrend_E))


###############################################
# 7. Continuous Difference-in-Differences Models
###############################################

# All models use the preferred specification.
# A one-unit increase in exposure_proxy corresponds to a €100 lower
# value of the pre-treatment wage indicator and therefore higher exposure.


## Panel A: Regular employment

c_did_A <- feols(
  log_svb_total ~ exposure_proxy:post16
  + pop_share_1864_2015:trend_quarter
  + empl_share_agric_2015:trend_quarter
  + empl_share_trade_2015:trend_quarter
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter |
    amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)


## Panel B: Marginal employment

c_did_B <- feols(
  log_geb_total ~ exposure_proxy:post16
  + pop_share_1864_2015:trend_quarter
  + empl_share_agric_2015:trend_quarter
  + empl_share_trade_2015:trend_quarter
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter |
    amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)


## Panel C: Exclusive marginal employment

c_did_C <- feols(
  log_geb_ausschl ~ exposure_proxy:post16
  + pop_share_1864_2015:trend_quarter
  + empl_share_agric_2015:trend_quarter
  + empl_share_trade_2015:trend_quarter
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter |
    amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)


## Panel D: Total employment

c_did_D <- feols(
  log_svgeb_total ~ exposure_proxy:post16
  + pop_share_1864_2015:trend_quarter
  + empl_share_agric_2015:trend_quarter
  + empl_share_trade_2015:trend_quarter
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter |
    amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)


## Panel E: Unemployment

c_did_E <- feols(
  log_abs_total ~ exposure_proxy:post16
  + pop_share_1864_2015:trend_quarter
  + empl_share_agric_2015:trend_quarter
  + empl_share_trade_2015:trend_quarter
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter |
    amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)

print(etable(c_did_A, c_did_B, c_did_C, c_did_D, c_did_E,
             keep_raw = "exposure_proxy:post16", digits = 4))

###############################################
# 8. Continuous Event-Study Models
###############################################

# All models use the preferred specification.
# Reference period: Q2/2016.
# A one-unit increase in exposure_proxy corresponds to a €100 lower
# value of the pre-treatment wage indicator and therefore higher exposure.


## Panel A: Regular employment

c_event_A <- feols(
  log_svb_total ~ i(timeQ, exposure_proxy, ref = "Q2/2016")
  + pop_share_1864_2015:trend_quarter
  + empl_share_agric_2015:trend_quarter
  + empl_share_trade_2015:trend_quarter
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter |
    amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)


## Panel B: Marginal employment

c_event_B <- feols(
  log_geb_total ~ i(timeQ, exposure_proxy, ref = "Q2/2016")
  + pop_share_1864_2015:trend_quarter
  + empl_share_agric_2015:trend_quarter
  + empl_share_trade_2015:trend_quarter
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter |
    amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)


## Panel C: Exclusive marginal employment

c_event_C <- feols(
  log_geb_ausschl ~ i(timeQ, exposure_proxy, ref = "Q2/2016")
  + pop_share_1864_2015:trend_quarter
  + empl_share_agric_2015:trend_quarter
  + empl_share_trade_2015:trend_quarter
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter |
    amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)


## Panel D: Total employment

c_event_D <- feols(
  log_svgeb_total ~ i(timeQ, exposure_proxy, ref = "Q2/2016")
  + pop_share_1864_2015:trend_quarter
  + empl_share_agric_2015:trend_quarter
  + empl_share_trade_2015:trend_quarter
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter |
    amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)


## Panel E: Unemployment

c_event_E <- feols(
  log_abs_total ~ i(timeQ, exposure_proxy, ref = "Q2/2016")
  + pop_share_1864_2015:trend_quarter
  + empl_share_agric_2015:trend_quarter
  + empl_share_trade_2015:trend_quarter
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter |
    amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = panel_data
)

print(etable(c_event_A, c_event_B, c_event_C, c_event_D, c_event_E,
             keep_raw = "^timeQ::", digits = 4))

###############################################
# 9. Continuous Model: Pre-Trend Diagnostics
###############################################

## Panel A: Regular employment

# Joint Wald test
wald(
  c_event_A,
  keep = pretrend_pattern
)

# Leave-one-out Wald tests
leave_out_results_cA <- leave_one_out_wald(
  c_event_A,
  pre_quarters
)

print(leave_out_results_cA)

# Linear pre-trend test
c_pretrend_A <- feols(
  log_svb_total ~ exposure_proxy:trend_quarter
  + pop_share_1864_2015:trend_quarter
  + empl_share_agric_2015:trend_quarter
  + empl_share_trade_2015:trend_quarter
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter |
    amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = pre_panel_data
)

print(summary(c_pretrend_A))


## Panel B: Marginal employment

# Joint Wald test
wald(c_event_B, keep = pretrend_pattern)

# Leave-one-out Wald tests
leave_out_results_cB <- leave_one_out_wald(
  c_event_B,
  pre_quarters
)

print(leave_out_results_cB)

# Linear pre-trend test
c_pretrend_B <- feols(
  log_geb_total ~ exposure_proxy:trend_quarter
  + pop_share_1864_2015:trend_quarter
  + empl_share_agric_2015:trend_quarter
  + empl_share_trade_2015:trend_quarter
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter |
    amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = pre_panel_data
)

print(summary(c_pretrend_B))


## Panel C: Exclusive marginal employment

# Joint Wald test
wald(
  c_event_C,
  keep = pretrend_pattern
)

# Leave-one-out Wald tests
leave_out_results_cC <- leave_one_out_wald(
  c_event_C,
  pre_quarters
)

print(leave_out_results_cC)

# Linear pre-trend test
c_pretrend_C <- feols(
  log_geb_ausschl ~ exposure_proxy:trend_quarter
  + pop_share_1864_2015:trend_quarter
  + empl_share_agric_2015:trend_quarter
  + empl_share_trade_2015:trend_quarter
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter |
    amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = pre_panel_data
)

print(summary(c_pretrend_C))


## Panel D: Total employment

# Joint Wald test
wald(
  c_event_D,
  keep = pretrend_pattern
)

# Leave-one-out Wald tests
leave_out_results_cD <- leave_one_out_wald(
  c_event_D,
  pre_quarters
)

print(leave_out_results_cD)

# Linear pre-trend test
c_pretrend_D <- feols(
  log_svgeb_total ~ exposure_proxy:trend_quarter
  + pop_share_1864_2015:trend_quarter
  + empl_share_agric_2015:trend_quarter
  + empl_share_trade_2015:trend_quarter
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter |
    amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = pre_panel_data
)

print(summary(c_pretrend_D))


## Panel E: Unemployment

# Joint Wald test
wald(
  c_event_E,
  keep = pretrend_pattern
)

# Leave-one-out Wald tests
leave_out_results_cE <- leave_one_out_wald(
  c_event_E,
  pre_quarters
)

print(leave_out_results_cE)

c_pretrend_E <- feols(
  log_abs_total ~ exposure_proxy:trend_quarter
  + pop_share_1864_2015:trend_quarter
  + empl_share_agric_2015:trend_quarter
  + empl_share_trade_2015:trend_quarter
  + empl_share_finan_2015:trend_quarter
  + empl_share_publ_2015:trend_quarter |
    amr + timeQ + east^timeQ,
  weights = ~weight_pop15,
  cluster = ~amr,
  data = pre_panel_data
)

print(summary(c_pretrend_E))


###############################################
# 10. Results Tables and Figures
###############################################

## 10.1 Binary DiD specification tables

# Common table settings

treatment_dict <- c(
  "treatment:post16" = "DiD estimate"
)

specification_rows <- list(
  "AMR FE" = c("Yes", "Yes", "Yes", "Yes", "Yes"),
  "Quarter FE" = c("Yes", "Yes", "Yes", "Yes", "Yes"),
  "East × Quarter FE" = c("No", "Yes", "Yes", "Yes", "Yes"),
  "Population trend" = c("No", "No", "Yes", "Yes", "Yes"),
  "Sector trends" = c("No", "No", "No", "Yes", "Yes"),
  "Trimmed sample" = c("No", "No", "No", "No", "Yes")
)

table_notes <- c(
  "Standard errors are clustered at the AMR level.",
  "All specifications are weighted by pre-treatment population.",
  "Treatment equals one for AMRs with a below-median pre-treatment wage indicator.",
  "East × Quarter FE allow for separate East/West time patterns.",
  "Population and sector trends are based on pre-treatment 2015 characteristics.",
  "The trimmed sample excludes the lowest and highest 10% of the exposure-proxy distribution.",
  "Column (4) is the preferred specification."
)

## Panel A: Regular employment

print(etable(
  panelA.1, panelA.2, panelA.3, panelA.4, panelA.5,
  se.below = TRUE,
  digits = 4,
  keep_raw = "treatment:post16",
  dict = treatment_dict,
  fitstat = ~ n + wr2,
  extralines = specification_rows,
  drop.section = "fixef",
  notes = table_notes
))


## Panel B: Marginal employment

print(etable(
  panelB.1, panelB.2, panelB.3, panelB.4, panelB.5,
  se.below = TRUE,
  digits = 4,
  keep_raw = "treatment:post16",
  dict = treatment_dict,
  fitstat = ~ n + wr2,
  extralines = specification_rows,
  drop.section = "fixef",
  notes = table_notes
))


## Panel C: Exclusive marginal employment

print(etable(
  panelC.1, panelC.2, panelC.3, panelC.4, panelC.5,
  se.below = TRUE,
  digits = 4,
  keep_raw = "treatment:post16",
  dict = treatment_dict,
  fitstat = ~ n + wr2,
  extralines = specification_rows,
  drop.section = "fixef",
  notes = table_notes
))


## Panel D: Total employment

print(etable(
  panelD.1, panelD.2, panelD.3, panelD.4, panelD.5,
  se.below = TRUE,
  digits = 4,
  keep_raw = "treatment:post16",
  dict = treatment_dict,
  fitstat = ~ n + wr2,
  extralines = specification_rows,
  drop.section = "fixef",
  notes = table_notes
))


## Panel E: Unemployment

print(etable(
  panelE.1, panelE.2, panelE.3, panelE.4, panelE.5,
  se.below = TRUE,
  digits = 4,
  keep_raw = "treatment:post16",
  dict = treatment_dict,
  fitstat = ~ n + wr2,
  extralines = specification_rows,
  drop.section = "fixef",
  notes = table_notes
))


## 10.2 Compact results table

results <- data.frame(
  Outcome = c(
    "Regular employment",
    "Marginal employment",
    "Exclusive marginal employment",
    "Total employment",
    "Unemployment"
  ),
  
  Binary_Estimate = c(
    coef(panelA.4)["treatment:post16"],
    coef(panelB.4)["treatment:post16"],
    coef(panelC.4)["treatment:post16"],
    coef(panelD.4)["treatment:post16"],
    coef(panelE.4)["treatment:post16"]
  ),
  
  Binary_SE = c(
    se(panelA.4)["treatment:post16"],
    se(panelB.4)["treatment:post16"],
    se(panelC.4)["treatment:post16"],
    se(panelD.4)["treatment:post16"],
    se(panelE.4)["treatment:post16"]
  ),
  
  Continuous_Estimate = c(
    coef(c_did_A)["exposure_proxy:post16"],
    coef(c_did_B)["exposure_proxy:post16"],
    coef(c_did_C)["exposure_proxy:post16"],
    coef(c_did_D)["exposure_proxy:post16"],
    coef(c_did_E)["exposure_proxy:post16"]
  ),
  
  Continuous_SE = c(
    se(c_did_A)["exposure_proxy:post16"],
    se(c_did_B)["exposure_proxy:post16"],
    se(c_did_C)["exposure_proxy:post16"],
    se(c_did_D)["exposure_proxy:post16"],
    se(c_did_E)["exposure_proxy:post16"]
  )
)

# p-values
results$Binary_p <- c(
  pvalue(panelA.4)["treatment:post16"],
  pvalue(panelB.4)["treatment:post16"],
  pvalue(panelC.4)["treatment:post16"],
  pvalue(panelD.4)["treatment:post16"],
  pvalue(panelE.4)["treatment:post16"]
)

results$Continuous_p <- c(
  pvalue(c_did_A)["exposure_proxy:post16"],
  pvalue(c_did_B)["exposure_proxy:post16"],
  pvalue(c_did_C)["exposure_proxy:post16"],
  pvalue(c_did_D)["exposure_proxy:post16"],
  pvalue(c_did_E)["exposure_proxy:post16"]
)

stars <- function(p) {
  ifelse(p < 0.01, "***",
         ifelse(p < 0.05, "**",
                ifelse(p < 0.10, "*", "")))
}

results$Binary_DiD <- sprintf(
  "%.4f%s (%.4f)",
  results$Binary_Estimate,
  stars(results$Binary_p),
  results$Binary_SE
)

results$Continuous_DiD <- sprintf(
  "%.4f%s (%.4f)",
  results$Continuous_Estimate,
  stars(results$Continuous_p),
  results$Continuous_SE
)

final_table <- results[, c("Outcome", "Binary_DiD", "Continuous_DiD")]
names(final_table) <- c("Outcome", "Binary DiD", "Continuous DiD")
print(final_table)


## 10.3 Individual continuous event-study plots

## Panel A: Regular employment

png(
  "figures/eventstudy_regular.png",
  width = 1600,
  height = 1000,
  res = 150
)

plot_eventstudy(
  c_event_A,
  "Regular employment"
)

dev.off()

## Panel B: Marginal employment

png(
  "figures/eventstudy_marginal.png",
  width = 1600,
  height = 1000,
  res = 150
)

plot_eventstudy(
  c_event_B,
  "Marginal employment"
)

dev.off()

## Panel C: Exclusive marginal employment

png(
  "figures/eventstudy_exclusive_marginal.png",
  width = 1600,
  height = 1000,
  res = 150
)

plot_eventstudy(
  c_event_C,
  "Exclusive marginal employment"
)

dev.off()

## Panel D: Total employment

png(
  "figures/eventstudy_total_employment.png",
  width = 1600,
  height = 1000,
  res = 150
)

plot_eventstudy(
  c_event_D,
  "Total employment"
)

dev.off()

## Panel E: Unemployment

png(
  "figures/eventstudy_unemployment.png",
  width = 1600,
  height = 1000,
  res = 150
)

plot_eventstudy(
  c_event_E,
  "Unemployment"
)

dev.off()

## 10.5 Multi-panel continuous event-study figure

png(
  "figures/continuous_event_studies.png",
  width = 2200,
  height = 1800,
  res = 150
)

par(
  mfrow = c(3, 2),
  mar = c(6, 4, 3, 1)
)

plot_eventstudy(c_event_A, "(a) Regular employment")
plot_eventstudy(c_event_B, "(b) Marginal employment")
plot_eventstudy(c_event_C, "(c) Exclusive marginal employment")
plot_eventstudy(c_event_D, "(d) Total employment")
plot_eventstudy(c_event_E, "(e) Unemployment")

# Sixth panel: shared legend
par(mar = c(0, 0, 0, 0))
plot.new()

legend(
  "center",
  legend = c(
    "Reference period: Q2/2016",
    "Treatment period begins (Q3/2016)",
    "Minimum-wage increase implemented (Q1/2017)"
  ),
  pch = c(1, NA, NA),
  lty = c(NA, 2, 1),
  bty = "n",
  cex = 1.8
)

text(
  0.5, 0.25,
  "1 unit of exposure_proxy = €100 lower\npre-treatment wage indicator",
  cex = 1.8
)

dev.off()