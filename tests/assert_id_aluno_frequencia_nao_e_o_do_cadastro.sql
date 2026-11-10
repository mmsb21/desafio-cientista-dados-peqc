-- Premissa: o id de aluno da tabela de frequência não identifica o mesmo aluno do cadastro.
-- O teste de relationships passa (todo id existe no cadastro), mas os pares (aluno, turma)
-- da frequência quase nunca existem na matrícula. Por isso a frequência só se liga às
-- outras tabelas por turma e escola, nunca pelo aluno.
-- O teste falha se mais de 1% dos pares passarem a existir na matrícula: sinal de que a
-- origem corrigiu o mapeamento e o join por aluno pode ser reavaliado.
with pares_frequencia as (
    select distinct
        id_aluno_frequencia as id_aluno,
        id_turma
    from {{ ref('int_educacao__frequencia_vinculo') }}
),
cruzamento as (
    select
        count(*) as pares,
        countif(matricula.id_aluno is not null) as pares_na_matricula
    from pares_frequencia
    left join {{ ref('stg_educacao__aluno_turma') }} as matricula
        on pares_frequencia.id_aluno = matricula.id_aluno
        and pares_frequencia.id_turma = matricula.id_turma
)
select
    pares,
    pares_na_matricula,
    round(100 * pares_na_matricula / pares, 2) as pct_na_matricula
from cruzamento
where pares_na_matricula / pares > 0.01
