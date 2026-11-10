"""Carrega os Parquets do desafio (gs://case_vagas/rmi) no BigQuery, sem transformação.

Como usar (com GCP_PROJECT_ID definido, como no README):
    uv run python scripts/load_raw.py
"""

import os
import sys

from google.cloud import bigquery as bq

ORIGEM = "gs://case_vagas/rmi"
TABELAS = ["aluno", "escola", "turma", "frequencia", "avaliacao"]
LOCALIZACAO = "US"


def main():
    projeto = os.environ.get("GCP_PROJECT_ID")
    if not projeto:
        sys.exit("Defina GCP_PROJECT_ID.")

    dataset_id = f"{projeto}.{os.environ.get('RAW_DATASET', 'rmi_raw')}"
    client = bq.Client(project=projeto, location=LOCALIZACAO)

    dataset = bq.Dataset(dataset_id)
    dataset.description = "Parquets brutos do desafio RMI, carregados sem transformação."
    client.create_dataset(dataset, exists_ok=True)

    config = bq.LoadJobConfig(
            source_format= bq.SourceFormat.PARQUET,
            write_disposition= bq.WriteDisposition.WRITE_TRUNCATE,
            )

    for nome in TABELAS:
        job = client.load_table_from_uri(f"{ORIGEM}/{nome}", f"{dataset_id}.{nome}", job_config=config)
        job.result()
        print(f"{nome}: {job.output_rows:,} linhas carregadas")

if __name__ == "__main__":
    main()
