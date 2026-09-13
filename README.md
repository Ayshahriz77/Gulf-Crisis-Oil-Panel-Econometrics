# 🛢️ The Geopolitics of Oil: Panel Econometrics of the 2026 Gulf Crisis

A panel-data econometrics project assessing the macroeconomic (inflationary) impact of a simulated 2026 Gulf Crisis oil-price shock across seven countries, using Pooled OLS, Fixed Effects, and Random Effects estimators with formal specification testing.

**Course:** Advanced Econometrics
**Authors:** Menna Sbai, Malek Omri, Aicha Hriz, Rihem Abdelmoumen, Yomna Brahmi
**Supervisor:** Prof. Dr. Naceuf Khraief
**Institution:** Tunis Business School, University of Tunis
**Date:** 2026

---

## 📌 Project Overview

This project examines whether a hypothetical geopolitical oil-price shock — the "2026 Gulf Crisis," calibrated to historical analogues, with Brent crude spiking above $140/barrel, generated a statistically significant increase in consumer price inflation across a panel of countries, and how that effect differs between oil importers and exporters.

**Research question:** Did the 2026 Gulf Crisis generate a statistically significant and economically meaningful increase in consumer price inflation across a panel of countries, and how does this effect vary by oil trade position?

## 📊 Data

- **Panel:** 7 countries × up to 42 monthly observations (N = 272, unbalanced)
- **Countries:** Eurozone, United States, India, South Africa (**importers**) · Canada, Russia, Saudi Arabia (**exporters**)
- **Note:** India and South Africa have shorter series (T=36) and are absent from the post-crisis window
- **Sources (simulated, calibrated to realistic patterns):** IMF IFS, World Bank, FRED, Bloomberg conventions

| Variable | Description | Expected Sign |
|---|---|---|
| `ln_cpi` | Log Consumer Price Index (dependent variable) | — |
| `post_crisis` | Binary dummy = 1 from March 2026 onward | + |
| `ln_neer` | Log Nominal Effective Exchange Rate | − (importers) |
| `policy_rate` | Central bank benchmark interest rate | − (theory) |
| `vix` | CBOE Volatility Index (global uncertainty) | + |
| `oil_pct_change` | Monthly % change in Brent crude (FE only) | + |
| `ln_brent` | Log Brent crude price (RE only) | + |

## 🧮 Methodology

Model: `ln_cpi_it = α + β1·post_crisis_t + β2·ln_neer_it + β3·policy_rate_it + β4·vix_t + u_it`

Three panel estimators are compared:

1. **Pooled OLS** — ignores country-specific heterogeneity (baseline, expected biased)
2. **Fixed Effects (Within)** — removes time-invariant country heterogeneity; preferred if individual effects correlate with regressors
3. **Random Effects** — more efficient than FE, but only consistent if individual effects are uncorrelated with regressors

**Model selection via diagnostic tests:**

| Test | Null Hypothesis | Result | Decision |
|---|---|---|---|
| Breusch–Pagan LM | No unobserved individual effects | χ²(1) = 1954.7, p < 0.001 | Reject → panel model required, Pooled OLS inconsistent |
| Hausman | RE is consistent | χ²(3) = 16.98, p = 0.0007 | Reject → Fixed Effects preferred |

**➡️ Fixed Effects with Arellano–Bond HC3 robust standard errors is the preferred specification.**

## 🏆 Key Results

**Main regression (Fixed Effects, robust SE):**

| Variable | Coefficient | Robust p-value |
|---|---|---|
| `post_crisis` | **+0.0456*** (+4.56% log CPI)** | p < 0.001 |
| `ln_neer` | 0.021 (insignificant) | p = 0.929 |
| `policy_rate` | 0.0085 | p = 0.093 |
| `vix` | 0.0029*** | p < 0.001 |

**Headline finding:** The 2026 Gulf Crisis is associated with an approximate **+4.6% increase in log CPI**, robust to country fixed effects and cluster-robust inference — a magnitude comparable to the COVID-19 supply-shock inflation impact of 2020–2021.

### Importers vs. Exporters (sub-sample FE)

