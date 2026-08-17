<script lang="ts">
  import SerieHistoricaChart from './SerieHistoricaChart.svelte';
  import { sniic } from './cores';
  import gestao from '../data/gestao-municipal.json';

  /** Bindable — repassado para a página poder oferecer o download do SVG. */
  let {
    svgEl = $bindable(null),
    background,
  }: { svgEl?: SVGSVGElement | null; background?: string | null } = $props();

  /**
   * Uma cor só para as três séries — a lista é percorrida ciclicamente.
   *
   * Quem separa as séries aqui não é mais a cor: cada linha traz o valor em
   * todas as ondas e um bloco na ponta com o nome. Fica um custo, e ele é real:
   * fundo e plano se cruzam por volta de 2010, e no cruzamento não há como
   * dizer qual faixa é qual sem ir aos rótulos das ondas vizinhas.
   */
  const colors = [sniic.vermelho];
</script>

<SerieHistoricaChart
  series={gestao.tripe.series}
  {colors}
  markerColor={sniic.marcador}
  endValueColor={sniic.azul}
  variant="faixa"
  valueFormat="pct"
  title="Evolução do tripé institucional da cultura"
  subtitle="Percentual de municípios brasileiros com cada instrumento do Sistema Nacional de Cultura criado, nas quatro ondas da MUNIC."
  footnote="O eixo é linear no tempo, e a inclinação de cada trecho mede o ritmo da mudança. Base: municípios com resposta válida em cada onda."
  source="Fonte: Elaboração própria com base na MUNIC/IBGE (2006, 2014, 2018 e 2021)."
  {background}
  bind:svgEl
/>
