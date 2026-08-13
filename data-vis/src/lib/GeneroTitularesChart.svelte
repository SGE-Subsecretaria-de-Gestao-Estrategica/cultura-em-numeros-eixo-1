<script lang="ts">
  import ComposicaoPorOndaChart from './ComposicaoPorOndaChart.svelte';
  import { rampaDe } from './cores';
  import gestao from '../data/gestao-municipal.json';

  let {
    svgEl = $bindable(null),
    background,
  }: { svgEl?: SVGSVGElement | null; background?: string | null } = $props();

  /**
   * Dois degraus da rampa da marca, separados por luminosidade e não por matiz.
   * Continua valendo o motivo de sempre: o par rosa/azul codificaria gênero por
   * estereótipo antes de codificá-lo por dado, e aqui não há dois matizes para
   * isso acontecer — as duas categorias são a mesma cor em claros diferentes.
   */
  const colors = rampaDe(2);
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
