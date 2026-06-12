with gaps as (select * from {{ ref('fct_dimension_gaps') }}),

store_metrics as (
    select
        store_id, is_pilot_store, measurement_date,
        count(distinct product_id)                              as total_products,
        countif(alert_mod_supp in ('HIGH_O','HIGH_U'))         as high_alerts,
        countif(alert_mod_supp in ('MED_O','MED_U'))           as med_alerts,
        countif(alert_mod_supp = 'OK')                         as ok_count,
        round(avg(abs(pct_mod_supp)), 2)                       as avg_gap_pct,
        sum(shelf_capacity_units)                              as total_shelf_capacity
    from gaps
    group by store_id, is_pilot_store, measurement_date
),

with_improvement as (
    select *,
        case when is_pilot_store = true then 'Pilot Store — Corrected Dimensions' else 'Standard Store' end as store_type,
        round(avg_gap_pct * total_products * 0.5, 1)     as estimated_extra_replenishments,
        round(avg_gap_pct * total_products * 0.5 * 5, 1) as estimated_extra_minutes_per_day
    from store_metrics
)
select * from with_improvement
order by measurement_date, is_pilot_store desc, avg_gap_pct asc
