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
        real_height_cm * real_width_cm * real_depth_cm as real_volume_cm3,
        last_updated
    from source
)

select * from renamed
