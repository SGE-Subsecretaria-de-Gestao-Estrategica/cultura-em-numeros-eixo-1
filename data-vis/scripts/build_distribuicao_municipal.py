"""
Duas leituras do gasto cultural proprio dos municipios em 2024 que as figuras
existentes nao dao: a forma da distribuicao e a concentracao.

As figuras que ha hoje sao de contagem agregada — "N municipios acima de 2% da
RCL", "X% dos municipios de cada regiao". Nenhuma mostra que a distribuicao e
uma massa colada no zero com uma cauda muito longa (mediana 1,4%, maximo 76%),
nem que metade do gasto sai de uma minoria de municipios.

O cruzamento e o mesmo de `prepara-dados-eixo1.py`: gasto proprio na Funcao 13
sobre a Receita Corrente Liquida do mesmo ano e do mesmo municipio, os dois em
reais correntes, com o codigo IBGE de 6 digitos como chave. A conferencia esta
no fim: a contagem de municipios analisados e a de municipios acima de 2% tem
de reproduzir `meta-rcl-municipios.json`, que ja passou pelos indicadores
publicados. Um join que perde municipios em silencio ainda produz curvas
plausiveis — o assert e o que separa numero conferido de numero inventado.

2024, e nao 2025, porque 2025 sai de uma base declarante bem menor: 4.788
municipios contra 5.191.

Uso:
    python3 scripts/build_distribuicao_municipal.py
"""

import csv
import json
import math
from collections import defaultdict
from itertools import accumulate
from pathlib import Path

PROJECT_DIR = Path(__file__).resolve().parent.parent
REPO_ROOT = PROJECT_DIR.parent
CACHE = PROJECT_DIR / ".cache/rcl-municipal"
GASTO_CSV = REPO_ROOT / "eixo1/orcamento/data/processed/municipal/municipal_final.csv"
META_JSON = PROJECT_DIR / "src/data/meta-rcl-municipios.json"

DISTRIBUICAO_OUT = PROJECT_DIR / "src/data/distribuicao-rcl-regiao.json"
CONCENTRACAO_OUT = PROJECT_DIR / "src/data/concentracao-gasto-municipal.json"

ANO = 2024
META = 2.0

# Teto do eixo das cristas. A cauda vai a 76%, e desenhar ate la deixaria as
# cinco curvas achatadas contra o zero — 99% dos municipios estao abaixo de 10%.
# O que fica fora e contado na propria figura, nao escondido.
X_MAX = 8.0
GRADE = 241  # pontos da grade de densidade, de 0 a X_MAX

# Largura de banda do nucleo gaussiano, em pontos percentuais. Estreita o
# bastante para a moda e o ombro dos 2% aparecerem, larga o bastante para a
# curva nao virar um pente com um dente por municipio.
BANDA = 0.22


def num(texto: str) -> float:
    return float(texto.replace(",", "."))


def num_siconfi(texto: str) -> float:
    texto = texto.strip()
    return float(texto.replace(".", "").replace(",", ".")) if "," in texto else float(texto)


def ler_rcl() -> dict[str, float]:
    """{codigo IBGE de 6 dígitos: RCL nominal de ANO}."""
    destino = CACHE / f"RCL_{ANO}_Municipios.csv"
    if not destino.exists():
        raise SystemExit(
            f"falta {destino}. Rode antes: python3 scripts/prepara-dados-eixo1.py, "
            "que extrai os .rar da RCL municipal para o cache."
        )

    rcl: dict[str, float] = {}
    with destino.open(encoding="latin1") as f:
        for i, row in enumerate(csv.reader(f, delimiter=";")):
            if i < 6 or len(row) < 8:
                continue
            if "TOTAL" not in row[4].upper() or "ReceitaCorrenteLiquida" not in row[6]:
                continue
            try:
                valor = num_siconfi(row[7])
            except ValueError:
                continue
            if valor <= 0:
                continue
            chave = row[1].strip().zfill(7)[:6]
            rcl[chave] = max(rcl.get(chave, 0.0), valor)
    return rcl


def ler_gasto() -> tuple[dict[str, float], dict[str, str]]:
    """{IBGE: gasto próprio} e {IBGE: macrorregião}, em ANO."""
    gasto: dict[str, float] = defaultdict(float)
    regiao: dict[str, str] = {}
    with GASTO_CSV.open(encoding="latin1") as f:
        for row in csv.DictReader(f, delimiter=";"):
            if int(row["exercicio"]) != ANO:
                continue
            # o CSV está em latin1, então "Próprio" chega com o byte cru
            if not row["origem"].startswith("Recurso Pr"):
                continue
            ibge = row["codigo_ibge"].strip().zfill(7)[:6]
            gasto[ibge] += num(row["valor_nominal_final"])
            regiao[ibge] = row["regiao_munic"]
    return gasto, regiao


