<script lang="ts">
  import { colorScales } from 'sniic-design-system';
  import BarrasHorizontaisChart from './BarrasHorizontaisChart.svelte';
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

  const dados = gestao.execucaoLab;

  /**
   * A barra mede a contagem de municípios e o rótulo carrega os dois números.
   * As faixas têm larguras diferentes — "0%" é um ponto, "Até 10%" é um
   * intervalo — então isto é uma contagem por categoria ordenada, não um
   * histograma: as barras não são densidades e não devem ser lidas como tal.
   */
  const itens = dados.itens.map((i) => ({
    label: i.label,
    valor: i.valor,
    rotulo: `${integer.format(i.valor)}  (${decimal.format(i.pct)}%)`,
  }));

  const doisPrimeiros = dados.itens[0].pct + dados.itens[1].pct;
</script>

<BarrasHorizontaisChart
  {itens}
  color={colorScales.teal[2]}
  bandHeight={26}
  title="Execução do repasse da Lei Aldir Blanc pelos municípios"
  subtitle={`Distribuição dos municípios pelo percentual do recurso recebido que chegou a ser executado, em ${dados.ano}.`}
  footnote={`${decimal.format(doisPrimeiros)}% dos municípios executaram no máximo 10% do que receberam, e ${decimal.format(dados.itens[dados.itens.length - 1].pct)}% executaram mais de 90%. Base: ${integer.format(dados.base)} municípios que informaram o percentual; ${integer.format(dados.semInformacao)} não informaram. As faixas não têm a mesma largura, então o comprimento das barras compara contagens entre categorias, não densidades.`}
  source="Fonte: Elaboração própria com base na MUNIC/IBGE 2021."
  {background}
  bind:svgEl
/>
