"""
Monta os dados dos graficos de gestao e participacao cultural municipal a partir
do painel historico da MUNIC/IBGE em
eixo1/gestao&participacao/data/processed/munic_cultura_painel_historico_06_21.csv
(4 ondas: 2006, 2014, 2018 e 2021).

O painel vem com os rotulos da pesquisa de origem, que mudam de onda para onda:
`tipo_orgao_gestor` tem 17 grafias para 5 categorias reais, e `gestor_sexo` e
`gestor_escolaridade` carregam meia duzia de codigos de nao-resposta cada. Todo o
de-para esta explicito aqui em cima, em tabelas nomeadas, para que a
harmonizacao seja auditavel — e nao escondida numa cadeia de `str.replace`.

Uso:
    python3 scripts/build_gestao_data.py

Requer pandas.
"""

import json
from pathlib import Path

import pandas as pd

PROJECT_DIR = Path(__file__).resolve().parent.parent
REPO_ROOT = PROJECT_DIR.parent
CSV_PATH = (
    REPO_ROOT
    / "eixo1/gestao&participacao/data/processed/munic_cultura_painel_historico_06_21.csv"
)
OUT_PATH = PROJECT_DIR / "src/data/gestao-municipal.json"

ONDAS = [2006, 2014, 2018, 2021]

# Codigos de nao-resposta. Aparecem em varias colunas com grafias diferentes
# entre ondas — inclusive `(**)Sem gestor` com e sem espaco depois do parentese.
# Nenhum deles entra em denominador: um municipio que recusou responder nao e
# evidencia nem a favor nem contra o que se esta medindo.
NAO_RESPOSTA = {
    "-",
    "(**)Sem gestor",
    "(**) Sem gestor",
    "Recusa",
    "Não informado",
    "Não informou",
    "Não aplicável",
    "Não disponível",
}


# --- tripe institucional ------------------------------------------------------

# Os tres instrumentos que a literatura do SNC trata como o tripe, na ordem em
# que o grafico os empilha. `tem_*` e binario limpo ("Sim"/"Não") nas 4 ondas.
TRIPE = [
    ("tem_conselho", "Conselho de Cultura"),
    ("tem_fundo", "Fundo de Cultura"),
    ("tem_plano", "Plano de Cultura"),
]

# Equipamentos culturais, mesma estrutura binaria.
EQUIPAMENTOS = [
    ("equip_biblioteca", "Biblioteca pública"),
    ("equip_museu", "Museu"),
    ("equip_teatro", "Teatro ou sala de espetáculo"),
    ("equip_cinema", "Cinema"),
]

# A MUNIC 2018 nao fez as perguntas de equipamento ao conjunto dos municipios:
# 2.358 dos 5.570 vem com "-". Entre os 3.212 que responderam, a taxa de
# bibliotecas cai para 63,9%, contra 97,1% em 2014 e 88,3% em 2021 — um degrau
# que e da amostra, nao do fenomeno. A onda fica fora da serie de equipamentos.
EQUIPAMENTOS_ONDAS = [2006, 2014, 2021]


# --- estrutura do orgao gestor ------------------------------------------------

# 17 rotulos -> 5 categorias. As variacoes sao de grafia (`à` vs `a`, `Executivo`
# vs `executivo`, um espaco duplo em 2021) e de vocabulario entre ondas
# ("Fundação pública" em 2006 vira "Órgão da administração indireta" em 2014+;
# "Secretaria municipal exclusiva" vira "Secretaria exclusiva").
ESTRUTURA_DE_PARA = {
    # secretaria propria, dedicada so a cultura
    "Secretaria exclusiva": "Secretaria exclusiva",
    "Secretaria municipal exclusiva": "Secretaria exclusiva",
    # fundacao ou autarquia
    "Fundação pública": "Administração indireta",
    "Órgão da administração indireta": "Administração indireta",
    # cultura dividindo secretaria com outra politica setorial
    "Secretaria em conjunto com outras políticas": "Secretaria em conjunto",
    "Secretaria em conjunto com outras políticas setoriais": "Secretaria em conjunto",
    "Secretaria municipal em conjunto com outras políticas": "Secretaria em conjunto",
    # setor sem status de secretaria, subordinado a alguem
    "Setor subordinado a outra secretaria": "Setor subordinado",
    "Setor subordinado à outra secretaria": "Setor subordinado",
    "Setor subordinado à chefia do Executivo": "Setor subordinado",
    "Setor subordinado diretamente à chefia do Executivo": "Setor subordinado",
    "Setor subordinado diretamente  à chefia do Executivo": "Setor subordinado",
    "Setor subordinado diretamente à chefia do executivo": "Setor subordinado",
    # sem nada
    "Não possui estrutura": "Não possui estrutura",
    "Não possui estrutura específica": "Não possui estrutura",
}

