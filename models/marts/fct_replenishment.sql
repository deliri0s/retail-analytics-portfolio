with gaps as (select * from {{ ref('fct_dimension_gaps') }}),
suppliers as (select * from {{ ref('stg_suppliers') }}),

replenishment as (
    select
        g.product_id, g.product_name, g.category, g.is_pre_sliced, g.supplier_name,
        g.store_id, g.measurement_date, g.is_pilot_store,
        g.alert_mod_supp, g.pct_mod_supp,
        s.units_per_box,
        g.shelf_capacity_units,
        round(100.0 / s.units_per_box, 1)        as replenishments_per_day_declared,
        round(100.0 / g.shelf_capacity_units, 1)  as replenishments_per_day_real,
        round((100.0 / g.shelf_capacity_units) - (100.0 / s.units_per_box), 1) as extra_replenishments_per_day,
        -- Pre-sliced boxes cut replenishment time in half (less manual sorting)
        round(
            (((100.0 / g.shelf_capacity_units) - (100.0 / s.units_per_box)) * 5)
            * (case when g.is_pre_sliced = 'true' then 0.5 else 1.0 end)
        , 1) as extra_minutes_per_day,
        case
            when g.alert_mod_supp = 'HIGH_O' then 'Efficiency loss — more replenishments needed'
            when g.alert_mod_supp = 'HIGH_U' then 'Planogram risk — shelf space wasted'
            when g.alert_mod_supp in ('MED_O','MED_U') then 'Monitor — moderate impact'
            else 'No impact'
        end as replenishment_impact
    from gaps g
    left join suppliers s on g.product_id = s.product_id
)
select * from replenishment
