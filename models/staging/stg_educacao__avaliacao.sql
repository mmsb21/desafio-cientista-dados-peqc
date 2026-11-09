-- Avaliação por aluno × turma × bimestre, com uma coluna de nota por disciplina.
-- Limpeza: ids em texto, bimestre como inteiro, notas com o nome da disciplina e
-- deduplicação. Inglês (`disciplina_3`) fica de fora: vem 100% nulo na origem.
with source as (
    select * from {{ source('educacao', 'avaliacao') }}
),
renamed as (
    select
        to_hex(id_aluno) as id_aluno,             -- mesmo id do cadastro de alunos
        cast(id_turma as string) as id_turma,
        cast(bimestre as int64) as bimestre,      -- chega como texto ('1' a '4')
        frequencia as frequencia_bimestre,        -- percentual 0–100 calculado pela origem; tem nulos
        disciplina_1 as nota_portugues,
        disciplina_2 as nota_ciencias,
        disciplina_4 as nota_matematica
    from source
),
-- A origem repete algumas chaves (aluno, turma, bimestre), em geral com uma das linhas
-- vazia. Fica a linha com frequência preenchida e, entre elas, a de menor frequência
-- (mais faltas), o mesmo critério da frequência; empate, a de menores notas.
deduplicado as (
    {{ dbt_utils.deduplicate(
        relation='renamed',
        partition_by='id_aluno, id_turma, bimestre',
        order_by='frequencia_bimestre is null, frequencia_bimestre, nota_portugues, nota_ciencias, nota_matematica'
    ) }}
)
select * from deduplicado
