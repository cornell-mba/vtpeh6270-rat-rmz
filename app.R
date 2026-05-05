# ============================================================
# VTPEH 6270 — Checkpoint 07: Shiny App
# NYC Rat Mitigation Zone Interactive Dashboard
# Siva Selvam | Cornell University | Spring 2026
# ============================================================

library(shiny)
library(shinydashboard)
library(dplyr)
library(ggplot2)
library(lubridate)
library(scales)
library(readr)
library(broom)
library(purrr)

# ============================================================
# 1. DATA LOADING
# ============================================================

complaints_raw <- read_csv("data/311-complaints.csv", show_col_types = FALSE) %>%
  rename(date = Date, zone_id = zoneID, rmz = RMZ,
         complaint_type = ComplaintType, count = Number) %>%
  mutate(date = mdy(date))

initial_raw <- read_csv("data/initial-inspections.csv", show_col_types = FALSE) %>%
  rename(date = Date, zone_id = zoneID, rmz = RMZ,
         category = Type, count = Number) %>%
  mutate(date = mdy(date))

compliance_raw <- read_csv("data/compliance-inspections.csv", show_col_types = FALSE) %>%
  rename(date = Date, zone_id = zoneID, rmz = RMZ,
         category = Type, count = Number) %>%
  mutate(date = mdy(date))

exterminator_raw <- read_csv("data/exterminator-visits.csv", show_col_types = FALSE) %>%
  rename(date = Date, zone_id = zoneID, rmz = RMZ,
         category = Thing, count = Number) %>%
  mutate(date = mdy(date))

# Constants
all_rmz <- sort(unique(complaints_raw$rmz))

rmz_colors <- c(
  "Brooklyn: Bed Stuy and Bushwick"       = "#2196F3",
  "Bronx: Grand Concourse"                = "#E91E63",
  "Manhattan: East Village and Chinatown" = "#FF9800",
  "Manhattan: Harlem"                     = "#4CAF50"
)

# Observed model parameters from CP4 / CP6 (East Village & Chinatown)
OBS_SLOPE     <- 10.4079
OBS_INTERCEPT <- 4729.8546
OBS_NOISE     <- 440.2262
OBS_MIN_COMP  <- 280
OBS_MAX_COMP  <- 422

# ============================================================
# 2. SHARED PLOT THEME
# ============================================================

app_theme <- function(base = 12) {
  theme_classic(base_size = base) +
    theme(
      plot.title    = element_text(face = "bold", size = base + 1),
      plot.subtitle = element_text(color = "grey45", size = base - 1),
      plot.caption  = element_text(color = "grey55", size = base - 2, hjust = 0),
      axis.title    = element_text(face = "bold"),
      legend.position  = "top",
      legend.title     = element_text(face = "bold"),
      panel.grid.major.y = element_line(linewidth = 0.25, color = "grey88"),
      panel.grid.minor   = element_blank()
    )
}

# ============================================================
# 3. UI
# ============================================================

