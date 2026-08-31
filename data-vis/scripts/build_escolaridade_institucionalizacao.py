"""
Cruza a escolaridade do gestor municipal de cultura com o grau de
institucionalizacao da politica cultural no municipio, na onda de 2021 da MUNIC.

Por que o grau, e nao o tripe completo: a leitura que existia media so o topo da
escada — o percentual de municipios com conselho, plano e fundo ao mesmo tempo —
e com isso mostrava uma relacao que parece forte (3,8% no ensino fundamental
contra 12,0% na pos-graduacao) sem mostrar o resto da distribuicao. Contando
quantos dos tres instrumentos o municipio tem, de zero a tres, as outras
situacoes entram, e o que aparece e uma relacao fraca: a coluna do zero fica
praticamente parada em torno de 42% em todas as escolaridades.

O denominador de cada linha sao os municipios cuja escolaridade do gestor foi
declarada. "Sem Informacao" nao entra: um municipio que nao respondeu nao e
evidencia nem a favor nem contra o que se esta medindo. Sao 135 dos 5.570.

Uso:
    python3 scripts/build_escolaridade_institucionalizacao.py
"""

import csv
import json
from collections import Counter
from pathlib import Path

PROJECT_DIR = Path(__file__).resolve().parent.parent
REPO_ROOT = PROJECT_DIR.parent
CSV_PATH = (
    REPO_ROOT / "eixo1/gestao&participacao/data/processed/munic_painel_historico.csv"
)
OUT_PATH = PROJECT_DIR / "src/data/escolaridade-institucionalizacao.json"

ONDA = 2021

# Da menor para a maior — a escada que a figura sobe de cima para baixo.
ESCOLARIDADES = [
    "Ensino Fundamental",
    "Ensino Médio",
    "Ensino Superior",
    "Pós-Graduação",
]

# Os tres instrumentos do tripe do SNC. `tem_*` e binario limpo em 2021.
TRIPE = ["tem_conselho", "tem_fundo", "tem_plano"]

GRAUS = [
    (0, "Nenhum dos três"),
    (1, "Um instrumento"),
    (2, "Dois instrumentos"),
    (3, "O tripé completo"),
]


def build() -> dict:
    with CSV_PATH.open(encoding="utf-8-sig") as f:
        linhas = [r for r in csv.DictReader(f) if int(r["ano"]) == ONDA]

    universo = len(linhas)
    tabela: dict[str, Counter] = {e: Counter() for e in ESCOLARIDADES}
    sem_informacao = 0

    for r in linhas:
        escolaridade = r["gestor_escolaridade_agrupada"]
        if escolaridade not in tabela:
            sem_informacao += 1
            continue
        tabela[escolaridade][sum(1 for c in TRIPE if r[c] == "Sim")] += 1

    faixas = []
    for escolaridade in ESCOLARIDADES:
        contagem = tabela[escolaridade]
        base = sum(contagem.values())
        faixas.append(
            {
                "label": escolaridade,
                "base": base,
                "celulas": [
                    {
                        "grau": grau,
                        "n": contagem[grau],
                        "pct": round(contagem[grau] / base * 100, 1),
                    }
                    for grau, _ in GRAUS
                ],
            }
        )

    return {
        "ano": ONDA,
        "universo": universo,
        "semInformacao": sem_informacao,
        "graus": [{"grau": g, "label": rotulo} for g, rotulo in GRAUS],
        "faixas": faixas,
    }


if __name__ == "__main__":
    dados = build()
    OUT_PATH.write_text(
        json.dumps(dados, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"escrito: {OUT_PATH.relative_to(PROJECT_DIR)}")
    print(f"  universo {dados['universo']}, sem informação {dados['semInformacao']}")
    for faixa in dados["faixas"]:
        celulas = " ".join(f"{c['grau']}:{c['pct']}%" for c in faixa["celulas"])
        print(f"  {faixa['label']:20s} n={faixa['base']:5d}  {celulas}")
