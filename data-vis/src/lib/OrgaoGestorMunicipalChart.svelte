<script lang="ts">
  /**
   * A autonomia institucional do órgão gestor municipal de cultura, coluna por
   * onda da MUNIC — o par municipal de `OrgaoGestorEstadualChart`, na mesma
   * rampa azul para que as duas figuras se leiam com uma chave só.
   *
   * A diferença entre as esferas é o que a rampa mostra: os estados chegam a
   * 2021 com 85% de secretaria exclusiva; os municípios, com menos de um
   * quinto. A maioria municipal segue em secretaria conjunta com outra pasta —
   * o grau intermediário de autonomia —, e não no extremo baixo.
   */
  import ComposicaoChart, { type AnoRow } from './ComposicaoChart.svelte';
  import { degrausDe, rampaAzul } from './cores';
  import dados from '../data/gestao-municipal.json';

  let {
    svgEl = $bindable(null),
    background,
  }: {
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  const inteiro = new Intl.NumberFormat('pt-BR');

  const data = dados.estrutura.ondas as unknown as AnoRow[];
  const colors = degrausDe(rampaAzul, dados.estrutura.categorias.length);

  const ultima = dados.estrutura.ondas[dados.estrutura.ondas.length - 1];

  const footnote =
    `Cada coluna soma 100% sobre os ${inteiro.format(ultima.base)} municípios da onda. As categorias vão do maior ` +
    `grau de autonomia ao menor: secretaria exclusiva ou administração indireta primeiro, depois secretaria em ` +
    `conjunto com outra política, setor subordinado e, por fim, nenhuma estrutura.`;
</script>

<ComposicaoChart
  {data}
  keys={dados.estrutura.categorias}
  {colors}
  columnRatio={0.62}
  title="A maioria dos municípios ainda divide a pasta de cultura com outra política"
  subtitle="Estrutura do órgão gestor municipal de cultura · MUNIC 2006 a 2021"
  {footnote}
  source="Fonte: Elaboração própria com base na MUNIC/IBGE, ondas de 2006 a 2021."
  {background}
  bind:svgEl
/>
