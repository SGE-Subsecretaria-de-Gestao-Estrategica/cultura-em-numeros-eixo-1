<script lang="ts">
  /**
   * Quanto cada município executou do repasse emergencial da Lei Aldir Blanc 1
   * até o corte de 2021 — a distribuição inteira, faixa por faixa, não só a
   * média.
   *
   * A distribuição é bimodal, e é isso que a figura existe para mostrar: a
   * faixa mais numerosa não é o topo nem o meio, é "até 10%" — mais de um
   * quarto dos municípios mal começou a gastar — e ainda assim "mais de 90%"
   * é a segunda maior faixa. Uma média sozinha esconderia as duas pontas atrás
   * de um número do meio que quase ninguém tem.
   *
   * As faixas ficam na ordem natural da régua — 0%, até 10%, 11-20% e por
   * diante —, não ordenadas por tamanho: é a forma da distribuição que
   * importa aqui, e reordenar por valor a destruiria.
   */
  import BarraRankingChart, { type LinhaRanking } from './BarraRankingChart.svelte';
  import { rampaVermelha } from './cores';
  import dados from '../data/gestao-municipal.json';

  let {
    svgEl = $bindable(null),
    background,
  }: {
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  const decimal = new Intl.NumberFormat('pt-BR', { maximumFractionDigits: 1 });
  const inteiro = new Intl.NumberFormat('pt-BR');

  const linhas: LinhaRanking[] = dados.execucaoLab.itens.map((item) => ({
    key: item.label,
    label: item.label,
    valor: item.pct,
    rotuloValor: `${inteiro.format(item.n)} (${decimal.format(item.pct)}%)`,
  }));

  const base = dados.execucaoLab.itens.reduce((soma, i) => soma + i.n, 0);
  const zero = dados.execucaoLab.itens.find((i) => i.label === '0%')!;
  const ateDez = dados.execucaoLab.itens.find((i) => i.label === 'Até 10%')!;
  const maisNoventa = dados.execucaoLab.itens.find((i) => i.label === 'Mais de 90%')!;
  const baixaExecucao = zero.pct + ateDez.pct;

  const footnote =
    `Percentual do repasse da Lei Aldir Blanc 1 (2020-21) que cada município já havia executado até o corte da ` +
    `MUNIC 2021, sobre ${inteiro.format(base)} municípios. ${decimal.format(baixaExecucao)}% executaram até 10% ` +
    `do valor — ${decimal.format(zero.pct)}% deles nada — contra ${decimal.format(maisNoventa.pct)}% que já haviam ` +
    `executado mais de 90%.`;
</script>

<BarraRankingChart
  {linhas}
  cor={rampaVermelha[2]}
  title="Mais de um quarto dos municípios mal começou a gastar o repasse da Lei Aldir Blanc"
  subtitle="Municípios por faixa de execução do repasse da Lei Aldir Blanc 1 · MUNIC 2021"
  formatValue={(v) => `${decimal.format(v)}%`}
  destaque={{
    valor: `${decimal.format(baixaExecucao)}%`,
    cor: rampaVermelha[2],
    texto: 'dos municípios executaram até 10% do repasse da Lei Aldir Blanc 1',
  }}
  {footnote}
  source="Fonte: Elaboração própria com base na MUNIC/IBGE, onda de 2021."
  {background}
  bind:svgEl
/>
