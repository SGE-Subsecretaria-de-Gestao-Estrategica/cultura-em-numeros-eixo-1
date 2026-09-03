<script lang="ts">
  /**
   * Quais estados têm lei própria de incentivo fiscal à cultura, sobre a
   * malha das UFs — a leitura territorial de `IncentivoEstadualChart`.
   *
   * O mapa original do capítulo cruzava lei de patrimônio e lei de incentivo
   * em quatro classes; em 2021 as 27 UFs já têm lei de patrimônio (ver
   * `PatrimonioEstadualChart`), então duas das quatro classes nunca ocorrem e
   * a única coisa que de fato varia no território é a lei de incentivo. O
   * mapa mede só o que varia.
   */
  import CoropletoUfChart from './CoropletoUfChart.svelte';
  import { rampaRosa } from './cores';
  import dados from '../data/estadic-governanca.json';

  let {
    svgEl = $bindable(null),
    background,
  }: {
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  const valores = dados.mapas2021.ufs.map((u) => ({ uf: u.uf, valor: u.temLeiIncentivo ? 1 : 0 }));
  const comLei = dados.mapas2021.ufs.filter((u) => u.temLeiIncentivo).length;
</script>

<CoropletoUfChart
  {valores}
  rampa={[rampaRosa[4], rampaRosa[1]]}
  quebras={[1]}
  rotulosClasses={['Não tem lei de incentivo', 'Tem lei de incentivo']}
  legendaTitulo="Mecenato estadual:"
  formatValue={(v) => String(v)}
  title="Poucos estados têm mecanismo próprio de incentivo fiscal à cultura"
  subtitle="Estados com lei estadual de renúncia fiscal para a cultura · ESTADIC 2021"
  destaque={{
    valor: `${comLei} de 27`,
    cor: rampaRosa[1],
    texto: 'estados têm lei própria de incentivo fiscal — as 27 UFs já têm lei de patrimônio',
  }}
  footnote="Em 2021 as 27 UFs já tinham legislação de proteção ao patrimônio cultural (ver figura de patrimônio); o mapa original do capítulo cruzava as duas leis, mas com o patrimônio universal a única variação territorial que resta é a lei de incentivo."
  source="Fonte: Elaboração própria com base na ESTADIC/IBGE, onda de 2021."
  {background}
  bind:svgEl
/>
