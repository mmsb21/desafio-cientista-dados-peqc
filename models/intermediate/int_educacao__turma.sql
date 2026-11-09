-- Turma com escola e cobertura em cada fonte: 1 linha por turma que aparece na frequência,
-- na matrícula ou na avaliação.
-- A escola de uma turma só existe na frequência, a única tabela com turma e escola juntas.
-- Turmas sem escola ficam no modelo, marcadas, em vez de serem descartadas: quem consome
-- decide o que fazer com elas (o mart por escola não as alcança; uma análise por idade, sim).
{{ config(materialized='table') }}

with frequencia as (
    select
        id_turma,
        id_escola,
        count(distinct id_aluno_frequencia) as qtd_alunos_frequencia
    from {{ ref('stg_educacao__frequencia') }}
    group by id_turma, id_escola
),
matricula as (
    select
        id_turma,
        count(*) as qtd_alunos_matricula
    from {{ ref('stg_educacao__aluno_turma') }}
    group by id_turma
),
avaliacao as (
    select
        id_turma,
        count(distinct id_aluno) as qtd_alunos_avaliacao
    from {{ ref('stg_educacao__avaliacao') }}
    group by id_turma
),
escola as (
    select * from {{ ref('stg_educacao__escola') }}
),
-- União das turmas das três fontes, para não perder as que aparecem em uma só.
turmas as (
    select id_turma from frequencia
    union distinct
    select id_turma from matricula
    union distinct
    select id_turma from avaliacao
)
select
    turmas.id_turma,
    frequencia.id_escola,
    escola.id_bairro_escola,
    frequencia.id_turma is not null as tem_frequencia,
    matricula.id_turma is not null as tem_matricula,
    avaliacao.id_turma is not null as tem_avaliacao,
    coalesce(frequencia.qtd_alunos_frequencia, 0) as qtd_alunos_frequencia,
    coalesce(matricula.qtd_alunos_matricula, 0) as qtd_alunos_matricula,
    coalesce(avaliacao.qtd_alunos_avaliacao, 0) as qtd_alunos_avaliacao
from turmas
left join frequencia on turmas.id_turma = frequencia.id_turma
left join matricula on turmas.id_turma = matricula.id_turma
left join avaliacao on turmas.id_turma = avaliacao.id_turma
left join escola on frequencia.id_escola = escola.id_escola
