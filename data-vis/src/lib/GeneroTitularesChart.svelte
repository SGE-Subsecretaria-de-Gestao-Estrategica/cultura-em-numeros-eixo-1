<script lang="ts">
  import { colorScales } from 'sniic-design-system';
  import ComposicaoPorOndaChart from './ComposicaoPorOndaChart.svelte';
  import gestao from '../data/gestao-municipal.json';

  let {
    svgEl = $bindable(null),
    background,
  }: { svgEl?: SVGSVGElement | null; background?: string | null } = $props();

  /**
   * Roxo e azul-escuro: dois matizes que se separam com folga sob qualquer tipo
   * de visão de cores, e nenhum dos dois é o par rosa/azul convencional que
   * codifica gênero por estereótipo antes de codificá-lo por dado.
   */
  const colors = [colorScales.purple[2], colorScales.blue[3]];
</script>

<ComposicaoPorOndaChart
  data={gestao.genero.ondas}
  categorias={gestao.genero.categorias}
  {colors}
  title="Gênero dos titulares dos órgãos gestores de cultura"
  subtitle="Participação feminina e masculina no comando da política cultural municipal."
  footnote="A onda de 2006 não coletou o perfil do gestor. A base de cada ano exclui municípios sem gestor no cargo e as não-respostas, que somam de 134 a 319 conforme a onda."
  source="Fonte: Elaboração própria com base na MUNIC/IBGE (2014, 2018 e 2021)."
  {background}
  bind:svgEl
/>