def densidade(valores: list[float]) -> list[float]:
    """
    Núcleo gaussiano avaliado numa grade de 0 a X_MAX, normalizado para somar 1
    na grade — as cinco curvas passam a ter a mesma área, então o que se compara
    é a forma e não o tamanho da região.

    Os valores acima de X_MAX entram na conta do núcleo (um município a 9%
    ainda empurra densidade para dentro do quadro) mas não têm ponto de grade
    próprio: a curva é a projeção do que existe sobre a janela desenhada.
    """
    passo = X_MAX / (GRADE - 1)
    grade = [i * passo for i in range(GRADE)]
    fora = 1 / (BANDA * math.sqrt(2 * math.pi))
    ys = [0.0] * GRADE

    for v in valores:
        # além de quatro bandas o núcleo não contribui de forma visível
        inicio = max(0, int((v - 4 * BANDA) / passo))
        fim = min(GRADE - 1, int((v + 4 * BANDA) / passo) + 1)
        for i in range(inicio, fim + 1):
            z = (grade[i] - v) / BANDA
            ys[i] += fora * math.exp(-0.5 * z * z)

    soma = sum(ys)
    return [y / soma for y in ys] if soma else ys


def build() -> tuple[dict, dict]:
    rcl = ler_rcl()
    gasto, regiao = ler_gasto()

    registros = [
        {"ibge": ibge, "pct": 100 * valor / rcl[ibge], "gasto": valor, "regiao": regiao[ibge]}
        for ibge, valor in gasto.items()
        if rcl.get(ibge)
    ]
    base = len(registros)
    acima = sum(1 for r in registros if r["pct"] > META)

    # --- conferência contra a figura já publicada -----------------------------
    meta = json.loads(META_JSON.read_text(encoding="utf-8"))
    referencia = next(a for a in meta["anos"] if a["ano"] == ANO)
    if base != referencia["analisados"] or acima != referencia["acima"]:
        raise SystemExit(
            f"join divergiu de meta-rcl-municipios.json: {base}/{acima} analisados/acima, "
            f"esperado {referencia['analisados']}/{referencia['acima']}"
        )

    # --- cristas de densidade por região --------------------------------------
    por_regiao: dict[str, list[dict]] = defaultdict(list)
    for r in registros:
        por_regiao[r["regiao"]].append(r)

    regioes = []
    for nome in sorted(por_regiao):
        grupo = por_regiao[nome]
        pcts = sorted(r["pct"] for r in grupo)
        n = len(pcts)
        regioes.append(
            {
                "regiao": nome,
                "n": n,
                "mediana": round(pcts[n // 2], 2),
                "pctAcimaMeta": round(100 * sum(1 for p in pcts if p > META) / n, 1),
                "foraDaEscala": sum(1 for p in pcts if p > X_MAX),
                "densidade": [round(y, 6) for y in densidade(pcts)],
            }
        )

    todos = sorted(r["pct"] for r in registros)
    distribuicao = {
        "ano": ANO,
        "meta": META,
        "xMax": X_MAX,
        "banda": BANDA,
        "base": base,
        "acimaDaMeta": acima,
        "medianaNacional": round(todos[base // 2], 2),
        "maximo": round(todos[-1], 1),
        "foraDaEscala": sum(1 for p in todos if p > X_MAX),
        "regioes": sorted(regioes, key=lambda r: -r["pctAcimaMeta"]),
    }

    # --- curva de concentração ------------------------------------------------
    valores = sorted(r["gasto"] for r in registros)
    total = sum(valores)
    acumulado = list(accumulate(valores))

    # 101 pontos: um por ponto percentual da população de municípios
    pontos = [[0.0, 0.0]]
    for p in range(1, 101):
        i = max(1, round(p / 100 * base))
        pontos.append([p, round(100 * acumulado[i - 1] / total, 2)])

    # Gini pela área entre a curva e a diagonal, no trapézio da própria série
    area = sum(
        (pontos[i][1] + pontos[i - 1][1]) / 2 * (pontos[i][0] - pontos[i - 1][0])
        for i in range(1, len(pontos))
    )
    gini = round((5000 - area) / 5000, 3)

    def concentram(topo: int) -> float:
        i = base - round(topo / 100 * base)
        return round(100 * (1 - acumulado[i - 1] / total), 1)

    concentracao = {
        "ano": ANO,
        "base": base,
        "gini": gini,
        "pontos": pontos,
        "marcos": [{"topo": t, "share": concentram(t)} for t in (1, 5, 10, 20, 50)],
    }

    return distribuicao, concentracao


if __name__ == "__main__":
    distribuicao, concentracao = build()
    DISTRIBUICAO_OUT.write_text(
        json.dumps(distribuicao, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    CONCENTRACAO_OUT.write_text(
        json.dumps(concentracao, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"escrito: {DISTRIBUICAO_OUT.relative_to(PROJECT_DIR)}")
    print(
        f"  {distribuicao['base']} municípios, mediana {distribuicao['medianaNacional']}%, "
        f"máximo {distribuicao['maximo']}%, {distribuicao['foraDaEscala']} fora da escala"
    )
    for r in distribuicao["regioes"]:
        print(
            f"    {r['regiao']:13s} n={r['n']:5d}  mediana {r['mediana']:5.2f}%  "
            f"acima da meta {r['pctAcimaMeta']:5.1f}%"
        )
    print(f"escrito: {CONCENTRACAO_OUT.relative_to(PROJECT_DIR)}")
    print(f"  Gini {concentracao['gini']}")
    for m in concentracao["marcos"]:
        print(f"    {m['topo']:2d}% que mais gastam concentram {m['share']}% do gasto")
