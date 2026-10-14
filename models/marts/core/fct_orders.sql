{{
    config(
        materialized = 'incremental',
        unique_key = 'order_id',
        incremental_strategy = 'merge' if target.type == 'snowflake' else 'delete+insert',
        on_schema_change = 'append_new_columns'
    )
}}

with orders as (
    select * from {{ ref('stg_shop__orders') }}
    {% if is_incremental() %}
    -- only orders changed since the last run, minus a lookback for late-arriving updates
    where updated_at >= (
        select {{ dbt.dateadd('day', -var('incremental_lookback_days'), 'max(updated_at)') }} from {{ this }}
    )
    {% endif %}
),

-- numbered over ALL orders, so incremental runs still get the right sequence per customer
order_numbers as (
    select
        order_id,
        row_number() over (partition by customer_id order by ordered_at, order_id) as customer_order_number
    from {{ ref('stg_shop__orders') }}
),

items as (select * from {{ ref('int_orders__item_totals') }}),
payments as (select * from {{ ref('int_orders__payments') }})

select
    o.order_id,
    o.customer_id,
    o.ordered_at,
    o.order_date,
    o.order_status,
    i.line_count,
    i.units,
    i.items_subtotal,
    o.discount_amount,
    o.shipping_amount,
    i.items_subtotal - o.discount_amount + o.shipping_amount            as order_total,
    coalesce(p.amount_collected, 0)                                     as amount_collected,
    coalesce(p.amount_refunded, 0)                                      as amount_refunded,
    coalesce(p.amount_collected, 0) - coalesce(p.amount_refunded, 0)    as net_revenue,
    coalesce(p.credit_card_amount, 0)                                   as credit_card_amount,
    coalesce(p.paypal_amount, 0)                                        as paypal_amount,
    coalesce(p.gift_card_amount, 0)                                     as gift_card_amount,
    coalesce(p.bank_transfer_amount, 0)                                 as bank_transfer_amount,
    coalesce(p.failed_attempts, 0)                                      as failed_payment_attempts,
    o.order_status in ('placed', 'shipped', 'completed')                as is_revenue_order,
    n.customer_order_number,
    o.updated_at
from orders o
join items i on i.order_id = o.order_id
left join payments p on p.order_id = o.order_id
join order_numbers n on n.order_id = o.order_id
