<script lang="ts">
  import MapaMunicipiosChart from './MapaMunicipiosChart.svelte';
  import { getPillarTheme } from 'sniic-design-system';
  import { rampaAzul } from './cores';
  import municipios from '../data/gestao-municipios-2021.json';

  let {
    svgEl = $bindable(null),
    background,
  }: { svgEl?: SVGSVGElement | null; background?: string | null } = $props();

  const palette = getPillarTheme(1).palette;

  /**
   * Uma contagem ordenada — 0, 1, 2, 3 instrumentos — pede uma escala
   * sequencial, e ela sai da rampa azul da marca para não disputar com o
   * vermelho, que nas figuras vizinhas de gestão é a cor do dado. O zero fica
   * fora da rampa de propósito: "nenhum instrumento" é ausência, não o degrau
   * mais claro de uma presença, e o cinza do tema diz isso sozinho.
   */
  const classes = [
    { label: 'Nenhum instrumento', color: palette.base[300] },
    { label: '1 instrumento', color: rampaAzul[4] },
    { label: '2 instrumentos', color: rampaAzul[2] },
    { label: 'Tripé completo (3)', color: rampaAzul[0] },
  ];

  const valores = Object.fromEntries(
    Object.entries(municipios.municipios).map(([cod, m]) => [cod, m.t]),
  );
</script>

<MapaMunicipiosChart
  {valores}
  {classes}
  title="Institucionalização cultural no território"
  subtitle={`Quantos instrumentos do tripé — conselho, fundo e plano de cultura — cada município tinha criado em ${municipios.ano}.`}
  footnote="A projeção preserva áreas, então a mancha de cada cor mede território, não número de municípios: o Norte, de municípios extensos e pouco institucionalizados, pesa no mapa mais do que pesaria numa contagem."
  source="Fonte: Elaboração própria com base na MUNIC/IBGE 2021 e na malha municipal do IBGE."
  {background}
  bind:svgEl
/>
