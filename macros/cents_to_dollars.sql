{#- Convert integer cents to a fixed-precision dollar amount.
    Dispatched so each warehouse uses its native numeric type. -#}
{% macro cents_to_dollars(column_name, scale=2) -%}
    {{ return(adapter.dispatch('cents_to_dollars')(column_name, scale)) }}
{%- endmacro %}

{% macro default__cents_to_dollars(column_name, scale) -%}
    cast({{ column_name }} / 100.0 as numeric(16, {{ scale }}))
{%- endmacro %}

{% macro snowflake__cents_to_dollars(column_name, scale) -%}
    cast({{ column_name }} / 100 as number(16, {{ scale }}))
{%- endmacro %}

{% macro duckdb__cents_to_dollars(column_name, scale) -%}
    cast({{ column_name }} / 100.0 as decimal(16, {{ scale }}))
{%- endmacro %}
