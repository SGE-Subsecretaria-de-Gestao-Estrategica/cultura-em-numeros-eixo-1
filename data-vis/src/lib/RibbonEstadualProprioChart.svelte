<script lang="ts">
  /**
   * O recurso próprio estadual sozinho, como fita — o par de
   * `RibbonMunicipalProprioChart`, para quando a figura precisa contar só o
   * crescimento do próprio sem competir por espaço com as leis emergenciais.
   * Elas continuam na página, mas como período demarcado acima do plot, na
   * cor de cada uma em `fonteColors` — a mesma chave de leitura da versão
   * completa, `RibbonEstadualChart`, onde aparecem como segmento.
   *
   * Sem título nem legenda dentro do SVG: a folha de `A4.svelte` já escreve o
   * próprio `<h1>`, e os períodos coloridos acima do plot já nomeiam a única
   * fonte que a legenda listaria — repetir os dois só tomaria espaço do
   * plot. `title` continua o `aria-label` do gráfico.
   */
  import RibbonChart from './RibbonChart.svelte';
  import { fonteColors } from './fontes';
  import estadual from '../data/estadual-por-fonte.json';

  let {
    svgEl = $bindable(null),
    background,
  }: {
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  const PROPRIO = 'Recurso Próprio (Estadual)';

  const decimalBi = new Intl.NumberFormat('pt-BR', { minimumFractionDigits: 1, maximumFractionDigits: 1 });
  const formatValue = (v: number) => `R$ ${decimalBi.format(v / 1e9)} bi`;

  const primeiroAno = estadual.real[0].label;
  const ultimoAno = estadual.real[estadual.real.length - 1].label;
</script>

<RibbonChart
  data={estadual.real}
  keys={[PROPRIO]}
  colors={[fonteColors[0]]}
  spans={[
    { de: 2020, ate: 2020, texto: 'LAB 1', cor: fonteColors[2] },
    { de: 2023, ate: 2024, texto: 'LPG', cor: fonteColors[3] },
    { de: 2024, ate: 2025, texto: 'PNAB', cor: fonteColors[4] },
  ]}
  {formatValue}
  title="O recurso próprio estadual dobra de tamanho entre 2019 e 2025, mesmo com repasses federais entrando em ondas"
  subtitle="Investimento próprio estadual em cultura, a preços médios de 2024 (IPCA) · {primeiroAno}–{ultimoAno}"
  legenda={false}
  mostrarTitulo={false}
  mostrarNomes={false}
  {background}
  bind:svgEl
/>
