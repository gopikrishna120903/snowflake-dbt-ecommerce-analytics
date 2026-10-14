-- Share of each monthly signup cohort (first purchase month) that ordered again N months later.
with orders as (
    select
        customer_id,
        {{ dbt.date_trunc('month', 'order_date') }}             as order_month
    from {{ ref('fct_orders') }}
    where is_revenue_order
),

first_orders as (
    select customer_id, min(order_month) as cohort_month
    from orders
    group by customer_id
),

activity as (
    select distinct
        f.cohort_month,
        o.customer_id,
        {{ dbt.datediff('f.cohort_month', 'o.order_month', 'month') }} as months_since_first_order
    from orders o
    join first_orders f on f.customer_id = o.customer_id
),

cohort_sizes as (
    select cohort_month, count(*) as cohort_customers
    from first_orders
    group by cohort_month
)

select
    a.cohort_month,
    a.months_since_first_order,
    c.cohort_customers,
    count(*)                                                    as active_customers,
    round(count(*) * 1.0 / c.cohort_customers, 4)               as retention_rate
from activity a
join cohort_sizes c on c.cohort_month = a.cohort_month
group by a.cohort_month, a.months_since_first_order, c.cohort_customers
