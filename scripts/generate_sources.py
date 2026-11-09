"""Gera o esqueleto das sources do RMI com o codegen (pacote dbt-labs/codegen).

    Como usar:  source .env && uv run python scripts/generate_sources.py [arquivo_de_saida]

"""

import json
import subprocess
import sys
from pathlib import Path

ARGUMENTOS = {
    "schema_name": "rmi_raw", 
    "name": "educacao",  
    "generate_columns": True, 
    "include_descriptions": True, 
}


def main():
    saida = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("models/staging/schema.yml")
    if saida.exists():
        sys.exit(f"{saida} já existe e não será sobrescrito.")

    comando = ["dbt", "--quiet", "run-operation", "generate_source",
               "--args", json.dumps(ARGUMENTOS)]
    resultado = subprocess.run(comando, capture_output=True, text=True)
    if resultado.returncode != 0:
        sys.exit(f"O dbt falhou:\n{resultado.stdout}{resultado.stderr}")

    saida.parent.mkdir(parents=True, exist_ok=True)
    saida.write_text(resultado.stdout)
    print(f"Sources geradas em {saida}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
