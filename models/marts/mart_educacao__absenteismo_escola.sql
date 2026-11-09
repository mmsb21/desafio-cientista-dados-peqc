-- Absenteísmo crônico por escola: quantos alunos ficaram abaixo de 75% de frequência,
-- com intervalo de confiança e a referência da frequência oficial da avaliação.
-- Unidade: o aluno na escola. As turmas do mesmo aluno dentro da escola se juntam, para quem
-- trocou de turma não contar duas vezes; quem passou por duas escolas conta em cada uma.
with vinculos as (
    select * from {{ ref('int_educacao__frequencia_vinculo') }}
),
avaliacao as (
    select * from {{ ref('int_educacao__aluno_frequencia') }}
),
escola as (
    select * from {{ ref('stg_educacao__escola') }}
),
-- Frequência do aluno na escola: soma das frequências dos registros dividida pelo número
-- de registros, sem tirar média de médias entre as turmas.
aluno_na_escola as (
    select
        id_escola,
        id_aluno_frequencia,
        sum(soma_frequencia_pct) / sum(qtd_registros) as frequencia_pct
    from vinculos
    group by id_escola, id_aluno_frequencia
),
por_escola as (
    select
        id_escola,
        count(*) as qtd_alunos,
        countif(frequencia_pct < 75) as qtd_alunos_abaixo_75,
        avg(frequencia_pct) as frequencia_media_pct
    from aluno_na_escola
    group by id_escola
),
com_intervalo as (
    select
        *,
        100 * qtd_alunos_abaixo_75 / qtd_alunos as pct_alunos_abaixo_75,
        100 * {{ wilson_ic('qtd_alunos_abaixo_75', 'qtd_alunos', 'inferior') }} as ic95_inferior_pct,
        100 * {{ wilson_ic('qtd_alunos_abaixo_75', 'qtd_alunos', 'superior') }} as ic95_superior_pct,
        qtd_alunos >= 30 as amostra_suficiente
    from por_escola
),
-- Referência: a mesma taxa na frequência oficial da avaliação, no 1º semestre. Só existe
-- para escolas cujas turmas aparecem na avaliação.
avaliacao_aluno as (
    select
        id_escola,
        id_aluno,
        avg(frequencia_media_semestre_pct) as frequencia_pct
    from avaliacao
    where id_escola is not null
        and frequencia_media_semestre_pct is not null
    group by id_escola, id_aluno
),
referencia as (
    select
        id_escola,
        count(*) as qtd_alunos_avaliacao,
        100 * countif(frequencia_pct < 75) / count(*) as pct_alunos_abaixo_75_avaliacao
    from avaliacao_aluno
    group by id_escola
)
select
    com_intervalo.id_escola,
    escola.id_bairro_escola,
    com_intervalo.qtd_alunos,
    com_intervalo.qtd_alunos_abaixo_75,
    round(com_intervalo.pct_alunos_abaixo_75, 2) as pct_alunos_abaixo_75,
    round(com_intervalo.ic95_inferior_pct, 2) as ic95_inferior_pct,
    round(com_intervalo.ic95_superior_pct, 2) as ic95_superior_pct,
    round(com_intervalo.frequencia_media_pct, 2) as frequencia_media_pct,
    com_intervalo.amostra_suficiente,
    -- Ranking só entre escolas com amostra suficiente, pelo limite inferior do intervalo:
    -- uma escola pequena não sobe por acaso.
    if(
        com_intervalo.amostra_suficiente,
        rank() over (
            partition by com_intervalo.amostra_suficiente
            order by com_intervalo.ic95_inferior_pct desc
        ),
        null
    ) as posicao_ranking,
    referencia.qtd_alunos_avaliacao,
    round(referencia.pct_alunos_abaixo_75_avaliacao, 2) as pct_alunos_abaixo_75_avaliacao
from com_intervalo
left join escola on com_intervalo.id_escola = escola.id_escola
left join referencia on com_intervalo.id_escola = referencia.id_escola
