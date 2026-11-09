-- Cadastro de escolas: 1 linha por escola.
-- Limpeza: ids em texto, como no resto do projeto, e bairro renomeado para deixar claro
-- que é o hash do bairro da escola (não o de residência do aluno).
with source as (
    select * from {{ source('educacao', 'escola') }}
),
renamed as (
    select
        cast(id_escola as string) as id_escola,        -- hash INT64 → texto
        cast(bairro as string) as id_bairro_escola     -- hash do bairro da escola; sem nulos
    from source
)
select * from renamed
