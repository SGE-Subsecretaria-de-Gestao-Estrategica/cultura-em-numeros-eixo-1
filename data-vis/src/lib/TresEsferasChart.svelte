<script lang="ts">
  /**
   * O investimento público em cultura pelas três esferas, cada uma como uma
   * faixa grossa — a figura de abertura do capítulo de orçamento, no estilo do
   * primeiro print.
   *
   * As três séries somam recursos próprios e os repasses federais que cada
   * esfera executa, então as faixas contam também a história dos repasses: o
   * salto municipal de 2022 em diante é a LPG e a PNAB chegando na ponta.
   */
  import FaixaLinhasChart, { type Serie } from './FaixaLinhasChart.svelte';
  import { colors as marca } from './tokens';
  import dados from '../data/tres-esferas.json';

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

  const ultimoAno = dados.anos[dados.anos.length - 1];

  const porKey = Object.fromEntries(
    dados.series.map((s) => [
      s.key,
      dados.anos.map((ano, i) => ({ ano, valor: s.valores[i] })),
    ]),
  );

  const valorFinal = (key: string) => {
    const pontos = porKey[key];
    return `R$ ${bi(pontos[pontos.length - 1].valor)}`;
  };

  /**
   * Municipal por cima, que é a série que termina no topo; o rosa dos números
   * de destaque segue o print — as faixas quentes leem em rosa, a fria em azul.
   */
  const series: Serie[] = [
    {
      key: 'estadual',
      cor: marca.secondaryVariant,
      pontos: porKey.estadual,
      rotulos: [2019, 2022],
      abaixo: [2019],
      destaque: {
        valor: valorFinal('estadual'),
        cor: marca.primaryVariant,
        texto: `investidos pelos estados em ${ultimoAno}`,
      },
    },
    {
      key: 'federal',
      cor: marca.secondary,
      pontos: porKey.federal,
      rotulos: [2019, 2023],
      abaixo: [2023],
      destaque: {
        valor: valorFinal('federal'),
        cor: marca.secondaryVariant,
        texto: `de investimento federal pleno em ${ultimoAno}`,
      },
    },
    {
      key: 'municipal',
      cor: marca.primary,
      pontos: porKey.municipal,
      rotulos: [2019, 2020, 2021, 2023],
      destaque: {
        valor: valorFinal('municipal'),
        cor: marca.primaryVariant,
        texto: `investidos pelos municípios em ${ultimoAno}`,
      },
    },
  ];
</script>

<FaixaLinhasChart
  {series}
  title="Investimento público em cultura por esfera de governo"
  subtitle="R$ bilhões, a preços médios de 2024 (IPCA) · de 2019 a {ultimoAno}"
  formatValue={bi}
  footnote="Cada esfera soma recursos próprios e os repasses federais que ela executa — Lei Aldir Blanc, Lei Paulo Gustavo e PNAB. O investimento federal pleno inclui a renúncia fiscal da Lei Rouanet e os recursos da ANCINE."
  source="Fonte: Elaboração própria com base no SIOP, no SALIC, na ANCINE e na MSC/SICONFI."
  {background}
  bind:svgEl
/>
