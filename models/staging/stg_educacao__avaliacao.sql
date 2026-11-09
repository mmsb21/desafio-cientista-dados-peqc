

with source as (

    select * from {{ source('educacao', 'avaliacao') }}

),

renamed as (

    select
        id_aluno,
        id_turma,
        frequencia,
        bimestre,
        disciplina_1,
        disciplina_2,
        disciplina_3,
        disciplina_4

    from source

)

select * from renamed

