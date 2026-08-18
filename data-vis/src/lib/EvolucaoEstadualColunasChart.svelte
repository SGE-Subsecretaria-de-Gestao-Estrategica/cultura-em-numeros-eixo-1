<script lang="ts">
  /**
   * A mesma evolução do investimento estadual em cultura de
   * `EvolucaoEstadualLinhasChart`, empilhada: uma coluna por ano, a altura
   * total sendo o investimento do ano e cada segmento, uma fonte.
   *
   * As duas figuras são a mesma tabela e respondem perguntas diferentes. A
   * pilha responde **quanto foi o ano** — é a única das duas em que o total
   * existe como objeto visível, e é ele que mostra que o investimento estadual
   * passou de R$ 3,3 bi a R$ 7,9 bi. As linhas respondem o que cada fonte fez
   * ao longo do tempo, que a pilha esconde: nela uma faixa que sobe pode estar
   * crescendo ou apenas sendo empurrada pela de baixo.
   *
   * Onde a pilha ganha da linha, nesta série: em 2020 e em 2024–2025 o
   * empilhamento mostra a transferência federal *somando-se* ao recurso
   * próprio, e não competindo com ele — a leitura que a figura de linhas, com
   * cada série contra o eixo, deixa o leitor fazer sozinho.
   *
   * As cores são as mesmas das linhas (`fonteMarcaColors`), e a pilha segue a
   * ordem das chaves em vez da ordem de tamanho que o cartão usa por omissão:
   * azuis na base, vermelhos por cima. É o que faz a figura ser lida como uma
   * base permanente com acréscimos episódicos, que é o que ela é — e o preço é
   * deixar a fatia fina das emendas no meio da pilha, onde ela não tem altura
   * nem para a chamada. Os R$ 27 milhões dela estão na nota.
   *
   * O cartão é o de `InvestimentoPorFonteChart`, que já resolve o problema
   * desta série: as emendas parlamentares são R$ 3 mi contra uma coluna de
   * R$ 5 bi, e um segmento assim não tem altura para o próprio número — ele
   * sai numa chamada ao lado, ligada por uma linha ao segmento a que pertence.
   *
   * A nota daquele cartão é uma linha só, sem quebra automática: o texto que
   * não couber na largura sai cortado em silêncio, então a desta figura é
   * curta de propósito. O que não cabe nela está na story e neste comentário.
   *
   * A folga acima das colunas é maior que a padrão (`headroom`) por causa de um
   * único número: a PNAB de 2024 são R$ 557 mi no *topo* de uma coluna de
   * R$ 7,7 bi, fina demais para carregar o próprio valor dentro de si. A
   * chamada dela vai para cima do segmento, onde já está o total da coluna, e
   * com a folga padrão não sobrava altura para os dois — a rotina de
   * posicionamento só empurra para cima, e ali não havia para onde.
   */
  import { stackOrderNone } from 'd3';
  import InvestimentoPorFonteChart from './InvestimentoPorFonteChart.svelte';
  import { fonteLabels, fonteMarcaColors } from './fontes';
  import estadual from '../data/estadual-por-fonte.json';

  let {
    /** `real` está a preços médios de 2024; `nominal`, em reais correntes. */
    valores = 'real',
    svgEl = $bindable(null),
  }: {
    valores?: 'real' | 'nominal';
    svgEl?: SVGSVGElement | null;
  } = $props();

  const data = $derived(estadual[valores]);

  const unidade = $derived(
    valores === 'real'
      ? `corrigidos pela inflação (IPCA, preços médios de ${estadual.anoBaseDeflator})`
      : 'em valores nominais',
  );

  /** O deflator só se declara quando ele foi aplicado. */
  const fonte = $derived(
    'Fonte: Elaboração própria com base no SICONFI (MSC Orçamentária Estadual).' +
      (valores === 'real' ? ' Deflator: IPCA/SGS-BCB (série 433).' : ''),
  );
</script>

<InvestimentoPorFonteChart
  {data}
  keys={estadual.keys}
  labels={fonteLabels}
  colors={fonteMarcaColors}
  order={stackOrderNone}
  headroom={1.22}
  title="Evolução do investimento estadual em cultura por fonte de recurso"
  subtitle={`Valores empenhados pelos estados e pelo Distrito Federal, ${unidade} · 2019–2025`}
  footnote="LAB 1 = Lei Aldir Blanc 1 · LPG = Lei Paulo Gustavo · PNAB = Política Nacional Aldir Blanc (Aldir Blanc 2). As emendas, no ciano, não passam de R$ 27 mi e não têm altura visível na pilha."
  source={fonte}
  bind:svgEl
/>
