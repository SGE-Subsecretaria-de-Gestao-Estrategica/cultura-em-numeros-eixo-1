<script lang="ts">
  /**
   * A paridade entre sociedade civil e poder público nos conselhos estaduais
   * ativos de cultura — mesma pergunta e mesmo tratamento binário de
   * `GeneroGestoresChart`.
   *
   * As 27 UFs já tinham conselho ativo em 2018 e em 2021, então a base não
   * muda entre as duas ondas: a figura lê exatamente a mesma população nos
   * dois anos, sem o ruído de um conselho que apareceu ou sumiu no meio da
   * conta.
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

  const data = dados.paridade.ondas as unknown as AnoRow[];
  const colors = categoricaDe(dados.paridade.categorias.length);

  const primeira = dados.paridade.ondas[0];
  const ultima = dados.paridade.ondas[dados.paridade.ondas.length - 1];

  const footnote =
    `Cada coluna soma 100% sobre os conselhos estaduais ativos — as 27 UFs em ambas as ondas. "Paritário" é o ` +
    `conselho com representação equilibrada entre sociedade civil e poder público, segundo a própria UF.`;
</script>

<ComposicaoChart
  {data}
  keys={dados.paridade.categorias}
  {colors}
  columnRatio={0.4}
  title="Quase três em cada quatro conselhos estaduais de cultura são paritários"
  subtitle="Composição dos conselhos estaduais de cultura ativos · ESTADIC {primeira.label} e {ultima.label}"
  {footnote}
  source="Fonte: Elaboração própria com base na ESTADIC/IBGE, ondas de {primeira.label} e {ultima.label}."
  {background}
  bind:svgEl
/>
