"""
Monta os dados dos dois graficos do comportamento orcamentario municipal a
partir dos CSVs ja processados em
eixo1/orcamento/data/processed/municipal/:

  - Cabo_Guerra_Balanco_Liquido.csv       (% de municipios por regiao)
  - Efeito_Comportamental_Por_Porte.csv   (n e % por porte populacional)

Os dois descrevem o mesmo universo: os 5.434 municipios com dados, cada um
classificado em um dos quatro perfis de mudanca. O script verifica esse
casamento (ver `_check_universo`) antes de escrever a saida.

Uso:
    python3 scripts/build_comportamento_municipal_data.py

Nao requer dependencias externas.
"""

import csv
import json
from pathlib import Path

PROJECT_DIR = Path(__file__).resolve().parent.parent
REPO_ROOT = PROJECT_DIR.parent
MUNICIPAL_DIR = REPO_ROOT / "eixo1/orcamento/data/processed/municipal"
CABO_GUERRA_CSV = MUNICIPAL_DIR / "Cabo_Guerra_Balanco_Liquido.csv"
PORTE_CSV = MUNICIPAL_DIR / "Efeito_Comportamental_Por_Porte.csv"
OUT_PATH = PROJECT_DIR / "src/data/comportamento-municipal.json"

# Ordem narrativa: os dois perfis que representam movimento nas pontas, os dois
# estaveis no meio. E a ordem numerada da propria coluna `perfil_mudanca`.
PERFIS = [
    ("1. Despertados (Efeito Indutor)", "Despertados", "Efeito indutor"),
    ("2. Constantes (Sustentabilidade)", "Constantes", "Sustentabilidade"),
    ("3. Inertes (Dependência Exclusiva)", "Inertes", "Dependência exclusiva"),
    ("4. Efeito Substituição (Retração Local)", "Substituição", "Retração local"),
]

# Do maior para o menor: e assim que a gradacao do efeito indutor aparece.
PORTES = [
    "Metrópole",
    "Grande Porte",
    "Médio Porte",
    "Pequeno Porte II",
    "Pequeno Porte I",
]

REGIOES = ["Norte", "Nordeste", "Centro-Oeste", "Sudeste", "Sul"]

INDUTOR = "Efeito Indutor (+)"
SUBSTITUICAO = "Efeito Substituição (-)"


def _num(text: str) -> float:
    """Decimal com virgula, como o R escreve com `write.csv2`."""
    return float(text.strip().replace(".", "").replace(",", "."))


def read_cabo_guerra() -> list[dict]:
    # iso-8859-1: este CSV saiu do R sem `fileEncoding="UTF-8"`, ao contrario do outro
    with CABO_GUERRA_CSV.open(encoding="iso-8859-1", newline="") as fh:
        rows = list(csv.DictReader(fh, delimiter=";"))

    por_regiao: dict[str, dict[str, float]] = {}
    for row in rows:
        if not row.get("regiao_munic"):
            continue
        por_regiao.setdefault(row["regiao_munic"], {})[row["Efeito"]] = _num(row["Valor"])

    faltando = set(REGIOES) - por_regiao.keys()
    if faltando:
        raise ValueError(f"regioes ausentes em {CABO_GUERRA_CSV.name}: {sorted(faltando)}")

    # sem arredondar: `_check_universo` recupera o denominador de cada regiao a
    # partir da precisao cheia dos percentuais
    out = []
    for regiao in REGIOES:
        indutor = por_regiao[regiao][INDUTOR]
        # ja vem negativo na origem; o grafico desenha o sinal, o valor guarda o modulo
        substituicao = abs(por_regiao[regiao][SUBSTITUICAO])
        out.append(
            {
                "label": regiao,
                "indutor": indutor,
                "substituicao": substituicao,
                "liquido": indutor - substituicao,
            }
        )

    # maior saldo primeiro
    out.sort(key=lambda d: d["liquido"], reverse=True)
    return out


def read_porte() -> list[dict]:
    with PORTE_CSV.open(encoding="utf-8-sig", newline="") as fh:
        rows = list(csv.DictReader(fh, delimiter=";"))

    por_porte: dict[str, dict[str, dict[str, float]]] = {}
    for row in rows:
        if not row.get("porte_populacional"):
            continue
        por_porte.setdefault(row["porte_populacional"], {})[row["perfil_mudanca"]] = {
            "n": int(row["n"]),
            "pct": _num(row["pct"]) * 100,
        }

    faltando = set(PORTES) - por_porte.keys()
    if faltando:
        raise ValueError(f"portes ausentes em {PORTE_CSV.name}: {sorted(faltando)}")

    out = []
    for porte in PORTES:
        perfis = por_porte[porte]
        registro: dict = {"label": porte, "n": sum(p["n"] for p in perfis.values())}
        for origem, chave, _ in PERFIS:
            registro[chave] = round(perfis[origem]["pct"], 4)
            registro[f"n{chave}"] = perfis[origem]["n"]
        out.append(registro)

    return out


def _check_universo(cabo_guerra: list[dict], porte: list[dict]) -> int:
    """
    Os dois recortes particionam o mesmo universo, entao os totais nacionais de
    despertados e de substituicao tem de bater. O CSV regional so traz
    percentuais, sem o denominador; ele e recuperado aqui como o unico inteiro
    que torna os dois percentuais da regiao contagens exatas.
    """
    universo = sum(p["n"] for p in porte)

    def denominador(row: dict) -> int:
        candidatos = [
            n
            for n in range(1, universo + 1)
            if all(
                abs(row[campo] / 100 * n - round(row[campo] / 100 * n)) < 1e-6
                for campo in ("indutor", "substituicao")
            )
        ]
        if not candidatos:
            raise ValueError(f"sem denominador inteiro para {row['label']}")
        return candidatos[0]

    denominadores = {row["label"]: denominador(row) for row in cabo_guerra}
    if sum(denominadores.values()) != universo:
        raise ValueError(
            f"soma dos municipios por regiao ({sum(denominadores.values())}) "
            f"difere do universo por porte ({universo})"
        )

    for campo, chave in (("indutor", "Despertados"), ("substituicao", "Substituição")):
        por_regiao = sum(
            round(row[campo] / 100 * denominadores[row["label"]]) for row in cabo_guerra
        )
        por_porte = sum(p[f"n{chave}"] for p in porte)
        if por_regiao != por_porte:
            raise ValueError(
                f"{chave}: {por_regiao} municipios por regiao vs {por_porte} por porte"
            )

    return universo


def build() -> dict:
    cabo_guerra = read_cabo_guerra()
    porte = read_porte()
    universo = _check_universo(cabo_guerra, porte)

    return {
        "universo": universo,
        "unidade": "% dos municípios",
        "perfis": [
            {"key": chave, "label": chave, "descricao": descricao}
            for _, chave, descricao in PERFIS
        ],
        "caboGuerra": [
            {
                key: round(value, 4) if isinstance(value, float) else value
                for key, value in row.items()
            }
            for row in cabo_guerra
        ],
        "porte": porte,
    }


if __name__ == "__main__":
    resultado = build()
    OUT_PATH.write_text(
        json.dumps(resultado, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"wrote {OUT_PATH} ({resultado['universo']} municípios)")