# Do mais para o menos institucionalizado: e a leitura que a barra empilhada
# oferece de graca, de baixo para cima.
ESTRUTURA_ORDEM = [
    "Secretaria exclusiva",
    "Administração indireta",
    "Secretaria em conjunto",
    "Setor subordinado",
    "Não possui estrutura",
]


# --- escolaridade do gestor ---------------------------------------------------

# A coluna `gestor_escolaridade_agrupada` que vem no painel NAO e usavel: em 2021
# ela joga os 105 municipios de ensino fundamental dentro da faixa
# "Ensino Médio a Pós-graduação lato sensu", e a categoria fundamental aparece
# zerada — enquanto a coluna bruta mostra 55 completos e 50 incompletos. O
# agrupamento e refeito aqui a partir de `gestor_escolaridade`, que e consistente
# entre as ondas. Reproduz os numeros publicados do analista (15,2 / 10,3 / 3,8).
ESCOLARIDADE_ORDEM = [
    "Ensino fundamental",
    "Ensino médio a pós-graduação lato sensu",
    "Mestrado e doutorado",
]


def escolaridade(valor) -> str | None:
    """Agrupa a escolaridade bruta em tres faixas; None para nao-resposta."""
    v = str(valor)
    if v in NAO_RESPOSTA or v == "nan":
        return None
    if "fundamental" in v:
        return "Ensino fundamental"
    if v in ("Mestrado", "Doutorado"):
        return "Mestrado e doutorado"
    if "médio" in v or "superior" in v or v in ("Especialização", "Pós-graduação"):
        return "Ensino médio a pós-graduação lato sensu"
    raise ValueError(f"escolaridade nao mapeada: {valor!r}")


# --- execucao do repasse da Lei Aldir Blanc -----------------------------------

# Faixas de `orcamento_perc_executado`, que so existe na onda de 2021 e e
# categorica (nao e um percentual numerico). Ordem crescente de execucao.
FAIXAS_LAB = [
    "0%",
    "Até 10%",
    "11% a 20%",
    "21% a 30%",
    "31% a 40%",
    "41% a 50%",
    "51% a 60%",
    "61% a 70%",
    "71% a 80%",
    "81% a 90%",
    "Mais de 90%",
]


def _pct(parte: int, total: int) -> float:
    return round(100 * parte / total, 1) if total else 0.0


def _serie_binaria(df: pd.DataFrame, colunas, ondas) -> list[dict]:
    """% de municipios com "Sim" em cada coluna, onda a onda.

    O denominador e o total de respostas validas da propria coluna naquela onda,
    nao o total de municipios: as ondas tem universos diferentes (5.564 em 2006,
    5.570 depois) e algumas colunas carregam nao-resposta.
    """
    series = []
    for coluna, rotulo in colunas:
        pontos = []
        for ano in ondas:
            onda = df[df.ano == ano][coluna]
            validas = onda[~onda.isin(NAO_RESPOSTA) & onda.notna()]
            sim = int((validas == "Sim").sum())
            pontos.append(
                {
                    "ano": ano,
                    "pct": _pct(sim, len(validas)),
                    "n": sim,
                    "base": int(len(validas)),
                }
            )
        series.append({"key": coluna, "label": rotulo, "pontos": pontos})
    return series


def _composicao(df: pd.DataFrame, coluna: str, de_para, ordem, ondas) -> dict:
    """Distribuicao percentual de uma categorica por onda, em base 100."""
    ondas_out = []
    for ano in ondas:
        onda = df[df.ano == ano][coluna]
        mapeado = onda.map(de_para) if de_para else onda
        validas = mapeado.dropna()
        total = len(validas)
        contagem = validas.value_counts()
        ondas_out.append(
            {
                "label": str(ano),
                "base": total,
                "naoResposta": int(len(onda) - total),
                **{cat: _pct(int(contagem.get(cat, 0)), total) for cat in ordem},
                **{f"n_{cat}": int(contagem.get(cat, 0)) for cat in ordem},
            }
        )
    return {"categorias": list(ordem), "ondas": ondas_out}


