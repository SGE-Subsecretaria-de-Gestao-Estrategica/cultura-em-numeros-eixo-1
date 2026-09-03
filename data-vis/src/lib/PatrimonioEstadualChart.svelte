<script lang="ts">
  /**
   * A legislação estadual de proteção ao patrimônio cultural — tombamento e
   * acautelamento —, que em 2021 já cobre as 27 UFs.
   *
   * Uma série só, diferente do tripé ao lado: aqui a pergunta é uma lei, não
   * três instrumentos, e a figura mede a mesma coisa que
   * `EstadualFontesChart` mede em dinheiro — quão perto do universo total a
   * política já chegou.
   */
  import FaixaLinhasChart, { type Serie } from './FaixaLinhasChart.svelte';
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
  const pct = (v: number) => `${decimal.format(v)}%`;

  const anos = dados.patrimonio.anos;
  const ultimo = dados.patrimonio.pontos[dados.patrimonio.pontos.length - 1];

  const series: Serie[] = [
    {
      key: 'patrimonio',
      cor: rampaRoxa[1],
      pontos: dados.patrimonio.pontos.map((p) => ({ ano: p.ano, valor: p.taxa })),
      rotulos: anos,
      destaque: {
        valor: pct(ultimo.taxa),
        cor: rampaRoxa[1],
        texto: `das UFs têm lei própria de tombamento de patrimônio cultural em ${ultimo.ano}`,
      },
    },
  ];

  const footnote =
    'Cada ponto é a proporção das 27 UFs com legislação específica de tombamento e acautelamento de patrimônio ' +
    'cultural ativa naquela onda da ESTADIC.';
</script>

<FaixaLinhasChart
  {series}
  title="Toda unidade da federação já tem lei própria de patrimônio cultural"
  subtitle="Estados com legislação de tombamento de patrimônio cultural ativa · ESTADIC 2014, 2018 e 2021"
  formatValue={pct}
  {footnote}
  source="Fonte: Elaboração própria com base na ESTADIC/IBGE, ondas de 2014 a 2021."
  {background}
  bind:svgEl
/>
