-- One row per order: what was collected, what was refunded, and how.
select
    order_id,
    sum(case when payment_status = 'success'  then amount else 0 end)   as amount_collected,
    sum(case when payment_status = 'refunded' then -amount else 0 end)  as amount_refunded,
    sum(case when payment_status = 'success' and payment_method = 'credit_card'   then amount else 0 end) as credit_card_amount,
    sum(case when payment_status = 'success' and payment_method = 'paypal'        then amount else 0 end) as paypal_amount,
    sum(case when payment_status = 'success' and payment_method = 'gift_card'     then amount else 0 end) as gift_card_amount,
    sum(case when payment_status = 'success' and payment_method = 'bank_transfer' then amount else 0 end) as bank_transfer_amount,
    sum(case when payment_status = 'failed' then 1 else 0 end)          as failed_attempts
from {{ ref('stg_shop__payments') }}
group by order_id
