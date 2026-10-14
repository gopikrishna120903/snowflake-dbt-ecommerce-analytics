with customers as (
    select * from {{ ref('stg_shop__customers') }}
),

order_stats as (
    select
        customer_id,
        min(ordered_at)                                                     as first_order_at,
        max(ordered_at)                                                     as last_order_at,
        sum(case when is_revenue_order then 1 else 0 end)                   as lifetime_orders,
        sum(net_revenue)                                                    as lifetime_value,
        sum(case when order_status = 'returned' then 1 else 0 end)          as returned_orders
    from {{ ref('fct_orders') }}
    group by customer_id
)

select
    c.customer_id,
    c.full_name,
    c.email,
    c.country_code,
    c.acquisition_channel,
    c.created_at                                                            as signed_up_at,
    s.first_order_at,
    s.last_order_at,
    coalesce(s.lifetime_orders, 0)                                          as lifetime_orders,
    coalesce(s.lifetime_value, 0)                                           as lifetime_value,
    coalesce(s.returned_orders, 0)                                          as returned_orders,
    {{ dbt.datediff('cast(s.last_order_at as date)', "cast('" ~ var('as_of_date', '2025-12-31') ~ "' as date)", 'day') }} as days_since_last_order,
    case
        when s.first_order_at is null                         then 'prospect'
        when coalesce(s.lifetime_orders, 0) >= 5
             and coalesce(s.lifetime_value, 0) >= 750         then 'vip'
        when coalesce(s.lifetime_orders, 0) >= 2              then 'repeat'
        else 'one_time'
    end                                                                     as customer_segment
from customers c
left join order_stats s on s.customer_id = c.customer_id
