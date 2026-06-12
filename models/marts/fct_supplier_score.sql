with gaps as (
    select * from {{ ref('fct_dimension_gaps') }}
    where measurement_date = '2024-01-01'
),

supplier_metrics as (
    select
        supplier_name,
        count(distinct product_id)                              as total_products,
        round(avg(abs(pct_mod_supp)), 2)                       as avg_gap_mod_supp,
        round(avg(abs(pct_mod_if)), 2)                         as avg_gap_mod_if,
        round(avg(abs(pct_if_supp)), 2)                        as avg_gap_if_supp,
        countif(alert_mod_supp in ('HIGH_O','HIGH_U'))         as high_alerts,
        countif(alert_mod_supp in ('MED_O','MED_U'))           as med_alerts,
        countif(alert_mod_supp = 'OK')                         as ok_count
    from gaps
    group by supplier_name
),

scored as (
    select *,
        round((avg_gap_mod_supp * 0.5) + (avg_gap_mod_if * 0.3) + (avg_gap_if_supp * 0.2), 2) as weighted_gap_score,
        round(greatest(0, 100 - ((avg_gap_mod_supp * 0.5) + (avg_gap_mod_if * 0.3) + (avg_gap_if_supp * 0.2)) * 2), 1) as reliability_score,
        case
            when high_alerts >= 2 then 'URGENT — Immediate review with buyer'
            when high_alerts = 1  then 'HIGH — Schedule review next cycle'
            when med_alerts >= 2  then 'MEDIUM — Monitor next measurement'
            else 'LOW — No action needed'
        end as buyer_action
    from supplier_metrics
)
select supplier_name, total_products, avg_gap_mod_supp, avg_gap_mod_if, avg_gap_if_supp,
       weighted_gap_score, reliability_score, high_alerts, med_alerts, ok_count, buyer_action
from scored
order by reliability_score asc
