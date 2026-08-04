"""
Reconstroi a evolucao do investimento FEDERAL em cultura por fonte de recurso
(2003-2025), replicando a logica de eixo1/orcamento/scripts/federal/gasto federal.R
("Gasto Federal Pleno" = execucao direta no SIOP + renuncia fiscal).

Gasto direto (SIOP, empenhado), com a regra de transicao institucional do MinC:
  - anos com o orgao 42000 ativo: orgao 42000 + fundos (UO 73120/74912/73117);
  - 2019 (MinC recriado em meio ao exercicio): 42000 + Cidadania (55000) nas
    funcoes 13/28, excluida a UO do FNAS (55901), + fundos;
  - anos sem MinC (2020-2022): Turismo/Cidadania (54000/55000) nas funcoes 13/28,
    excluida a UO do FNAS, + fundos.

Gasto indireto (a partir de 2006, quando o SALIC passa a registrar o teto):
  - Lei Rouanet: valor de teto autorizado (SALIC);
  - Incentivo (ANCINE): captacao efetiva nos artigos de renuncia fiscal.

Uso:
    python3 scripts/build_federal_data.py

Requer pandas + openpyxl. A serie do IPCA (SGS 433) fica em cache em
scripts/ipca-433-2003-cache.json; apague o arquivo para buscar dados atualizados
da API do Banco Central (requer rede).
"""

import json
import urllib.request
from pathlib import Path

import pandas as pd

PROJECT_DIR = Path(__file__).resolve().parent.parent
REPO_ROOT = PROJECT_DIR.parent
FEDERAL_DIR = REPO_ROOT / "eixo1/orcamento/data"
SIOP_XLSX = FEDERAL_DIR / "raw/federal/funcoes_orgaos_unidades_rp_20260402_v2.xlsx"
SALIC_XLSX = FEDERAL_DIR / "raw/federal/salic_minc.xlsx"
ANCINE_XLSX = FEDERAL_DIR / "processed/federal/ANCINE - 2005 a 2026.xlsx"
IPCA_CACHE = PROJECT_DIR / "scripts/ipca-433-2003-cache.json"
OUT_PATH = PROJECT_DIR / "src/data/federal-por-fonte.json"

IPCA_URL = (
    "https://api.bcb.gov.br/dados/serie/bcdata.sgs.433/dados"
    "?formato=json&dataInicial=01/01/2003&dataFinal=31/12/2025"
)

ANO_BASE_DEFLATOR = 2024
ANO_INICIAL = 2003
ANO_FINAL = 2025
# o SALIC so registra teto a partir de 2006, e a ANCINE comeca em 2005
ANO_INICIAL_INDIRETO = 2006

ID_MINC = "42000"
IDS_TRANSICAO = {"54000", "55000"}
IDS_FUNDOS = {"73120", "74912", "73117"}
UO_FNAS = "55901"

ORDER = [
    "Ministério da Cultura (órgão 42000)",
    "Lei Rouanet",
    "Incentivo (ANCINE)",
    "FSA (UO 74912)",
    "PNAB (UO 73120)",
    "Lei Paulo Gustavo",
    "Lei Aldir Blanc 1",
    "Outros órgãos (Cidadania/Turismo)",
]

