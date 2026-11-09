-- Frequência por vínculo (aluno × turma × escola) no período coberto pela tabela de frequência.
-- A origem gravou frequencia = 100 − faltas/dias, sem o ×100. Como faltas/dias = 100 − frequencia,
-- a frequência certa sai da própria coluna: 100 − 100 × (100 − frequencia_bruta).
-- Cada registro é uma disciplina num período; a frequência do vínculo é a média simples dos
-- registros, então cada período pesa igual.
{{ config(materialized='table') }}

with frequencia as (
    select * from {{ ref('stg_educacao__frequencia') }}
),
corrigida as (
    select
        id_escola,
        id_turma,
        id_aluno_frequencia,
        disciplina,
        data_inicio,
        data_fim,
        100 - 100 * (100 - frequencia_bruta) as frequencia_calculada_pct
    from frequencia
),
limitada as (
    select
        *,
        greatest(frequencia_calculada_pct, 0) as frequencia_pct,
        frequencia_calculada_pct < 0 as frequencia_limitada
    from corrigida
)
select
    id_escola,
    id_turma,
    id_aluno_frequencia,
    count(*) as qtd_registros,
    count(distinct disciplina) as qtd_disciplinas,
    count(distinct data_inicio) as qtd_periodos,
    min(data_inicio) as primeira_data,
    max(data_fim) as ultima_data,
    sum(frequencia_pct) as soma_frequencia_pct,
    avg(frequencia_pct) as frequencia_media_pct,
    countif(frequencia_limitada) as qtd_registros_limitados
from limitada
group by id_escola, id_turma, id_aluno_frequencia
