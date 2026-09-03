<script lang="ts">
  /**
   * A escolaridade do secretário estadual de cultura, coluna por onda da
   * ESTADIC — a mesma rampa vermelha de `EscolaridadeInstitucionalizacaoChart`
   * (MUNIC), para que as duas figuras de escolaridade da coleção se leiam com
   * uma chave só.
   *
   * "Ensino Fundamental" sai das categorias: nenhum secretário estadual caiu
   * nela em nenhuma das três ondas — diferente dos municípios, onde a faixa
   * existe e pesa. Manter a categoria vazia na legenda seria reservar uma cor
   * para um dado que os estados nunca produziram.
   */
  import ComposicaoChart, { type AnoRow } from './ComposicaoChart.svelte';
  import { degrausDe, rampaVermelha } from './cores';
  import dados from '../data/estadic-governanca.json';

  let {
    svgEl = $bindable(null),
    background,
  }: {
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  const inteiro = new Intl.NumberFormat('pt-BR');

  const data = dados.escolaridade.ondas as unknown as AnoRow[];
  const colors = degrausDe(rampaVermelha, dados.escolaridade.categorias.length);

  const primeira = dados.escolaridade.ondas[0];
  const ultima = dados.escolaridade.ondas[dados.escolaridade.ondas.length - 1];

  const footnote =
    `Cada coluna soma 100% sobre as ${inteiro.format(dados.universo)} UFs. Nenhum secretário estadual de ` +
    `cultura declarou ensino fundamental como escolaridade máxima em nenhuma das três ondas — a categoria não ` +
    `entra na figura porque não tem o que mostrar.`;
</script>

<ComposicaoChart
  {data}
  keys={dados.escolaridade.categorias}
  {colors}
  columnRatio={0.5}
  title="Quase todo secretário estadual de cultura tem curso superior"
  subtitle="Escolaridade do titular da pasta de cultura nos estados · ESTADIC {primeira.label}, 2018 e {ultima.label}"
  {footnote}
  source="Fonte: Elaboração própria com base na ESTADIC/IBGE, ondas de {primeira.label} a {ultima.label}."
  {background}
  bind:svgEl
/>
