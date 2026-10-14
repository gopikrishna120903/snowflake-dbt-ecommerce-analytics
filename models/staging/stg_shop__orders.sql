with source as (
    select * from {{ source('shop', 'raw_orders') }}
)

select
    order_id,
    customer_id,
    cast(ordered_at as timestamp)                       as ordered_at,
    cast(ordered_at as date)                            as order_date,
    {{ normalize_status('status') }}                    as order_status,
    {{ cents_to_dollars('discount_cents') }}            as discount_amount,
    {{ cents_to_dollars('shipping_cents') }}            as shipping_amount,
    cast(updated_at as timestamp)                       as updated_at
from source
