-- Vínculo aluno–turma (tabela `turma` da origem): 1 linha por aluno.
-- Limpeza: ids em texto, como no resto do projeto, e ano renomeado.
with source as (
    select * from {{ source('educacao', 'turma') }}
),
renamed as (
    select
        to_hex(id_aluno) as id_aluno,           -- BYTES → texto hexadecimal, igual à stg de aluno
        cast(id_turma as string) as id_turma,   -- hash INT64 → texto
        ano as ano_letivo                       -- sempre 2000 (o ano real é 2025)
    from source
)
select * from renamed
