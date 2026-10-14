"""Generate deterministic raw e-commerce data as dbt seeds.

The data is intentionally messy in the ways real source systems are:
duplicate customer rows from updates, inconsistent status casing, emails with
stray whitespace and capitals, failed payment attempts, and refunds.
"""
from __future__ import annotations

import csv
import random
from datetime import datetime, timedelta
from pathlib import Path

SEED = 7
START = datetime(2024, 1, 1)
END = datetime(2025, 12, 31)
OUT = Path(__file__).resolve().parents[1] / "seeds"

CATEGORIES = {
    "Outerwear": (60, 220), "Footwear": (45, 180), "Tops": (15, 70),
    "Bottoms": (25, 95), "Accessories": (8, 60), "Gear": (20, 300),
}
COUNTRIES = [("US", 0.70), ("CA", 0.12), ("GB", 0.10), ("AU", 0.08)]
CHANNELS = [("organic", 0.35), ("paid_search", 0.25), ("social", 0.20), ("email", 0.12), ("referral", 0.08)]
FIRST = ["Ava", "Liam", "Noah", "Emma", "Mia", "Ethan", "Priya", "Arjun", "Sofia", "Lucas", "Zoe", "Ravi"]
LAST = ["Smith", "Patel", "Garcia", "Kim", "Nguyen", "Johnson", "Reddy", "Lopez", "Brown", "Chen"]


def pick(rng, pairs):
    return rng.choices([p for p, _ in pairs], [w for _, w in pairs])[0]


def ts(d: datetime) -> str:
    return d.strftime("%Y-%m-%d %H:%M:%S")


def write(name, header, rows):
    with (OUT / f"{name}.csv").open("w", newline="") as f:
        w = csv.writer(f, lineterminator="\n")
        w.writerow(header)
        w.writerows(rows)


def main(n_customers=2500, n_orders=12000):
    rng = random.Random(SEED)
    OUT.mkdir(exist_ok=True)

    products = []
    pid = 1
    for cat, (lo, hi) in CATEGORIES.items():
        for _ in range(20):
            price = round(rng.uniform(lo, hi), 2)
            products.append((pid, f"{cat[:-1] if cat.endswith('s') else cat} {pid:03d}", cat,
                             int(price * 100), int(price * rng.uniform(0.35, 0.6) * 100)))
            pid += 1
    write("raw_products", ["product_id", "product_name", "category", "price_cents", "unit_cost_cents"], products)

    customers, signup = [], {}
    for cid in range(1, n_customers + 1):
        fn, ln = rng.choice(FIRST), rng.choice(LAST)
        created = START + timedelta(days=rng.randint(0, 690), seconds=rng.randint(0, 86399))
        signup[cid] = created
        email = f"{fn}.{ln}{cid}@Example.com"
        if rng.random() < 0.15:
            email = f"  {email.upper()} "
        country = pick(rng, COUNTRIES)
        channel = pick(rng, CHANNELS)
        customers.append([cid, fn, ln, email, country, channel, ts(created), ts(created)])
        if rng.random() < 0.08:  # later update: customer moved country -> duplicate row in the extract
            upd = created + timedelta(days=rng.randint(30, 300))
            if upd < END:
                customers.append([cid, fn, ln, email.strip().lower(), pick(rng, COUNTRIES), channel, ts(created), ts(upd)])
    write("raw_customers", ["customer_id", "first_name", "last_name", "email", "country", "acquisition_channel",
                            "created_at", "updated_at"], customers)

    orders, items, payments = [], [], []
    item_id = pay_id = 1
    # repeat buyers: a skewed distribution of orders per customer
    weights = [rng.paretovariate(1.6) for _ in range(n_customers)]
    for oid in range(1, n_orders + 1):
        cid = rng.choices(range(1, n_customers + 1), weights)[0]
        placed = signup[cid] + timedelta(days=int(rng.expovariate(1 / 120)), seconds=rng.randint(0, 86399))
        if placed > END:
            placed = END - timedelta(days=rng.randint(0, 30), seconds=rng.randint(0, 86399))
        r = rng.random()
        status = "completed" if r < 0.78 else "shipped" if r < 0.86 else "returned" if r < 0.94 else "cancelled"
        if placed > END - timedelta(days=5) and status == "completed":
            status = "placed"
        messy = rng.choice([status, status, status, status.upper(), status.title()])

        n_lines = rng.choices([1, 2, 3, 4], [0.5, 0.3, 0.15, 0.05])[0]
        subtotal = 0
        for prod in rng.sample(products, n_lines):
            qty = rng.choices([1, 2, 3], [0.8, 0.15, 0.05])[0]
            items.append((item_id, oid, prod[0], qty, prod[3]))
            subtotal += qty * prod[3]
            item_id += 1
        discount = int(subtotal * rng.choice([0, 0, 0, 0.1, 0.15, 0.2]))
        shipping = 0 if subtotal >= 7500 else 799
        total = subtotal - discount + shipping
        updated = placed + timedelta(days=rng.randint(0, 10))
        if updated > END:
            updated = END
        orders.append((oid, cid, ts(placed), messy, discount, shipping, ts(updated)))

        method = rng.choices(["credit_card", "paypal", "gift_card", "bank_transfer"], [0.6, 0.25, 0.08, 0.07])[0]
        if rng.random() < 0.06:  # a failed attempt before the successful one
            payments.append((pay_id, oid, method, "failed", total, ts(placed))); pay_id += 1
        if status == "cancelled":
            payments.append((pay_id, oid, method, "failed", total, ts(placed))); pay_id += 1
            continue
        if method == "credit_card" and total > 4000 and rng.random() < 0.25:  # split with a gift card
            gift = rng.randint(1000, 2500)
            payments.append((pay_id, oid, "gift_card", "success", gift, ts(placed))); pay_id += 1
            payments.append((pay_id, oid, method, "success", total - gift, ts(placed))); pay_id += 1
        else:
            payments.append((pay_id, oid, method, "success", total, ts(placed))); pay_id += 1
        if status == "returned":
            payments.append((pay_id, oid, method, "refunded", -total, ts(updated))); pay_id += 1

    write("raw_orders", ["order_id", "customer_id", "ordered_at", "status", "discount_cents", "shipping_cents",
                         "updated_at"], orders)
    write("raw_order_items", ["order_item_id", "order_id", "product_id", "quantity", "unit_price_cents"], items)
    write("raw_payments", ["payment_id", "order_id", "payment_method", "status", "amount_cents", "created_at"], payments)
    print({"customers": len(customers), "orders": len(orders), "items": len(items), "payments": len(payments)})


if __name__ == "__main__":
    main()
