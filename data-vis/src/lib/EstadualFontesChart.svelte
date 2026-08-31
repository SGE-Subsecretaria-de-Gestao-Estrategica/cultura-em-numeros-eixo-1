<script lang="ts">
  /**
   * O investimento estadual em duas faixas: o que os estados põem do próprio
   * orçamento e o que chega da União em repasse — a leitura de linhas da
   * Figura 5 da publicação, no estilo do primeiro print.
   *
   * As duas séries saem da mesma tabela por fonte usada pelas figuras
   * estaduais: o próprio é a fonte "Recurso Próprio (Estadual)", e os repasses
   * são todo o resto — LAB 1, LPG, PNAB e emendas parlamentares. É a separação
   * que o texto narra: os estados ampliaram o investimento próprio *mesmo com*
   * os repasses entrando em ondas.
   */
  import FaixaLinhasChart, { type Serie } from './FaixaLinhasChart.svelte';
  import { colors as marca } from './tokens';
  import estadual from '../data/estadual-por-fonte.json';

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
  const bi = (v: number) => `${decimal.format(v)} bi`;

  const PROPRIO = 'Recurso Próprio (Estadual)';

  const linhas = estadual.real.map((row) => {
    const total = estadual.keys.reduce(
      (soma, key) => soma + (row as unknown as Record<string, number>)[key],
      0,
    );
    const proprio = (row as unknown as Record<string, number>)[PROPRIO];
    return { ano: Number(row.label), proprio: proprio / 1e9, repasses: (total - proprio) / 1e9 };
  });

  const ultimoAno = linhas[linhas.length - 1].ano;
  const final = linhas[linhas.length - 1];

  const series: Serie[] = [
    {
      key: 'repasses',
      cor: marca.primary,
      pontos: linhas.map((l) => ({ ano: l.ano, valor: l.repasses })),
      rotulos: [2020, 2024],
      destaque: {
        valor: `R$ ${bi(final.repasses)}`,
        cor: marca.primaryVariant,
        texto: `de repasses federais aos estados em ${ultimoAno}`,
      },
    },
    {
      key: 'proprio',
      cor: marca.secondary,
      pontos: linhas.map((l) => ({ ano: l.ano, valor: l.proprio })),
      rotulos: [2019, 2023],
      abaixo: [2019],
      destaque: {
        valor: `R$ ${bi(final.proprio)}`,
        cor: marca.secondaryVariant,
        texto: `de recursos próprios dos estados em ${ultimoAno}`,
      },
    },
  ];
</script>

<FaixaLinhasChart
  {series}
  title="Investimento estadual em cultura: recursos próprios e repasses federais"
  subtitle="R$ bilhões, a preços médios de 2024 (IPCA) · de 2019 a {ultimoAno}"
  formatValue={bi}
  footnote="Repasses federais: Lei Aldir Blanc 1, Lei Paulo Gustavo, PNAB e emendas parlamentares executadas pelos estados — em 2024, 25,5% do total investido. Eles chegam em ondas: a LAB em 2020, a LPG em 2023, a PNAB desde 2024."
  source="Fonte: Elaboração própria com base na MSC/SICONFI, Função 13 (Cultura)."
  {background}
  bind:svgEl
/>
