-- Ad-hoc analysis (compiled, not built): top 10 products by realized gross margin.
select
    p.product_name,
    p.category,
    sum(i.gross_margin)                     as gross_margin,
    round(sum(i.gross_margin) / sum(i.line_amount), 4) as margin_pct
from {{ ref('fct_order_items') }} i
join {{ ref('dim_products') }} p on p.product_id = i.product_id
where i.order_status in ('placed', 'shipped', 'completed')
group by 1, 2
order by gross_margin desc
limit 10
