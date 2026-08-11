# data-vis

Visualizações do projeto **Cultura em Números** (Eixo 1 — Orçamento), construídas com
[sniic-design-system](https://www.npmjs.com/package/sniic-design-system) (Svelte 5 + D3).

## Rodando

```bash
npm install
npm run dev
```

## Gráficos

### Orçamento

- **Evolução do investimento cultural estadual por fonte de recurso (2019–2025)** —
  `src/lib/EstadualPorFonteChart.svelte`, dados em `src/data/estadual-por-fonte.json`.

### Gestão e participação

Todos derivam do painel histórico da MUNIC/IBGE, em `src/data/gestao-municipal.json`.
Três componentes genéricos servem os seis gráficos:

| Componente genérico | Gráficos |
|---|---|
| `SerieHistoricaChart` | `TripeInstitucionalChart`, `EquipamentosCulturaisChart` |
| `ComposicaoPorOndaChart` | `EstruturaOrgaoGestorChart`, `GeneroTitularesChart` |
| `BarrasHorizontaisChart` | `EscolaridadeTripeChart`, `ExecucaoAldirBlancChart` |

A prova de impressão fica em `/gestao.html` (a de orçamento, em `/a4.html`).

## Regenerando os dados

Os dados do gráfico estadual são derivados da base MSC Orçamentária (SICONFI), replicando a
lógica de `../eixo1/orcamento/scripts/estadual/fonte_recurso_estadual.R` (classificação por
fonte de recurso + deflação pelo IPCA, base 2024). Para regenerar:

```bash
# requer: python3, pandas, pyarrow
# requer o parquet extraído em ../eixo1/orcamento/data/raw/estadual/
#   (7z x msc_orcamentaria_estados_2019_2025_final.7z)
python3 scripts/build_estadual_data.py
```

A série do IPCA (SGS-BCB 433) fica em cache em `scripts/ipca-433-cache.json`; apague o
arquivo para buscar dados atualizados da API do Banco Central (requer rede).

Os dados de gestão e participação vêm do painel histórico da MUNIC já processado em
`../eixo1/gestao&participacao/data/processed/`:

```bash
# requer: python3, pandas
python3 scripts/build_gestao_data.py
```

O script harmoniza os rótulos que mudam de onda para onda — `tipo_orgao_gestor` traz 17
grafias para 5 categorias reais — e refaz o agrupamento de escolaridade a partir da coluna
bruta, porque a coluna `gestor_escolaridade_agrupada` do painel está inconsistente (em 2021
ela joga os 105 municípios de ensino fundamental dentro da faixa do meio e deixa a categoria
zerada). Todo o de-para está explícito no topo do script.

> **Nota:** os dados municipais equivalentes por fonte de recurso (base SICONFI municipal
> detalhada + BB Ágil/LAB1) não estão disponíveis neste repositório — apenas os outputs já
> gerados localmente. Ver `../eixo1/orcamento/scripts/municipal/fonte_recurso_municipal.R`.

## Stack

- [Svelte 5](https://svelte.dev) + [Vite](https://vitejs.dev)
- [sniic-design-system](https://www.npmjs.com/package/sniic-design-system) para os componentes de gráfico e tokens de design
