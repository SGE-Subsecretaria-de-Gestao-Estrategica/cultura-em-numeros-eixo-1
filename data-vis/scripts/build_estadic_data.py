"""
Monta os dados de governanca estadual da cultura a partir do painel ja
processado da ESTADIC/IBGE em
eixo1/gestao&participacao/estadic/data/processed/estadic_cultura_painel_transversal_12_24.csv
(27 UFs, ondas de 2012 a 2024).

O painel ja chega com os rotulos finais recodificados pelo proprio
eixo1/gestao&participacao/estadic/scripts/ESTADIC.R (tipo_orgao_gestor em 3
categorias, gestor_escolaridade_agrupada em 4, cons_paritario/cons_competencia
ja resolvidos) — este script so filtra, conta e sobe para percentual, sem
refazer nenhum de-para.

Duas simplificacoes em relacao ao R original, ambas por o que o dado de 2021
de fato mostra, e nao por decisao de design:

- `cons_competencia` de 2014 vem inteiramente vazio no painel (o modulo de
  2014 nao tinha essa pergunta) — a onda sai da figura de competencia dos
  conselhos, que fica com 2018 e 2021.
- Em 2021 as 27 UFs ja tem conselho ativo e lei de patrimonio propria: o mapa
  de "fomento" do R (que cruza patrimonio x incentivo em 4 classes) tem duas
  das quatro classes vazias por construcao. Reduzido a mapa binario do que de
  fato varia — lei de incentivo, sim ou nao — em vez de simular uma variacao
  que a onda mais recente nao tem.

Uso:
    python3 scripts/build_estadic_data.py

Nao requer dependencias externas.
"""

import csv
import json
from collections import Counter
from pathlib import Path

PROJECT_DIR = Path(__file__).resolve().parent.parent
REPO_ROOT = PROJECT_DIR.parent
CSV_PATH = (
    REPO_ROOT
    / "eixo1/gestao&participacao/estadic/data/processed/estadic_cultura_painel_transversal_12_24.csv"
)
OUT_PATH = PROJECT_DIR / "src/data/estadic-governanca.json"

UNIVERSO = 27  # 26 estados + Distrito Federal


def ler() -> list[dict]:
    with CSV_PATH.open(encoding="utf-8-sig") as f:
        return list(csv.DictReader(f, delimiter=","))


def por_ano(linhas: list[dict], ano: int) -> list[dict]:
    return [l for l in linhas if l["ano"] == str(ano)]


def contagem(linhas: list[dict], coluna: str, validos: set[str] | None = None) -> Counter:
    valores = (l[coluna] for l in linhas)
    if validos is not None:
        valores = (v for v in valores if v in validos)
    return Counter(valores)


def composicao_por_onda(
    linhas: list[dict], anos: list[int], coluna: str, categorias: list[str], filtro=None
) -> dict:
    """{categorias, ondas: [{label, base, ...pct por categoria, ...n_ por categoria}]}"""
    ondas = []
    for ano in anos:
        sub = por_ano(linhas, ano)
        if filtro is not None:
            sub = [l for l in sub if filtro(l)]
        c = contagem(sub, coluna, set(categorias))
        base = sum(c.values())
        onda = {"label": str(ano), "base": base}
        for cat in categorias:
            n = c.get(cat, 0)
            onda[cat] = round(100 * n / base, 1) if base else 0.0
            onda[f"n_{cat}"] = n
        ondas.append(onda)
    return {"categorias": categorias, "ondas": ondas}


def serie_binaria(linhas: list[dict], anos: list[int], coluna: str) -> list[dict]:
    """[{ano, taxa, nSim, base}] — a proporcao de UFs com a coluna == 'Sim'."""
    pontos = []
    for ano in anos:
        sub = por_ano(linhas, ano)
        c = contagem(sub, coluna, {"Sim", "Não"})
        base = sum(c.values())
        n_sim = c.get("Sim", 0)
        pontos.append(
            {"ano": ano, "taxa": round(100 * n_sim / base, 1) if base else 0.0, "nSim": n_sim, "base": base}
        )
    return pontos


