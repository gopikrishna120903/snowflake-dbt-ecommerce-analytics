-- The finance mart must not gain or lose revenue compared to the order fact.
with daily as (select sum(net_revenue) as total from {{ ref('fct_daily_revenue') }}),
     orders as (select sum(net_revenue) as total from {{ ref('fct_orders') }})
select daily.total, orders.total
from daily cross join orders
where daily.total <> orders.total
