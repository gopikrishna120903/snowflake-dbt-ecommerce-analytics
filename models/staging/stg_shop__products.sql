with source as (
    select * from {{ source('shop', 'raw_products') }}
)

select
    product_id,
    product_name,
    category,
    {{ cents_to_dollars('price_cents') }}       as list_price,
    {{ cents_to_dollars('unit_cost_cents') }}   as unit_cost
from source
