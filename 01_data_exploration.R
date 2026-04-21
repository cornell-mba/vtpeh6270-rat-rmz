# Data Dictionary — NYC Rat Mitigation Zone Datasets

**Source:** New York City Department of Health and Mental Hygiene (NYC DOHMH)  
**Program:** Rat Mitigation Zone (RMZ) Initiative  
**Time Period:** June 2022 – June 2025 (semiannual reporting periods)  
**Geographic Scope:** All NYC Rat Mitigation Zones

---

## Shared Variables (present in all four datasets)

| Variable (original) | Renamed to | Type | Class | Description |
|---|---|---|---|---|
| `Date` | `date` | Discrete (time) | Date | End date of the semiannual reporting period (e.g., 6/30/2022, 12/31/2022). Format: m/d/YYYY |
| `zoneID` | `zone_id` | Categorical | numeric | Unique numeric identifier for each Rat Mitigation Zone |
| `RMZ` | `rmz` | Categorical | character | Full name of the Rat Mitigation Zone (e.g., "Manhattan: East Village and Chinatown") |
| `Number` | `count` | Discrete (count) | numeric | Number of events recorded for the given type, zone, and reporting period |

---

## Dataset-Specific Variables

### 311-complaints.csv

| Variable (original) | Renamed to | Type | Class | Description |
|---|---|---|---|---|
| `ComplaintType` | `complaint_type` | Categorical | character | Type of 311 rat-related complaint (e.g., "Rat sighting", "Mouse sighting", "Signs of rodents", "Condition attracting rodents") |

### initial-inspections.csv

| Variable (original) | Renamed to | Type | Class | Description |
|---|---|---|---|---|
| `Type` | `inspection_type` | Categorical | character | Type of initial inspection outcome (e.g., "Active rat signs", "City agency", "Private property", "Failed (any reason)") |

### compliance-inspections.csv

| Variable (original) | Renamed to | Type | Class | Description |
|---|---|---|---|---|
| `Type` | `inspection_type` | Categorical | character | Type of compliance inspection outcome (e.g., "Passed", "Failed (any reason), summons issued", "Active rat signs", "Compliance inspections") |

### exterminator-visits.csv

| Variable (original) | Renamed to | Type | Class | Description |
|---|---|---|---|---|
| `Thing` | `visit_type` | Categorical | character | Type of exterminator activity (e.g., "Exterminator visits", "Bait applied") |

---

## Derived Variables (created during analysis)

| Variable | Type | Description |
|---|---|---|
| `complaints_n` | Discrete count | Total 311 complaints summed across all complaint types for a given RMZ and date |
| `initial_inspections_n` | Discrete count | Total initial inspections summed across all inspection types for a given RMZ and date |
| `complaint_burden` | Ordered factor | Binary category: "Lower complaint period" (at or below median) vs. "Higher complaint period" (above median) |
| `complaint_quartile` | Ordered integer (1–4) | Quartile rank of `complaints_n` using `ntile()` |
| `complaint_quartile_f` | Ordered factor | Labeled factor version of `complaint_quartile` |
| `period_label` | Character | Human-readable label for reporting period (e.g., "Jun 2022") |

---

## Notes

- All analyses are restricted to the **Manhattan: East Village and Chinatown** RMZ unless otherwise noted.
- Semiannual totals are computed by summing `count` across all subtypes within each RMZ and date.
- The dataset contains 7 semiannual observations for the target RMZ (June 2022 through June 2025).
