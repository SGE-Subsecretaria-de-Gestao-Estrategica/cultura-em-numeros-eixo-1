<script lang="ts">
  /**
   * A composição do investimento federal em cultura em colunas fechando em
   * 100% — o par do `HistomapFederalChart`: lá a forma corrida dos 23 anos,
   * aqui o número.
   *
   * Duas variantes, e a diferença entre elas é só quantos anos viram coluna.
   * Um percentual só cabe escrito dentro de uma coluna larga, e 23 anos no
   * espaço de um cartão de A4 retrato não deixam largura nenhuma sobrando —
   * é a mesma conta que tirou o percentual do histomap.
   *
   * - `marco`, a padrão: sete anos, os mesmos que os blocos de destaque do
   *   histomap já chamam de assunto. Colunas largas, todo número cabe.
   * - `todos`: os 23 anos corridos, lado a lado com o histomap na mesma
   *   unidade de tempo. Ganha-se a comparação direta com a figura ao lado e
   *   perde-se o número em toda fatia fina — a mesma troca que o histomap fez
   *   ao abandonar o percentual, só que aqui a geometria ainda escreve o que
   *   couber, em vez de nada.
   *
   * A ordem de empilhamento vem dos grupos institucionais do próprio JSON, e
   * não da ordem das chaves — ver `HistomapFederalChart` para a razão: o MinC
   * e os Outros Órgãos ficam vizinhos, e a extinção do primeiro lê-se como
   * troca de cor dentro da mesma base da coluna.
   *
   * Não há variante nominal, pelo mesmo motivo do histomap: o deflator
   * multiplica todas as fontes de um ano pelo mesmo índice, então a repartição
   * do ano é idêntica nas duas medidas.
   */
  import ComposicaoChart, { type AnoRow } from './ComposicaoChart.svelte';
  import { fonteFederalLabels, fonteFederalStackColors } from './fontes';
  import federal from '../data/federal-por-fonte.json';

  let {
    /** `marco`, sete anos escolhidos; `todos`, os 23 anos corridos da série. */
    variante = 'marco',
    svgEl = $bindable(null),
    background,
  }: {
    variante?: 'marco' | 'todos';
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  const ordem = federal.grupos.keys.flatMap(
    (grupo) => (federal.grupos.composicao as Record<string, string[]>)[grupo],
  );

  const cores = fonteFederalStackColors(ordem);
  const colors = ordem.map((key) => cores[key]);

  /**
   * 2003, antes de a renúncia ser medida; 2006, quando ela entra na série;
   * 2012 e 2020 e 2023, os três outros anos dos blocos de destaque do
   * histomap; 2019, o primeiro ano sem o MinC; 2025, o último da série.
   */
  const ANOS_MARCO = [2003, 2006, 2012, 2019, 2020, 2023, 2025];

  /** Os mesmos oito anos que o histomap teria usado como marcação do eixo. */
  const TICK_YEARS_TODOS = [2003, 2006, 2010, 2013, 2016, 2019, 2023, 2025];

  const todosOsDados = federal.real as unknown as AnoRow[];

  const data = $derived(
    variante === 'todos'
      ? todosOsDados
      : todosOsDados.filter((row) => ANOS_MARCO.includes(Number(row.label))),
  );

  /**
   * 23 colunas cabem num vão bem mais estreito do que sete: o vão entre elas
   * encolhe para sobrar largura ao número, e é a mesma decisão que o
   * `ComposicaoAnualChart` original tomava com `columnRatio` perto de 1.
   */
  const columnRatio = $derived(variante === 'todos' ? 0.92 : 0.62);

  const subtitle = $derived(
    variante === 'todos'
      ? 'Participação de cada fonte no gasto federal pleno em cultura, ano a ano · 2003–2025'
      : 'Participação de cada fonte no gasto federal pleno em cultura, em anos-marco da série · 2003–2025',
  );

  const footnoteMarco =
    'As colunas empilham por natureza, de baixo para cima: execução direta, renúncia fiscal, transferências a estados e municípios. Os sete anos são os mesmos que o histomap ao lado chama de assunto — não uma amostra do meio da série, e sim os pontos em que a composição muda: 2003, antes de a renúncia fiscal ser medida; 2006, quando ela entra na série; 2012, o pico do ciclo do MinC; 2019, o primeiro ano sem o MinC, extinto — a despesa da pasta passa a correr por Cidadania e Turismo, e a coluna troca de cor sem trocar de dinheiro; 2020, a emergência da pandemia; 2023, o maior ano da série; 2025, o mais recente. As participações não dependem do deflator, e por isso a figura vale igual a preços de 2024 e em valores correntes.';

  /**
   * A mesma nota do histomap, adaptada: aqui a fatia muda em degrau na virada
   * do ano, e uma fatia fina de propósito fica sem número — a coluna ainda
   * mostra a cor, só não escreve o que a própria largura já nega.
   */
  const footnoteTodos =
    'As colunas empilham por natureza, de baixo para cima: execução direta, renúncia fiscal, transferências a estados e municípios. A série de renúncia fiscal começa em 2006 — até 2005 a fatia do Ministério da Cultura está superestimada, porque a renúncia não era nula, não era medida. De 2019 a 2022 o MinC não aparece porque foi extinto, e a despesa da pasta corre por Cidadania e Turismo: as duas cores são o mesmo dinheiro trocando de casa. Uma fatia estreita demais para o próprio número fica sem ele — a cor e a legenda ainda a identificam. As participações não dependem do deflator, e por isso a figura vale igual a preços de 2024 e em valores correntes.';
</script>

<ComposicaoChart
  {data}
  keys={ordem}
  labels={fonteFederalLabels}
  {colors}
  {columnRatio}
  tickYears={variante === 'todos' ? TICK_YEARS_TODOS : undefined}
  spans={[
    variante === 'todos'
      ? { de: 2003, ate: 2005, texto: 'renúncia fiscal não medida' }
      : { de: 2003, ate: 2003, texto: 'renúncia fiscal não medida' },
  ]}
  title="Composição do investimento federal em cultura por fonte de recurso"
  {subtitle}
  footnote={variante === 'todos' ? footnoteTodos : footnoteMarco}
  source="Fonte: Elaboração própria com base no SIOP, no SALIC e na ANCINE."
  {background}
  bind:svgEl
/>
