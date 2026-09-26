################################################ 
# Function for weighted descriptive trends
###############################################

plot_descriptive_trend <- function(data, outcome, title) {
  
  # Calculate weighted quarterly means by treatment group
  plot_data <- data |>
    group_by(treatment, year, month, timeQ) |>
    summarise(
      value = weighted.mean(
        .data[[outcome]],
        weight_pop15,
        na.rm = TRUE
      ),
      .groups = "drop"
    ) |>
    arrange(year, month)
  
  # Separate higher- and lower-exposure regions
  treatment_group <- plot_data |>
    filter(treatment == 1)
  
  control_group <- plot_data |>
    filter(treatment == 0)
  
  # Create numerical x-axis
  xaxis <- seq_len(nrow(treatment_group))
  quarter_labels <- treatment_group$timeQ
  
  # Plot higher-exposure group
  plot(
    xaxis,
    treatment_group$value,
    type = "o",
    pch = 16,
    xaxt = "n",
    ylim = range(
      c(
        treatment_group$value,
        control_group$value
      ),
      na.rm = TRUE
    ),
    xlab = "",
    ylab = "",
    main = title
  )
  
  # Add lower-exposure group
  lines(
    xaxis,
    control_group$value,
    type = "o",
    pch = 1
  )
  
  # Quarter labels
  axis(
    1,
    at = xaxis,
    labels = quarter_labels,
    las = 2
  )
  
  # Treatment period begins in Q3/2016
  abline(v = 6.5, lty = 2)
  
  # Minimum-wage increase implemented in Q1/2017
  abline(v = 8.5, lty = 1)
}

###############################################
# Function for leave-one-out Wald tests
###############################################

## Pre-treatment quarters
pre_quarters <- c(
  "Q1/2015",
  "Q2/2015",
  "Q3/2015",
  "Q4/2015",
  
  
  "Q1/2016"
)

# Pre-treatment coefficient pattern
pretrend_pattern <- paste(pre_quarters, collapse = "|")

# Function for leave-one-out Wald tests
leave_one_out_wald <- function(model, pre_quarters) {
  
  results <- data.frame(
    left_out = pre_quarters,
    p_value = NA
  )
  
  for (i in seq_along(pre_quarters)) {
    
    keep_quarters <- pre_quarters[-i]
    pattern <- paste(keep_quarters, collapse = "|")
    
    test <- wald(
      model,
      keep = pattern,
      print = FALSE
    )
    
    results$p_value[i] <- test["p"]
  }
  
  return(results)
}


###############################################
# Event-study plotting function
###############################################

event_x <- c(1:5, 7:16)

plot_eventstudy <- function(model, title) {
  
  idx <- grepl(
    "^timeQ::.*:exposure_proxy$",
    names(coef(model))
  )
  
  b <- coef(model)[idx]
  se <- se(model)[idx]
  
  lower <- b - 1.96 * se
  upper <- b + 1.96 * se
  
  # Plot coefficients
  plot(
    event_x, b,
    ylim = range(c(lower, upper)),
    xlim = c(1, 16),
    xaxt = "n",
    pch = 16,
    xlab = "",
    ylab = "Coefficient and 95% CI",
    main = title
  )
  
  # 95% confidence intervals
  arrows(
    event_x, lower,
    event_x, upper,
    angle = 90,
    code = 3,
    length = 0.04
  )
  
  # Reference period: Q2/2016
  points(6, 0, pch = 1)
  
  # Zero line
  abline(h = 0)
  
  # Treatment period begins in Q3/2016
  abline(v = 6.5, lty = 2)
  
  # Minimum-wage increase implemented in Q1/2017
  abline(v = 8.5, lty = 1)
  
  # Quarter labels
  axis(
    1,
    at = 1:16,
    labels = quarter_levels,
    las = 2,
    cex.axis = 1
  )
}