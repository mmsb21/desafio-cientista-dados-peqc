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
  reutilizada; marts como table, porque o BigQuery Sandbox não aceita DML e o modo
  incremental depende de MERGE.
- **Localização US:** a mesma da tabela pública `datario.dados_mestres.bairro`.

## Status

- [x] Tarefa 1: configuração, sources e estrutura
- [ ] Tarefa 2: staging
- [ ] Tarefa 3: intermediate
- [ ] Tarefa 4: mart
- [ ] Testes de regra de negócio
- [ ] Documentação final e análise exploratória
