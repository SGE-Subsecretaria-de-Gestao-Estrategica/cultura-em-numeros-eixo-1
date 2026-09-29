<script lang="ts">
  /**
   * As cinco fontes do investimento estadual como fita: quem lidera o ano é
   * sempre o recurso próprio, mas as três leis emergenciais se revezam atrás
   * dele — a LAB 1 sozinha em 2020, a LPG assumindo em 2023-2024, a PNAB
   * ultrapassando-a em 2025. É a mesma tabela de `EstadualFontesChart`
   * (próprio × repasses agregados), aqui aberta fonte a fonte para mostrar
   * qual repasse pesou em cada onda.
   *
   * Sem título nem legenda dentro do SVG — a folha de `A4.svelte` já escreve
   * o próprio `<h1>`. `title` continua o `aria-label` do gráfico.
   */
  import RibbonChart from './RibbonChart.svelte';
  import { fonteColors, fonteLabels } from './fontes';
  import estadual from '../data/estadual-por-fonte.json';

  let {
    svgEl = $bindable(null),
    background,
  }: {
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  const decimalBi = new Intl.NumberFormat('pt-BR', { minimumFractionDigits: 1, maximumFractionDigits: 1 });
  const decimalMi = new Intl.NumberFormat('pt-BR', { maximumFractionDigits: 0 });

  /** Bilhões acima de R$ 1 bi; milhões abaixo — as emendas nunca chegam a um bi. */
  const formatValue = (v: number) =>
    v >= 1e9 ? `R$ ${decimalBi.format(v / 1e9)} bi` : `R$ ${decimalMi.format(v / 1e6)} mi`;

  const primeiroAno = estadual.real[0].label;
  const ultimoAno = estadual.real[estadual.real.length - 1].label;
</script>

<RibbonChart
  data={estadual.real}
  keys={estadual.keys}
  labels={fonteLabels}
  colors={fonteColors}
  {formatValue}
  title=""
  subtitle=""
  mostrarTitulo={false}
  legenda={false}
  {background}
  bind:svgEl
/>
