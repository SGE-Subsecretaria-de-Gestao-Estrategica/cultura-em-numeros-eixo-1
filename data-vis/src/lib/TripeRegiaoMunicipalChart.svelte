<script lang="ts">
  /**
   * O tripé institucional completo — conselho, fundo e plano juntos — por
   * macrorregião, o corte que falta a `TripeUfChart`: a mesma pergunta, com o
   * denominador que deixa comparar cinco números em vez de vinte e sete.
   *
   * A ordem dos painéis é o ranking de 2021, não a ordem alfabética: o Sul
   * ultrapassa o Sudeste na última onda, depois de partir atrás dele em todas
   * as anteriores — a única troca de posição da série. Norte e Nordeste
   * seguem na cauda nas quatro ondas.
   *
   * A linha fantasma atrás de cada painel é a média nacional ponderada pelo
   * número de municípios de cada região — não a média simples das cinco —,
   * para não inflar Norte e Centro-Oeste, que têm menos municípios, no
   * cálculo do país inteiro.
   */
  import PequenosMultiplosChart, { type PainelSerie } from './PequenosMultiplosChart.svelte';
  import { colors as marca } from './tokens';
  import dados from '../data/gestao-municipal.json';

  let {
    svgEl = $bindable(null),
    background,
  }: {
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  const decimal = new Intl.NumberFormat('pt-BR', { maximumFractionDigits: 1 });
  const pct = (v: number) => `${decimal.format(v)}%`;

  const anos = dados.tripeRegiao.ondas.map((o) => o.ano);

  const porRegiao = (regiao: string) =>
    dados.tripeRegiao.ondas.map((o) => o.regioes.find((r) => r.regiao === regiao)!);

  const regioes = dados.tripeRegiao.ondas[0].regioes.map((r) => r.regiao);
  const ultimaOnda = dados.tripeRegiao.ondas[dados.tripeRegiao.ondas.length - 1];

  const ordenadas = [...regioes].sort((a, b) => {
    const va = ultimaOnda.regioes.find((r) => r.regiao === a)!.completo;
    const vb = ultimaOnda.regioes.find((r) => r.regiao === b)!.completo;
    return vb - va;
  });

  const paineis: PainelSerie[] = ordenadas.map((regiao) => {
    const serie = porRegiao(regiao);
    return {
      key: regiao,
      label: regiao,
      valores: serie.map((r) => r.completo),
      nota: `${serie[serie.length - 1].base} municípios`,
    };
  });

  /** Média nacional de cada onda, ponderada pela base de municípios de cada região. */
  const referencia = dados.tripeRegiao.ondas.map((o) => {
    const totalBase = o.regioes.reduce((soma, r) => soma + r.base, 0);
    const somaCompleto = o.regioes.reduce((soma, r) => soma + (r.completo / 100) * r.base, 0);
    return (100 * somaCompleto) / totalBase;
  });

  const primeira = ordenadas[0];
  const ultima = ordenadas[ordenadas.length - 1];
  const valorPrimeira = ultimaOnda.regioes.find((r) => r.regiao === primeira)!.completo;
  const valorUltima = ultimaOnda.regioes.find((r) => r.regiao === ultima)!.completo;

  const footnote =
    `Municípios com conselho, fundo e plano de cultura ativos ao mesmo tempo, sobre o total de municípios da ` +
    `região. A linha cinza é a média nacional ponderada pelo número de municípios de cada região, que em ` +
    `${ultimaOnda.ano} é ${pct(referencia[referencia.length - 1])}. Entre ${primeira} (${pct(valorPrimeira)}) e ` +
    `${ultima} (${pct(valorUltima)}) há uma distância de ${decimal.format(valorPrimeira - valorUltima)} pontos.`;
</script>

<PequenosMultiplosChart
  {anos}
  {paineis}
  {referencia}
  labelReferencia="Brasil"
  cor={marca.primary}
  corMarcador={marca.primaryVariant}
  formatValue={pct}
  rotulos={anos}
  title="O Sul ultrapassa o Sudeste na institucionalização plena da cultura em 2021"
  subtitle="Municípios com o tripé institucional completo, por macrorregião · MUNIC 2006 a 2021"
  {footnote}
  source="Fonte: Elaboração própria com base na MUNIC/IBGE, ondas de 2006 a 2021."
  {background}
  bind:svgEl
/>
