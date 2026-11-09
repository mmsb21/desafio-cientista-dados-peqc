# Desafio RMI — Cientista de Dados (Prefeitura do Rio)

Projeto dbt sobre BigQuery que modela dados anonimizados da rede municipal de educação
do Rio de Janeiro, extraídos do RMI (Registro Municipal Integrado), com foco em
frequência escolar e absenteísmo crônico.

O enunciado original do desafio está em [ENUNCIADO.md](ENUNCIADO.md).

## Como reproduzir

**Pré-requisitos:** Python 3.13 com [uv](https://docs.astral.sh/uv/), Google Cloud CLI
e um projeto no BigQuery.

```bash
# 1. autenticação (é a credencial que o script de carga e o dbt usam)
gcloud auth application-default login
export GCP_PROJECT_ID=seu-projeto

# 2. ambiente Python (versões fixadas no uv.lock)
uv sync

# 3. carga dos Parquets de gs://case_vagas/rmi no dataset rmi_raw (location US)
uv run python scripts/load_raw.py

# 4. dbt
uv run dbt deps               # dbt_utils, dbt_expectations e codegen
uv run dbt debug              # testa a conexão
uv run dbt source freshness   # confere a atualização das fontes
uv run dbt build              # modelos e testes
```

Sem uv: `python -m venv .venv && .venv/bin/pip install -r requirements.txt`.

Os modelos são criados nos datasets `dbt_dev_staging`, `dbt_dev_intermediate` e
`dbt_dev_marts` (o prefixo `dbt_dev` pode ser trocado pela variável `DBT_DATASET`).

## Decisões até aqui

- **Fontes:** as 5 tabelas são carregadas sem transformação no dataset `rmi_raw` e
  declaradas como a source `educacao`. O esqueleto do YAML foi gerado com o codegen
  e completado com descrições, tipos reais e testes de contrato com a origem.
- **Materializações:** staging como view (1:1 com a fonte, sem custo de armazenamento);
  intermediate como view por padrão, com `table` só onde a agregação é pesada e
  reutilizada (`int_educacao__frequencia_vinculo` e `int_educacao__turma`, que leem a
  frequência inteira); marts como table, porque o BigQuery Sandbox não aceita DML e o
  modo incremental depende de MERGE.
- **Localização US:** a mesma da tabela pública `datario.dados_mestres.bairro`.

### Convenções de staging

- **Nomes:** modelos `stg_<source>__<tabela>` (ex.: `stg_educacao__aluno`); colunas em
  snake_case, com prefixo `id_` para identificadores. A tabela `turma` vira
  `stg_educacao__aluno_turma`, porque cada linha é o vínculo de um aluno com sua turma.
- **Identificadores como texto:** todos os ids são STRING, em todas as camadas. Na origem
  eles chegam com tipos diferentes (BYTES no id do aluno, INT64 nos demais) e não são
  números: padronizar evita junções entre tipos diferentes. O id do aluno é convertido
  com `to_hex` (17 bytes → 34 caracteres).
- **Tipos corrigidos só onde a origem errou:** datas gravadas como texto viram DATE e o
  bimestre, gravado como texto, vira INT64. Colunas que já chegam com o tipo certo
  (faixa etária, frequência, notas) não são convertidas.
- **Nomes que evitam confusão:** na frequência, o id do aluno vira `id_aluno_frequencia`,
  porque não identifica o mesmo aluno do cadastro, e a coluna `frequencia` vira
  `frequencia_bruta`, porque foi gravada sem o ×100.
- **Nulos:** mantidos quando são reais (ex.: bairro de residência ausente); o staging
  não inventa valores. A exceção é a nota de Inglês, que vem 100% nula e fica fora de
  `stg_educacao__avaliacao`.
- **Deduplicação:** só onde a origem repete a chave, com `dbt_utils.deduplicate` e a
  regra comentada no próprio modelo:
  - frequência: fica a linha de menor frequência, a de mais faltas, para não subestimar
    o absenteísmo;
  - avaliação: fica a linha com frequência preenchida e, entre elas, a de menor
    frequência; empate, a de menores notas.

### Intermediate

Três problemas só aparecem quando se cruzam as fontes, e cada modelo resolve um deles:

1. **A frequência foi gravada sem o ×100.** A origem calculou `100 − faltas/dias` em vez
   de `100 − 100 × faltas/dias`. Como `faltas/dias = 100 − frequencia`, a frequência
   certa sai da própria coluna: `100 − 100 × (100 − frequencia_bruta)`.
   `int_educacao__frequencia_vinculo` (tabela) aplica essa correção e calcula a
   frequência de cada vínculo (aluno da frequência × turma × escola) como a média simples
   dos registros (disciplina × período). Registros com mais faltas que dias, que dariam
   frequência negativa, ficam em 0 (0,07% dos registros).
2. **O id de aluno da frequência não identifica o mesmo aluno do cadastro.** Só 11 de
   105.934 pares (aluno, turma) da frequência existem na matrícula, e, aluno a aluno, a
   correlação com a frequência da avaliação é 0,00 (por turma, cerca de 0,7). Por isso a
   frequência só se liga às outras tabelas por turma e escola.
   `int_educacao__aluno_frequencia` faz o "alunos + matrículas + frequência" com a
   frequência da avaliação, usada como veio, onde o id é o do cadastro.
3. **A escola de uma turma só aparece na frequência.** `int_educacao__turma` (tabela)
   reúne as turmas das três fontes e traz a escola das que estão na frequência. As
   demais ficam com escola nula e marcadas: 12.544 de 18.060 turmas, quase todas de
   alunos mais novos. Um teste de `unique` garante que cada turma tem uma única escola.

**Médias simples:** sem o número de dias de cada período, cada mês (e, na avaliação,
cada bimestre) pesa igual na média. É uma aproximação documentada.

## Status

- [x] Tarefa 1: configuração, sources e estrutura
- [x] Tarefa 2: staging
- [x] Tarefa 3: intermediate
- [ ] Tarefa 4: mart
- [ ] Testes de regra de negócio
- [ ] Documentação final e análise exploratória
