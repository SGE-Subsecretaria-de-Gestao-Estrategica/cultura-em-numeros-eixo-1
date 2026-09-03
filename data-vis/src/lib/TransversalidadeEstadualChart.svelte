<script lang="ts">
  /**
   * Cultura entrando pela porta de outras políticas — não como orçamento
   * próprio, mas como ação integrada a primeira infância, mulheres e
   * igualdade racial. As cinco perguntas vêm de módulos transversais que a
   * ESTADIC só passou a fazer em 2023 e 2024, por isso não há série histórica
   * aqui: é um retrato, não uma evolução.
   *
   * O ranking, não a categoria, ordena as barras — a mesma decisão de
   * `ConcentracaoChart`: a forma da figura é o próprio achado, e reordenar
   * pela pergunta em vez do valor esconderia que a articulação com política
   * para mulheres é a mais rara das cinco.
   */
  import BarraRankingChart, { type LinhaRanking } from './BarraRankingChart.svelte';
  import { rampaRoxa } from './cores';
  import dados from '../data/estadic-governanca.json';

  let {
    svgEl = $bindable(null),
    background,
  }: {
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  const decimal = new Intl.NumberFormat('pt-BR', { maximumFractionDigits: 0 });
  const inteiro = new Intl.NumberFormat('pt-BR');

  const ordenado = [...dados.transversalidade].sort((a, b) => b.pct - a.pct);
  const linhas: LinhaRanking[] = ordenado.map((item) => ({
    key: item.key,
    label: `${item.label} (${item.ano})`,
    valor: item.pct,
    rotuloValor: `${inteiro.format(item.n)} UFs (${decimal.format(item.pct)}%)`,
  }));

  const maior = ordenado[0];
  const menor = ordenado[ordenado.length - 1];

  const footnote =
    `Proporção das ${inteiro.format(dados.universo)} UFs com a ação declarada. As cinco perguntas vêm de ` +
    'módulos transversais aplicados uma única vez, em 2023 (primeira infância e política para mulheres) ou em ' +
    '2024 (igualdade racial) — não há onda anterior para comparar.';
</script>

<BarraRankingChart
  {linhas}
  cor={rampaRoxa[1]}
  title="A cultura articula mais com a primeira infância do que com a igualdade racial ou as mulheres"
  subtitle="Estados com ação cultural integrada a outras políticas sociais · ESTADIC 2023-2024"
  formatValue={(v) => `${decimal.format(v)}%`}
  destaque={{
    valor: `${decimal.format(maior.pct)}%`,
    cor: rampaRoxa[1],
    texto: `dos estados já têm ${maior.label.toLowerCase()}, a mais frequente das cinco frentes`,
  }}
  {footnote}
  source="Fonte: Elaboração própria com base na ESTADIC/IBGE, módulos transversais de 2023 e 2024."
  {background}
  bind:svgEl
/>
