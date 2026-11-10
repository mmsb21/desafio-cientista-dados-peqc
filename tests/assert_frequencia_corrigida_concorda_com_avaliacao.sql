-- Regra: a frequência de uma turma não pode depender do sistema que a registrou.
-- A tabela de frequência (corrigida com o ×100) e a frequência oficial da avaliação medem
-- a mesma coisa em sistemas diferentes: por turma, precisam andar juntas. Se a correlação
-- cair abaixo de 0,6, a origem mudou a fórmula ou a correção deixou de valer.
-- Usa o 1º semestre da avaliação, a janela que a frequência cobre, e turmas com 5+ alunos.
with frequencia as (
    select
        id_turma,
        sum(soma_frequencia_pct) / sum(qtd_registros) as frequencia_corrigida_pct
    from {{ ref('int_educacao__frequencia_vinculo') }}
    group by id_turma
),
avaliacao as (
    select
        id_turma,
        avg(frequencia_media_semestre_pct) as frequencia_oficial_pct
    from {{ ref('int_educacao__aluno_frequencia') }}
    where frequencia_media_semestre_pct is not null
    group by id_turma
    having count(*) >= 5
),
comparacao as (
    select
        count(*) as turmas,
        corr(frequencia.frequencia_corrigida_pct, avaliacao.frequencia_oficial_pct) as correlacao
    from frequencia
    inner join avaliacao on frequencia.id_turma = avaliacao.id_turma
)
select *
from comparacao
where correlacao is null or correlacao < 0.6