def build() -> dict:
    df = pd.read_csv(CSV_PATH)
    df["ano"] = df["ano"].astype(int)

    # Erro cedo se o painel mudar de forma sob os pes do script.
    faltando = set(ONDAS) - set(df.ano.unique())
    if faltando:
        raise ValueError(f"ondas ausentes no painel: {sorted(faltando)}")

    universo = {str(ano): int((df.ano == ano).sum()) for ano in ONDAS}

    # -- A1 / A8: series historicas ------------------------------------------
    tripe = _serie_binaria(df, TRIPE, ONDAS)
    equipamentos = _serie_binaria(df, EQUIPAMENTOS, EQUIPAMENTOS_ONDAS)

    # -- A2: estrutura do orgao gestor ---------------------------------------
    nao_mapeados = set(df.tipo_orgao_gestor.dropna().unique()) - set(
        ESTRUTURA_DE_PARA
    ) - NAO_RESPOSTA
    if nao_mapeados:
        raise ValueError(f"tipo_orgao_gestor nao mapeado: {sorted(nao_mapeados)}")
    estrutura = _composicao(
        df, "tipo_orgao_gestor", ESTRUTURA_DE_PARA, ESTRUTURA_ORDEM, ONDAS
    )

    # -- A3: genero dos titulares --------------------------------------------
    # 2006 nao coletou o perfil do gestor: as 5.564 linhas vem nulas.
    genero_de_para = {"Feminino": "Feminino", "Masculino": "Masculino"}
    genero = _composicao(
        df, "gestor_sexo", genero_de_para, ["Feminino", "Masculino"], [2014, 2018, 2021]
    )

    # -- A9 (bonus): cor/raca, coletada so em 2018 e 2021 ---------------------
    cor_ordem = ["Branca", "Parda", "Preta", "Amarela", "Indígena"]
    cor_raca = _composicao(
        df, "gestor_cor_raca", {c: c for c in cor_ordem}, cor_ordem, [2018, 2021]
    )

    # -- A4: escolaridade x tripe completo, 2021 ------------------------------
    d21 = df[df.ano == 2021].copy()
    d21["faixa"] = d21.gestor_escolaridade.map(escolaridade)
    d21["tripe_completo"] = (
        d21.tem_plano.eq("Sim") & d21.tem_fundo.eq("Sim") & d21.tem_conselho.eq("Sim")
    )
    escolaridade_itens = []
    for faixa in ESCOLARIDADE_ORDEM:
        grupo = d21[d21.faixa == faixa]
        escolaridade_itens.append(
            {
                "label": faixa,
                "n": int(len(grupo)),
                "valor": int(grupo.tripe_completo.sum()),
                "pct": _pct(int(grupo.tripe_completo.sum()), len(grupo)),
            }
        )

    # -- A5: execucao do repasse da Lei Aldir Blanc, 2021 ---------------------
    contagem_lab = d21.orcamento_perc_executado.value_counts()
    base_lab = int(sum(contagem_lab.get(f, 0) for f in FAIXAS_LAB))
    lab_itens = [
        {
            "label": faixa,
            "n": int(contagem_lab.get(faixa, 0)),
            "valor": int(contagem_lab.get(faixa, 0)),
            "pct": _pct(int(contagem_lab.get(faixa, 0)), base_lab),
        }
        for faixa in FAIXAS_LAB
    ]

    return {
        "ondas": ONDAS,
        "universo": universo,
        "tripe": {"series": tripe},
        "equipamentos": {"series": equipamentos, "ondas": EQUIPAMENTOS_ONDAS},
        "estrutura": estrutura,
        "genero": genero,
        "corRaca": cor_raca,
        "escolaridadeTripe": {
            "ano": 2021,
            "itens": escolaridade_itens,
            "semInformacao": int(d21.faixa.isna().sum()),
        },
        "execucaoLab": {
            "ano": 2021,
            "itens": lab_itens,
            "base": base_lab,
            "semInformacao": int(contagem_lab.get("Sem Informação", 0)),
        },
    }


if __name__ == "__main__":
    dados = build()
    OUT_PATH.write_text(
        json.dumps(dados, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"escrito: {OUT_PATH.relative_to(PROJECT_DIR)}")
    print(f"  universo por onda: {dados['universo']}")
    print(f"  tripé 2021: " + ", ".join(
        f"{s['label']} {s['pontos'][-1]['pct']}%" for s in dados["tripe"]["series"]
    ))
