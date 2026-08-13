<script lang="ts">
  import CaboGuerraChart from './CaboGuerraChart.svelte';
  import comportamento from '../data/comportamento-municipal.json';

  /** Bindable — passed through so the page can offer an SVG download. */
  let {
    svgEl = $bindable(null),
    background,
  }: { svgEl?: SVGSVGElement | null; background?: string | null } = $props();

  const universo = new Intl.NumberFormat('pt-BR').format(comportamento.universo);
</script>

<CaboGuerraChart
  data={comportamento.caboGuerra}
  title="Cabo de guerra: efeito indutor e efeito substituição"
  subtitle="Municípios classificados em cada efeito, como % dos municípios da região. Comportamentos Pós-repasses (2023, 2024)."
  footnote="Saldo líquido = diferença, em pontos percentuais, entre a parcela de municípios com efeito indutor e a com efeito substituição. Critério de Classificação: Variação da Trajetória
  (> 20% + R$ 5,00 de margem)."
  source={`Fonte: Ministério da Cultura / SICONFI (MSC Orçamentária Municipal). Universo: ${universo} municípios com dados.`}
  {background}
  bind:svgEl
/>
