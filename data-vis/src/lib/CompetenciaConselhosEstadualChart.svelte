<script lang="ts">
  /**
   * A natureza institucional dos conselhos estaduais ativos de cultura — se
   * deliberam, se só consultam, ou se normatizam e fiscalizam — 2018 contra
   * 2021.
   *
   * Duas ondas e três categorias não ordenadas entre si: uma coluna 100%
   * empilhada mostraria os mesmos dois pares de números duas vezes, um do
   * lado do outro, e pediria ao leitor subtrair para achar o que mudou. Aqui
   * o traço entre os dois pontos mede a distância direto — o Consultivo nem
   * tem traço, porque não mudou nada; o Normativo/Fiscalizador é o único com
   * um traço de verdade, de zero a 3,7%.
   */
  import AntesDepoisChart, { type LinhaAntesDepois } from './AntesDepoisChart.svelte';
  import { rampaRoxa } from './cores';
  import dados from '../data/estadic-governanca.json';

  let {
    svgEl = $bindable(null),
    background,
  }: {
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  const decimal = new Intl.NumberFormat('pt-BR', { maximumFractionDigits: 1 });
  const pct = (v: number) => `${decimal.format(v)}%`;

  const [onda2018, onda2021] = dados.competencia.ondas;

  const linhas: LinhaAntesDepois[] = dados.competencia.categorias.map((cat) => ({
    key: cat,
    label: cat,
    antes: (onda2018 as unknown as Record<string, number>)[cat],
    depois: (onda2021 as unknown as Record<string, number>)[cat],
  }));

  const footnote =
    `Cada valor é a proporção dos conselhos estaduais ativos que declararam aquela natureza — as 27 UFs em ` +
    `ambas as ondas. A onda de 2014 não entra: o módulo daquele ano não perguntou a competência do conselho. ` +
    `"Normativo / Fiscalizador" reúne os conselhos que regulam ou fiscalizam sem deliberar sobre recursos.`;
</script>

<AntesDepoisChart
  {linhas}
  corAntes={rampaRoxa[3]}
  corDepois={rampaRoxa[1]}
  labelAntes={String(onda2018.label)}
  labelDepois={String(onda2021.label)}
  formatValue={pct}
  title="A natureza dos conselhos estaduais de cultura quase não mudou entre 2018 e 2021"
  subtitle="Natureza declarada dos conselhos estaduais de cultura ativos · ESTADIC 2018 e 2021"
  {footnote}
  source="Fonte: Elaboração própria com base na ESTADIC/IBGE, ondas de 2018 e 2021."
  {background}
  bind:svgEl
/>
