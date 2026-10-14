-- Daily finance view. Revenue is recognized on the order date; refunds on the order date too,
-- so a returned order nets to zero for the day it was placed.
select
    order_date,
    count(*)                                                        as orders,
    sum(case when is_revenue_order then 1 else 0 end)               as revenue_orders,
    sum(items_subtotal)                                             as gross_merchandise_value,
    sum(discount_amount)                                            as discounts,
    sum(shipping_amount)                                            as shipping_charged,
    sum(amount_collected)                                           as collected,
    sum(amount_refunded)                                            as refunded,
    sum(net_revenue)                                                as net_revenue,
    round(sum(net_revenue) / nullif(sum(case when is_revenue_order then 1 else 0 end), 0), 2) as average_order_value
from {{ ref('fct_orders') }}
group by order_date
