<script lang="ts">
  /**
   * A forma da distribuição do gasto cultural próprio dos municípios, por
   * macrorregião — a leitura que nenhuma das figuras municipais dá.
   *
   * `MetaRcl` conta quantos municípios passam de 2% da RCL e `MetaRclRegiao`
   * mostra essa contagem subindo ao longo do tempo em cada região. As duas
   * medem a mesma fronteira e nenhuma mostra o que há dos dois lados dela: a
   * massa está colada no zero — a mediana nacional é 1,36% — e a cauda vai
   * muito longe, até 76%.
   *
   * Por isso a curva é partida na meta e as duas partes têm cores diferentes:
   * a fração pintada de vermelho é exatamente o percentual que a figura de
   * linhas mostra ano a ano, e escrevê-lo na ponta direita faz as duas leituras
   * se reconhecerem como a mesma medida.
   *
   * As regiões descem pela proporção acima da meta, então o Nordeste abre e o
   * Sul fecha — a mesma ordem da figura de pequenos múltiplos.
   */
  import CristasChart, { type Crista } from './CristasChart.svelte';
  import { rampaVermelha } from './cores';
  import dados from '../data/distribuicao-rcl-regiao.json';

  let {
    svgEl = $bindable(null),
    background,
  }: {
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  const inteiro = new Intl.NumberFormat('pt-BR');
  const decimal = new Intl.NumberFormat('pt-BR', {
    minimumFractionDigits: 1,
    maximumFractionDigits: 1,
  });

  const cristas: Crista[] = dados.regioes.map((r) => ({
    key: r.regiao,
    label: r.regiao,
    nota: `${inteiro.format(r.n)} municípios · mediana ${decimal.format(r.mediana)}%`,
    densidade: r.densidade,
    destaque: `${decimal.format(r.pctAcimaMeta)}%`,
  }));

  const foraDaEscala = dados.regioes.reduce((soma, r) => soma + r.foraDaEscala, 0);

  const footnote =
    `Gasto com recursos próprios na Função 13 (Cultura) como parcela da Receita Corrente Líquida de ${dados.ano}, ` +
    `município a município, em valores correntes. Cada curva é a densidade da sua região, normalizada para ter a ` +
    `mesma área das demais: o que se compara é a forma, e o tamanho de cada região está ao lado do rótulo. ` +
    `A parte vermelha da área é a fração de municípios acima da meta, e é o número escrito na ponta direita — o ` +
    `mesmo que a figura de evolução por região mostra em ${dados.ano}. O eixo vai até ` +
    `${decimal.format(dados.xMax)}% porque a cauda é muito longa: ${foraDaEscala} municípios ficam além dele e o ` +
    `maior chega a ${decimal.format(dados.maximo)}%. A mediana nacional é ${decimal.format(dados.medianaNacional)}%, ` +
    `sobre ${inteiro.format(dados.base)} municípios com contas declaradas.`;
</script>

<CristasChart
  {cristas}
  xMax={dados.xMax}
  referencia={dados.meta}
  corAbaixo={rampaVermelha[4]}
  corAcima={rampaVermelha[2]}
  corTraco={rampaVermelha[1]}
  title="A distribuição por trás da meta: onde estão os municípios, e não quantos passam"
  subtitle="Densidade dos municípios pelo gasto cultural próprio como percentual da Receita Corrente Líquida, por região · {dados.ano}"
  formatX={(v) => `${v}%`}
  legendaReferencia="Linha preta: {decimal.format(dados.meta)}% da RCL, a meta do Plano Nacional de Cultura. À direita dela, a parte da região que a cumpre."
  {footnote}
  source="Fonte: Elaboração própria com base na MSC/SICONFI, Função 13 (Cultura), e nos demonstrativos de RCL do SICONFI."
  {background}
  bind:svgEl
/>
