<script lang="ts">
  /**
   * O tripé institucional da cultura — conselho, plano e fundo em funcionamento
   * — estado a estado, no mapa hexagonal do terceiro print.
   *
   * Cada hexágono compara as duas ondas da MUNIC: 2014 à esquerda, 2021 à
   * direita. A linha preta é a média nacional de 2021 e o verde é o quanto a
   * UF passa dela — o mapa responde de relance onde o tripé avançou de fato.
   *
   * O DF entra pela própria adesão, porque não tem municípios: a barra de 100%
   * é real, mas é a resposta de um ente só, e fica fora da escala das demais.
   */
  import HexMapaUfChart from './HexMapaUfChart.svelte';
  import dados from '../data/tripe-uf.json';

  let {
    svgEl = $bindable(null),
    background,
  }: {
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  const valores = dados.ufs.map((u) => ({ uf: u.uf, a: u.pct2014, b: u.pct2021 }));
  const media = dados.mediaNacional['2021'];
</script>

<HexMapaUfChart
  {valores}
  referencia={media}
  title="Municípios com o tripé institucional da cultura, estado a estado"
  subtitle="Percentual de municípios com conselho, plano e fundo de cultura em funcionamento · 2014 e 2021"
  legendas={{
    excedente: 'Parte em verde: quanto a UF supera a média nacional de 2021',
    referencia: `Linha preta: ${Math.round(media)}%, a média nacional em 2021`,
    a: 'À esquerda: municípios com o tripé completo em 2014',
    b: 'À direita: municípios com o tripé completo em 2021',
  }}
  footnote="O Distrito Federal, que não tem municípios, entra pela própria adesão ao tripé — uma resposta de um ente só, fora da escala das demais barras."
  source="Fonte: Elaboração própria com base na MUNIC/IBGE, ondas de 2014 e 2021."
  {background}
  bind:svgEl
/>
