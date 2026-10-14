-- Every paid order must have collected exactly its order total (items - discount + shipping).
-- Returned orders must be fully refunded. Cancelled orders must collect nothing.
select order_id, order_status, order_total, amount_collected, amount_refunded
from {{ ref('fct_orders') }}
where
    (order_status in ('placed', 'shipped', 'completed', 'returned') and amount_collected <> order_total)
    or (order_status = 'returned' and amount_refunded <> amount_collected)
    or (order_status = 'cancelled' and amount_collected <> 0)
