<script lang="ts">
  /**
   * Os municípios acima de 2% da RCL — a Figura 7 da publicação no estilo do
   * segundo print: a contagem como faixa grossa e a proporção como régua de
   * bolinhas.
   *
   * O último ano tem base declarante menor, mas isso não é uma quebra da linha
   * do tempo: 2024 e 2025 são anos consecutivos e o eixo não salta. A ressalva
   * corre na nota de rodapé, e o percentual da régua — que já traz a base do
   * ano no denominador — é quem absorve a diferença.
   *
   * O recorte de 2% dialoga com a demanda histórica do campo por um percentual
   * mínimo para a cultura, incorporada ao Plano Nacional de Cultura.
   */
  import LinhaProporcaoChart from './LinhaProporcaoChart.svelte';
  import dados from '../data/meta-rcl-municipios.json';

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

  const pontos = dados.anos.map((a) => ({ ano: a.ano, valor: a.acima, pct: a.pct }));
  const final = dados.anos[dados.anos.length - 1];
  const penultimo = dados.anos[dados.anos.length - 2];

  const footnote =
    `Gasto com recursos próprios na Função 13 (Cultura) como parcela da Receita Corrente Líquida. ` +
    `Em ${final.ano} nem todos os municípios haviam declarado contas — ${inteiro.format(final.analisados)} ` +
    `contra ${inteiro.format(penultimo.analisados)} em ${penultimo.ano} —, então a contagem do último ano ` +
    `sai de uma base menor. O percentual já é medido sobre a base de cada ano.`;
</script>

<LinhaProporcaoChart
  {pontos}
  title="Municípios que destinam mais de 2% da receita à cultura"
  subtitle="Municípios com gasto cultural próprio acima de 2% da Receita Corrente Líquida · de {dados.anos[0].ano} a {final.ano}"
  formatValue={(v) => inteiro.format(v)}
  formatPct={(v) => `${decimal.format(v)}%`}
  destaque={{
    valor: inteiro.format(final.acima),
    texto: `municípios acima de 2% da RCL em ${final.ano}`,
  }}
  fraseDaRegua="No conjunto dos municípios com contas declaradas, eles representam…"
  destaqueDaRegua={{
    valor: `${decimal.format(final.pct)}%`,
    texto: 'dos municípios analisados',
  }}
  {footnote}
  source="Fonte: Elaboração própria com base na MSC/SICONFI. Diretriz: Plano Nacional de Cultura (PNC)."
  {background}
  bind:svgEl
/>
