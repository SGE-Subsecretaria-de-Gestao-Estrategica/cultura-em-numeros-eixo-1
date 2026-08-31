"""
Transcreve a tabela de agentes territoriais de cultura por UF que esta na
publicacao (secao 2.1.2, "Agentes territoriais: fortalecimento da politica
cultural junto as comunidades locais").

A tabela nao vem de nenhuma base do repositorio: ela e um registro
administrativo da Secretaria dos Comites de Cultura do MinC, e chegou ate nos
como tabela dentro do texto. Por isso a transcricao mora num script, e nao num
JSON escrito a mao — assim a fonte de cada numero fica declarada, e o total
publicado vira uma asserção que quebra o build se alguem editar um valor sem
querer.

Uso:
    python3 scripts/build_agentes_territoriais.py
"""

import json
from pathlib import Path

PROJECT_DIR = Path(__file__).resolve().parent.parent
OUT_PATH = PROJECT_DIR / "src/data/agentes-territoriais.json"

# O total impresso na propria tabela, na linha "TOTAL". Serve de conferencia da
# transcricao: se a soma das 27 UFs divergir, o script para.
TOTAL_PUBLICADO = 596

# Agentes territoriais de cultura em atuacao, por UF.
AGENTES = {
    # Centro-Oeste
    "DF": 4, "GO": 20, "MS": 12, "MT": 18,
    # Nordeste
    "AL": 11, "BA": 43, "CE": 22, "MA": 23, "SE": 6,
    "PB": 15, "PE": 24, "PI": 18, "RN": 11,
    # Norte
    "AC": 5, "AM": 11, "AP": 5, "PA": 21, "RO": 6, "RR": 5, "TO": 11,
    # Sudeste
    "ES": 9, "MG": 73, "RJ": 27, "SP": 93,
    # Sul
    "PR": 34, "RS": 43, "SC": 26,
}


def build() -> dict:
    soma = sum(AGENTES.values())
    if soma != TOTAL_PUBLICADO:
        raise SystemExit(
            f"transcrição não fecha: soma {soma}, total publicado {TOTAL_PUBLICADO}"
        )
    if len(AGENTES) != 27:
        raise SystemExit(f"esperava 27 UFs, tenho {len(AGENTES)}")

    return {
        "total": soma,
        "unidade": "agentes territoriais de cultura",
        "ufs": [{"uf": uf, "valor": v} for uf, v in AGENTES.items()],
    }


if __name__ == "__main__":
    dados = build()
    OUT_PATH.write_text(
        json.dumps(dados, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"escrito: {OUT_PATH.relative_to(PROJECT_DIR)}")
    print(f"  {dados['total']} agentes em {len(dados['ufs'])} UFs")
    maiores = sorted(dados["ufs"], key=lambda u: -u["valor"])[:4]
    print("  maiores: " + ", ".join(f"{u['uf']} {u['valor']}" for u in maiores))
