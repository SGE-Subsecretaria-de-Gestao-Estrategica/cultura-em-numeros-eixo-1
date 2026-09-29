<script lang="ts">
  /**
   * O recurso próprio municipal sozinho, como fita — o par de
   * `RibbonEstadualProprioChart`, para quando a figura precisa contar só o
   * crescimento do próprio sem competir por espaço com as leis emergenciais
   * (que aqui pesam ainda menos do que no estadual). Elas continuam na
   * página, mas como período demarcado acima do plot, na cor de cada uma em
   * `fonteColors` — a mesma chave de leitura de `RibbonMunicipalChart`, onde
   * aparecem como segmento. Emendas parlamentares ficam de fora dos dois:
   * somam no máximo 1,1% do total num único ano (2024).
   *
   * Sem título nem legenda dentro do SVG: a folha de `A4.svelte` já escreve o
   * próprio `<h1>`, e os períodos coloridos acima do plot já nomeiam a única
   * fonte que a legenda listaria — repetir os dois só tomaria espaço do
   * plot. `title` continua o `aria-label` do gráfico.
   */
  import RibbonChart from './RibbonChart.svelte';
  import { fonteColors } from './fontes';
  import municipal from '../data/municipal-por-fonte.json';

  let {
    svgEl = $bindable(null),
    background,
  }: {
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  const PROPRIO = 'Recurso Próprio (Municipal)';

  const decimalBi = new Intl.NumberFormat('pt-BR', { minimumFractionDigits: 1, maximumFractionDigits: 1 });
  const formatValue = (v: number) => `R$ ${decimalBi.format(v / 1e9)} bi`;

  const primeiroAno = municipal.real[0].label;
  const ultimoAno = municipal.real[municipal.real.length - 1].label;
</script>

<RibbonChart
  data={municipal.real}
  keys={[PROPRIO]}
  colors={[fonteColors[0]]}
  legenda={false}
  title="O recurso próprio dobra de tamanho enquanto as leis emergenciais se revezam"
  subtitle="Investimento municipal em cultura por fonte, a preços médios de 2024 (IPCA) · {primeiroAno}–{ultimoAno}"
  mostrarTitulo={false}
  mostrarNomes={false}
  spans={[
    { de: 2020, ate: 2021, texto: 'LAB 1', cor: fonteColors[2] },
    { de: 2023, ate: 2024, texto: 'LPG', cor: fonteColors[3] },
    { de: 2024, ate: 2025, texto: 'PNAB', cor: fonteColors[4] },
  ]}
  {formatValue}
  bind:svgEl
/>
