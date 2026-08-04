<script lang="ts">
  import InvestimentoPorFonteChart from './InvestimentoPorFonteChart.svelte';
  import municipal from '../data/municipal-por-fonte.json';

  /** Bindable — passed through so the page can offer an SVG download. */
  let { svgEl = $bindable(null) }: { svgEl?: SVGSVGElement | null } = $props();

  // short names for the legend; the full ones are expanded in the footnote
  const labels: Record<string, string> = {
    'Recurso Próprio (Municipal)': 'Recurso próprio',
    'Emendas Parlamentares (Cultura)': 'Emendas',
    'Lei Aldir Blanc 1 (LAB 1)': 'LAB 1',
    'Lei Paulo Gustavo (LPG)': 'LPG',
    'PNAB (Aldir Blanc 2)': 'PNAB',
  };
</script>

<InvestimentoPorFonteChart
  data={municipal.real}
  keys={municipal.keys}
  {labels}
  title="Evolução do investimento cultural municipal por fonte de recurso"
  subtitle={`Valores empenhados, corrigidos pela inflação (IPCA, preços médios de ${municipal.anoBaseDeflator}) · 2019–2025`}
  footnote="LAB 1 = Lei Aldir Blanc 1 · LPG = Lei Paulo Gustavo · PNAB = Política Nacional Aldir Blanc (Aldir Blanc 2)."
  source="Fonte: Ministério da Cultura / SICONFI (MSC Orçamentária Municipal) e BB Ágil. Deflator: IPCA/SGS-BCB (série 433)."
  bind:svgEl
/>
