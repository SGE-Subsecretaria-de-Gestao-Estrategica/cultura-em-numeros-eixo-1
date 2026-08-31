<script lang="ts">
  /**
   * A meta de 2% da RCL por macrorregião — a Figura 7 da publicação, em
   * pequenos múltiplos em vez de cinco linhas num plot só.
   *
   * A troca não é estética. Cinco matizes da paleta da marca não se separam o
   * bastante para carregar cinco séries que se cruzam: o par vermelho e rosa
   * fica em ΔE 14,6 sob visão normal, abaixo do piso, e rosa e verde caem a 7,6
   * sob deuteranopia. Com um painel por região a posição faz o trabalho da cor,
   * e as cinco linhas podem ser da mesma cor sem ambiguidade nenhuma.
   *
   * A escala é comum aos cinco painéis, e a linha cinza atrás de cada um é o
   * conjunto do país — as duas coisas que fazem os painéis comparáveis entre si
   * em vez de cinco figuras soltas.
   */
  import PequenosMultiplosChart, { type PainelSerie } from './PequenosMultiplosChart.svelte';
  import dados from '../data/meta-rcl-regiao.json';

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
  const inteiro = new Intl.NumberFormat('pt-BR');
  const pct = (v: number) => `${decimal.format(v)}%`;

  const [primeiro] = dados.anos;
  const ultimo = dados.anos[dados.anos.length - 1];

  /**
   * Os painéis descem pelo valor final: o Nordeste, que chega mais alto, abre a
   * figura, e o Sul, que fica para trás, a fecha. Ordenar por nome esconderia
   * justamente o ranking que a figura mede.
   */
  const paineis: PainelSerie[] = [...dados.regioes]
    .sort((a, b) => b.pcts[b.pcts.length - 1] - a.pcts[a.pcts.length - 1])
    .map((r) => ({
      key: r.regiao,
      label: r.regiao,
      valores: r.pcts,
      nota: `${inteiro.format(r.municipios)} municípios`,
    }));
</script>

<PequenosMultiplosChart
  anos={dados.anos}
  {paineis}
  referencia={dados.nacional}
  labelReferencia="Linha cinza: o conjunto do país"
  title="Municípios que destinam mais de 2% da receita à cultura, por região"
  subtitle="Percentual de municípios com gasto cultural próprio acima de 2% da Receita Corrente Líquida · de {primeiro} a {ultimo}"
  formatValue={pct}
  rotulos={[primeiro, 2021]}
  footnote="As cinco regiões dividem a mesma escala vertical, então a altura de uma linha significa o mesmo em qualquer painel. Todas caem em 2020 e 2021, nos anos da pandemia, e se recuperam a partir de 2022 com a chegada da Lei Paulo Gustavo e da PNAB — mas em ritmos diferentes: o Nordeste ganha 23 pontos percentuais no período e o Sul, cinco. O denominador de cada ano são os municípios com contas declaradas naquele ano."
  source="Fonte: Elaboração própria com base na MSC/SICONFI e nos demonstrativos de RCL. Diretriz: Plano Nacional de Cultura (PNC)."
  {background}
  bind:svgEl
/>