# As oito fontes sao a matriz de referencia, mas nao sao oito series temporais:
# quatro delas existem em 4 anos ou menos, e duas em um unico ano. Agrupadas
# pelo que sao institucionalmente, sobram tres — duas continuas e uma de eventos.
#
# "Execucao direta" reune o orgao gestor onde quer que a cultura estivesse
# alojada (MinC, ou Cidadania/Turismo entre 2019 e 2022) mais os fundos sob sua
# supervisao: e a mesma dotacao atravessando a extincao do ministerio.
GRUPOS: dict[str, list[str]] = {
    "Execução direta": [
        "Ministério da Cultura (órgão 42000)",
        "Outros órgãos (Cidadania/Turismo)",
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

# as tres leis de transferencia nunca coexistem num mesmo ano, entao a coluna e
# uma serie so e o rotulo diz qual lei a originou
ROTULO_TRANSFERENCIA = {
    "Lei Aldir Blanc 1": "LAB 1",
    "Lei Paulo Gustavo": "LPG",
    "PNAB (UO 73120)": "PNAB",
}

# artigos de renuncia fiscal do audiovisual; as demais colunas da planilha da
# ANCINE (FSA, editais, contrapartida) nao sao renuncia e ficariam duplicadas
COLUNAS_RENUNCIA = [
    "ART 1A",
    "ART 3A",
    "ART1",
    "ART18 (Lei 8.313/91 ROUANET)",
    "ART25 (Lei 8.313/91 ROUANET)",
    "ART3",
    "ART39 (CONDECINE)",
    "ART41 (FUNCINES)",
]


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
    indice_base = fatores.loc[
        fatores["ano"] == ANO_BASE_DEFLATOR, "indice_medio_ano"
    ].iloc[0]
    fatores["fator_deflacao"] = indice_base / fatores["indice_medio_ano"]
    return fatores[["ano", "fator_deflacao"]]


def load_siop() -> pd.DataFrame:
    df = pd.read_excel(
        SIOP_XLSX,
        usecols=[
            "Ano",
            "Órgão Orçamentário",
            "Função",
            "Unidade Orçamentária",
            "Empenhado",
        ],
    ).rename(
        columns={
            "Ano": "ano",
            "Órgão Orçamentário": "orgao",
            "Função": "funcao",
            "Unidade Orçamentária": "unidade",
            "Empenhado": "empenhado",
        }
    )

    df["ano"] = pd.to_numeric(df["ano"], errors="coerce")
    df["empenhado"] = pd.to_numeric(df["empenhado"], errors="coerce")
    df = df.dropna(subset=["ano", "unidade"])
    df["ano"] = df["ano"].astype(int)
    df["empenhado"] = df["empenhado"].fillna(0)
    df["orgao5"] = df["orgao"].astype(str).str[:5]
    df["uo5"] = df["unidade"].astype(str).str[:5]
    df["funcao"] = df["funcao"].astype(str)
    return df[df["ano"].between(ANO_INICIAL, ANO_FINAL)].copy()


def build_direto(df: pd.DataFrame) -> pd.DataFrame:
    anos_com_minc = set(df.loc[df["orgao5"] == ID_MINC, "ano"].unique())

    # funcoes 13 (Cultura) e 28 (Encargos Especiais), esta sem o fundo da
    # assistencia social — o recorte usado enquanto a cultura esteve alojada em
    # Cidadania/Turismo
    cultura_ou_encargos = (
        df["funcao"].str.contains("13")
        | (df["funcao"].str.contains("28") & (df["uo5"] != UO_FNAS))
    )
    fundos = df["uo5"].isin(IDS_FUNDOS)

    fase_2019 = (df["ano"] == 2019) & (
        (df["orgao5"] == ID_MINC)
        | ((df["orgao5"] == "55000") & cultura_ou_encargos)
        | fundos
    )
    fase_minc = (
        (df["ano"] != 2019)
        & df["ano"].isin(anos_com_minc)
        & ((df["orgao5"] == ID_MINC) | fundos)
    )
    fase_transicao = (
        (df["ano"] != 2019)
        & ~df["ano"].isin(anos_com_minc)
        & ((df["orgao5"].isin(IDS_TRANSICAO) & cultura_ou_encargos) | fundos)
    )

    escopo = df[fase_2019 | fase_minc | fase_transicao].copy()

    def categoria(row: pd.Series) -> str:
        if row["uo5"] == "73120":
            return "PNAB (UO 73120)"
        if row["uo5"] == "74912":
            return "FSA (UO 74912)"
        if row["uo5"] == "73117":
            return "Lei Paulo Gustavo" if row["ano"] >= 2022 else "Lei Aldir Blanc 1"
        if row["orgao5"] == ID_MINC:
            return "Ministério da Cultura (órgão 42000)"
        return "Outros órgãos (Cidadania/Turismo)"

    escopo["fonte"] = escopo.apply(categoria, axis=1)
    return escopo.groupby(["ano", "fonte"], as_index=False).agg(
        valor=("empenhado", "sum")
    )


def build_indireto() -> pd.DataFrame:
    salic = pd.read_excel(SALIC_XLSX, usecols=["ano", "vl_teto"])
    salic["ano"] = pd.to_numeric(salic["ano"], errors="coerce")
    salic = salic.dropna(subset=["ano"])
    salic["ano"] = salic["ano"].astype(int)
    rouanet = (
        salic.groupby("ano", as_index=False)
        .agg(valor=("vl_teto", "sum"))
        .assign(fonte="Lei Rouanet")
    )

    ancine_raw = pd.read_excel(ANCINE_XLSX)
    ancine_raw["ano"] = pd.to_numeric(ancine_raw["Ano"], errors="coerce")
    ancine_raw = ancine_raw.dropna(subset=["ano"])
    ancine_raw["ano"] = ancine_raw["ano"].astype(int)
    for col in COLUNAS_RENUNCIA:
        ancine_raw[col] = pd.to_numeric(ancine_raw[col], errors="coerce").fillna(0)
    ancine = (
        ancine_raw.assign(valor=ancine_raw[COLUNAS_RENUNCIA].sum(axis=1))
        .groupby("ano", as_index=False)
        .agg(valor=("valor", "sum"))
        .assign(fonte="Incentivo (ANCINE)")
    )

    indireto = pd.concat([rouanet, ancine], ignore_index=True)
    return indireto[indireto["ano"].between(ANO_INICIAL_INDIRETO, ANO_FINAL)]


def build() -> dict:
    fatores = load_ipca()
    resumo = pd.concat([build_direto(load_siop()), build_indireto()], ignore_index=True)
    resumo = resumo[resumo["valor"] > 0]

    resumo = resumo.merge(fatores, on="ano", how="left")
    resumo["valor_real"] = resumo["valor"] * resumo["fator_deflacao"]

    years = list(range(ANO_INICIAL, ANO_FINAL + 1))
    faltando = set(resumo["fonte"]) - set(ORDER)
    if faltando:
        raise ValueError(f"fontes fora de ORDER: {sorted(faltando)}")

    def pivot(value_col: str) -> list[dict]:
        piv = (
            resumo.pivot_table(
                index="ano", columns="fonte", values=value_col, aggfunc="sum"
            )
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

    def agrupar(detalhado: list[dict]) -> list[dict]:
        out = []
        for row in detalhado:
            rec = {"label": row["label"]}
            for grupo, fontes in GRUPOS.items():
                rec[grupo] = round(sum(row[f] for f in fontes), 2)
            # qual lei originou a transferencia daquele ano, para o rotulo da coluna
            origem = max(
                GRUPOS[GRUPO_TRANSFERENCIAS], key=lambda f: row[f], default=None
            )
            if origem and row[origem] > 0:
                rec["origemTransferencia"] = ROTULO_TRANSFERENCIA[origem]
            out.append(rec)
        return out

    detalhado_nominal = pivot("valor")
    detalhado_real = pivot("valor_real")

    return {
        "keys": ORDER,
        "unidade": "R$",
        "anoBaseDeflator": ANO_BASE_DEFLATOR,
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
    result = build()
    OUT_PATH.write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"wrote {OUT_PATH}")
