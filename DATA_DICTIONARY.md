# Data Dictionary — Retail Analytics Portfolio

Complete reference for every dataset and field in this project.

---

## 1. Seeds (Raw Data)

### `suppliers.csv`
Declared dimensions and packaging info as negotiated with each supplier.

| Field | Type | Description |
|---|---|---|
| `supplier_id` | string | Unique identifier per supplier-product combination |
| `supplier_name` | string | Fictional supplier name |
| `product_id` | string | Product identifier (links to itemfile and modulares) |
| `declared_height_cm` | float | Height declared by the supplier, in cm |
| `declared_width_cm` | float | Width declared by the supplier, in cm |
| `declared_depth_cm` | float | Depth declared by the supplier, in cm |
| `units_per_box` | int | Number of units the supplier declares fit per shipping box |

### `itemfile.csv`
Product specs as registered internally by the Itemfile team.

| Field | Type | Description |
|---|---|---|
| `product_id` | string | Product identifier |
| `product_name` | string | Product display name |
| `category` | string | One of: Oils, Biscuits, Detergents, Pasta, Cookies |
| `itemfile_height_cm` | float | Height registered by Itemfile, in cm |
| `itemfile_width_cm` | float | Width registered by Itemfile, in cm |
| `itemfile_depth_cm` | float | Depth registered by Itemfile, in cm |
| `created_date` | date | Date the item was registered |
| `is_pre_sliced` | boolean | Cookies only — whether the box comes pre-divided into smaller sub-units, reducing manual sorting time during replenishment |

### `modulares.csv`
Real dimensions measured directly on the shelf, across 5 stores and 3 monthly snapshots.

| Field | Type | Description |
|---|---|---|
| `product_id` | string | Product identifier |
| `shelf_id` | string | Shelf location identifier |
| `store_id` | string | One of: ST001–ST005 |
| `real_height_cm` | float | Height measured physically on the shelf, in cm |
| `real_width_cm` | float | Width measured physically on the shelf, in cm |
| `real_depth_cm` | float | Depth measured physically on the shelf, in cm |
| `shelf_capacity_units` | int | Real number of units that physically fit on the shelf |
| `measurement_date` | date | Snapshot date (2024-01-01, 2024-02-01, 2024-03-01) |
| `is_pilot_store` | boolean | True only for ST003 — the control group store using corrected, accurate dimensions |

---

## 2. Staging Models

Staging models clean and standardize each raw source, adding a calculated volume field (`height × width × depth`) for comparison.

| Model | Source | Adds |
|---|---|---|
| `stg_suppliers` | `suppliers` | `declared_volume_cm3` |
| `stg_itemfile` | `itemfile` | `itemfile_volume_cm3` |
| `stg_modulares` | `modulares` | `real_volume_cm3` |

---

## 3. Mart Models

### `fct_dimension_gaps` — Single Source of Truth
Joins all 3 sources and calculates the gap between every pair.

| Field | Description |
|---|---|
| `dif_mod_supp` / `pct_mod_supp` | Volume difference / % difference: Modulares vs Suppliers |
| `dif_mod_if` / `pct_mod_if` | Volume difference / % difference: Modulares vs Itemfile |
| `dif_if_supp` / `pct_if_supp` | Volume difference / % difference: Itemfile vs Suppliers |
| `alert_mod_supp` | Directional classification of the Mod vs Supp gap |
| `alert_mod_if` | Directional classification of the Mod vs Itemfile gap |
| `alert_if_supp` | Directional classification of the Itemfile vs Supplier gap |

**Alert values:**
- `HIGH_O` — gap > 10%, product **oversized** (bigger than expected)
- `HIGH_U` — gap < -10%, product **undersized** (smaller than expected)
- `MED_O` / `MED_U` — gap between 6% and 10% in either direction
- `OK` — gap under 6%, within tolerance

### `fct_replenishment` — Operational Time Impact
Translates dimension gaps into a real operational cost: extra time spent restocking shelves.

| Field | Description |
|---|---|
| `replenishments_per_day_declared` | Expected restocking trips per day, based on supplier-declared box capacity |
| `replenishments_per_day_real` | Actual restocking trips per day, based on real shelf capacity |
| `extra_replenishments_per_day` | Difference between the two — the inefficiency caused by the gap |
| `extra_minutes_per_day` | Extra time per day (5 min per replenishment), halved if `is_pre_sliced = true` |
| `replenishment_impact` | Business-readable label: efficiency loss, planogram risk, monitor, or no impact |

### `fct_supplier_score` — Reliability Ranking
One row per supplier, scoring how trustworthy their declared dimensions are.

| Field | Description |
|---|---|
| `avg_gap_mod_supp` / `_mod_if` / `_if_supp` | Average absolute gap % per comparison, baseline snapshot only |
| `weighted_gap_score` | Combined score: 50% Mod vs Supp + 30% Mod vs Itemfile + 20% Itemfile vs Supp |
| `reliability_score` | 0–100 scale, where 100 = perfectly accurate, 0 = worst possible gap |
| `high_alerts` / `med_alerts` / `ok_count` | Count of products in each alert tier for this supplier |
| `buyer_action` | Recommended next step for procurement: Urgent, High, Medium, or Low priority |

### `fct_store_performance` — Store Comparison
Compares replenishment efficiency across stores, using the pilot store (corrected dimensions) as a benchmark.

| Field | Description |
|---|---|
| `store_type` | "Pilot Store — Corrected Dimensions" or "Standard Store" |
| `avg_gap_pct` | Average absolute dimension gap for that store and month |
| `estimated_extra_replenishments` | Estimated extra restocking trips caused by gaps, vs the pilot store baseline |
| `estimated_extra_minutes_per_day` | Estimated extra time per day, vs the pilot store baseline |

---

## 4. Data Quality (dbt tests)

29 automated tests validate the pipeline on every run:

- **Uniqueness** — `supplier_id` (staging), `product_id` (Itemfile), `supplier_name` (score)
- **Not null** — all key business fields across every model
- **Accepted values** — `category` (5 valid categories), `store_id` (5 valid stores), all 3 `alert_*` fields (5 valid alert states), `replenishment_impact` (4 valid labels)

Run with: `dbt test`
