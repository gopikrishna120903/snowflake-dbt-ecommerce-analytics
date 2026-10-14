select
    oi.order_item_id,
    oi.order_id,
    o.customer_id,
    o.order_date,
    o.order_status,
    oi.product_id,
    p.category,
    oi.quantity,
    oi.unit_price,
    oi.line_amount,
    oi.quantity * p.unit_cost                       as line_cost,
    oi.line_amount - oi.quantity * p.unit_cost      as gross_margin
from {{ ref('stg_shop__order_items') }} oi
join {{ ref('stg_shop__orders') }} o on o.order_id = oi.order_id
join {{ ref('stg_shop__products') }} p on p.product_id = oi.product_id