ui <- dashboardPage(
  skin = "black",

  dashboardHeader(
    title = span(icon("rat"), " NYC Rat Mitigation Zones"),
    titleWidth = 280
  ),

  dashboardSidebar(
    width = 220,
    sidebarMenu(
      menuItem("About",               tabName = "about",      icon = icon("circle-info")),
      menuItem("Data Explorer",       tabName = "explorer",   icon = icon("chart-bar")),
      menuItem("Statistical Analysis",tabName = "stats",      icon = icon("chart-line")),
      menuItem("Power Simulation",    tabName = "simulation", icon = icon("flask"))
    )
  ),

  dashboardBody(
    tags$head(tags$style(HTML("
      .content-wrapper, .right-side { background-color: #f5f6fa; }
      .box { border-top: 3px solid #2c3e50; border-radius: 4px; }
      .box-header { background: #fff !important; }
      .main-header .logo { background-color: #1a252f !important; }
      .main-header .navbar { background-color: #1a252f !important; }
      .skin-black .main-sidebar { background-color: #2c3e50; }
      .skin-black .sidebar a { color: #ecf0f1 !important; }
      .skin-black .sidebar-menu > li.active > a { 
        border-left: 3px solid #e74c3c; color: #fff !important; 
      }
      .info-box { border-radius: 4px; }
      p { line-height: 1.7; }
    "))),

    tabItems(

      # ----------------------------------------------------------
      # TAB 1 : ABOUT
      # ----------------------------------------------------------
      tabItem(tabName = "about",
        fluidRow(
          box(width = 12, solidHeader = TRUE, status = "primary",
              title = "NYC Rat Mitigation Zone Analysis — Interactive Dashboard",

              h4(icon("magnifying-glass"), " Research Question"),
              p("Is the number of initial inspections higher during semiannual periods
                with more 311 rat-related complaints in NYC's Rat Mitigation Zones?"),
              hr(),

              h4(icon("book-open"), " Background"),
              p("The New York City Department of Health and Mental Hygiene (NYC DOHMH)
                monitors rat activity through Rat Mitigation Zones (RMZs) — designated
                geographic areas where inspection and enforcement resources are
                concentrated. Resident-submitted 311 complaints may reflect periods of
                heightened rat activity and could drive or co-occur with increased
                municipal inspection activity."),
              hr(),

              h4(icon("bullseye"), " App Goals"),
              tags$ul(
                tags$li(tags$b("Data Explorer:"),
                  " Visualize complaint, inspection, compliance, and exterminator
                    visit trends across all four RMZs (2022–2025)."),
                tags$li(tags$b("Statistical Analysis:"),
                  " Quantify the association between 311 complaints and initial
                    inspections using Pearson correlation and simple linear regression.
                    Select any RMZ interactively."),
                tags$li(tags$b("Power Simulation:"),
                  " Explore how effect size, sample size, and noise affect the
                    detectability of the association.")
              ),
              hr(),

              h4(icon("database"), " Data"),
              p("Source: NYC DOHMH Rat Mitigation Zone initiative."),
              tags$ul(
                tags$li("311 rat-related complaints"),
                tags$li("Initial inspections"),
                tags$li("Compliance inspections"),
                tags$li("Exterminator visits")
              ),
              p(tags$b("Time period:"), " June 2022 – June 2025 (semiannual)"),
              p(tags$b("RMZs:"),
                " Brooklyn: Bed Stuy & Bushwick | Bronx: Grand Concourse |
                  Manhattan: East Village & Chinatown | Manhattan: Harlem"),
              hr(),
              p(tags$em("Siva Selvam — VTPEH 6270: Data Analysis with R —
                Cornell University — Spring 2026"),
                style = "color: grey55; font-size: 12px;")
          )
        )
      ),

      # ----------------------------------------------------------
      # TAB 2 : DATA EXPLORER
      # ----------------------------------------------------------
      tabItem(tabName = "explorer",
        h2("Data Explorer"),
        fluidRow(
          # Sidebar panel
          box(width = 3, title = "Filters", status = "primary", solidHeader = TRUE,
              checkboxGroupInput(
                "ex_rmz", "RMZ(s):",
                choices  = all_rmz,
                selected = all_rmz
              ),
              hr(),
              radioButtons(
                "ex_dataset", "Dataset:",
                choices  = c("311 Complaints", "Initial Inspections",
                             "Compliance Inspections", "Exterminator Visits"),
                selected = "311 Complaints"
              )
          ),
          # Main panel
          box(width = 9, title = "Total Activity Over Time by RMZ",
              status = "primary", solidHeader = TRUE,
              plotOutput("ex_trend", height = "370px"),
              p(tags$em("Points = one semiannual period. Lines connect periods within each RMZ."),
                style = "font-size:11px; color:grey;")
          )
        ),
        fluidRow(
          box(width = 12, title = "Subtype Breakdown (Stacked by Period)",
              status = "info", solidHeader = TRUE,
              plotOutput("ex_breakdown", height = "310px"))
        )
      ),

      # ----------------------------------------------------------
      # TAB 3 : STATISTICAL ANALYSIS
      # ----------------------------------------------------------
      tabItem(tabName = "stats",
        h2("Statistical Analysis"),
        fluidRow(
          box(width = 3, title = "Settings", status = "danger", solidHeader = TRUE,
              selectInput(
                "st_rmz", "Select RMZ:",
                choices  = all_rmz,
                selected = "Manhattan: East Village and Chinatown"
              ),
              hr(),
              checkboxInput("st_labels", "Show period labels", value = TRUE),
              hr(),
              tags$b("Method"), br(),
              tags$ul(
                tags$li("Pearson correlation"),
                tags$li("Simple linear regression")
              ),
              tags$b("Variables"), br(),
              tags$ul(
                tags$li("X: Total 311 complaints (semiannual)"),
                tags$li("Y: Total initial inspections (semiannual)")
              ),
              p(tags$b("α = 0.05"), style = "margin-top:6px;")
          ),
          box(width = 9,
              title = "Scatter Plot: 311 Complaints vs. Initial Inspections",
              status = "danger", solidHeader = TRUE,
              plotOutput("st_scatter", height = "390px"))
        ),
        fluidRow(
          valueBoxOutput("vb_r",    width = 4),
          valueBoxOutput("vb_p",    width = 4),
          valueBoxOutput("vb_r2",   width = 4)
        ),
        fluidRow(
          box(width = 6, title = "Pearson Correlation",
              status = "warning", solidHeader = TRUE,
              tableOutput("st_cor_tbl")),
          box(width = 6, title = "Linear Regression Coefficients",
              status = "warning", solidHeader = TRUE,
              tableOutput("st_reg_tbl"))
        ),
        fluidRow(
          box(width = 12, status = "warning", solidHeader = FALSE,
              p(tags$b("Interpretation note:"),
                "n = 7 semiannual observations. Pearson correlation assumes
                approximate normality; Shapiro-Wilk tests on both variables
                returned p > 0.05 for the East Village & Chinatown RMZ (CP6).
                Results should be interpreted as descriptive given the small
                sample size."))
        )
      ),

      # ----------------------------------------------------------
      # TAB 4 : POWER SIMULATION
      # ----------------------------------------------------------
      tabItem(tabName = "simulation",
        h2("Power Analysis Simulation"),
        p("Explore how effect size (slope), sample size, and noise level
          influence the detectability of the association between 311 complaints
          and initial inspections. Based on the simulation framework from CP4."),
        fluidRow(
          box(width = 3, title = "Parameters", status = "success", solidHeader = TRUE,
              sliderInput("sim_slope", "Effect Size — Slope (a):",
                          min = 0, max = 25, value = OBS_SLOPE, step = 0.5),
              sliderInput("sim_n", "Sample Size (n):",
                          min = 5, max = 150, value = 20, step = 5),
              sliderInput("sim_noise", "Noise — SD (ε):",
                          min = 50, max = 900, value = round(OBS_NOISE), step = 10),
              hr(),
              p(tags$b("Observed parameters (CP6):"),
                br(), paste0("Slope = ", OBS_SLOPE),
                br(), paste0("Intercept = ", round(OBS_INTERCEPT, 0)),
                br(), paste0("Noise SD ≈ ", round(OBS_NOISE, 0)),
                br(), "n = 7"),
              hr(),
              actionButton("run_sim", "  Run Simulation",
                           icon = icon("play"),
                           class = "btn-success btn-block",
                           style = "font-weight: bold;"),
              br(),
              p(tags$em("20 simulation runs per click. Each run uses the
                observed intercept and complaint range."),
                style = "font-size:11px; color:grey;")
          ),
          box(width = 9,
              title = "Mean Initial Inspections Across Complaint Quartiles (20 Runs)",
              status = "success", solidHeader = TRUE,
              plotOutput("sim_lines", height = "390px"),
              p(tags$em("Each line = one simulation run. Steeper lines indicate
                a stronger detectable association. Low slope or high noise
                produces flat, overlapping lines."),
                style = "font-size:11px; color:grey;")
          )
        ),
        fluidRow(
          box(width = 12, title = "Simulation Summary (Averaged Across 20 Runs)",
              status = "success", solidHeader = TRUE,
              tableOutput("sim_tbl"))
        )
      )

    ) # end tabItems
  ) # end dashboardBody
)   # end dashboardPage

# ============================================================
# 4. SERVER
# ============================================================

server <- function(input, output, session) {

  # ==========================================================
  # TAB 2 : DATA EXPLORER
  # ==========================================================

  # Aggregated total by date & RMZ for selected dataset
  ex_totals <- reactive({
    req(length(input$ex_rmz) > 0)
    switch(input$ex_dataset,
      "311 Complaints" =
        complaints_raw %>% filter(rmz %in% input$ex_rmz) %>%
        group_by(date, rmz) %>% summarise(total = sum(count), .groups = "drop"),
      "Initial Inspections" =
        initial_raw %>% filter(rmz %in% input$ex_rmz) %>%
        group_by(date, rmz) %>% summarise(total = sum(count), .groups = "drop"),
      "Compliance Inspections" =
        compliance_raw %>% filter(rmz %in% input$ex_rmz) %>%
        group_by(date, rmz) %>% summarise(total = sum(count), .groups = "drop"),
      "Exterminator Visits" =
        exterminator_raw %>% filter(rmz %in% input$ex_rmz) %>%
        group_by(date, rmz) %>% summarise(total = sum(count), .groups = "drop")
    )
  })

  # Subtype breakdown
  ex_subtypes <- reactive({
    req(length(input$ex_rmz) > 0)
    switch(input$ex_dataset,
      "311 Complaints" =
        complaints_raw %>% filter(rmz %in% input$ex_rmz) %>%
        group_by(date, category = complaint_type) %>%
        summarise(total = sum(count), .groups = "drop"),
      "Initial Inspections" =
        initial_raw %>% filter(rmz %in% input$ex_rmz) %>%
        group_by(date, category) %>%
        summarise(total = sum(count), .groups = "drop"),
      "Compliance Inspections" =
        compliance_raw %>% filter(rmz %in% input$ex_rmz) %>%
        group_by(date, category) %>%
        summarise(total = sum(count), .groups = "drop"),
      "Exterminator Visits" =
        exterminator_raw %>% filter(rmz %in% input$ex_rmz) %>%
        group_by(date, category) %>%
        summarise(total = sum(count), .groups = "drop")
    )
  })

  output$ex_trend <- renderPlot({
    df <- ex_totals(); req(nrow(df) > 0)
    ggplot(df, aes(x = date, y = total, color = rmz, group = rmz)) +
      geom_line(linewidth = 1) +
      geom_point(size = 3) +
      scale_color_manual(values = rmz_colors, name = "RMZ") +
      scale_x_date(date_labels = "%b %Y", date_breaks = "6 months") +
      scale_y_continuous(labels = comma) +
      labs(title = paste(input$ex_dataset, "— Total Count by RMZ"),
           x = "Reporting Period", y = "Total Count") +
      app_theme() +
      theme(axis.text.x = element_text(angle = 30, hjust = 1))
  })

  output$ex_breakdown <- renderPlot({
    df <- ex_subtypes(); req(nrow(df) > 0)
    lab <- switch(input$ex_dataset,
      "311 Complaints"       = "Complaint Type",
      "Initial Inspections"  = "Inspection Type",
      "Compliance Inspections" = "Inspection Outcome",
      "Exterminator Visits"  = "Visit Type"
    )
    ggplot(df, aes(x = date, y = total, fill = category)) +
      geom_col(position = "stack") +
      scale_x_date(date_labels = "%b %Y", date_breaks = "6 months") +
      scale_y_continuous(labels = comma) +
      labs(title = paste(input$ex_dataset, "— Subtype Breakdown (Selected RMZs)"),
           x = "Reporting Period", y = "Count", fill = lab) +
      app_theme() +
      theme(axis.text.x = element_text(angle = 30, hjust = 1))
  })

  # ==========================================================
  # TAB 3 : STATISTICAL ANALYSIS
  # ==========================================================

  analysis_df <- reactive({
    req(input$st_rmz)
    c_df <- complaints_raw %>% filter(rmz == input$st_rmz) %>%
      group_by(date) %>% summarise(complaints_n = sum(count), .groups = "drop")
    i_df <- initial_raw %>% filter(rmz == input$st_rmz) %>%
      group_by(date) %>% summarise(initial_inspections_n = sum(count), .groups = "drop")
    c_df %>% inner_join(i_df, by = "date") %>% arrange(date) %>%
      mutate(period_label = format(date, "%b %Y"))
  })

  cor_res <- reactive({
    df <- analysis_df(); req(nrow(df) >= 3)
    cor.test(df$complaints_n, df$initial_inspections_n, method = "pearson")
  })

  fit_res <- reactive({
    df <- analysis_df(); req(nrow(df) >= 3)
    lm(initial_inspections_n ~ complaints_n, data = df)
  })

  output$st_scatter <- renderPlot({
    df <- analysis_df(); req(nrow(df) >= 3)
    p <- ggplot(df, aes(x = complaints_n, y = initial_inspections_n)) +
      geom_smooth(method = "lm", se = TRUE, color = "#c0392b",
                  linewidth = 0.9, fill = "#f5c6cb") +
      geom_point(size = 3.5, color = "#2c3e50") +
      scale_x_continuous(labels = comma) +
      scale_y_continuous(labels = comma) +
      labs(
        title = paste("311 Complaints vs. Initial Inspections —", input$st_rmz),
        subtitle = "Semiannual reporting periods, June 2022 – June 2025",
        x = "311 rat-related complaints (semiannual total)",
        y = "Initial inspections (semiannual total)",
        caption = "Shaded band = 95% confidence interval of the regression line."
      ) + app_theme()
    if (input$st_labels)
      p <- p + geom_text(aes(label = period_label),
                          vjust = -0.85, hjust = 0.5, size = 3, color = "grey40")
    p
  })

  output$vb_r <- renderValueBox({
    valueBox(round(cor_res()$estimate, 3), "Pearson r",
             icon = icon("link"), color = "red")
  })

  output$vb_p <- renderValueBox({
    pv <- round(cor_res()$p.value, 4)
    valueBox(pv, "p-value",
             icon = icon("chart-line"),
             color = if (pv < 0.05) "green" else "yellow")
  })

  output$vb_r2 <- renderValueBox({
    valueBox(round(summary(fit_res())$r.squared, 3), "R² (model fit)",
             icon = icon("bullseye"), color = "blue")
  })

  output$st_cor_tbl <- renderTable({
    ct <- cor_res()
    data.frame(
      Statistic = c("Pearson r", "t statistic", "df",
                    "p-value", "95% CI lower", "95% CI upper"),
      Value = round(c(ct$estimate, ct$statistic, ct$parameter,
                      ct$p.value, ct$conf.int[1], ct$conf.int[2]), 4)
    )
  }, striped = TRUE, bordered = TRUE, hover = TRUE)

  output$st_reg_tbl <- renderTable({
    ft <- tidy(fit_res()) %>%
      mutate(across(where(is.numeric), ~ round(., 4))) %>%
      rename(Term = term, Estimate = estimate,
             `Std. Error` = std.error,
             `t value` = statistic, `p-value` = p.value)
    r2_row <- data.frame(Term = "R²",
                          Estimate = round(summary(fit_res())$r.squared, 4),
                          `Std. Error` = NA_real_, `t value` = NA_real_,
                          `p-value` = NA_real_, check.names = FALSE)
    bind_rows(ft, r2_row)
  }, striped = TRUE, bordered = TRUE, hover = TRUE, na = "—")

  # ==========================================================
  # TAB 4 : POWER SIMULATION
  # ==========================================================

  sim_results <- eventReactive(input$run_sim, {
    set.seed(sample(1:9999, 1))   # different seed each click
    n_runs <- 20

    map_dfr(seq_len(n_runs), function(i) {
      comp_sim  <- runif(input$sim_n, OBS_MIN_COMP, OBS_MAX_COMP)
      insp_sim  <- OBS_INTERCEPT +
                   input$sim_slope * comp_sim +
                   rnorm(input$sim_n, 0, input$sim_noise)
      insp_sim  <- pmax(0, insp_sim)

      data.frame(complaints_n = comp_sim, inspections = insp_sim) %>%
        mutate(quartile = ntile(complaints_n, 4)) %>%
        group_by(quartile) %>%
        summarise(mean_insp = mean(inspections), .groups = "drop") %>%
        mutate(run = i)
    })
  })

  output$sim_lines <- renderPlot({
    df <- sim_results()
    ggplot(df, aes(x = quartile, y = mean_insp,
                    group = factor(run), color = factor(run))) +
      geom_line(linewidth = 0.8, alpha = 0.55) +
      geom_point(size = 2, alpha = 0.7) +
      scale_x_continuous(breaks = 1:4,
                          labels = c("Q1\n(Lowest)", "Q2", "Q3", "Q4\n(Highest)")) +
      scale_y_continuous(labels = comma) +
      scale_color_viridis_d(guide = "none") +
      labs(
        title = paste0("Simulated Mean Inspections by Complaint Quartile  |  ",
                        "n = ", input$sim_n, "  |  slope = ", input$sim_slope,
                        "  |  noise SD = ", input$sim_noise),
        subtitle = paste0("20 runs  |  Intercept fixed at observed value (",
                           round(OBS_INTERCEPT, 0), ")"),
        x = "Complaint Quartile", y = "Mean Initial Inspections"
      ) + app_theme()
  })

  output$sim_tbl <- renderTable({
    sim_results() %>%
      group_by(quartile) %>%
      summarise(
        `Mean inspections (avg across 20 runs)` = round(mean(mean_insp), 0),
        `SD across runs`                         = round(sd(mean_insp), 0),
        `Min`                                    = round(min(mean_insp), 0),
        `Max`                                    = round(max(mean_insp), 0),
        .groups = "drop"
      ) %>%
      mutate(quartile = c("Q1 (Lowest complaints)", "Q2", "Q3",
                           "Q4 (Highest complaints)")) %>%
      rename(`Complaint Quartile` = quartile)
  }, striped = TRUE, bordered = TRUE, hover = TRUE)

}

# ============================================================
# 5. LAUNCH
# ============================================================
shinyApp(ui = ui, server = server)
