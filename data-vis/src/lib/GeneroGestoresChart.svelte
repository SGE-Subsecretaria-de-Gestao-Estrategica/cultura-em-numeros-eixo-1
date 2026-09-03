<script lang="ts">
  /**
   * O sexo do titular da pasta de cultura, coluna por onda da MUNIC — o par
   * de `RacaGestoresChart` na mesma leitura de composição.
   *
   * A pergunta não é "quem ocupa o cargo hoje", é a trajetória: a proporção
   * de mulheres sobe de 2014 para 2018 e cai abaixo do ponto de partida em
   * 2021, um recuo pequeno mas que atravessa três ondas na mesma direção do
   * meio para o fim — o suficiente para não ser ruído de amostra.
   */
  import ComposicaoChart, { type AnoRow } from './ComposicaoChart.svelte';
  import { categoricaDe } from './cores';
  import dados from '../data/gestao-municipal.json';

  let {
    svgEl = $bindable(null),
    background,
  }: {
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  const inteiro = new Intl.NumberFormat('pt-BR');

  const data = dados.genero.ondas as unknown as AnoRow[];
  const colors = categoricaDe(dados.genero.categorias.length);

  const primeira = dados.genero.ondas[0];
  const ultima = dados.genero.ondas[dados.genero.ondas.length - 1];

  const footnote =
    `Cada coluna soma 100% sobre os titulares que declararam o próprio sexo. Ficaram de fora, por não ` +
    `terem declarado: ${dados.genero.ondas.map((o) => `${inteiro.format(o.naoResposta)} em ${o.label}`).join(', ')} ` +
    `— não-resposta não é evidência nem a favor nem contra o que se mede.`;
</script>

<ComposicaoChart
  {data}
  keys={dados.genero.categorias}
  {colors}
  columnRatio={0.5}
  title="A proporção de mulheres à frente da cultura municipal recuou entre 2014 e 2021"
  subtitle="Sexo do titular da pasta de cultura nos municípios · MUNIC {primeira.label}, 2018 e {ultima.label}"
  {footnote}
  source="Fonte: Elaboração própria com base na MUNIC/IBGE, ondas de {primeira.label} a {ultima.label}."
  {background}
  bind:svgEl
/>
