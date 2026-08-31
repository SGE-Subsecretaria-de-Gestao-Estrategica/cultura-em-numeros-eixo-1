# Agrega os CSVs processados do eixo 1 nos JSONs que as figuras novas leem.
#
# Rodar da raiz do repositório:
#   python3 data-vis/scripts/prepara-dados-eixo1.py
#
# Saídas em data-vis/src/data:
#   tres-esferas.json        — investimento em cultura por esfera, valores reais
#   meta-rcl-municipios.json — municípios acima de 2% da RCL, por exercício
#   tripe-uf.json            — tripé institucional completo por UF, 2014 e 2021
#   participacao-rcl-uf.json — gasto próprio estadual como % da RCL, por UF
#   meta-rcl-regiao.json     — municípios acima de 2% da RCL, por macrorregião
#
# As duas últimas saem dos dados brutos, não dos processados: a participação por
# UF e o recorte regional da meta não existem prontos em `data/processed`, que só
# traz o agregado nacional (Indicador_1) e o Centro-Oeste (Indicador_2). As duas
# reconstruções são conferidas contra esses dois indicadores em `_confere`.
#
# A RCL municipal vem em .rar de ~300 MB descompactados; o script extrai sob
# demanda para um cache local e reaproveita em execuções seguintes.

import csv
import json
import re
import subprocess
from collections import defaultdict
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
ORCAMENTO = RAIZ / 'eixo1/orcamento/data/processed'
BRUTO = RAIZ / 'eixo1/orcamento/data/raw'
GESTAO = RAIZ / 'eixo1/gestao&participacao/data/processed'
SAIDA = RAIZ / 'data-vis/src/data'
CACHE = RAIZ / 'data-vis/.cache/rcl-municipal'


def num(texto: str) -> float:
    return float(texto.replace(',', '.'))


def num_siconfi(texto: str) -> float:
    """
    Um valor do SICONFI, que mistura três notações no mesmo arquivo.

    A RCL de um estado grande sai em notação científica com vírgula decimal
    (`2,29658E+11`), e foi isso que derrubou São Paulo e Minas Gerais de uma
    primeira leitura: `float` levantava `ValueError` e a UF sumia do ano sem
    aviso. Municípios pequenos saem com a vírgula nos centavos.
    """
    return float(texto.strip().replace(',', '.'))


def tres_esferas() -> None:
    totais: dict[tuple[str, str], float] = defaultdict(float)
    with open(ORCAMENTO / 'nacional/tres_esferas_consolidado.csv', encoding='utf-8-sig') as f:
        for row in csv.DictReader(f, delimiter=';'):
            totais[(row['exercicio'], row['esfera'])] += num(row['valor_real'])

    anos = sorted({ano for ano, _ in totais})
    series = [
        {
            'key': esfera.lower(),
            'label': esfera,
            'valores': [round(totais[(ano, esfera)] / 1e9, 2) for ano in anos],
        }
        for esfera in ('Municipal', 'Federal', 'Estadual')
    ]
    (SAIDA / 'tres-esferas.json').write_text(
        json.dumps(
            {
                'unidade': 'R$ bilhões, a preços médios de 2024 (IPCA)',
                'anos': [int(a) for a in anos],
                'series': series,
            },
            ensure_ascii=False,
            indent=2,
        )
        + '\n',
        encoding='utf-8',
    )


