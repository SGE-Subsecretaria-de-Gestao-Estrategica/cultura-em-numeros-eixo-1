<script lang="ts">
  /**
   * O tripé institucional do SNC município a município — o mosaico dos 5.570,
   * cada um na cor do próprio grau de institucionalização, não da média do
   * seu estado. É a leitura mais granular da coleção da mesma pergunta que
   * `TripeUfChart` responde por UF.
   *
   * O achado que só esta granularidade mostra: quase 4 em cada 10 municípios
   * não têm nenhum dos três instrumentos — um número que o corte por UF
   * dilui, porque estados grandes com capitais bem institucionalizadas
   * escondem o interior sem nenhum dos três.
   */
  import MosaicoMunicipalChart from './MosaicoMunicipalChart.svelte';
  import { degrausDe, rampaVermelha } from './cores';
  import dados from '../data/gestao-municipios-2021.json';

  let {
    svgEl = $bindable(null),
    background,
  }: {
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  const inteiro = new Intl.NumberFormat('pt-BR');
  const decimal = new Intl.NumberFormat('pt-BR', { maximumFractionDigits: 1 });

  const valores: Record<string, number> = Object.fromEntries(
    Object.entries(dados.municipios).map(([codigo, m]) => [codigo, m.t]),
  );

  const total = Object.keys(dados.municipios).length;
  const contagem = [0, 0, 0, 0];
  for (const m of Object.values(dados.municipios)) contagem[m.t]++;
  const nenhum = contagem[0];
  const completo = contagem[3];

  /** Do mais claro (nenhum instrumento) ao mais escuro (tripé completo). */
  const rampa = degrausDe(rampaVermelha, 4).slice().reverse();

  const footnote =
    `Cada município na cor do número de instrumentos do tripé do SNC — conselho, fundo e plano de cultura — que ` +
    `tinha ativos em ${dados.ano}, não na cor agregada do seu estado. ${decimal.format((100 * nenhum) / total)}% ` +
    `dos municípios (${inteiro.format(nenhum)} de ${inteiro.format(total)}) não tinham nenhum dos três; ` +
    `${decimal.format((100 * completo) / total)}% tinham os três. Malha municipal do IBGE em projeção cônica ` +
    `equivalente de Albers.`;
</script>

<MosaicoMunicipalChart
  {valores}
  {rampa}
  quebras={[1, 2, 3]}
  rotulosClasses={['Nenhum instrumento', 'Um instrumento', 'Dois instrumentos', 'Tripé completo']}
  legendaTitulo="Instrumentos do tripé ativos:"
  formatValue={(v) => String(v)}
  title="Quase 4 em cada 10 municípios não têm nenhum instrumento do SNC ativo"
  subtitle="Municípios por número de instrumentos do tripé institucional — conselho, fundo e plano de cultura · MUNIC {dados.ano}"
  destaque={{
    valor: `${decimal.format((100 * nenhum) / total)}%`,
    cor: rampa[0],
    texto: 'dos municípios não têm conselho, fundo nem plano de cultura ativos',
  }}
  {footnote}
  source="Fonte: Elaboração própria com base na MUNIC/IBGE, onda de 2021, e na malha municipal do IBGE."
  {background}
  bind:svgEl
/>
