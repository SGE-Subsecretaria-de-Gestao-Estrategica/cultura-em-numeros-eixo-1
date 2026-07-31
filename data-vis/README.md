# data-vis

Visualizações do projeto **Cultura em Números** (Eixo 1 — Orçamento), construídas com
[sniic-design-system](https://www.npmjs.com/package/sniic-design-system) (Svelte 5 + D3).

## Rodando

```bash
npm install
npm run dev
```

## Gráficos

- **Evolução do investimento cultural estadual por fonte de recurso (2019–2025)** —
  `src/lib/EstadualPorFonteChart.svelte`, dados em `src/data/estadual-por-fonte.json`.

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

> **Nota:** os dados municipais equivalentes por fonte de recurso (base SICONFI municipal
> detalhada + BB Ágil/LAB1) não estão disponíveis neste repositório — apenas os outputs já
> gerados localmente. Ver `../eixo1/orcamento/scripts/municipal/fonte_recurso_municipal.R`.

## Stack

- [Svelte 5](https://svelte.dev) + [Vite](https://vitejs.dev)
- [sniic-design-system](https://www.npmjs.com/package/sniic-design-system) para os componentes de gráfico e tokens de design
