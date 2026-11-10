"""Gera o esqueleto SQL dos modelos de staging com o codegen (generate_base_model).

Gera para as 5 tabelas da source `educacao`.

Como usar (com GCP_PROJECT_ID definido, como no README):
    uv run python scripts/generate_staging.py
"""

import json
import subprocess
import sys
from pathlib import Path

PASTA = Path("models/staging")

MODELOS = {
    "aluno": "stg_educacao__aluno",
    "escola": "stg_educacao__escola",
    "turma": "stg_educacao__aluno_turma",
    "frequencia": "stg_educacao__frequencia",
    "avaliacao": "stg_educacao__avaliacao",
}


def gerar(tabela: str) -> str:
    """Roda o generate_base_model para uma tabela e devolve o SQL gerado."""
    argumentos = {"source_name": "educacao", "table_name": tabela}
    comando = ["dbt", "--quiet", "run-operation", "generate_base_model",
               "--args", json.dumps(argumentos)]
    resultado = subprocess.run(comando, capture_output=True, text=True)
    if resultado.returncode != 0:
        sys.exit(f"O dbt falhou para {tabela}:\n{resultado.stdout}{resultado.stderr}")
    return resultado.stdout


def main():
    tabelas = sys.argv[1:] or list(MODELOS)
    desconhecidas = [t for t in tabelas if t not in MODELOS]
    if desconhecidas:
        sys.exit(f"Tabela(s) desconhecida(s): {', '.join(desconhecidas)}. "
                 f"Opções: {', '.join(MODELOS)}")

    for tabela in tabelas:
        destino = PASTA / f"{MODELOS[tabela]}.sql"
        if destino.exists():
            print(f"{destino} já existe; mantido sem alteração.")
            continue
        destino.write_text(gerar(tabela))
        print(f"{destino} gerado.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
