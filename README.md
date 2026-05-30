# Retail Analytics Portfolio — dbt + BigQuery + GCP

## Problem Statement

In a large retail environment, three teams — **Suppliers**, **Itemfile**, and **Modulares** — operated with completely disconnected databases. This caused a critical gap: supplier-declared product dimensions rarely matched the real measurements registered in store shelves, leading to inventory miscalculations and inefficient shelf space utilization.

Nobody had a unified view of the problem. The impact was silent but significant.

## Solution

Built an end-to-end Analytics Engineering pipeline that:

- **Ingested** data from three isolated sources into Google BigQuery
- **Transformed** raw data using dbt Core with a layered architecture (staging → marts)
- **Calculated** three dimension gap metrics across all data sources
- **Delivered** a single source of truth enabling monthly monitoring of dimension accuracy

## Tech Stack

| Tool | Purpose |
|------|---------|
| Google BigQuery | Cloud data warehouse |
| dbt Core 1.11 | Data transformation & documentation |
| GCP | Cloud infrastructure |
| Power BI | Dashboard & visualization |
| Git + GitHub | Version control |

## Project Architecture

## Key Metrics

Three gap comparisons measured in both absolute (cm³) and percentage (%):

| Metric | Comparison | Business Question |
|--------|-----------|-------------------|
| `gap_reality_vs_system` | Modulares vs Itemfile | Does the system reflect what is actually on the shelf? |
| `gap_reality_vs_supplier` | Modulares vs Suppliers | Does the supplier deliver products that fit the shelf? |
| `gap_system_vs_supplier` | Itemfile vs Suppliers | Does the negotiated spec match what Itemfile registered? |

By triangulating these three gaps, the business can pinpoint exactly **where the error originates** — whether it's a supplier accuracy problem, an internal registration issue, or a misalignment between procurement and operations.

## Business Impact

- Unified 3 disconnected data sources into a single source of truth
- Enabled monthly monitoring of supplier dimension accuracy
- Identified root causes of inventory discrepancies at shelf level
- Prototype delivered with significant potential ROI for the business

## How to Run

```bash
# Install dependencies
pip install dbt-bigquery

# Authenticate with GCP
gcloud auth application-default login

# Load raw data
dbt seed

# Run transformations
dbt run

# Generate documentation
dbt docs generate && dbt docs serve
```