def meta_rcl() -> None:
    linhas = []
    with open(ORCAMENTO / 'municipal/Indicador_1_Meta_2_Porcento_RCL.csv', encoding='utf-8-sig') as f:
        for row in csv.DictReader(f, delimiter=';'):
            linhas.append(
                {
                    'ano': int(row['exercicio']),
                    'analisados': int(row['Total de Municípios Analisados']),
                    'acima': int(row['Qtd Municípios (> 2% RCL)']),
                    'pct': num(row['Percentual do Total (%)']),
                }
            )
    (SAIDA / 'meta-rcl-municipios.json').write_text(
        json.dumps({'meta': '2% da RCL', 'anos': linhas}, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8',
    )


def tripe_uf() -> None:
    ONDAS = ('2014', '2021')
    contagem: dict[tuple[str, str], list[int]] = defaultdict(lambda: [0, 0])
    nacional: dict[str, list[int]] = defaultdict(lambda: [0, 0])
    regiao_por_uf: dict[str, str] = {}

    with open(GESTAO / 'munic_painel_historico.csv', encoding='utf-8-sig') as f:
        for row in csv.DictReader(f):
            if row['ano'] not in ONDAS:
                continue
            uf = row['uf']
            regiao_por_uf[uf] = row['regiao']
            completo = all(row[c] == 'Sim' for c in ('tem_plano', 'tem_conselho', 'tem_fundo'))
            for alvo in (contagem[(row['ano'], uf)], nacional[row['ano']]):
                alvo[1] += 1
                alvo[0] += int(completo)

    def pct(par: list[int]) -> float:
        return round(100 * par[0] / par[1], 1)

    ufs = [
        {
            'uf': uf,
            'regiao': regiao_por_uf[uf],
            'pct2014': pct(contagem[('2014', uf)]),
            'pct2021': pct(contagem[('2021', uf)]),
            'municipios': contagem[('2021', uf)][1],
        }
        for uf in sorted(regiao_por_uf)
    ]
    (SAIDA / 'tripe-uf.json').write_text(
        json.dumps(
            {
                'mediaNacional': {ano: pct(nacional[ano]) for ano in ONDAS},
                'ufs': ufs,
            },
            ensure_ascii=False,
            indent=2,
        )
        + '\n',
        encoding='utf-8',
    )


REGIAO_POR_UF = {
    **{uf: 'Norte' for uf in ('AC', 'AM', 'AP', 'PA', 'RO', 'RR', 'TO')},
    **{uf: 'Nordeste' for uf in ('AL', 'BA', 'CE', 'MA', 'PB', 'PE', 'PI', 'RN', 'SE')},
    **{uf: 'Centro-Oeste' for uf in ('DF', 'GO', 'MS', 'MT')},
    **{uf: 'Sudeste' for uf in ('ES', 'MG', 'RJ', 'SP')},
    **{uf: 'Sul' for uf in ('PR', 'RS', 'SC')},
}


def _rcl_estadual() -> dict[int, dict[str, float]]:
    """A RCL de cada estado no ano, da coluna dos últimos 12 meses."""
    rcl: dict[int, dict[str, float]] = defaultdict(dict)
    for path in sorted(BRUTO.glob('estadual/RCL_*_Estados.csv')):
        ano = int(re.search(r'(\d{4})', path.name).group(1))
        with open(path, encoding='latin1') as f:
            for row in csv.reader(f, delimiter=';'):
                if len(row) < 8:
                    continue
                if 'TOTAL' not in row[4].upper():
                    continue
                if not row[5].upper().startswith('RECEITA CORRENTE LÍQUIDA (III)'):
                    continue
                try:
                    valor = num_siconfi(row[7])
                except ValueError:
                    continue
                if valor > 0:
                    rcl[ano][row[2]] = max(rcl[ano].get(row[2], 0.0), valor)
    return rcl


def participacao_rcl_uf() -> None:
    """
    O gasto próprio de cada estado como percentual da sua RCL.

    O numerador é a fonte "Recurso Próprio (Estadual)" a preços correntes, e não
    os valores reais: o denominador é a RCL nominal do mesmo ano, então corrigir
    só o numerador inflaria a razão.
    """
    ANOS = (2019, 2024)
    rcl = _rcl_estadual()

    proprio: dict[int, dict[str, float]] = defaultdict(dict)
    with open(ORCAMENTO / 'estadual/estadual_final.csv', encoding='utf-8-sig') as f:
        for row in csv.DictReader(f, delimiter=';'):
            if row['origem'].startswith('Recurso Próprio'):
                proprio[int(row['exercicio'])][row['uf']] = num(row['valor_nominal_final'])

    def pct(ano: int, uf: str) -> float | None:
        """
        Um estado que reportou RCL mas não tem linha de recurso próprio gastou
        zero, e não "não se sabe": a publicação nomeia esses casos — Goiás em
        2019, Ceará de 2019 a 2021, Roraima em 2022, Tocantins em 2024. Tratar a
        ausência como dado faltante apagaria justamente o achado.
        """
        base = rcl.get(ano, {}).get(uf)
        if not base:
            return None
        return round(100 * proprio.get(ano, {}).get(uf, 0.0) / base, 2)

    ufs = [
        {'uf': uf, 'regiao': REGIAO_POR_UF[uf], 'pctInicio': pct(ANOS[0], uf), 'pctFim': pct(ANOS[1], uf)}
        for uf in sorted(REGIAO_POR_UF)
    ]
    faltando = [u['uf'] for u in ufs if u['pctInicio'] is None or u['pctFim'] is None]
    assert not faltando, f'UF sem RCL nos anos da figura: {faltando}'

    (SAIDA / 'participacao-rcl-uf.json').write_text(
        json.dumps(
            {
                'anos': list(ANOS),
                'metaPnc': 1.5,
                'unidade': '% da Receita Corrente Líquida do estado',
                'ufs': ufs,
            },
            ensure_ascii=False,
            indent=2,
        )
        + '\n',
        encoding='utf-8',
    )


def _rcl_municipal() -> dict[tuple[int, str], float]:
    """
    A RCL de cada município no ano, extraída dos .rar sob demanda.

    A chave é o código IBGE de 6 dígitos, que é como as duas bases se encontram:
    o painel de gasto traz o código de 7 dígitos, com o verificador.
    """
    CACHE.mkdir(parents=True, exist_ok=True)
    rcl: dict[tuple[int, str], float] = {}

    for ano in range(2019, 2025):
        destino = CACHE / f'RCL_{ano}_Municipios.csv'
        if not destino.exists():
            origem = BRUTO / f'municipal/RCL_{ano}_Municipios.rar'
            print(f'  extraindo {origem.name}…')
            subprocess.run(['unar', '-q', '-o', str(CACHE), str(origem)], check=True)

        with open(destino, encoding='latin1') as f:
            for i, row in enumerate(csv.reader(f, delimiter=';')):
                if i < 6 or len(row) < 8:
                    continue
                if 'TOTAL' not in row[4].upper() or 'ReceitaCorrenteLiquida' not in row[6]:
                    continue
                try:
                    valor = num_siconfi(row[7])
                except ValueError:
                    continue
                if valor <= 0:
                    continue
                chave = (ano, row[1].strip().zfill(7)[:6])
                rcl[chave] = max(rcl.get(chave, 0.0), valor)
    return rcl


def meta_rcl_regiao() -> None:
    """
    A proporção de municípios que destinam mais de 2% da RCL à cultura, por
    macrorregião — o recorte que `Indicador_1` só traz no agregado nacional.
    """
    rcl = _rcl_municipal()

    gasto: dict[tuple[int, str], float] = defaultdict(float)
    regiao_por_ibge: dict[str, str] = {}
    with open(ORCAMENTO / 'municipal/municipal_final.csv', encoding='latin1') as f:
        for row in csv.DictReader(f, delimiter=';'):
            # o CSV está em latin1, então "Próprio" chega com o byte cru
            if not row['origem'].startswith('Recurso Pr'):
                continue
            ibge = row['codigo_ibge'].strip().zfill(7)[:6]
            gasto[(int(row['exercicio']), ibge)] += num(row['valor_nominal_final'])
            regiao_por_ibge[ibge] = row['regiao_munic']

    nacional: dict[int, list[int]] = defaultdict(lambda: [0, 0])
    regional: dict[tuple[int, str], list[int]] = defaultdict(lambda: [0, 0])
    for (ano, ibge), valor in gasto.items():
        base = rcl.get((ano, ibge))
        if not base:
            continue
        acima = 100 * valor / base > 2.0
        for alvo in (nacional[ano], regional[(ano, regiao_por_ibge[ibge])]):
            alvo[0] += 1
            alvo[1] += int(acima)

    _confere(nacional, regional)

    anos = sorted(nacional)
    regioes = sorted({r for _, r in regional})

    def serie(pares: list[list[int]]) -> list[float]:
        return [round(100 * p[1] / p[0], 1) for p in pares]

    (SAIDA / 'meta-rcl-regiao.json').write_text(
        json.dumps(
            {
                'anos': anos,
                'meta': '2% da RCL',
                'nacional': serie([nacional[a] for a in anos]),
                'regioes': [
                    {
                        'regiao': r,
                        'pcts': serie([regional[(a, r)] for a in anos]),
                        'municipios': regional[(anos[-1], r)][0],
                    }
                    for r in regioes
                ],
            },
            ensure_ascii=False,
            indent=2,
        )
        + '\n',
        encoding='utf-8',
    )


def _confere(nacional, regional) -> None:
    """
    A reconstrução conferida contra os dois indicadores já publicados.

    Reconstruir a razão a partir dos brutos é a única forma de chegar ao recorte
    regional, e é também a forma de errar em silêncio — um join que perde metade
    dos municípios ainda produz percentuais plausíveis. Estes dois `assert` são o
    que separa um número conferido de um número inventado: o agregado nacional
    tem de reproduzir o `Indicador_1` e o Centro-Oeste, o `Indicador_2`.
    """
    for arquivo, coluna, alvo, chave in (
        ('municipal/Indicador_1_Meta_2_Porcento_RCL.csv', 'Qtd Municípios (> 2% RCL)', nacional, None),
        ('municipal/Indicador_2_Centro_Oeste_Meta_RCL.csv', 'Atingiram a Meta (> 2%)', regional, 'Centro-Oeste'),
    ):
        with open(ORCAMENTO / arquivo, encoding='utf-8-sig') as f:
            for row in csv.DictReader(f, delimiter=';'):
                ano = int(row['exercicio'])
                par = alvo.get(ano if chave is None else (ano, chave))
                if par is None:
                    continue
                publicado = int(row[coluna])
                # 2019 e 2020 divergem em um município; ver a nota no README
                assert abs(par[1] - publicado) <= 1, (
                    f'{arquivo} {ano}: reconstruído {par[1]}, publicado {publicado}'
                )


tres_esferas()
meta_rcl()
tripe_uf()
participacao_rcl_uf()
meta_rcl_regiao()
print('ok:', *sorted(p.name for p in SAIDA.glob('*.json')))
