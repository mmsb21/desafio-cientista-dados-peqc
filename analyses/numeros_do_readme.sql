-- Números da "Análise dos resultados" do README que saem dos marts: itens 1, 2, 3 e 5 e a
-- parte de bairros do item 4. A variação entre escolas e bairros (item 4) e os itens 6 e 7
-- são reproduzidos no notebook. Para conferir:
--     uv run dbt show -s numeros_do_readme --output json
with escolas as (
    select * from {{ ref('mart_educacao__absenteismo_escola') }}
),
bairros as (
    select * from {{ ref('mart_educacao__absenteismo_bairro') }}
),
-- Escolas com 30 alunos ou mais: a base dos itens 1 e 2 e do ranking.
com_amostra as (
    select * from escolas where amostra_suficiente
),
rede as (
    select 100 * sum(qtd_alunos_abaixo_75) / sum(qtd_alunos) as taxa from escolas
),
-- Escolas da maior para a menor taxa, com os alunos abaixo de 75% acumulados nessa ordem.
ordem as (
    select
        row_number() over (order by pct_alunos_abaixo_75 desc, id_escola) as posicao,
        qtd_alunos,
        qtd_alunos_abaixo_75,
        sum(qtd_alunos_abaixo_75) over (
            order by pct_alunos_abaixo_75 desc, id_escola
            rows between unbounded preceding and current row
        ) as abaixo_acumulado
    from com_amostra
),
-- Item 5: escolas com 30 alunos ou mais nas duas fontes.
referencia as (
    select * from escolas where qtd_alunos >= 30 and qtd_alunos_avaliacao >= 30
)
select
    -- item 1
    (select count(*) from escolas) as escolas,
    (select sum(qtd_alunos) from escolas) as alunos,
    (select sum(qtd_alunos_abaixo_75) from escolas) as alunos_abaixo_75,
    (select round(taxa, 1) from rede) as taxa_rede_pct,
    (select count(*) from com_amostra) as escolas_30_ou_mais,
    (select approx_quantiles(pct_alunos_abaixo_75, 100)[offset(50)] from com_amostra) as taxa_mediana_pct,
    (select approx_quantiles(pct_alunos_abaixo_75, 100)[offset(90)] from com_amostra) as taxa_p90_pct,
    (select max(pct_alunos_abaixo_75) from com_amostra) as maior_taxa_pct,
    -- item 2
    (select countif(qtd_alunos_abaixo_75 = 0) from com_amostra) as escolas_sem_nenhum_abaixo,
    (select round(100 * sum(if(posicao <= 47, qtd_alunos, 0)) / sum(qtd_alunos), 1) from ordem)
        as pct_alunos_nas_47_maiores,
    (select round(100 * sum(if(posicao <= 47, qtd_alunos_abaixo_75, 0)) / sum(qtd_alunos_abaixo_75), 1) from ordem)
        as pct_abaixo_75_nas_47_maiores,
    (select min(posicao) from ordem
        where abaixo_acumulado >= (select sum(qtd_alunos_abaixo_75) from com_amostra) / 2)
        as escolas_com_metade_dos_abaixo,
    -- item 3
    (select countif(com_amostra.ic95_inferior_pct > rede.taxa) from com_amostra cross join rede)
        as escolas_acima_da_rede,
    -- item 4, parte de bairros
    (select count(*) from bairros) as bairros,
    (select round(100 * countif(qtd_escolas <= 2) / count(*), 1) from bairros) as pct_bairros_ate_2_escolas,
    (select max(qtd_escolas) from bairros where posicao_ranking <= 4) as max_escolas_4_primeiros_bairros,
    -- item 5
    (select count(*) from referencia) as escolas_referencia,
    (select round(corr(pct_alunos_abaixo_75, pct_alunos_abaixo_75_avaliacao), 3) from referencia)
        as correlacao_com_oficial,
    (select round(sum(pct_alunos_abaixo_75_avaliacao * qtd_alunos_avaliacao) / sum(qtd_alunos_avaliacao), 2)
        from referencia) as taxa_oficial_pct,
    (select round(100 * sum(qtd_alunos_abaixo_75) / sum(qtd_alunos), 2) from referencia) as taxa_corrigida_pct
