<script lang="ts">
  /**
   * Quantos estados têm mecanismo próprio de renúncia fiscal para cultura —
   * uma linha só, entre 2018 e 2021: "Não" é o complemento exato de "Sim", e
   * duas colunas 100% empilhadas para duas categorias e duas ondas repetiriam
   * o mesmo par de números que a linha já mostra num traço.
   */
  import FaixaLinhasChart, { type Serie } from './FaixaLinhasChart.svelte';
  import { rampaRosa } from './cores';
  import dados from '../data/estadic-governanca.json';

  let {
    svgEl = $bindable(null),
    background,
  }: {
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  const decimal = new Intl.NumberFormat('pt-BR', { maximumFractionDigits: 1 });
  const inteiro = new Intl.NumberFormat('pt-BR');
  const pct = (v: number) => `${decimal.format(v)}%`;

  const ondas = dados.incentivo.ondas;
  const anos = ondas.map((o) => Number(o.label));
  const final = ondas[ondas.length - 1] as unknown as Record<string, number> & { label: string };
  const primeira = ondas[0];

  const series: Serie[] = [
    {
      key: 'sim',
      cor: rampaRosa[1],
      pontos: ondas.map((o) => ({
        ano: Number(o.label),
        valor: (o as unknown as Record<string, number>)['Sim'],
      })),
      rotulos: anos,
      destaque: {
        valor: pct(final['Sim']),
        cor: rampaRosa[1],
        texto: `dos estados têm lei própria de incentivo fiscal à cultura em ${final.label}`,
      },
    },
  ];

  const footnote = `Cada ponto é a proporção das ${inteiro.format(dados.universo)} UFs com o mecanismo ativo.`;
</script>

<FaixaLinhasChart
  {series}
  title="Só um em cada três estados tem lei própria de incentivo fiscal à cultura"
  subtitle="Estados com mecanismo estadual de renúncia fiscal para cultura · ESTADIC {primeira.label} e {final.label}"
  formatValue={pct}
  {footnote}
  source="Fonte: Elaboração própria com base na ESTADIC/IBGE, ondas de {primeira.label} e {final.label}."
  {background}
  bind:svgEl
/>
