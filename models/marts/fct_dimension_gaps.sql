with suppliers as (select * from {{ ref('stg_suppliers') }}),
itemfile as (select * from {{ ref('stg_itemfile') }}),
modulares as (select * from {{ ref('stg_modulares') }}),

joined as (
    select
        i.product_id, i.product_name, i.category, i.is_pre_sliced, s.supplier_name,
        m.store_id, m.shelf_id, m.measurement_date, m.is_pilot_store,
        m.shelf_capacity_units,
        s.declared_height_cm, s.declared_width_cm, s.declared_depth_cm, s.declared_volume_cm3,
        i.itemfile_height_cm, i.itemfile_width_cm, i.itemfile_depth_cm, i.itemfile_volume_cm3,
        m.real_height_cm, m.real_width_cm, m.real_depth_cm, m.real_volume_cm3,
        round(m.real_volume_cm3 - s.declared_volume_cm3, 2) as dif_mod_supp,
        round((m.real_volume_cm3 - s.declared_volume_cm3) / s.declared_volume_cm3 * 100, 2) as pct_mod_supp,
        round(m.real_volume_cm3 - i.itemfile_volume_cm3, 2) as dif_mod_if,
        round((m.real_volume_cm3 - i.itemfile_volume_cm3) / i.itemfile_volume_cm3 * 100, 2) as pct_mod_if,
        round(i.itemfile_volume_cm3 - s.declared_volume_cm3, 2) as dif_if_supp,
        round((i.itemfile_volume_cm3 - s.declared_volume_cm3) / s.declared_volume_cm3 * 100, 2) as pct_if_supp
    from itemfile i
    left join suppliers s on i.product_id = s.product_id
    left join modulares m on i.product_id = m.product_id
),

alerts as (
    select *,
        case when pct_mod_supp > 10 then 'HIGH_O' when pct_mod_supp < -10 then 'HIGH_U'
             when pct_mod_supp >= 6 then 'MED_O'  when pct_mod_supp <= -6 then 'MED_U' else 'OK' end as alert_mod_supp,
        case when pct_mod_if > 10 then 'HIGH_O'   when pct_mod_if < -10 then 'HIGH_U'
             when pct_mod_if >= 6 then 'MED_O'    when pct_mod_if <= -6 then 'MED_U'  else 'OK' end as alert_mod_if,
        case when pct_if_supp > 10 then 'HIGH_O'  when pct_if_supp < -10 then 'HIGH_U'
             when pct_if_supp >= 6 then 'MED_O'   when pct_if_supp <= -6 then 'MED_U' else 'OK' end as alert_if_supp
    from joined
)
select * from alerts
