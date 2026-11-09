-- Frequência por aluno × turma × disciplina × período (em geral mensal).
-- Limpeza: ids em texto, datas como DATE, disciplina pelo nome e deduplicação.
-- O id do aluno vira `id_aluno_frequencia` porque não identifica o mesmo aluno do cadastro.
-- `frequencia_bruta` guarda o valor da origem (gravado sem o ×100); as faltas são
-- reconstruídas na camada intermediate, com o calendário letivo.
with source as (
    select * from {{ source('educacao', 'frequencia') }}
),
renamed as (
    select
        cast(id_escola as string) as id_escola,
        to_hex(id_aluno) as id_aluno_frequencia,
        cast(id_turma as string) as id_turma,
        case disciplina
            when 'disciplina_1' then 'portugues'
            when 'disciplina_2' then 'ciencias'
            when 'disciplina_3' then 'ingles'
            when 'disciplina_4' then 'matematica'
        end as disciplina,
        cast(data_inicio as date) as data_inicio,   -- texto AAAA-MM-DD → DATE
        cast(data_fim as date) as data_fim,
        frequencia as frequencia_bruta              -- lido do CTE `source`, é a coluna, não a tabela
    from source
),
-- A origem repete algumas chaves (aluno, turma, disciplina, início do período): parte são
-- linhas idênticas, parte traz frequências diferentes. Fica a de menor frequência, ou seja,
-- a de mais faltas, para não subestimar o absenteísmo.
deduplicado as (
    {{ dbt_utils.deduplicate(
        relation='renamed',
        partition_by='id_aluno_frequencia, id_turma, disciplina, data_inicio',
        order_by='frequencia_bruta'
    ) }}
)
select * from deduplicado
