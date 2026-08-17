<script lang="ts">
  import SerieHistoricaChart from './SerieHistoricaChart.svelte';
  import { sniic } from './cores';
  import gestao from '../data/gestao-municipal.json';

  let {
    svgEl = $bindable(null),
    background,
  }: { svgEl?: SVGSVGElement | null; background?: string | null } = $props();

  /**
   * Uma cor só para as quatro séries — a lista é percorrida ciclicamente. Cada
   * linha é identificada pelo bloco na ponta e pelos valores em cada onda.
   *
   * Aqui o custo é maior que no tripé: museu e teatro chegam a 0,7 ponto de
   * distância em 2006, e sem matizes diferentes as duas faixas são uma só até
   * se separarem, depois de 2014.
   */
  const colors = [sniic.vermelho];
</script>

<SerieHistoricaChart
  series={gestao.equipamentos.series}
  {colors}
  markerColor={sniic.marcador}
  endValueColor={sniic.azul}
  variant="faixa"
  valueFormat="abs"
  rowPerSeries
  dotStrip
  dotStripLead="Do total de 5.570 municípios brasileiros, isso representa…"
  yMax={100}
  title="Equipamentos culturais nos municípios"
  subtitle="Número de municípios que declaram ter cada equipamento em funcionamento."
  footnote="A onda de 2018 fica fora da série: a MUNIC daquele ano não fez as perguntas de equipamento ao conjunto dos municípios — 2.358 dos 5.570 vêm sem resposta — e entre os que responderam a taxa de bibliotecas cai a 63,9%, um degrau que é da amostra e não do fenômeno."
  source="Fonte: Elaboração própria com base na MUNIC/IBGE (2006, 2014 e 2021)."
  {background}
  bind:svgEl
/>
