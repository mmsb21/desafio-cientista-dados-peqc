{#
    Limite do intervalo de confiança de Wilson para a proporção sucessos / total, de 0 a 1.
    Usado nas taxas por escola e por bairro: com proporções pequenas e amostras de tamanhos
    muito diferentes, o intervalo normal pode sair negativo ou estreito demais e o de Wilson não.

    Argumentos: expressões SQL de sucessos e de total, o limite ('inferior' ou 'superior')
    e z (1.96 para 95% de confiança).
    Exemplo: {{ wilson_ic('qtd_alunos_abaixo_75', 'qtd_alunos', 'inferior') }}
#}
{% macro wilson_ic(sucessos, total, limite, z=1.96) -%}
    {%- if limite not in ['inferior', 'superior'] -%}
        {{ exceptions.raise_compiler_error("wilson_ic: limite deve ser 'inferior' ou 'superior', não '" ~ limite ~ "'") }}
    {%- endif -%}
    {%- set p = '(' ~ sucessos ~ ' / ' ~ total ~ ')' -%}
    {%- set n = '(' ~ total ~ ')' -%}
    {%- set centro = p ~ ' + ' ~ z ~ ' * ' ~ z ~ ' / (2 * ' ~ n ~ ')' -%}
    {%- set margem = z ~ ' * sqrt(' ~ p ~ ' * (1 - ' ~ p ~ ') / ' ~ n ~ ' + ' ~ z ~ ' * ' ~ z ~ ' / (4 * ' ~ n ~ ' * ' ~ n ~ '))' -%}
    {%- set denominador = '(1 + ' ~ z ~ ' * ' ~ z ~ ' / ' ~ n ~ ')' -%}
    {%- if limite == 'inferior' -%}
        greatest(0, ({{ centro }} - {{ margem }}) / {{ denominador }})
    {%- else -%}
        least(1, ({{ centro }} + {{ margem }}) / {{ denominador }})
    {%- endif -%}
{%- endmacro %}
