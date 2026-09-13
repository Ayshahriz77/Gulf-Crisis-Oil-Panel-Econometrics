# ============================================================================
# Project: Geopolitics, Oil Shock, and Macroeconomics - Panel Data Analysis
# ============================================================================

# ============================================================================
# 1. INSTALL AND LOAD LIBRARIES
# ============================================================================
# install.packages(c("tidyverse", "plm", "lmtest", "stargazer", "ggplot2", "car"))

library(tidyverse)
library(plm)
library(lmtest)
library(stargazer)
library(ggplot2)
library(car)

# ============================================================================
# 2. LOAD AND PREPARE THE DATA
# ============================================================================

data_raw <- read.csv(
  "C:/Users/malek/Downloads/ADV Econometrics Project - Panel dataset.csv",
  stringsAsFactors = FALSE
)

# The CSV stores numbers as quoted comma-decimal strings e.g. "129,10".
# dec = "," does NOT fix this — replace comma then coerce to numeric.
numeric_cols <- c("cpi", "ipi", "brent", "neer", "policy_rate", "vix")
data_raw[numeric_cols] <- lapply(data_raw[numeric_cols], function(x) {
  as.numeric(gsub(",", ".", x))
})

# Dates are "YYYY-MM" — append "-01" to make proper Date objects.
data_raw$date <- as.Date(paste0(data_raw$date, "-01"), format = "%Y-%m-%d")

# Standardise oil_balance to lowercase ("importer" / "exporter")
data_raw$oil_balance <- tolower(data_raw$oil_balance)

# Feature engineering
data_processed <- data_raw %>%
  group_by(country) %>%
  arrange(date, .by_group = TRUE) %>%
  mutate(
    ln_cpi         = log(cpi),
    ln_ipi         = log(ipi),
    ln_neer        = log(neer),
    ln_brent       = log(brent),          # log-level of oil price (used in RE)
    oil_pct_change = (brent - lag(brent)) / lag(brent) * 100,
    oil_pct_change = ifelse(is.na(oil_pct_change), 0, oil_pct_change),
    post_crisis    = ifelse(date >= as.Date("2026-03-01"), 1, 0)
  ) %>%
  ungroup() %>%
  filter(!is.na(ln_cpi), !is.na(ln_ipi), !is.na(oil_pct_change))

# ============================================================================
# 3. EXPLORATORY DATA ANALYSIS
# ============================================================================

brent_unique <- data_processed %>% distinct(date, brent)

ggplot(brent_unique, aes(x = date, y = brent)) +
  geom_line(color = "darkred", linewidth = 1) +
  geom_vline(xintercept = as.Date("2026-02-27"),
             linetype = "dashed", color = "blue") +
  annotate("text",
           x = as.Date("2026-02-27"),
           y = max(brent_unique$brent, na.rm = TRUE),
           label = "Crisis Start", hjust = -0.1, size = 3.5) +
  labs(title = "Brent Crude Oil Price: Pre and Post 2026 Gulf Crisis",
       x = "Date", y = "USD per Barrel") +
  theme_minimal()

ggplot(data_processed, aes(x = date, y = ln_cpi, color = group)) +
  stat_summary(fun = mean, geom = "line", linewidth = 1) +
  geom_vline(xintercept = as.Date("2026-02-27"),
             linetype = "dashed", color = "grey40") +
  labs(title = "Average Log CPI Trends by Country Group",
       x = "Date", y = "Log(CPI)", color = "Group") +
  theme_minimal()

# ============================================================================
# 4. DECLARE PANEL DATA FRAME
# ============================================================================

pdata <- pdata.frame(data_processed, index = c("country", "date"))

# ============================================================================
# 5. REGRESSION MODELS
# ============================================================================

# --- Formula notes -----------------------------------------------------------
#
# POLS and FE use oil_pct_change (monthly % shock) + post_crisis dummy.
#
# RE cannot use this specification for two reasons:
#   (1) oil_pct_change is a global price — it takes the same 1-3 values across
#       all countries at every date. After the RE between-transformation the
#       cross-sectional variance collapses to near zero → "lacking within
#       variation" error, regardless of which random.method is chosen.
#   (2) post_crisis = 0 for ALL observations of India and South Africa (their
#       data ends Feb 2026, one month before the dummy activates). The between
#       matrix becomes exactly singular → Lapack U[2,2] = 0 error.
#
# Solution for RE: replace oil_pct_change with ln_brent (the log-level of the
# oil price). ln_brent varies meaningfully over time within each country, so
# the RE estimator can identify it. post_crisis is dropped for reason (2).
# The FE model remains the primary model; RE serves as a robustness check.
# -----------------------------------------------------------------------------

formula_fe   <- ln_cpi ~ oil_pct_change + ln_neer + policy_rate + vix + post_crisis
formula_pols <- ln_cpi ~ oil_pct_change + ln_neer + policy_rate + vix + post_crisis
formula_re   <- ln_cpi ~ ln_brent      + ln_neer + policy_rate + vix

# --- Model 1: Pooled OLS ------------------------------------------------------
pols_model <- plm(formula_pols, data = pdata, model = "pooling")
summary(pols_model)

# --- Model 2: Fixed Effects ---------------------------------------------------
fe_model <- plm(formula_fe, data = pdata, model = "within")
summary(fe_model)

# --- Model 3: Random Effects --------------------------------------------------
re_model <- plm(formula_re, data = pdata, model = "random",
                random.method = "amemiya")
summary(re_model)

# ============================================================================
# 6. DIAGNOSTIC TESTS
# ============================================================================

# Hausman Test (FE vs RE on their shared regressors: ln_neer, policy_rate, vix)
# H0: RE is consistent.   p < 0.05 → prefer Fixed Effects.
hausman_test <- phtest(fe_model, re_model)
print(hausman_test)

# Breusch-Pagan LM Test (Pooled OLS vs RE)
# H0: no individual effects.   p < 0.05 → panel model needed.
bp_test <- plmtest(pols_model, effect = "individual", type = "bp")
print(bp_test)

# Robust standard errors
cat("\n--- Pooled OLS with Robust SE ---\n")
coeftest(pols_model, vcov = vcovHC(pols_model, method = "arellano", type = "HC3"))

cat("\n--- Fixed Effects with Robust SE ---\n")
coeftest(fe_model,   vcov = vcovHC(fe_model,   method = "arellano", type = "HC3"))

cat("\n--- Random Effects with Robust SE ---\n")
coeftest(re_model,   vcov = vcovHC(re_model,   method = "arellano", type = "HC3"))

# ============================================================================
# 7. REGRESSION TABLE
# ============================================================================

stargazer(pols_model, fe_model, re_model,
          title         = "Panel Regression Results: Impact of Oil Shock on CPI",
          column.labels = c("Pooled OLS", "Fixed Effects", "Random Effects"),
          type          = "text",
          keep.stat     = c("n", "rsq", "adj.rsq"))

# ============================================================================
# 8. HETEROGENEITY: IMPORTERS VS. EXPORTERS
# ============================================================================

# Use subset() on pdata.frame — dplyr::filter() strips panel index attributes.
importers_pdata <- subset(pdata, oil_balance == "importer")
exporters_pdata <- subset(pdata, oil_balance == "exporter")

fe_importers <- plm(formula_fe, data = importers_pdata, model = "within")
fe_exporters <- plm(formula_fe, data = exporters_pdata, model = "within")

stargazer(fe_importers, fe_exporters,
          title         = "Fixed Effects: Oil Importers vs. Exporters",
          column.labels = c("Importers", "Exporters"),
          type          = "text",
          keep.stat     = c("n", "rsq"))
