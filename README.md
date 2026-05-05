# NYC Rat Mitigation Zone Analysis
**VTPEH 6270 — Data Analysis with R | Cornell University | Spring 2026**
**Author:** Siva Selvam | Contact via Canvas or course email

---

## Research Question
Is the number of initial inspections higher during semiannual periods with more 311 rat-related complaints in the Manhattan: East Village and Chinatown RMZ?

---

## Key Outputs
- **Shiny App:** https://s0mzwx-siva-selvam.shinyapps.io/shiny_app/
- **Final Report:** `final_report.Rmd` (knit to PDF)

---

## Data
Source: NYC Department of Health and Mental Hygiene — Rat Mitigation Zone initiative

| File | Description |
|---|---|
| 311-complaints.csv | Semiannual 311 rat-related complaint counts by RMZ |
| initial-inspections.csv | Semiannual initial inspection counts by RMZ |
| compliance-inspections.csv | Semiannual compliance inspection counts by RMZ |
| exterminator-visits.csv | Semiannual exterminator visit counts by RMZ |

**Time period:** June 2022 – June 2025 | **Primary RMZ:** Manhattan: East Village and Chinatown

---

## Repository Structure
vtpeh6270-rat-rmz/
├── README.md                  # Project overview
├── data_dictionary.md         # Variable descriptions
├── 01_data_exploration.R      # Data loading, cleaning, visualizations
├── 02_simulation.R            # Simulation study
├── final_report.Rmd           # Final report (knit to PDF)
├── app.R                      # Shiny app source code
├── 311-complaints.csv         # Raw data
├── initial-inspections.csv    # Raw data
├── compliance-inspections.csv # Raw data
└── exterminator-visits.csv    # Raw data

---

## How to Reproduce

**Install packages:**
```r
install.packages(c("readr", "dplyr", "ggplot2", "lubridate",
                   "scales", "broom", "knitr", "tidyr", "purrr",
                   "gridExtra", "shiny", "shinydashboard"))
```

**Run analysis scripts:**
```r
source("01_data_exploration.R")
source("02_simulation.R")
```

**Knit final report:**
```r
rmarkdown::render("final_report.Rmd")
```

**Run Shiny app locally:**
```r
shiny::runApp("app.R")
```

Or visit the live app: https://s0mzwx-siva-selvam.shinyapps.io/shiny_app/

---

## References
1. NYC DOHMH. Rat Mitigation Zones. https://a816-dohbesp.nyc.gov/IndicatorPublic/data-features/rat-mitigation-zones/
2. Himsworth et al. (2013). Rats, cities, people, and pathogens. *Vector-Borne and Zoonotic Diseases*, 13(6).
3. Brown et al. (2017). Resident perceptions of urban wildlife. *Human Dimensions of Wildlife*, 22(4).
4. Parsons et al. (2021). Rats and the COVID-19 pandemic. *Urban Ecosystems*, 24.

---

## AI Tool Disclosure
Claude (Anthropic) was used to assist with drafting R code for data exploration, simulation, the final report, and the Shiny app. All code, analyses, and interpretations were reviewed and validated by the author.
