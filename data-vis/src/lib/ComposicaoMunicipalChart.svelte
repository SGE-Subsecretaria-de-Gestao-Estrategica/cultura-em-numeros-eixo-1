<script lang="ts">
  /**
   * A composição do investimento municipal em cultura por fonte de recurso, em
   * colunas fechando em 100% — o par municipal de `ComposicaoFederalChart` e o
   * terceiro lado do trio Federal/Estadual/Municipal de composição por fonte.
   *
   * O recurso próprio nunca cai abaixo de 85% em nenhum ano: mesmo em 2020,
   * quando a LAB 1 chega inteira de uma vez, ela é a única fonte emergencial do
   * ano e ainda assim fica em 14,5%. É a mesma leitura de `CrescimentoMunicipalChart`
   * por outro ângulo — o crescimento é sobretudo dinheiro local —, só que aqui
   * a métrica é participação, não volume.
   */
  import ComposicaoChart, { type AnoRow } from './ComposicaoChart.svelte';
  import { fonteLabels, fonteMarcaColors } from './fontes';
  import municipal from '../data/municipal-por-fonte.json';

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
  const pct = (v: number) => `${decimal.format(v)}%`;

  const PROPRIO = 'Recurso Próprio (Municipal)';

  const data = municipal.real as unknown as AnoRow[];

  const proprioPor = (label: string) => {
    const row = municipal.real.find((r) => r.label === label)!;
    const total = municipal.keys.reduce(
      (soma, key) => soma + (row as unknown as Record<string, number>)[key],
      0,
    );
    return (100 * (row as unknown as Record<string, number>)[PROPRIO]) / total;
  };

  const primeiroAno = municipal.real[0].label;
  const ultimoAno = municipal.real[municipal.real.length - 1].label;
  const menorProprio = Math.min(...municipal.real.map((r) => proprioPor(r.label)));
  const anoMenorProprio = municipal.real.find((r) => proprioPor(r.label) === menorProprio)!.label;

  const footnote =
    `As colunas empilham por fonte, de baixo para cima: recurso próprio, emendas parlamentares e as três leis ` +
    `emergenciais, na ordem em que entraram. O ano de menor participação própria é ${anoMenorProprio}, com ` +
    `${pct(menorProprio)} — mesmo ali, nenhuma fonte emergencial isolada supera 15% do total. Valores a preços ` +
    `médios de 2024 (IPCA); a participação percentual não depende do deflator.`;
</script>

<ComposicaoChart
  {data}
  keys={municipal.keys}
  labels={fonteLabels}
  colors={fonteMarcaColors}
  columnRatio={0.62}
  title="O recurso próprio segue maioria absoluta no investimento cultural municipal"
  subtitle="Participação de cada fonte no investimento cultural municipal, ano a ano · {primeiroAno}–{ultimoAno}"
  {footnote}
  source="Fonte: Elaboração própria com base na MSC/SICONFI e no Cadastro Único (BB Ágil/LAB1)."
  {background}
  bind:svgEl
/>