| Variable | Importers (n=116) | Exporters (n=156) |
|---|---|---|
| `post_crisis` | 0.003 (not significant) | **+0.057*** |
| `ln_neer` | −0.616*** | +0.166*** |
| `policy_rate` | −0.027*** | +0.011*** |

**Key insight — structural asymmetry:** The crisis raised inflation significantly among **exporters** (revenue windfall → domestic demand-pull pressure), while **importers** saw a muted, statistically insignificant effect in the short run — likely due to demand compression from higher energy costs offsetting cost-push pressure. Exchange-rate and policy-rate coefficients also *reverse sign* between the two groups, illustrating why pooling importers and exporters together is economically misleading.

## 🛠️ Tech Stack

- **Language:** R
- **Panel data modeling:** `plm` (Pooled OLS, Fixed Effects, Random Effects)
- **Diagnostics & robust inference:** `lmtest`, `sandwich` (Arellano/HC3 robust SE, Breusch-Pagan, Hausman test)
- **Data manipulation:** `dplyr`
- **Visualization:** `ggplot2`
- **Regression tables:** `stargazer`

## 📁 Repository Structure

```
Gulf-Crisis-Oil-Panel-Econometrics/
├── README.md
├── ADV_Econometrics_Report.pdf              # Full project report (methodology, R code, results)
├── Econometrics_Interpretations.pdf         # Detailed interpretation & full R console output
├── ADV_Econometrics_Project_-_Panel_dataset.csv   # Panel dataset
└── panel_analysis_final.R                   # Full R analysis script
```

## 🚀 Reproducing the Analysis

```r
# Install required packages
install.packages(c("plm", "lmtest", "sandwich", "dplyr", "ggplot2", "stargazer"))

# Run the full analysis
source("panel_analysis_final.R")
```

The script simulates the panel dataset, estimates all three models, runs the diagnostic tests, computes robust standard errors, performs the importer/exporter sub-sample analysis, and outputs a consolidated regression table.

## ⚠️ Limitations

- **Short post-crisis window** — only 1–2 months of post-crisis data; full pass-through (wage effects, inflation expectations) typically takes 12–18 months, so the +4.6% estimate likely understates the eventual cumulative impact
- **Endogeneity** — policy rate, VIX, and NEER are plausibly endogenous; ordinary FE doesn't address this (IV-FE or system GMM would be needed)
- **Small N, large T panel** — only 7 countries limits cross-sectional power and the precision of the Hausman test
- **Unbalanced panel** — India and South Africa exit before the crisis window, biasing the importer post-crisis coefficient toward zero
- **Dummy conflation** — `post_crisis` absorbs all concurrent shocks from March 2026 onward, not solely the oil-price effect
- **Simulated scenario** — the 2026 Gulf Crisis is hypothetical and built for pedagogical purposes; results should not be read as real-world forecasts

## 🔮 Future Work

- Address policy rate endogeneity via Instrumental Variables (IV-FE) or System GMM
- Extend the time series once more post-crisis data is available
- Apply a Synthetic Control Method (SCM) to better isolate the causal oil-shock effect
- Expand the panel to include more emerging-market importers

## 📚 Key References

- Hamilton, J. D. (2009). *Causes and Consequences of the Oil Shock of 2007–08*. Brookings Papers on Economic Activity.
- Kilian, L. (2014). *Oil Price Shocks: Causes and Consequences*. Annual Review of Resource Economics.
- Hausman, J. A. (1978). *Specification Tests in Econometrics*. Econometrica.
- Baltagi, B. H. (2021). *Econometric Analysis of Panel Data* (6th ed.). Springer.
- Croissant, Y., & Millo, G. (2008). *Panel Data Econometrics in R: The plm Package*. Journal of Statistical Software.

## 📄 Full Reports

- [`ADV_Econometrics_Report.pdf`](./ADV_Econometrics_Report.pdf) — full methodology, R code, and regression results
- [`Econometrics_Interpretations.pdf`](./Econometrics_Interpretations.pdf) — in-depth economic interpretation and complete R console output

---

*This project was completed as part of the Advanced Econometrics coursework at Tunis Business School.*
