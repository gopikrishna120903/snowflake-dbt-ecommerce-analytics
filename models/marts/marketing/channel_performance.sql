-- Customer value by acquisition channel.
select
    acquisition_channel,
    count(*)                                                                as customers,
    sum(case when lifetime_orders > 0 then 1 else 0 end)                    as purchasers,
    round(sum(case when lifetime_orders > 0 then 1 else 0 end) * 1.0 / count(*), 4) as purchase_rate,
    round(avg(case when lifetime_orders > 0 then lifetime_value end), 2)    as avg_ltv_per_purchaser,
    sum(case when customer_segment in ('repeat', 'vip') then 1 else 0 end)  as repeat_or_vip_customers
from {{ ref('dim_customers') }}
group by acquisition_channel
