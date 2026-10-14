with source as (
    select * from {{ source('shop', 'raw_order_items') }}
)

select
    order_item_id,
    order_id,
    product_id,
    quantity,
    {{ cents_to_dollars('unit_price_cents') }}              as unit_price,
    {{ cents_to_dollars('quantity * unit_price_cents') }}   as line_amount
from source
