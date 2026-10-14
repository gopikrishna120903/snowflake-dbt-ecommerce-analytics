with sales as (
    select
        product_id,
        sum(case when order_status in ('placed', 'shipped', 'completed') then quantity else 0 end)      as units_sold,
        sum(case when order_status in ('placed', 'shipped', 'completed') then line_amount else 0 end)   as gross_sales,
        sum(case when order_status = 'returned' then quantity else 0 end)                               as units_returned
    from {{ ref('fct_order_items') }}
    group by product_id
)

select
    p.product_id,
    p.product_name,
    p.category,
    p.list_price,
    p.unit_cost,
    round((p.list_price - p.unit_cost) / p.list_price, 4)                as list_margin_pct,
    coalesce(s.units_sold, 0)                                            as units_sold,
    coalesce(s.gross_sales, 0)                                           as gross_sales,
    coalesce(s.units_returned, 0)                                        as units_returned,
    round(coalesce(s.units_returned, 0) * 1.0
          / nullif(coalesce(s.units_sold, 0) + coalesce(s.units_returned, 0), 0), 4) as return_rate
from {{ ref('stg_shop__products') }} p
left join sales s on s.product_id = p.product_id
