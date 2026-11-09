-- Absenteísmo crônico por bairro da escola: a mesma medida do mart por escola, somando os
-- alunos das escolas de cada bairro. Construído a partir do mart por escola, para que as
-- duas leituras usem sempre a mesma definição. O bairro é um hash: dá para comparar
-- bairros entre si, mas não saber qual é cada um.
with escolas as (
    select * from {{ ref('mart_educacao__absenteismo_escola') }}
),
por_bairro as (
    select
        id_bairro_escola,
        count(*) as qtd_escolas,
        sum(qtd_alunos) as qtd_alunos,
        sum(qtd_alunos_abaixo_75) as qtd_alunos_abaixo_75,
        sum(frequencia_media_pct * qtd_alunos) / sum(qtd_alunos) as frequencia_media_pct
    from escolas
    group by id_bairro_escola
),
com_intervalo as (
    select
        *,
        100 * qtd_alunos_abaixo_75 / qtd_alunos as pct_alunos_abaixo_75,
        100 * {{ wilson_ic('qtd_alunos_abaixo_75', 'qtd_alunos', 'inferior') }} as ic95_inferior_pct,
        100 * {{ wilson_ic('qtd_alunos_abaixo_75', 'qtd_alunos', 'superior') }} as ic95_superior_pct,
        qtd_alunos >= 30 as amostra_suficiente
    from por_bairro
)
select
    com_intervalo.id_bairro_escola,
    com_intervalo.qtd_escolas,
    com_intervalo.qtd_alunos,
    com_intervalo.qtd_alunos_abaixo_75,
    round(com_intervalo.pct_alunos_abaixo_75, 2) as pct_alunos_abaixo_75,
    round(com_intervalo.ic95_inferior_pct, 2) as ic95_inferior_pct,
    round(com_intervalo.ic95_superior_pct, 2) as ic95_superior_pct,
    round(com_intervalo.frequencia_media_pct, 2) as frequencia_media_pct,
    com_intervalo.amostra_suficiente,
    if(
        com_intervalo.amostra_suficiente,
        rank() over (
            partition by com_intervalo.amostra_suficiente
            order by com_intervalo.ic95_inferior_pct desc
        ),
        null
    ) as posicao_ranking
from com_intervalo
