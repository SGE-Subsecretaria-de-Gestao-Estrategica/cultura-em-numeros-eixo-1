<script lang="ts">
  /**
   * As quatro fontes do investimento municipal que pesam de fato — recurso
   * próprio e as três leis emergenciais — como fita: o próprio lidera e cresce
   * ano a ano, enquanto LAB 1, LPG e PNAB se revezam atrás dele em ondas
   * curtas, cada uma na sua coluna e na sua cor. É a mesma leitura de
   * `ComposicaoMunicipalChart` em valor absoluto, e não em participação: aqui
   * dá para ver que a fonte que mais cresce é o próprio, não que ela domina a
   * fatia.
   *
   * Emendas parlamentares ficam de fora: somam no máximo 1,1% do total num
   * único ano (2024) — pequenas demais para abrir uma fatia própria na escala
   * do recurso próprio sem virar ruído.
   *
   * Sem título nem legenda dentro do SVG — a folha de `A4.svelte` já escreve
   * o próprio `<h1>`. `title` continua o `aria-label` do gráfico.
   */
  import RibbonChart from './RibbonChart.svelte';
  import { fonteColors, fonteLabels } from './fontes';
  import municipal from '../data/municipal-por-fonte.json';

  let {
    svgEl = $bindable(null),
    background,
  }: {
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  const EMENDAS = 'Emendas Parlamentares (Cultura)';

  /** As fontes de `municipal.keys`, sem as emendas, com a cor que cada uma tem em `fonteColors`. */
  const fontes = municipal.keys
    .map((key, i) => ({ key, cor: fonteColors[i] }))
    .filter((f) => f.key !== EMENDAS);
  const keys = fontes.map((f) => f.key);
  const colors = fontes.map((f) => f.cor);

  const decimalBi = new Intl.NumberFormat('pt-BR', { minimumFractionDigits: 1, maximumFractionDigits: 1 });
  const decimalMi = new Intl.NumberFormat('pt-BR', { maximumFractionDigits: 0 });

  /** Bilhões acima de R$ 1 bi; milhões abaixo — as leis emergenciais raramente chegam a um bi. */
  const formatValue = (v: number) =>
    v >= 1e9 ? `R$ ${decimalBi.format(v / 1e9)} bi` : `R$ ${decimalMi.format(v / 1e6)} mi`;

  const primeiroAno = municipal.real[0].label;
  const ultimoAno = municipal.real[municipal.real.length - 1].label;
</script>

<RibbonChart
  data={municipal.real}
  {keys}
  {colors}
  labels={fonteLabels}
  {formatValue}
  title="O recurso próprio dobra de tamanho enquanto as leis emergenciais se revezam"
  subtitle="Investimento municipal em cultura por fonte, a preços médios de 2024 (IPCA) · {primeiroAno}–{ultimoAno}"
  mostrarTitulo={false}
  legenda={false}
  {background}
  bind:svgEl
/>
