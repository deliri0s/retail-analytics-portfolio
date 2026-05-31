with suppliers as (
    select * from {{ ref('stg_suppliers') }}
),

itemfile as (
    select * from {{ ref('stg_itemfile') }}
),

modulares as (
    select * from {{ ref('stg_modulares') }}
),

joined as (
    select
        i.product_id,
        i.product_name,
        i.category,
        s.supplier_name,

        -- Dimensions
        s.declared_height_cm,
        s.declared_width_cm,
        s.declared_depth_cm,
        s.declared_volume_cm3,

        i.itemfile_height_cm,
        i.itemfile_width_cm,
        i.itemfile_depth_cm,
        i.itemfile_volume_cm3,

        m.real_height_cm,
        m.real_width_cm,
        m.real_depth_cm,
        m.real_volume_cm3,

        m.shelf_id,
        m.store_id,

        -- Gap 1: Mod vs Supplier
        round(m.real_volume_cm3 - s.declared_volume_cm3, 2) as dif_mod_supp,
        round((m.real_volume_cm3 - s.declared_volume_cm3) / s.declared_volume_cm3 * 100, 2) as pct_mod_supp,

        -- Gap 2: Mod vs Itemfile
        round(m.real_volume_cm3 - i.itemfile_volume_cm3, 2) as dif_mod_if,
        round((m.real_volume_cm3 - i.itemfile_volume_cm3) / i.itemfile_volume_cm3 * 100, 2) as pct_mod_if,

        -- Gap 3: Itemfile vs Supplier
        round(i.itemfile_volume_cm3 - s.declared_volume_cm3, 2) as dif_if_supp,
        round((i.itemfile_volume_cm3 - s.declared_volume_cm3) / s.declared_volume_cm3 * 100, 2) as pct_if_supp

    from itemfile i
    left join suppliers s on i.product_id = s.product_id
    left join modulares m on i.product_id = m.product_id
),

alerts as (
    select
        *,

        -- Alert: Mod vs Supplier
        case
            when pct_mod_supp > 10  then 'HIGH_OVER'
            when pct_mod_supp < -10 then 'HIGH_UNDER'
            when pct_mod_supp >= 6  then 'MEDIUM_OVER'
            when pct_mod_supp <= -6 then 'MEDIUM_UNDER'
            else 'OK'
        end as alert_mod_supp,

        -- Alert: Mod vs Itemfile
        case
            when pct_mod_if > 10  then 'HIGH_OVER'
            when pct_mod_if < -10 then 'HIGH_UNDER'
            when pct_mod_if >= 6  then 'MEDIUM_OVER'
            when pct_mod_if <= -6 then 'MEDIUM_UNDER'
            else 'OK'
        end as alert_mod_if,

        -- Alert: Itemfile vs Supplier
        case
            when pct_if_supp > 10  then 'HIGH_OVER'
            when pct_if_supp < -10 then 'HIGH_UNDER'
            when pct_if_supp >= 6  then 'MEDIUM_OVER'
            when pct_if_supp <= -6 then 'MEDIUM_UNDER'
            else 'OK'
        end as alert_if_supp

    from joined
)

select * from alerts
