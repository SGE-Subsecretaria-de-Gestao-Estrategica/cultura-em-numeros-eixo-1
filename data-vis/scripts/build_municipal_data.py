"""
Reconstroi a evolucao do investimento cultural MUNICIPAL por fonte de recurso
(2019-2025) a partir da base ja processada em
eixo1/orcamento/data/processed/municipal/df_municipios_final.xlsx, que replica
a logica de eixo1/orcamento/scripts/municipal/fonte_recurso_municipal.R
(SICONFI + LAB 1 via BB Agil, ja deflacionada pelo IPCA).

Uso:
    python3 scripts/build_municipal_data.py

Requer pandas + openpyxl.
"""

import json
from pathlib import Path

import pandas as pd

PROJECT_DIR = Path(__file__).resolve().parent.parent
REPO_ROOT = PROJECT_DIR.parent
RAW_XLSX = (
    REPO_ROOT / "eixo1/orcamento/data/processed/municipal/df_municipios_final.xlsx"
)
OUT_PATH = PROJECT_DIR / "src/data/municipal-por-fonte.json"

ORDER = [
    "Recurso Próprio (Municipal)",
    "Emendas Parlamentares (Cultura)",
    "Lei Aldir Blanc 1 (LAB 1)",
    "Lei Paulo Gustavo (LPG)",
    "PNAB (Aldir Blanc 2)",
]


def build() -> dict:
    df = pd.read_excel(
        RAW_XLSX,
        usecols=["exercicio", "origem", "valor_nominal_final", "valor_real_final"],
    )
    df["exercicio"] = df["exercicio"].astype(int)

    resumo = df.groupby(["exercicio", "origem"], as_index=False).agg(
        valor_nominal=("valor_nominal_final", "sum"),
        valor_real=("valor_real_final", "sum"),
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
