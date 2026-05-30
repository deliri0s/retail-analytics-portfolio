with source as (
    select * from {{ ref('itemfile') }}
),

renamed as (
    select
        product_id,
        product_name,
        category,
        itemfile_height_cm,
        itemfile_width_cm,
        itemfile_depth_cm,
        itemfile_height_cm * itemfile_width_cm * itemfile_depth_cm as itemfile_volume_cm3,
        created_date
    from source
)

select * from renamed
