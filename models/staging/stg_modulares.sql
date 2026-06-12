with source as (
    select * from {{ ref('modulares') }}
),
renamed as (
    select
        product_id,
        shelf_id,
        store_id,
        real_height_cm,
        real_width_cm,
        real_depth_cm,
        shelf_capacity_units,
        measurement_date,
        is_pilot_store,
        real_height_cm * real_width_cm * real_depth_cm as real_volume_cm3
    from source
)
select * from renamed
