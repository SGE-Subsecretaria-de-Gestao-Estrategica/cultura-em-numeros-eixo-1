<script lang="ts">
  import { categorical8 } from 'sniic-design-system';
  import SerieHistoricaChart from './SerieHistoricaChart.svelte';
  import gestao from '../data/gestao-municipal.json';

  /** Bindable — repassado para a página poder oferecer o download do SVG. */
  let {
    svgEl = $bindable(null),
    background,
  }: { svgEl?: SVGSVGElement | null; background?: string | null } = $props();

  /**
   * Azul, laranja e teal — três matizes de fato distintos da escala categórica
   * do sistema, não três degraus da mesma cor. As linhas se cruzam entre 2006 e
   * 2014, então elas têm de se separar por matiz e não por luminosidade.
   */
  const colors = [categorical8[0], categorical8[2], categorical8[1]];
</script>

<SerieHistoricaChart
  series={gestao.tripe.series}
  {colors}
  title="Evolução do tripé institucional da cultura"
  subtitle="Proporção dos municípios brasileiros com cada instrumento do Sistema Nacional de Cultura criado, nas quatro ondas da MUNIC."
  footnote="O eixo é linear no tempo: as ondas estão a 8, 4 e 3 anos de distância, e a inclinação de cada trecho mede o ritmo da mudança. Base: municípios com resposta válida em cada onda."
  source="Fonte: Elaboração própria com base na MUNIC/IBGE (2006, 2014, 2018 e 2021)."
  {background}
  bind:svgEl
/>
