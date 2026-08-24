<script lang="ts">
  import MapaMunicipiosChart from './MapaMunicipiosChart.svelte';
  import { getPillarTheme } from 'sniic-design-system';
  import { degrausDe, rampaVermelha } from './cores';
  import municipios from '../data/gestao-municipios-2021.json';

  let {
    svgEl = $bindable(null),
    background,
  }: { svgEl?: SVGSVGElement | null; background?: string | null } = $props();

  const palette = getPillarTheme(1).palette;

  /**
   * As cinco categorias da barra empilhada viram três classes no mapa:
   * municípios são polígonos minúsculos, e cinco degraus de luminosidade na
   * mesma matiz não se separam nesse tamanho. A rampa é a mesma vermelha da
   * figura da estrutura, do mais escuro (mais institucionalizado) ao mais
   * claro, para as duas figuras se lerem como o mesmo dado em dois recortes.
   */
  const cores = degrausDe(rampaVermelha, 3);
  const classes = municipios.estruturaClasses.map((label, i) => ({
    label,
    color: cores[i],
  }));

  const valores = Object.fromEntries(
    Object.entries(municipios.municipios).map(([cod, m]) => [cod, m.e]),
  );
</script>

<MapaMunicipiosChart
  {valores}
  {classes}
  semInfo={{ label: 'Sem informação', color: palette.base[200] }}
  title="Estrutura do órgão gestor no território"
  subtitle={`O grau de autonomia institucional da pasta da cultura em cada município, em ${municipios.ano}.`}
  footnote="As três classes agrupam as cinco categorias da figura da estrutura: secretaria exclusiva soma-se à administração indireta, e o setor subordinado aos municípios sem estrutura específica. Quatro municípios não informaram."
  source="Fonte: Elaboração própria com base na MUNIC/IBGE 2021 e na malha municipal do IBGE."
  {background}
  bind:svgEl
/>
