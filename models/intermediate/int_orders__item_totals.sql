select
    order_id,
    count(*)                    as line_count,
    sum(quantity)               as units,
    sum(line_amount)            as items_subtotal
from {{ ref('stg_shop__order_items') }}
group by order_id
