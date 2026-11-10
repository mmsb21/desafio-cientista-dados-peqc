-- Regra: um aluno não pode ter mais faltas do que dias letivos no período.
-- Na origem, 100 − frequencia_bruta = faltas/dias, então esse valor não pode passar de 1.
-- A extração tem um resíduo de registros assim, que a intermediate zera. O teste aceita
-- esse resíduo, mas falha se ele passar de 0,1% dos registros: aí deixou de ser ruído.
with registros as (
    select
        count(*) as total,
        countif(100 - frequencia_bruta > 1) as acima_dos_dias
    from {{ ref('stg_educacao__frequencia') }}
)
select
    total,
    acima_dos_dias,
    round(100 * acima_dos_dias / total, 3) as pct_acima_dos_dias
from registros
where acima_dos_dias / total > 0.001
