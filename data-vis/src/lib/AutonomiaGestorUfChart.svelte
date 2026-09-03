<script lang="ts">
  /**
   * A autonomia institucional do órgão gestor estadual, sobre a malha das
   * UFs — a leitura territorial de `OrgaoGestorEstadualChart`.
   *
   * Só duas classes aparecem em 2021: nenhuma UF caiu em "setor subordinado",
   * o grau mais baixo de autonomia que a classificação original prevê — a
   * mesma simplificação de `MaturidadeTripeUfChart`, desenhar só o que o ano
   * de fato tem.
   */
  import CoropletoUfChart from './CoropletoUfChart.svelte';
  import { rampaAzul } from './cores';
  import dados from '../data/estadic-governanca.json';

  let {
    svgEl = $bindable(null),
    background,
  }: {
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  const valores = dados.mapas2021.ufs
    .filter((u) => u.orgaoOrdinal !== null)
    .map((u) => ({ uf: u.uf, valor: u.orgaoOrdinal as number }));
  const exclusivas = dados.mapas2021.ufs.filter((u) => u.orgaoOrdinal === 1).length;
</script>

<CoropletoUfChart
  {valores}
  rampa={[rampaAzul[3], rampaAzul[1]]}
  quebras={[1]}
  rotulosClasses={['Secretaria conjunta', 'Secretaria exclusiva / fundação']}
  legendaTitulo="Estrutura do órgão gestor:"
  formatValue={(v) => String(v)}
  title="Autonomia do órgão gestor estadual de cultura"
  subtitle="Tipologia das pastas que respondem pela cultura nos estados · ESTADIC 2021"
  destaque={{
    valor: `${exclusivas} de 27`,
    cor: rampaAzul[1],
    texto: 'estados mantêm secretaria própria e exclusiva de cultura',
  }}
  footnote="Nenhuma UF caiu em 'setor subordinado ou sem estrutura' — o grau mais baixo de autonomia — na onda de 2021; o único caso do painel foi o Tocantins em 2018, já revertido."
  source="Fonte: Elaboração própria com base na ESTADIC/IBGE, onda de 2021."
  {background}
  bind:svgEl
/>
