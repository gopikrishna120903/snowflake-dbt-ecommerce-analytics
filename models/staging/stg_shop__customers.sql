with source as (
    select * from {{ source('shop', 'raw_customers') }}
),

latest as (
    -- the extract keeps every update; keep the newest row per customer
    select *
    from source
    qualify row_number() over (partition by customer_id order by updated_at desc) = 1
)

select
    customer_id,
    first_name,
    last_name,
    first_name || ' ' || last_name          as full_name,
    lower(trim(email))                      as email,
    upper(country)                          as country_code,
    acquisition_channel,
    cast(created_at as timestamp)           as created_at,
    cast(updated_at as timestamp)           as updated_at
from latest
