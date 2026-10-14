{#- Source systems send status values in mixed case and with stray spaces. -#}
{% macro normalize_status(column_name) -%}
    lower(trim({{ column_name }}))
{%- endmacro %}
