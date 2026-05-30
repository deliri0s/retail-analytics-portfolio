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
        round(m.real_volume_cm3 - s.declared_volume_cm3, 2) as volume_gap_cm3,
        round((m.real_volume_cm3 - s.declared_volume_cm3) / s.declared_volume_cm3 * 100, 2) as volume_gap_pct
    from itemfile i
    left join suppliers s on i.product_id = s.product_id
    left join modulares m on i.product_id = m.product_id
)

select * from joined
