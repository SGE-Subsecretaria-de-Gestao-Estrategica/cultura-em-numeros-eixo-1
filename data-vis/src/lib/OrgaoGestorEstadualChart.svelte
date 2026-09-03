<script lang="ts">
  /**
   * A autonomia institucional do órgão gestor estadual de cultura, coluna por
   * onda da ESTADIC — o par estadual de `EstruturaOrgaoGestorChart` (MUNIC).
   *
   * Três categorias ordenadas por grau de autonomia — de setor subordinado a
   * secretaria exclusiva —, por isso a cor sai de uma rampa só e não da
   * escala categórica: `degrausDe` mostra a ordem sozinha, sem pedir ao leitor
   * que decore qual matiz é qual.
   */
  import ComposicaoChart, { type AnoRow } from './ComposicaoChart.svelte';
  import { degrausDe, rampaAzul } from './cores';
  import dados from '../data/estadic-governanca.json';

  let {
    svgEl = $bindable(null),
    background,
  }: {
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  const inteiro = new Intl.NumberFormat('pt-BR');

  const data = dados.orgaoGestor.ondas as unknown as AnoRow[];
  const colors = degrausDe(rampaAzul, dados.orgaoGestor.categorias.length);

  const primeira = dados.orgaoGestor.ondas[0];
  const ultima = dados.orgaoGestor.ondas[dados.orgaoGestor.ondas.length - 1];

  const footnote =
    `Cada coluna soma 100% sobre as ${inteiro.format(dados.universo)} UFs — as 26 unidades federativas e o ` +
    `Distrito Federal. "Secretaria Exclusiva / Fundação" reúne as pastas com estrutura própria; "Secretaria ` +
    `Conjunta", as que dividem a estrutura com outra política; "Setor Subordinado" é o grau mais baixo de ` +
    `autonomia, um órgão sem estrutura própria dentro de outra secretaria.`;
</script>

<ComposicaoChart
  {data}
  keys={dados.orgaoGestor.categorias}
  {colors}
  columnRatio={0.5}
  title="Mais de 8 em cada 10 estados mantêm secretaria própria e exclusiva de cultura"
  subtitle="Estrutura do órgão gestor estadual de cultura · ESTADIC {primeira.label}, 2018 e {ultima.label}"
  {footnote}
  source="Fonte: Elaboração própria com base na ESTADIC/IBGE, ondas de {primeira.label} a {ultima.label}."
  {background}
  bind:svgEl
/>
