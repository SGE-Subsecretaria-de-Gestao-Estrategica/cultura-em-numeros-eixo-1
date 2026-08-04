"""
Prepara a evolucao do investimento FEDERAL em cultura por fonte de recurso
(2003-2025) para os graficos, a partir da base ja processada em
eixo1/orcamento/data/processed/federal/federal_final.csv.

O CSV vem em formato longo (ano, fonte, valor) e ja traz a deflacao aplicada:
`fator_correcao` e o indice do ano contra o ano-base (fator 1), e `valor_real` e
o `valor_nominal` corrigido. A logica que o produz esta em
eixo1/orcamento/scripts/federal/gasto federal.R — recorte institucional do MinC
por fase, fundos setoriais, e a renuncia fiscal de Rouanet e ANCINE.

Uso:
    python3 scripts/build_federal_data.py

Requer apenas a biblioteca padrao.
"""

import csv
import json
from collections import defaultdict
from pathlib import Path

PROJECT_DIR = Path(__file__).resolve().parent.parent
REPO_ROOT = PROJECT_DIR.parent
CSV_PATH = REPO_ROOT / "eixo1/orcamento/data/processed/federal/federal_final.csv"
OUT_PATH = PROJECT_DIR / "src/data/federal-por-fonte.json"

# ordem de empilhamento na matriz completa: as continuas primeiro, as episodicas
# depois, e o residual por ultimo
ORDER = [
    "Ministério da Cultura (Órgão 42000)",
    "Lei Rouanet",
    "Incentivo (ANCINE)",
    "FSA (UO 74912)",
    "PNAB (UO 73120)",
    "Lei Paulo Gustavo",
    "Lei Aldir Blanc 1",
    "Outros Órgãos (Cidadania/Turismo)",
]

# As oito fontes sao a matriz de referencia, mas nao sao oito series temporais:
# quatro delas existem em 4 anos ou menos, e uma em um unico ano. Agrupadas
# pelo que sao institucionalmente, sobram tres — duas continuas e uma de eventos.
#
# "Execucao direta" reune o orgao gestor onde quer que a cultura estivesse
# alojada (MinC, ou Cidadania/Turismo entre 2019 e 2022) mais os fundos sob sua
# supervisao: e a mesma dotacao atravessando a extincao do ministerio.
GRUPOS: dict[str, list[str]] = {
    "Execução direta": [
        "Ministério da Cultura (Órgão 42000)",
        "Outros Órgãos (Cidadania/Turismo)",
        "FSA (UO 74912)",
    ],
    "Renúncia fiscal": ["Lei Rouanet", "Incentivo (ANCINE)"],
    "Transferências a estados e municípios": [
        "Lei Aldir Blanc 1",
        "Lei Paulo Gustavo",
        "PNAB (UO 73120)",
    ],
}

GRUPO_TRANSFERENCIAS = "Transferências a estados e municípios"

# a coluna de transferencias e uma serie so; o rotulo nomeia a lei — ou as leis,
# desde que a LPG passou a ser contada em 2023, onde ja havia PNAB
ROTULO_TRANSFERENCIA = {
    "Lei Aldir Blanc 1": "LAB 1",
    "Lei Paulo Gustavo": "LPG",
    "PNAB (UO 73120)": "PNAB",
}


def ler_csv() -> tuple[dict[int, dict[str, dict[str, float]]], int]:
    """Devolve {ano: {fonte: {real, nominal}}} e o ano-base do deflator."""
    por_ano: dict[int, dict[str, dict[str, float]]] = defaultdict(dict)
    ano_base: int | None = None

    with CSV_PATH.open(encoding="utf-8") as f:
        for linha in csv.DictReader(f):
            ano = int(linha["ano"])
            fonte = linha["fonte"]
            por_ano[ano][fonte] = {
                "real": float(linha["valor_real"]),
                "nominal": float(linha["valor_nominal"]),
            }
            # o ano-base e aquele em que corrigir nao muda nada
            if abs(float(linha["fator_correcao"]) - 1) < 1e-9:
                ano_base = ano

    if ano_base is None:
        raise ValueError("nenhum ano com fator_correcao = 1; deflator sem base")

    desconhecidas = {f for fontes in por_ano.values() for f in fontes} - set(ORDER)
    if desconhecidas:
        raise ValueError(f"fontes fora de ORDER: {sorted(desconhecidas)}")

    return por_ano, ano_base


def build() -> dict:
    por_ano, ano_base = ler_csv()
    anos = list(range(min(por_ano), max(por_ano) + 1))

    def pivot(medida: str) -> list[dict]:
        saida = []
        for ano in anos:
            registro: dict[str, str | float] = {"label": str(ano)}
            for fonte in ORDER:
                registro[fonte] = round(por_ano[ano].get(fonte, {}).get(medida, 0.0), 2)
            saida.append(registro)
        return saida

    def agrupar(detalhado: list[dict]) -> list[dict]:
        saida = []
        for linha in detalhado:
            registro: dict[str, str | float] = {"label": linha["label"]}
            for grupo, fontes in GRUPOS.items():
                registro[grupo] = round(sum(linha[f] for f in fontes), 2)

            # quais leis originaram a transferencia do ano, da maior para a
            # menor — em 2023 sao duas
            leis = sorted(
                (f for f in GRUPOS[GRUPO_TRANSFERENCIAS] if linha[f] > 0),
                key=lambda f: linha[f],
                reverse=True,
            )
            if leis:
                registro["origemTransferencia"] = " + ".join(
                    ROTULO_TRANSFERENCIA[f] for f in leis
                )
            saida.append(registro)
        return saida

    detalhado_nominal = pivot("nominal")
    detalhado_real = pivot("real")

    return {
        "keys": ORDER,
        "unidade": "R$",
        "anoBaseDeflator": ano_base,
        "nominal": detalhado_nominal,
        "real": detalhado_real,
        "grupos": {
            "keys": list(GRUPOS),
            "composicao": GRUPOS,
            # as duas primeiras sao continuas e viram linhas; a terceira e
            # episodica e vira coluna
            "linhas": list(GRUPOS)[:2],
            "colunas": [GRUPO_TRANSFERENCIAS],
            "nominal": agrupar(detalhado_nominal),
            "real": agrupar(detalhado_real),
        },
    }


if __name__ == "__main__":
    resultado = build()
    OUT_PATH.write_text(
        json.dumps(resultado, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"wrote {OUT_PATH}")
