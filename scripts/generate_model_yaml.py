"""Gera o YAML dos modelos de staging com o codegen (generate_model_yaml) e acrescenta no schema.yml.

O codegen lê colunas e tipos das views no BigQuery: o modelo precisa ter rodado antes
(`dbt run -s <modelo>`). Nunca reescreve o arquivo: só acrescenta, no fim, os modelos que
ainda não estão documentados. Descrições e testes são completados à mão depois.

Como usar:
    source .env && uv run python scripts/generate_model_yaml.py                       # todos de uma vez
    source .env && uv run python scripts/generate_model_yaml.py stg_educacao__aluno   # só os escolhidos
"""
import json
import re
import subprocess
import sys
from pathlib import Path

PASTA = Path("models/staging")
DESTINO = PASTA / "schema.yml"


def gerar(modelos):
    args = json.dumps({"model_names": modelos})
    resultado = subprocess.run(
        ["dbt", "--quiet", "run-operation", "generate_model_yaml", "--args", args],
        capture_output=True,
        text=True,
    )
    _, achou, blocos = resultado.stdout.partition("models:\n")
    if resultado.returncode != 0 or not achou:
        sys.exit(resultado.stdout + resultado.stderr)
    return blocos


def main():
    existentes = sorted(sql.stem for sql in PASTA.glob("stg_*.sql"))
    pedidos = sys.argv[1:] or existentes
    desconhecidos = [m for m in pedidos if m not in existentes]
    if desconhecidos:
        sys.exit(f"Sem arquivo .sql em {PASTA}: {', '.join(desconhecidos)}")

    texto = DESTINO.read_text(encoding="utf-8")
    faltam = [m for m in pedidos if not re.search(rf"^  - name: {m}$", texto, re.M)]
    if not faltam:
        sys.exit("Nada a fazer: os modelos pedidos já estão no schema.yml.")

    novos = []
    for bloco in re.split(r"^(?=  - name: )", gerar(faltam), flags=re.M)[1:]:
        nome = bloco.split()[2]
        if "      - name:" not in bloco:
            print(f"{nome}: pulado, rode `dbt run -s {nome}` antes.")
            continue
        novos.append("\n".join(linha for linha in bloco.splitlines() if linha.strip()))
        print(f"{nome}: colunas geradas.")
    if not novos:
        sys.exit("Nada foi escrito.")

    cabecalho = "" if re.search(r"^models:", texto, re.M) else "models:\n"
    with DESTINO.open("a", encoding="utf-8") as arquivo:
        arquivo.write("\n" + cabecalho + "\n\n".join(novos) + "\n")
    print(f"Acrescentado em {DESTINO}. Complete descrições e testes.")


if __name__ == "__main__":
    main()
