"""
Reconstroi a evolucao do investimento cultural ESTADUAL por fonte de recurso
(2019-2025) a partir da base MSC Orcamentaria (SICONFI) e do deflator IPCA,
replicando a logica de eixo1/orcamento/scripts/estadual/fonte_recurso_estadual.R.

Uso:
    python3 scripts/build_estadual_data.py

Requer pandas + pyarrow. A serie do IPCA (SGS 433) fica em cache em
scripts/ipca-433-cache.json; apague o arquivo para buscar dados atualizados
da API do Banco Central (requer rede).
"""

import json
import re
import urllib.request
from pathlib import Path

import pandas as pd

PROJECT_DIR = Path(__file__).resolve().parent.parent
REPO_ROOT = PROJECT_DIR.parent
RAW_PARQUET = (
    REPO_ROOT
    / "eixo1/orcamento/data/raw/estadual/msc_orcamentaria_estados_2019_2025_final.parquet"
)
IPCA_CACHE = PROJECT_DIR / "scripts/ipca-433-cache.json"
OUT_PATH = PROJECT_DIR / "src/data/estadual-por-fonte.json"

IPCA_URL = (
    "https://api.bcb.gov.br/dados/serie/bcdata.sgs.433/dados"
    "?formato=json&dataInicial=01/01/2019&dataFinal=31/12/2025"
)

ORDER = [
    "Recurso Próprio (Estadual)",
    "Emendas Parlamentares (Cultura)",
    "Lei Aldir Blanc 1 (LAB 1)",
    "Lei Paulo Gustavo (LPG)",
    "PNAB (Aldir Blanc 2)",
]

CODIGOS_EMENDAS = {
    "3101", "3110", "3111", "3120", "3121", "3130", "3140",
    "3201", "3202", "3210", "3211", "3220", "3221",
}


def load_ipca() -> pd.DataFrame:
    if not IPCA_CACHE.exists():
        with urllib.request.urlopen(IPCA_URL) as resp:
            raw = json.load(resp)
        IPCA_CACHE.write_text(json.dumps(raw, ensure_ascii=False, indent=2))
    else:
        raw = json.loads(IPCA_CACHE.read_text())

    ipca = pd.DataFrame(raw)
    ipca["data"] = pd.to_datetime(ipca["data"], format="%d/%m/%Y")
    ipca["valor"] = ipca["valor"].astype(float)
    ipca["ano"] = ipca["data"].dt.year
    ipca = ipca.sort_values("data").reset_index(drop=True)
    ipca["indice_encadeado"] = (1 + ipca["valor"] / 100).cumprod()

    fatores = (
        ipca.groupby("ano")["indice_encadeado"]
        .mean()
        .rename("indice_medio_ano")
        .reset_index()
    )
    indice_base = fatores.loc[fatores["ano"] == 2024, "indice_medio_ano"].iloc[0]
    fatores["fator_deflacao"] = indice_base / fatores["indice_medio_ano"]
    return fatores.rename(columns={"ano": "exercicio"})[["exercicio", "fator_deflacao"]]


def classify_origem(row: pd.Series) -> str:
    fs = row["fonte_string"]
    if re.match(r"^(1719|2719|1720|2720|719|720)", fs):
        return "PNAB (Aldir Blanc 2)"
    if re.match(r"^(1715|2715|1716|2716|715|716)", fs):
        return "Lei Paulo Gustavo (LPG)"
    if (
        row["exercicio"] in (2020, 2021)
        and not re.match(r"^(19|29)", fs)
        and re.match(r"^(17|27)", fs)
    ):
        return "Lei Aldir Blanc 1 (LAB 1)"
    if row["complemento_limpo"] in CODIGOS_EMENDAS:
        return "Emendas Parlamentares (Cultura)"
    return "Recurso Próprio (Estadual)"


def build() -> dict:
    fatores = load_ipca()

    cols = [
        "uf", "exercicio", "fonte_recursos", "funcao",
        "conta_contabil", "complemento_fonte", "natureza_conta", "valor",
    ]
    df = pd.read_parquet(RAW_PARQUET, columns=cols)

    df = df[df["natureza_conta"] == "C"].copy()
    df["exercicio"] = df["exercicio"].astype(int)
    df["id_funcao"] = df["funcao"].str.extract(r"(\d+)").astype(float)
    df["fonte_string"] = df["fonte_recursos"].astype(str).str.replace(".", "", regex=False)
    df["conta_limpa"] = df["conta_contabil"].astype(str).str.replace(".", "", regex=False)
    df["complemento_limpo"] = (
        df["complemento_fonte"].astype(str).str.replace(r"[^0-9]", "", regex=True).str.zfill(4)
    )

    df = df[df["conta_limpa"].str.startswith("62213")].copy()
    df["origem"] = df.apply(classify_origem, axis=1)
    df = df[(df["id_funcao"] == 13) | (df["origem"] == "Lei Aldir Blanc 1 (LAB 1)")].copy()

    df = df.merge(fatores, on="exercicio", how="left")
    df["valor"] = df["valor"].abs()
    df["valor_real"] = df["valor"] * df["fator_deflacao"]

    resumo = df.groupby(["exercicio", "origem"], as_index=False).agg(
        valor_nominal=("valor", "sum"),
        valor_real=("valor_real", "sum"),
    )

    years = sorted(resumo["exercicio"].unique().tolist())

    def pivot(value_col: str) -> list[dict]:
        piv = (
            resumo.pivot(index="exercicio", columns="origem", values=value_col)
            .reindex(columns=ORDER)
            .reindex(years)
            .fillna(0)
        )
        out = []
        for year, row in piv.iterrows():
            rec = {"label": str(int(year))}
            for key in ORDER:
                rec[key] = round(float(row[key]), 2)
            out.append(rec)
        return out

    return {
        "keys": ORDER,
        "unidade": "R$",
        "anoBaseDeflator": 2024,
        "nominal": pivot("valor_nominal"),
        "real": pivot("valor_real"),
    }


if __name__ == "__main__":
    result = build()
    OUT_PATH.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {OUT_PATH}")
