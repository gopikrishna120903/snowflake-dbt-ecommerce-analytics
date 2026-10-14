{#- Like dbt_utils.unique_combination_of_columns, without needing the package. -#}
{% test dbt_utils_free_unique_combination(model, columns) %}
select {{ columns | join(', ') }}
from {{ model }}
group by {{ columns | join(', ') }}
having count(*) > 1
{% endtest %}
