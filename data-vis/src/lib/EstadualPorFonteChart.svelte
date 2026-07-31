<script lang="ts">
  import { VerticalStackedBarChart, BRL, blue, lime, purple, orange, yellow } from 'sniic-design-system';
  import estadual from '../data/estadual-por-fonte.json';

  // colors must line up positionally with `keys` (the component indexes into this array)
  const colors = [blue, lime, purple, orange, yellow];

  // kept short: the legend row has a fixed ~110px pitch per item in this
  // chart component, so long labels overlap — full names go in the caption below
  const labels: Record<string, string> = {
    'Recurso Próprio (Estadual)': 'Recurso próprio',
    'Emendas Parlamentares (Cultura)': 'Emendas',
    'Lei Aldir Blanc 1 (LAB 1)': 'LAB 1',
    'Lei Paulo Gustavo (LPG)': 'LPG',
    'PNAB (Aldir Blanc 2)': 'PNAB',
  };

  const yTickFormat = (v: number) => BRL.format(v);
</script>

<figure class="chart-card">
  <figcaption>
    <h2>Evolução do investimento cultural estadual por fonte de recurso</h2>
    <p class="subtitle">
      Valores empenhados, corrigidos pela inflação (IPCA, preços médios de {estadual.anoBaseDeflator}) · 2019–2025
    </p>
  </figcaption>

  <VerticalStackedBarChart
    data={estadual.real}
    keys={estadual.keys}
    {colors}
    {labels}
    {yTickFormat}
    sortBy=""
    height={460}
  />

  <p class="source">
    <strong>LAB 1</strong> = Lei Aldir Blanc 1 · <strong>LPG</strong> = Lei Paulo Gustavo ·
    <strong>PNAB</strong> = Política Nacional Aldir Blanc (Aldir Blanc 2).<br />
    Fonte: Ministério da Cultura / SICONFI (MSC Orçamentária Estadual). Deflator: IPCA/SGS-BCB (série 433).
  </p>
</figure>

<style>
  .chart-card {
    margin: 0;
    padding: 24px;
    border: 1px solid var(--border);
    border-radius: 12px;
    background: var(--card-bg);
    box-sizing: border-box;
  }

  h2 {
    font-size: 20px;
    margin: 0 0 4px;
  }

  .subtitle {
    color: var(--text);
    font-size: 14px;
    margin: 0 0 20px;
  }

  .source {
    color: var(--text);
    font-size: 12px;
    margin: 16px 0 0;
  }
</style>
