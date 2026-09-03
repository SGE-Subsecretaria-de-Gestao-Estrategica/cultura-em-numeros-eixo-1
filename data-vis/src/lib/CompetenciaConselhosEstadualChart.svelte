<script lang="ts">
  /**
   * A natureza institucional dos conselhos estaduais ativos de cultura — se
   * deliberam, se só consultam, ou se normatizam e fiscalizam.
   *
   * Três categorias ordenadas por peso institucional — deliberar pesa mais
   * que consultar —, por isso a rampa e não a escala categórica, na mesma
   * lógica de `OrgaoGestorEstadualChart`. A onda de 2014 não entra: o módulo
   * daquele ano não perguntou a natureza do conselho, e a coluna ficaria
   * vazia.
   */
  import ComposicaoChart, { type AnoRow } from './ComposicaoChart.svelte';
  import { degrausDe, rampaRoxa } from './cores';
  import dados from '../data/estadic-governanca.json';

  let {
    svgEl = $bindable(null),
    background,
  }: {
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  const inteiro = new Intl.NumberFormat('pt-BR');

  const data = dados.competencia.ondas as unknown as AnoRow[];
  const colors = degrausDe(rampaRoxa, dados.competencia.categorias.length);

  const primeira = dados.competencia.ondas[0];
  const ultima = dados.competencia.ondas[dados.competencia.ondas.length - 1];

  const footnote =
    `Cada coluna soma 100% sobre os conselhos estaduais ativos que declararam a própria natureza. A onda de ` +
    `2014 não entra: o módulo daquele ano não perguntou a competência do conselho. "Normativo / Fiscalizador" ` +
    `reúne os conselhos que regulam ou fiscalizam sem deliberar sobre recursos.`;
</script>

<ComposicaoChart
  {data}
  keys={dados.competencia.categorias}
  {colors}
  columnRatio={0.4}
  title="Oito em cada dez conselhos estaduais de cultura têm poder deliberativo"
  subtitle="Natureza declarada dos conselhos estaduais de cultura ativos · ESTADIC {primeira.label} e {ultima.label}"
  {footnote}
  source="Fonte: Elaboração própria com base na ESTADIC/IBGE, ondas de {primeira.label} e {ultima.label}."
  {background}
  bind:svgEl
/>
