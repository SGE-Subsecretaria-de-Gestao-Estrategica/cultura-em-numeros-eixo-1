<script lang="ts">
  /**
   * As oito fontes do investimento federal em cultura, 2003–2025, uma linha
   * cada, no cartão das figuras de série histórica — o mesmo do tripé
   * institucional.
   *
   * É a tabela `Federal · Tabela por fonte` desenhada: os mesmos oito valores
   * por ano, nas mesmas cores, lidos como trajetória em vez de como grade. O
   * combo em `EvolucaoFederalChart` agrupa as oito em três por natureza
   * institucional; aqui elas ficam separadas, que é o que deixa ver quando cada
   * uma entra, quanto dura e quanto pesa.
   *
   * Quatro coisas que a série anual pede e a de ondas não pedia:
   *
   * - a linha se parte nos anos sem execução (`maxGap`). O MinC some de 2019 a
   *   2022, e o buraco é o dado: ligar 2018 a 2023 desenharia um ministério que
   *   não existia.
   * - o nome de cada fonte vai à ponta da sua linha, não à margem direita —
   *   três delas acabam antes de 2025.
   * - os valores são escritos em poucos anos, escolhidos por série: 23 anos por
   *   8 fontes dariam mais de cem rótulos.
   * - o eixo X marca oito dos 23 anos.
   */
  import SerieHistoricaChart from './SerieHistoricaChart.svelte';
  import { fonteFederalLabels, fonteFederalLineColors } from './fontes';
  import federal from '../data/federal-por-fonte.json';

  let {
    /** `real` está a preços médios de 2024; `nominal`, em reais correntes. */
    valores = 'real',
    svgEl = $bindable(null),
    background,
  }: {
    valores?: 'real' | 'nominal';
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  type Ano = { label: string } & Record<string, number | string>;
  type Ponto = { ano: number; pct: number };
  type Serie = { key: string; label: string; pontos: Ponto[] };

  const tabela = $derived(federal[valores] as unknown as Ano[]);

  /** Bilhões: a unidade em que a figura inteira é escrita e medida. */
  const BI = 1e9;

  /**
   * A série de uma fonte: só os anos em que ela executou alguma coisa.
   *
   * Zero aqui não é um valor medido, é ausência — a fonte não existia, ou o
   * empenho líquido foi nulo (o FSA em 2014). É a mesma convenção do traço na
   * tabela por fonte. Os anos ausentes viram vão, e `maxGap` parte a linha
   * neles em vez de atravessá-los.
   */
  function serie(key: string): Serie {
    return {
      key,
      label: fonteFederalLabels[key] ?? key,
      pontos: tabela
        .filter((ano) => Number(ano[key]) > 0)
        .map((ano) => ({ ano: Number(ano.label), pct: Number(ano[key]) / BI })),
    };
  }

  const series = $derived(federal.keys.map(serie));
  const colorsPorFonte = fonteFederalLineColors(federal.keys);
  const colors = federal.keys.map((k) => colorsPorFonte[k]);

  const decimal = new Intl.NumberFormat('pt-BR', {
    minimumFractionDigits: 1,
    maximumFractionDigits: 1,
  });

  /** Uma casa decimal: a escala do gráfico não sustenta mais precisão. */
  const bi = (v: number) => `R$ ${decimal.format(v)} bi`;

  /**
   * Teto na unidade acima do maior valor, e não o múltiplo de 10 que o cartão
   * usa por omissão: nenhuma fonte isolada passa de R$ 4,3 bi, e a dezena
   * deixaria mais da metade do plot vazia.
   */
  const yMax = $derived(
    Math.ceil(Math.max(...series.flatMap((s) => s.pontos.map((p) => p.pct)))),
  );

  /**
   * Os valores escritos dentro do plot, fonte por fonte.
   *
   * Com oito séries em 23 anos, rotular tudo daria mais de cem números. Aqui
   * cada fonte recebe rótulo só onde ela decide alguma coisa: o pico do MinC em
   * 2013, o ano único da Aldir Blanc 1 e o da Paulo Gustavo, a entrada da PNAB
   * e o ano em que a Rouanet chega ao seu máximo recente.
   *
   * As fontes pequenas — ANCINE, FSA — ficam sem rótulo de propósito: elas
   * correm rentes ao eixo, onde não há altura para um número, e o que a figura
   * diz delas é a ordem de grandeza, que a escala já dá.
   */
  const labelYears: Record<string, number[]> = {
    'Ministério da Cultura (Órgão 42000)': [2013],
    'Lei Rouanet': [2024],
    'Lei Aldir Blanc 1': [2020],
    'Lei Paulo Gustavo': [2023],
    'PNAB (UO 73120)': [2023],
    'Outros Órgãos (Cidadania/Turismo)': [2019],
  };

  /**
   * Oito dos 23 anos no eixo. Os anos anotados estão entre eles, para o rótulo
   * de valor cair sobre uma marca do eixo e não no meio de um vão; o resto é o
   * espaçamento mais regular que sobra sem encostar em 2025.
   */
  const tickYears = [2003, 2006, 2010, 2013, 2016, 2019, 2023, 2025];

  const unidade = $derived(
    valores === 'real' ? 'a preços médios de 2024' : 'em valores nominais',
  );

  /**
   * O vale da PNAB em 2024 é o único ponto da figura que se lê como erro — a
   * linha desce ao eixo entre dois anos de bilhões — e é execução real. Os três
   * números saem da tabela para valerem nas duas versões, deflacionada e
   * nominal.
   */
  const valePnab = $derived.by(() => {
    const pnab = series.find((s) => s.key === 'PNAB (UO 73120)');
    const em = (ano: number) => pnab?.pontos.find((p) => p.ano === ano)?.pct;
    const [antes, vale, depois] = [em(2023), em(2024), em(2025)];
    if (antes === undefined || vale === undefined || depois === undefined) return '';
    const milhoes = Math.round(vale * 1000);
    return ` O vale da PNAB em 2024 é execução real de R$ ${milhoes} milhões, entre ${bi(antes)} em 2023 e ${bi(depois)} em 2025.`;
  });

  /** O deflator só se declara quando ele foi aplicado. */
  const fonte = $derived(
    'Fonte: Elaboração própria com base no SIOP, no SALIC e na ANCINE.' +
      (valores === 'real' ? ' Deflator: IPCA, a preços médios de 2024.' : ''),
  );
</script>

<SerieHistoricaChart
  {series}
  {colors}
  {yMax}
  {labelYears}
  {tickYears}
  maxGap={1}
  lineWidth={8.5}
  smooth
  legend
  hideYAxis
  xGuides
  formatValue={bi}
  title="Evolução do investimento federal em cultura por fonte de recurso"
  subtitle={`Gasto federal pleno em cultura, fonte a fonte, em R$ bilhões ${unidade}.`}
  footnote={'A linha se interrompe nos anos sem execução. O MinC não aparece de 2019 a 2022 porque foi extinto, e nesses quatro anos a despesa da pasta corre por outros órgãos — as duas linhas são o mesmo dinheiro trocando de casa. O FSA fica de fora de 2014, quando o empenho líquido foi nulo. A Lei Aldir Blanc 1 e a Lei Paulo Gustavo foram executadas num ano só cada uma, e por isso aparecem como ponto, não como linha.' +
    valePnab}
  source={fonte}
  {background}
  bind:svgEl
/>
