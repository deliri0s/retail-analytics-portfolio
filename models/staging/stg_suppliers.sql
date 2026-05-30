with source as (
    select * from {{ ref('suppliers') }}
),

renamed as (
    select
        supplier_id,
        supplier_name,
        product_id,
        declared_height_cm,
        declared_width_cm,
        declared_depth_cm,
        declared_height_cm * declared_width_cm * declared_depth_cm as declared_volume_cm3
    from source
)

select * from renamed
