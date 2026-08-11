<script lang="ts">
  import { colorScales } from 'sniic-design-system';
  import ComposicaoPorOndaChart from './ComposicaoPorOndaChart.svelte';
  import gestao from '../data/gestao-municipal.json';

  let {
    svgEl = $bindable(null),
    background,
  }: { svgEl?: SVGSVGElement | null; background?: string | null } = $props();

  /**
   * Uma rampa sequencial, não uma paleta categórica: as cinco categorias estão
   * ordenadas por grau de institucionalização, de secretaria própria a nenhuma
   * estrutura, e a escala de azul deixa essa ordem visível sem que o leitor
   * precise decorar qual matiz é qual. Do mais escuro (mais institucionalizado)
   * ao mais claro.
   */
  const colors = [
    colorScales.blue[4],
    colorScales.blue[3],
    colorScales.blue[2],
    colorScales.blue[1],
    colorScales.blue[0],
  ];
</script>

<ComposicaoPorOndaChart
  data={gestao.estrutura.ondas}
  categorias={gestao.estrutura.categorias}
  {colors}
  title="A estrutura do órgão gestor da cultura"
  subtitle="Como a cultura está alocada na administração municipal, em cada onda da MUNIC."
  footnote="Os 17 rótulos das quatro ondas foram harmonizados em cinco categorias — 'Fundação pública' (2006) e 'Órgão da administração indireta' (2014+) são a mesma coisa, assim como as variações de grafia de 'Setor subordinado'. Recusas e não-respostas ficam fora da base."
  source="Fonte: Elaboração própria com base na MUNIC/IBGE (2006, 2014, 2018 e 2021)."
  {background}
  bind:svgEl
/>
