<script lang="ts">
  import { categorical8 } from 'sniic-design-system';
  import SerieHistoricaChart from './SerieHistoricaChart.svelte';
  import gestao from '../data/gestao-municipal.json';

  let {
    svgEl = $bindable(null),
    background,
  }: { svgEl?: SVGSVGElement | null; background?: string | null } = $props();

  /**
   * Azul, laranja, teal e roxo. O amarelo da escala categórica fica de fora: a
   * linha aqui tem 2 px e o amarelo não sustenta contraste com o fundo claro do
   * cartão numa marca dessa espessura.
   */
  const colors = [categorical8[0], categorical8[1], categorical8[2], categorical8[4]];
</script>

<SerieHistoricaChart
  series={gestao.equipamentos.series}
  {colors}
  title="Equipamentos culturais nos municípios"
  subtitle="Proporção dos municípios que declaram ter cada equipamento em funcionamento."
  footnote="A onda de 2018 fica fora da série: a MUNIC daquele ano não fez as perguntas de equipamento ao conjunto dos municípios — 2.358 dos 5.570 vêm sem resposta — e entre os que responderam a taxa de bibliotecas cai a 63,9%, um degrau que é da amostra e não do fenômeno."
  source="Fonte: Elaboração própria com base na MUNIC/IBGE (2006, 2014 e 2021)."
  {background}
  bind:svgEl
/>
