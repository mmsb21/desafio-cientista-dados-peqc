-- Cadastro de alunos: 1 linha por aluno.
-- Limpeza: ids padronizados como texto em todo o projeto (o id do aluno chega em BYTES)
-- e o bairro de residência renomeado para deixar claro que é um id anonimizado.

with source as (

    select * from {{ source('educacao', 'aluno') }}

),

renamed as (

    select
        to_hex(id_aluno) as id_aluno,                   
        cast(id_turma as string) as id_turma,          
        faixa_etaria,                                 
        cast(bairro as string) as id_bairro_residencia 

    from source

)

select * from renamed
