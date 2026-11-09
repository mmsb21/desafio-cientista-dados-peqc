

with source as (

    select * from {{ source('educacao', 'turma') }}

),

renamed as (

    select
        ano,
        id_turma,
        id_aluno

    from source

)

select * from renamed

