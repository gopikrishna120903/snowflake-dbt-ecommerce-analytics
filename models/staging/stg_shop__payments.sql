with source as (
    select * from {{ source('shop', 'raw_payments') }}
)

select
    payment_id,
    order_id,
    payment_method,
    {{ normalize_status('status') }}            as payment_status,
    {{ cents_to_dollars('amount_cents') }}      as amount,
    cast(created_at as timestamp)               as created_at
from source