def build() -> dict:
    linhas = ler()

    orgao_gestor = composicao_por_onda(
        linhas,
        [2014, 2018, 2021],
        "tipo_orgao_gestor",
        ["Setor Subordinado / Outros", "Secretaria Conjunta", "Secretaria Exclusiva / Fundação"],
    )

    escolaridade = composicao_por_onda(
        linhas,
        [2014, 2018, 2021],
        "gestor_escolaridade_agrupada",
        ["Ensino Médio", "Ensino Superior", "Pós-Graduação"],
    )

    tem_conselho = lambda l: l["tem_conselho"] == "Sim"  # noqa: E731

    paridade = composicao_por_onda(
        linhas, [2018, 2021], "cons_paritario", ["Não Paritário", "Paritário"], filtro=tem_conselho
    )

    competencia = composicao_por_onda(
        linhas,
        [2018, 2021],
        "cons_competencia",
        ["Consultivo", "Normativo / Fiscalizador", "Deliberativo"],
        filtro=tem_conselho,
    )

    incentivo = composicao_por_onda(linhas, [2018, 2021], "tem_lei_incentivo", ["Não", "Sim"])

    tripe = {
        "instrumentos": [
            {"key": "conselho", "label": "Conselho Estadual", "coluna": "tem_conselho"},
            {"key": "fundo", "label": "Fundo Estadual", "coluna": "tem_fundo"},
            {"key": "plano", "label": "Plano Estadual", "coluna": "tem_plano"},
        ],
        "anos": [2014, 2018, 2021],
    }
    for instrumento in tripe["instrumentos"]:
        instrumento["pontos"] = serie_binaria(linhas, tripe["anos"], instrumento["coluna"])

    patrimonio = {
        "anos": [2014, 2018, 2021],
        "pontos": serie_binaria(linhas, [2014, 2018, 2021], "tem_lei_patrimonio"),
    }

    transversalidade_defs = [
        ("pi_2023", "Arte e cultura na primeira infância", 2023, "pi_arte_cultura"),
        ("pm_2023", "Articulação com políticas para mulheres", 2023, "pm_parceria_cultura"),
        ("ir_gt_2024", "Cultura nos GTs de igualdade racial", 2024, "ir_gt_cultura"),
        ("ir_afro_2024", "Preservação do patrimônio afro-brasileiro", 2024, "ir_patrimonio_afro"),
        ("ir_quilombola_2024", "Preservação do patrimônio quilombola", 2024, "ir_patrimonio_quilombola"),
    ]
    transversalidade = []
    for key, label, ano, coluna in transversalidade_defs:
        sub = por_ano(linhas, ano)
        c = contagem(sub, coluna, {"Sim", "Não"})
        base = sum(c.values())
        n = c.get("Sim", 0)
        transversalidade.append(
            {"key": key, "label": label, "ano": ano, "n": n, "base": base, "pct": round(100 * n / base, 1) if base else 0.0}
        )

    # --- mapas 2021: um valor por UF -----------------------------------------
    linhas_21 = por_ano(linhas, 2021)

    ORGAO_ORDEM = {"Secretaria Conjunta": 0, "Secretaria Exclusiva / Fundação": 1}

    ufs = []
    for l in linhas_21:
        status_tripe = sum(1 for c in ("tem_plano", "tem_conselho", "tem_fundo") if l[c] == "Sim")
        ufs.append(
            {
                "uf": l["sigla_uf"],
                "regiao": l["regiao"],
                "statusTripe": status_tripe,
                "temPlano": l["tem_plano"],
                "temFundo": l["tem_fundo"],
                "orgaoOrdinal": ORGAO_ORDEM.get(l["tipo_orgao_gestor"]),
                "tipoOrgao": l["tipo_orgao_gestor"],
                "temLeiIncentivo": l["tem_lei_incentivo"] == "Sim",
            }
        )

    status_tripe_dist = Counter(u["statusTripe"] for u in ufs)
    orgao_dist = Counter(u["tipoOrgao"] for u in ufs)
    incentivo_dist = Counter(u["temLeiIncentivo"] for u in ufs)

    return {
        "universo": UNIVERSO,
        "ano": 2021,
        "orgaoGestor": orgao_gestor,
        "escolaridade": escolaridade,
        "paridade": paridade,
        "competencia": competencia,
        "incentivo": incentivo,
        "tripe": tripe,
        "patrimonio": patrimonio,
        "transversalidade": transversalidade,
        "mapas2021": {
            "ufs": ufs,
            "distribuicoes": {
                "statusTripe": dict(sorted(status_tripe_dist.items())),
                "tipoOrgao": dict(orgao_dist),
                "temLeiIncentivo": {str(k): v for k, v in incentivo_dist.items()},
            },
        },
    }


def main() -> None:
    dados = build()
    OUT_PATH.write_text(json.dumps(dados, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"{OUT_PATH.relative_to(PROJECT_DIR)}: {len(dados['mapas2021']['ufs'])} UFs em 2021")
    print("  status do tripé (2021):", dados["mapas2021"]["distribuicoes"]["statusTripe"])
    print("  órgão gestor (2021):", dados["mapas2021"]["distribuicoes"]["tipoOrgao"])
    print("  lei de incentivo (2021):", dados["mapas2021"]["distribuicoes"]["temLeiIncentivo"])


if __name__ == "__main__":
    main()
