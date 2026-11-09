-- Frequência oficial e nota média por aluno e turma, no semestre (bimestres 1 e 2) e no ano.
-- É o "alunos + matrículas + frequência" do enunciado, feito com a frequência da avaliação,
-- calculada pelo sistema de origem: ali o id do aluno é o mesmo do cadastro (na tabela de
-- frequência, não é). A frequência é usada como veio, e cada janela é a média simples dos
-- bimestres. A escola vem da turma, pelo int_educacao__turma.
with avaliacao as (
    select * from {{ ref('stg_educacao__avaliacao') }}
),
aluno as (
    select * from {{ ref('stg_educacao__aluno') }}
),
matricula as (
    select * from {{ ref('stg_educacao__aluno_turma') }}
),
turma as (
    select * from {{ ref('int_educacao__turma') }}
),
bimestres as (
    select
        id_aluno,
        id_turma,
        bimestre,
        frequencia_bimestre,
        coalesce(nota_portugues, 0) + coalesce(nota_ciencias, 0) + coalesce(nota_matematica, 0) as soma_notas,
        cast(nota_portugues is not null as int64)
            + cast(nota_ciencias is not null as int64)
            + cast(nota_matematica is not null as int64) as qtd_notas
    from avaliacao
),
por_aluno_turma as (
    select
        id_aluno,
        id_turma,
        count(*) as qtd_bimestres,
        countif(frequencia_bimestre < 75) as qtd_bimestres_abaixo_75,
        avg(if(bimestre <= 2, frequencia_bimestre, null)) as frequencia_media_semestre_pct,
        avg(frequencia_bimestre) as frequencia_media_ano_pct,
        safe_divide(
            sum(if(bimestre <= 2, soma_notas, null)),
            sum(if(bimestre <= 2, qtd_notas, null))
        ) as nota_media_semestre,
        safe_divide(sum(soma_notas), sum(qtd_notas)) as nota_media_ano
    from bimestres
    group by id_aluno, id_turma
)
select
    por_aluno_turma.id_aluno,
    por_aluno_turma.id_turma,
    turma.id_escola,
    turma.id_bairro_escola,
    aluno.faixa_etaria,
    aluno.id_bairro_residencia,
    matricula.id_aluno is not null as turma_da_matricula,
    por_aluno_turma.qtd_bimestres,
    por_aluno_turma.qtd_bimestres_abaixo_75,
    por_aluno_turma.frequencia_media_semestre_pct,
    por_aluno_turma.frequencia_media_ano_pct,
    por_aluno_turma.nota_media_semestre,
    por_aluno_turma.nota_media_ano
from por_aluno_turma
left join aluno
    on por_aluno_turma.id_aluno = aluno.id_aluno
left join matricula
    on por_aluno_turma.id_aluno = matricula.id_aluno
    and por_aluno_turma.id_turma = matricula.id_turma
left join turma
    on por_aluno_turma.id_turma = turma.id_turma
