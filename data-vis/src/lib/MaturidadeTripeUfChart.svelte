<script lang="ts">
  /**
   * A maturidade do tripé institucional do SNC nos estados, sobre a malha das
   * UFs — a leitura territorial de `TripeEstadualChart`.
   *
   * Nenhum estado aparece com "nenhum instrumento": as 27 UFs já têm conselho
   * ativo em 2021 (`TripeEstadualChart` mostra a série completa), então o
   * terceiro degrau da classificação original do capítulo fica vazio por
   * construção. A figura desenha só os dois que de fato ocorrem.
   */
  import CoropletoUfChart from './CoropletoUfChart.svelte';
  import { rampaVerde } from './cores';
  import dados from '../data/estadic-governanca.json';

  let {
    svgEl = $bindable(null),
    background,
  }: {
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  const valores = dados.mapas2021.ufs.map((u) => ({ uf: u.uf, valor: u.statusTripe }));
  const completos = dados.mapas2021.ufs.filter((u) => u.statusTripe === 3).length;
</script>

<CoropletoUfChart
  {valores}
  rampa={[rampaVerde[4], rampaVerde[2], rampaVerde[0]]}
  quebras={[2, 3]}
  rotulosClasses={['Só o conselho ativo', 'Dois dos três instrumentos', 'Tripé completo']}
  legendaTitulo="Situação do tripé:"
  formatValue={(v) => String(v)}
  title="Maturidade do tripé institucional do SNC nos estados"
  subtitle="Consolidação de conselho, fundo e plano estaduais de cultura · ESTADIC 2021"
  destaque={{
    valor: `${completos} de 27`,
    cor: rampaVerde[0],
    texto: 'estados já têm os três instrumentos do tripé ativos',
  }}
  footnote="Classificação pelo número de instrumentos ativos — conselho, fundo e plano de cultura — entre os três que o SNC trata como núcleo duro da institucionalização. Nenhum estado tem zero instrumentos ativos: o conselho já é universal desde 2018."
  source="Fonte: Elaboração própria com base na ESTADIC/IBGE, onda de 2021."
  {background}
  bind:svgEl
/>
