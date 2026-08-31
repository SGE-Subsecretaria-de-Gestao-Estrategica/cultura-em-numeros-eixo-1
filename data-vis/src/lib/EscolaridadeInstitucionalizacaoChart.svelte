<script lang="ts">
  /**
   * A escolaridade do gestor municipal de cultura contra o grau de
   * institucionalização da política cultural no município.
   *
   * A leitura anterior media só o topo da escada — o percentual de municípios
   * com o tripé completo — e com isso mostrava uma relação que parece forte:
   * 3,8% no ensino fundamental contra 12,0% na pós-graduação, mais de três
   * vezes. Contando de zero a três instrumentos, as outras situações entram e a
   * relação se desfaz quase toda: a coluna do zero fica parada em torno de 42%
   * em três das quatro escolaridades, e mesmo entre os gestores pós-graduados
   * quatro em cada dez municípios não têm nenhum dos três.
   *
   * Ou seja: a escolaridade do gestor mexe em quem chega ao tripé completo, não
   * em quem sai do zero. É uma conclusão mais fraca que a anterior, e é a que o
   * dado sustenta.
   *
   * A cor é uma rampa e não uma escala categórica: as quatro colunas são
   * ordenadas — nenhum, um, dois, três instrumentos — e uma rampa mostra a
   * ordem sozinha, sem pedir ao leitor que decore qual matiz é qual.
   */
  import MatrizBolhasChart, { type Coluna, type Linha } from './MatrizBolhasChart.svelte';
  import { degrausDe, rampaVermelha } from './cores';
  import { colors as marca } from './tokens';
  import dados from '../data/escolaridade-institucionalizacao.json';

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

  /** Do claro ao escuro: quanto mais instrumentos, mais escuro o degrau. */
  const cores = degrausDe(rampaVermelha, dados.graus.length).reverse();

  const colunas: Coluna[] = dados.graus.map((g, i) => ({
    key: String(g.grau),
    label: g.label,
    cor: cores[i],
  }));

  const linhas: Linha[] = dados.faixas.map((f) => ({
    key: f.label,
    label: f.label,
    nota: `${inteiro.format(f.base)} municípios`,
    valores: f.celulas.map((c) => c.pct),
  }));

  const posGraduacao = dados.faixas[dados.faixas.length - 1];
  const semNenhum = posGraduacao.celulas[0];

  const fundamental = dados.faixas[0];
  const tripeFundamental = fundamental.celulas[fundamental.celulas.length - 1];
  const tripePos = posGraduacao.celulas[posGraduacao.celulas.length - 1];

  const footnote =
    `Cada linha soma 100% e é lida sobre a sua própria base, que está ao lado do rótulo — uma proporção sobre ` +
    `${inteiro.format(fundamental.base)} municípios não vale o mesmo que uma sobre ${inteiro.format(posGraduacao.base)}. ` +
    `A área da bolha acompanha o percentual, não o diâmetro. Das quatro colunas, só a do tripé completo se move com a ` +
    `escolaridade, de ${pct(tripeFundamental.pct)} a ${pct(tripePos.pct)}; a do "nenhum dos três" fica praticamente ` +
    `parada. Dos ${inteiro.format(dados.universo)} municípios da onda, ${dados.semInformacao} ficaram de fora por não ` +
    `terem declarado a escolaridade do titular — não-resposta não é evidência nem a favor nem contra o que se mede.`;
</script>

<MatrizBolhasChart
  {linhas}
  {colunas}
  title="A escolaridade do gestor quase não muda a institucionalização da cultura"
  subtitle="Municípios por número de instrumentos do tripé do SNC — conselho, fundo e plano de cultura — segundo a escolaridade do titular da pasta · MUNIC {dados.ano}"
  formatValue={pct}
  destaque={{
    valor: pct(semNenhum.pct),
    cor: marca.primaryVariant,
    texto: 'dos municípios com gestor pós-graduado não têm nenhum dos três instrumentos',
  }}
  {footnote}
  source="Fonte: Elaboração própria com base na MUNIC/IBGE, onda de {dados.ano}."
  {background}
  bind:svgEl
/>
