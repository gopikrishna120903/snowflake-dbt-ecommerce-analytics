-- Share of units returned in each product category.
select
    category,
    sum(quantity)                                                       as units_ordered,
    sum(case when order_status = 'returned' then quantity else 0 end)   as units_returned,
    round(sum(case when order_status = 'returned' then quantity else 0 end) * 1.0 / sum(quantity), 4) as return_rate
from {{ ref('fct_order_items') }}
where order_status <> 'cancelled'
group by category