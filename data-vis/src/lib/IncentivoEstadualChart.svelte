<script lang="ts">
  /**
   * Quantos estados têm mecanismo próprio de renúncia fiscal para cultura —
   * uma lei estadual de incentivo, na linhagem da Lei Rouanet federal, mas
   * decidida e financiada pelo próprio estado.
   */
  import ComposicaoChart, { type AnoRow } from './ComposicaoChart.svelte';
  import { categoricaDe } from './cores';
  import dados from '../data/estadic-governanca.json';

  let {
    svgEl = $bindable(null),
    background,
  }: {
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  const inteiro = new Intl.NumberFormat('pt-BR');

  const data = dados.incentivo.ondas as unknown as AnoRow[];
  const colors = categoricaDe(dados.incentivo.categorias.length);

  const primeira = dados.incentivo.ondas[0];
  const ultima = dados.incentivo.ondas[dados.incentivo.ondas.length - 1];

  const footnote = `Cada coluna soma 100% sobre as ${inteiro.format(dados.universo)} UFs.`;
</script>

<ComposicaoChart
  {data}
  keys={dados.incentivo.categorias}
  {colors}
  columnRatio={0.4}
  title="Só um em cada três estados tem lei própria de incentivo fiscal à cultura"
  subtitle="Estados com mecanismo estadual de renúncia fiscal para cultura · ESTADIC {primeira.label} e {ultima.label}"
  {footnote}
  source="Fonte: Elaboração própria com base na ESTADIC/IBGE, ondas de {primeira.label} e {ultima.label}."
  {background}
  bind:svgEl
/>
