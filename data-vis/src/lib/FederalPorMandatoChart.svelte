<script lang="ts">
  /**
   * O gasto federal pleno em cultura acumulado por mandato presidencial — o
   * mesmo dado de `HistomapFederalChart` e `ComposicaoFederalChart`, ano a
   * ano, somado em outra unidade de tempo. As três respondem perguntas
   * diferentes: as duas primeiras, "como veio mudando"; esta, "quanto cada
   * governo executou no total".
   *
   * 2003-2005 ficam fora: são os três anos em que só a execução direta do MinC
   * é medida, e somar um mandato parcial mediria só a fatia mais visível dele.
   * O corte começa em 2006 — o próprio critério que already tira aqueles três
   * anos do histomap.
   *
   * A Lei Paulo Gustavo foi sancionada em 2022, no fim do governo Bolsonaro,
   * mas o grosso da execução corre em 2023, já no ciclo de Lula III — por
   * isso ela entra no mandato seguinte, e não no que a assinou. É a única
   * reclassificação da figura, e a nota diz isso.
   */
  import ColunaCategoriaChart, { type CategoriaRow } from './ColunaCategoriaChart.svelte';
  import { fonteFederalLabels, fonteFederalStackColors } from './fontes';
  import federal from '../data/federal-por-fonte.json';

  let {
    svgEl = $bindable(null),
    background,
  }: {
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  const decimal = new Intl.NumberFormat('pt-BR', {
    minimumFractionDigits: 1,
    maximumFractionDigits: 1,
  });
  const bi = (v: number) => `${decimal.format(v / 1e9)} bi`;

  const MANDATOS = ['Lula I (Final)', 'Lula II', 'Dilma I', 'Dilma II', 'Temer', 'Bolsonaro', 'Lula III'];

  function mandatoDe(ano: number, fonte: string): string | null {
    if (fonte === 'Lei Paulo Gustavo' && ano === 2022) return 'Lula III';
    if (ano === 2006) return 'Lula I (Final)';
    if (ano >= 2007 && ano <= 2010) return 'Lula II';
    if (ano >= 2011 && ano <= 2014) return 'Dilma I';
    if (ano === 2015) return 'Dilma II';
    if (ano >= 2016 && ano <= 2018) return 'Temer';
    if (ano >= 2019 && ano <= 2022) return 'Bolsonaro';
    if (ano >= 2023) return 'Lula III';
    return null;
  }

  const ordem = federal.grupos.keys.flatMap(
    (grupo) => (federal.grupos.composicao as Record<string, string[]>)[grupo],
  );
  const cores = fonteFederalStackColors(ordem);
  const colors = ordem.map((key) => cores[key]);

  const acumulado: Record<string, Record<string, number>> = Object.fromEntries(
    MANDATOS.map((m) => [m, Object.fromEntries(ordem.map((f) => [f, 0]))]),
  );

  for (const row of federal.real as unknown as Record<string, number | string>[]) {
    const ano = Number(row.label);
    if (ano < 2006) continue;
    for (const fonte of ordem) {
      const mandato = mandatoDe(ano, fonte);
      if (!mandato) continue;
      acumulado[mandato][fonte] += Number(row[fonte]) || 0;
    }
  }

  const data: CategoriaRow[] = MANDATOS.map((m) => ({ label: m, ...acumulado[m] }));

  const totalDe = (m: string) => ordem.reduce((soma, f) => soma + acumulado[m][f], 0);
  const totais = Object.fromEntries(MANDATOS.map((m) => [m, totalDe(m)]));
  const maiorMandato = MANDATOS.reduce((a, b) => (totais[a] >= totais[b] ? a : b));
  const lulaIII = totais['Lula III'];

  const footnote =
    `Soma do gasto federal pleno em cultura (execução direta + renúncia fiscal + transferências a estados e ` +
    `municípios) por mandato, a preços médios de 2024 (IPCA). 2003-2005 ficam fora do corte — só a execução ` +
    `direta do Ministério da Cultura é medida ali, e um mandato parcial mediria só essa fatia. A Lei Paulo ` +
    `Gustavo, sancionada em 2022 sob Bolsonaro, entra em Lula III: o grosso da execução corre em 2023, já no ` +
    `mandato seguinte. Lula III soma três anos (2023-2025) contra os quatro dos mandatos plenos anteriores — ` +
    `em ritmo anual, já é o maior da série, mesmo sem ultrapassar ${maiorMandato} em total acumulado.`;
</script>

<ColunaCategoriaChart
  {data}
  keys={ordem}
  labels={fonteFederalLabels}
  {colors}
  columnRatio={0.68}
  radius={6}
  formatValue={bi}
  title="Lula III se aproxima do maior gasto federal acumulado em cultura da série, em só três anos"
  subtitle="Gasto federal pleno em cultura, acumulado por mandato presidencial · a preços médios de 2024 (IPCA)"
  {footnote}
  source="Fonte: Elaboração própria com base no SIOP, no SALIC e na ANCINE."
  {background}
  bind:svgEl
/>
