<script lang="ts">
  import PerfilPorPorteChart from './PerfilPorPorteChart.svelte';
  import comportamento from '../data/comportamento-municipal.json';

  /** Bindable — passed through so the page can offer an SVG download. */
  let {
    svgEl = $bindable(null),
    background,
  }: { svgEl?: SVGSVGElement | null; background?: string | null } = $props();

  const keys = comportamento.perfis.map((p) => p.key);
  // the parenthetical glosses ride in the footnote, not in the chips
  const footnote = comportamento.perfis
    .map((p) => `${p.label} = ${p.descricao.toLowerCase()}`)
    .join(' · ');
  const universo = new Intl.NumberFormat('pt-BR').format(comportamento.universo);
</script>

<PerfilPorPorteChart
  data={comportamento.porte}
  {keys}
  title="Perfil de mudança no gasto municipal em cultura"
  subtitle="Distribuição dos municípios de cada porte populacional entre os quatro perfis. Comportamentos Pós-repasses (2023, 2024)."
  footnote={`${footnote}. Critério de Classificação: Variação da Trajetória
  (> 20% + R$ 5,00 de margem).`}
  source={`Fonte: Ministério da Cultura / SICONFI (MSC Orçamentária Municipal). Universo: ${universo} municípios com dados.`}
  {background}
  bind:svgEl
/>
