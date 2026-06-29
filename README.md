# Retail Analytics Portfolio — dbt + BigQuery + GCP

## Problem Statement

In a large retail environment, three teams — **Suppliers**, **Itemfile**, and **Modulares** — operated with completely disconnected databases. This caused a critical gap: supplier-declared product dimensions rarely matched the real measurements registered in store shelves, leading to inventory miscalculations, inefficient replenishment, and poor shelf space utilization.

Nobody had a unified view of the problem — or knew which of the three sources to trust.

## Solution

Built an end-to-end Analytics Engineering pipeline that:

- **Ingests** data from three isolated sources into Google BigQuery
- **Transforms** raw data using dbt Core with a layered architecture (staging → marts)
- **Calculates** three directional gap metrics across all data sources
- **Quantifies** the operational cost of those gaps in replenishment time
- **Scores** supplier reliability to prioritize buyer action
- **Compares** store-level performance using a pilot store as a control group
- **Validates** data quality with 29 automated dbt tests

## Tech Stack

| Tool | Purpose |
|------|---------|
| Google BigQuery | Cloud data warehouse |
| dbt Core 1.11 | Data transformation, testing & documentation |
| GCP | Cloud infrastructure |
| Looker Studio | Dashboard & visualization |
| Git + GitHub | Version control |

## Dataset

Fictional retail data simulating a real-world scenario:

- **20 suppliers** with varying reliability profiles (from highly accurate to systematically inaccurate)
- **75 products** across **5 categories**: Oils, Biscuits, Detergents, Pasta, Cookies
- **5 stores**, including 1 pilot store with corrected dimensions (control group)
- **Cookies** category includes an `is_pre_sliced` flag — pre-sliced boxes reduce manual sorting time during replenishment, independent of any dimension gap

## Project Architecture

```
seeds (raw data)
    ├── suppliers.csv     → supplier declared dimensions + units per box
    ├── itemfile.csv      → itemfile team registered dimensions + category + is_pre_sliced
    └── modulares.csv     → real shelf measurements across 5 stores

models/
    ├── staging/
    │   ├── stg_suppliers.sql
    │   ├── stg_itemfile.sql
    │   └── stg_modulares.sql
    └── marts/
        ├── fct_dimension_gaps.sql      ← single source of truth + directional alerts
        ├── fct_replenishment.sql       ← operational time impact of gaps
        ├── fct_supplier_score.sql      ← weighted reliability score (0-100)
        └── fct_store_performance.sql   ← store comparison vs pilot store
```

## Key Metrics

**Three gap comparisons**, measured in absolute (cm³) and percentage (%):

| Metric | Comparison | Business Question |
|--------|-----------|-------------------|
| `pct_mod_supp` | Modulares vs Suppliers | Does the supplier deliver products that fit the shelf? |
| `pct_mod_if` | Modulares vs Itemfile | Does the system reflect what is actually on the shelf? |
| `pct_if_supp` | Itemfile vs Suppliers | Does the negotiated spec match what Itemfile registered? |

**Directional alert classification** — distinguishes *oversized* from *undersized* products, because the operational impact is different:

| Alert | Meaning | Impact |
|-------|---------|--------|
| `HIGH_O` | Product significantly bigger than expected | Fewer units fit per shelf → more replenishments |
| `HIGH_U` | Product significantly smaller than expected | Shelf space wasted → planogram not respected |
| `MED_O` / `MED_U` | Moderate gap in either direction | Monitor |
| `OK` | Within acceptable tolerance | No action needed |

**Supplier reliability score (0-100)** — weighted combination of all 3 gaps, used to prioritize which suppliers need a buyer review first.

## Business Impact

- Unified 3 disconnected data sources into a single source of truth
- Identified that dimension gaps translate directly into extra replenishment time — quantified in minutes per day per product
- Built a reliability ranking across 20 suppliers, separating systematic offenders from one-off errors
- Used a pilot store with corrected dimensions as a control group to estimate potential time savings if all stores adopted accurate measurements
- Validated the entire pipeline with 29 automated data quality tests (uniqueness, nulls, accepted values)

## How to Run

```bash
# Install dependencies
pip install dbt-bigquery

# Authenticate with GCP
gcloud auth application-default login

# Load raw data
dbt seed --full-refresh

# Run transformations
dbt run

# Run data quality tests
dbt test

# Generate documentation
dbt docs generate && dbt docs serve
```

## Dashboard

Interactive dashboard built in Looker Studio with 2 pages:
- **Supplier Score** — ranking, reliability heatmap, alert distribution
- **Replenishment** — operational time impact by product and category
