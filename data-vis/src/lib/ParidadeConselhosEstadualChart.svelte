<script lang="ts">
  /**
   * A paridade entre sociedade civil e poder público nos conselhos estaduais
   * ativos de cultura — uma linha só, entre 2018 e 2021: "Não Paritário" é o
   * complemento exato de "Paritário", e a proporção não mudou nada entre as
   * duas ondas — a linha é reta, e é isso que ela existe para mostrar.
   */
  import FaixaLinhasChart, { type Serie } from './FaixaLinhasChart.svelte';
  import { categoricaDe } from './cores';
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

  const ondas = dados.paridade.ondas;
  const anos = ondas.map((o) => Number(o.label));
  const final = ondas[ondas.length - 1] as unknown as Record<string, number> & { label: string };
  const primeira = ondas[0];
  const cor = categoricaDe(dados.paridade.categorias.length)[1];

  const series: Serie[] = [
    {
      key: 'paritario',
      cor,
      pontos: ondas.map((o) => ({
        ano: Number(o.label),
        valor: (o as unknown as Record<string, number>)['Paritário'],
      })),
      rotulos: anos,
      destaque: {
        valor: pct(final['Paritário']),
        cor,
        texto: `dos conselhos estaduais de cultura ativos são paritários em ${final.label}`,
      },
    },
  ];

  const footnote =
    `Cada ponto é a proporção dos conselhos estaduais ativos — as 27 UFs em ambas as ondas — com representação ` +
    `equilibrada entre sociedade civil e poder público, segundo a própria UF. A proporção não mudou entre as ` +
    `duas ondas.`;
</script>

<FaixaLinhasChart
  {series}
  title="Quase três em cada quatro conselhos estaduais de cultura são paritários"
  subtitle="Conselhos estaduais de cultura ativos com composição paritária · ESTADIC {primeira.label} e {final.label}"
  formatValue={pct}
  {footnote}
  source="Fonte: Elaboração própria com base na ESTADIC/IBGE, ondas de {primeira.label} e {final.label}."
  {background}
  bind:svgEl
/>
