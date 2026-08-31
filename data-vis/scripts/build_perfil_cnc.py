"""
Transcreve o perfil das pessoas inscritas como delegadas na 4a Conferencia
Nacional de Cultura (2024), da tabela da secao 2.2.1 da publicacao.

Sao 1.201 pessoas, repartidas de quatro maneiras. Como na tabela de agentes
territoriais, a transcricao mora num script para que a fonte de cada numero
fique declarada e para que os totais virem assercao: os quatro recortes tem de
fechar em 1.201 cada um, e fecham.

Duas decisoes de agregacao, ambas explicitas aqui:

- **Genero.** A tabela traz sete categorias e a paleta da marca sustenta cinco
  series. As tres com menos de 30 pessoas — mulher trans (22), travesti (11) e
  homem trans (4) — entram somadas as pessoas nao-binarias (28), num grupo de
  65. "Outro", com 77, fica separado e com o nome que a tabela deu: nao da para
  saber o que ele agrega, entao agrega-lo a qualquer outra coisa seria inventar.
- **Inscricao.** O recorte de delegacao nata / eleita titular / eleita suplente
  nao entra na figura. Ele descreve como a pessoa chegou, e nao quem ela e, que
  e a pergunta dos outros quatro. Fica na tabela.

Uso:
    python3 scripts/build_perfil_cnc.py
"""

import json
from pathlib import Path

PROJECT_DIR = Path(__file__).resolve().parent.parent
OUT_PATH = PROJECT_DIR / "src/data/perfil-cnc.json"

TOTAL_PUBLICADO = 1201

RECORTES = [
    {
        "key": "origem",
        "titulo": "De onde vêm",
        "fatias": [
            {"key": "sociedade-civil", "label": "Sociedade civil", "n": 810},
            {"key": "poder-publico", "label": "Poder público", "n": 391},
        ],
    },
    {
        "key": "raca",
        "titulo": "Cor ou raça declarada",
        "fatias": [
            {"key": "pardos", "label": "Pardas", "n": 425},
            {"key": "brancos", "label": "Brancas", "n": 406},
            {"key": "pretos", "label": "Pretas", "n": 262},
            {"key": "indigenas", "label": "Indígenas", "n": 77},
            {"key": "amarelos", "label": "Amarelas", "n": 31},
        ],
    },
    {
        "key": "genero",
        "titulo": "Identidade de gênero",
        "fatias": [
            {"key": "homem-cis", "label": "Homens cisgênero", "n": 564},
            {"key": "mulher-cis", "label": "Mulheres cisgênero", "n": 495},
            {"key": "outro", "label": "Outro", "n": 77},
            {
                "key": "trans-nb",
                "label": "Pessoas trans, travestis e não-binárias",
                "n": 28 + 22 + 11 + 4,
            },
        ],
    },
    {
        "key": "deficiencia",
        "titulo": "Pessoas com deficiência",
        "fatias": [
            {"key": "sem", "label": "Sem deficiência", "n": 1126},
            {"key": "com", "label": "Com deficiência", "n": 75},
        ],
    },
]


def build() -> dict:
    for recorte in RECORTES:
        soma = sum(f["n"] for f in recorte["fatias"])
        if soma != TOTAL_PUBLICADO:
            raise SystemExit(
                f"recorte {recorte['key']} soma {soma}, esperado {TOTAL_PUBLICADO}"
            )

    return {
        "total": TOTAL_PUBLICADO,
        "evento": "4ª Conferência Nacional de Cultura",
        "ano": 2024,
        "recortes": [
            {
                "key": r["key"],
                "titulo": r["titulo"],
                "fatias": [
                    {
                        **f,
                        "pct": round(f["n"] / TOTAL_PUBLICADO * 100, 1),
                    }
                    for f in r["fatias"]
                ],
            }
            for r in RECORTES
        ],
    }


if __name__ == "__main__":
    dados = build()
    OUT_PATH.write_text(
        json.dumps(dados, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"escrito: {OUT_PATH.relative_to(PROJECT_DIR)}")
    print(f"  {dados['total']} pessoas, {len(dados['recortes'])} recortes")
    for r in dados["recortes"]:
        partes = ", ".join(f"{f['label']} {f['pct']}%" for f in r["fatias"])
        print(f"  {r['titulo']}: {partes}")
