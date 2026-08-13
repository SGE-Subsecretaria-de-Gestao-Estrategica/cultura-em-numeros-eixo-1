<script lang="ts">
  import BarrasHorizontaisChart from './BarrasHorizontaisChart.svelte';
  import { sniic } from './cores';
  import gestao from '../data/gestao-municipal.json';

  let {
    svgEl = $bindable(null),
    background,
  }: { svgEl?: SVGSVGElement | null; background?: string | null } = $props();

  const decimal = new Intl.NumberFormat('pt-BR', {
    minimumFractionDigits: 1,
    maximumFractionDigits: 1,
  });
  const integer = new Intl.NumberFormat('pt-BR');

  const dados = gestao.escolaridadeTripe;

  /**
   * O n de cada faixa vai junto do percentual: as faixas são muito desiguais
   * — 105 municípios de ensino fundamental contra 4.988 do bloco do meio — e um
   * percentual sozinho esconderia que a barra de cima repousa sobre 105 casos.
   */
  const itens = dados.itens.map((i) => ({
    label: i.label,
    valor: i.pct,
    rotulo: `${decimal.format(i.pct)}%  (${integer.format(i.valor)} de ${integer.format(i.n)})`,
  }));
</script>

<BarrasHorizontaisChart
  {itens}
  color={sniic.vermelho}
  title="Escolaridade do gestor e institucionalização da cultura"
  subtitle={`Percentual de municípios com o tripé completo — plano, fundo e conselho de cultura — por nível de escolaridade do titular do órgão gestor, em ${dados.ano}.`}
  footnote={`A relação é monotônica, mas descreve associação e não causa: municípios que atraem gestores mais titulados também tendem a ser maiores e mais estruturados. ${integer.format(dados.semInformacao)} municípios sem informação de escolaridade ficam fora.`}
  source="Fonte: Elaboração própria com base na MUNIC/IBGE 2021."
  {background}
  bind:svgEl
/>
