

with source as (

    select * from {{ source('educacao', 'frequencia') }}

),

renamed as (

    select
        id_escola,
        id_aluno,
        id_turma,
        data_inicio,
        data_fim,
        disciplina,
        frequencia

    from source

)

select * from renamed

