<script lang="ts">
  /**
   * As cinco fontes do investimento estadual em cultura, 2019–2025, uma linha
   * cada, no cartão das figuras de série histórica — o mesmo do tripé
   * institucional e da evolução federal.
   *
   * É a mesma tabela de `EstadualPorFonteChart`, que a desenha como colunas
   * empilhadas. A pilha responde quanto foi o total do ano e como ele se
   * repartiu; as linhas respondem outra coisa, que a pilha esconde: o que cada
   * fonte fez ao longo do tempo. Numa pilha, uma faixa que se move pode estar
   * crescendo ou apenas sendo empurrada pela de baixo — aqui cada trajetória é
   * lida contra o eixo, e não contra a vizinha.
   *
   * O que a figura mostra e a pilha não deixava ver:
   *
   * - o recurso próprio dos estados dobra na série, de R$ 3,3 bi a R$ 6,7 bi, e
   *   é ele quem carrega o total. As transferências federais entram e saem por
   *   cima disso.
   * - as três leis não se sucedem, se revezam: LAB 1 em 2020 e em nenhum outro
   *   ano, LPG de 2023 a 2025, PNAB a partir de 2024. Só 2024 tem duas ao mesmo
   *   tempo.
   * - a LPG desaba de R$ 1,4 bi para R$ 18 milhões em 2025. Não é queda de
   *   política: é uma lei de valor fechado, e 2025 é o resto do que sobrou
   *   dela. Quem assume no lugar é a PNAB, que sobe a R$ 1,2 bi no mesmo ano.
   *
   * A cor separa o dinheiro recorrente do extraordinário — azuis para o
   * recurso próprio e as emendas, vermelhos para as três leis, do mais claro
   * ao mais escuro na ordem em que entram. Ver `fonteMarcaColors`.
   *
   * Duas coisas que a série anual pede:
   *
   * - a linha se parte nos anos sem execução (`maxGap`). Zero aqui não é um
   *   valor medido, é ausência — a fonte não existia, ou não repassou nada
   *   àquele ente naquele ano —, e ligar 2020 a 2023 desenharia uma Aldir Blanc
   *   correndo por três anos em que ela não correu.
   * - a legenda no lugar do nome na ponta de cada linha: quatro das cinco
   *   fontes terminam empilhadas na faixa de baixo do plot, e quatro nomes ali
   *   disputariam o mesmo espaço em que as linhas já se cruzam.
   */
  import SerieHistoricaChart from './SerieHistoricaChart.svelte';
  import { fonteLabels, fonteMarcaColors } from './fontes';
  import estadual from '../data/estadual-por-fonte.json';

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

  const tabela = $derived(estadual[valores] as unknown as Ano[]);

  /** Bilhões: a unidade em que a figura inteira é escrita e medida. */
  const BI = 1e9;

  /** A série de uma fonte: só os anos em que ela pôs dinheiro — ver `maxGap`. */
  function serie(key: string): Serie {
    return {
      key,
      label: fonteLabels[key] ?? key,
      pontos: tabela
        .filter((ano) => Number(ano[key]) > 0)
        .map((ano) => ({ ano: Number(ano.label), pct: Number(ano[key]) / BI })),
    };
  }

  const series = $derived(estadual.keys.map(serie));

  const decimal = new Intl.NumberFormat('pt-BR', {
    minimumFractionDigits: 1,
    maximumFractionDigits: 1,
  });
  const inteiro = new Intl.NumberFormat('pt-BR', { maximumFractionDigits: 0 });

  /**
   * Abaixo de R$ 100 milhões o valor é escrito em milhões, e não em bilhões.
   *
   * A figura inteira está em bilhões, mas duas fontes vivem uma ordem de
   * grandeza abaixo — as emendas nunca passam de R$ 27 mi, e a LPG termina em
   * R$ 18 mi. Com uma casa decimal em bilhões, as duas sairiam como
   * "R$ 0,0 bi", que é a única coisa que o rótulo não pode dizer: que não há
   * valor ali. O corte fica em 0,1 porque é onde a casa decimal deixa de
   * distinguir.
   */
  const bi = (v: number) =>
    v < 0.1 ? `R$ ${inteiro.format(v * 1000)} mi` : `R$ ${decimal.format(v)} bi`;

  /**
   * Teto na unidade acima do maior valor, e não o múltiplo de 10 padrão do
   * cartão: nada passa de R$ 6,7 bi, e a dezena deixaria um terço do plot vazio.
   */
  const yMax = $derived(
    Math.ceil(Math.max(...series.flatMap((s) => s.pontos.map((p) => p.pct)))),
  );

  /**
   * Onde cada fonte é anotada.
   *
   * O recurso próprio leva rótulo em todo ano: é a série contínua da figura, e
   * com sete pontos os números cabem sem disputa — é ela que dá a escala
   * vertical a todas as outras, já que o eixo Y saiu.
   *
   * As transferências são anotadas só onde decidem alguma coisa: o ano único da
   * LAB 1, a entrada e o pico da LPG, a entrada e o segundo ano da PNAB. As
   * emendas recebem um número só — elas correm coladas ao eixo, onde não há
   * altura para dois, e o que a figura precisa dizer delas é a ordem de
   * grandeza. O ano é 2023, e não um dos dois últimos: é o último em que a
   * linha delas está sozinha lá embaixo, sem a PNAB por perto para o rótulo
   * escuro ser lido como dela.
   *
   * Ninguém é anotado em 2025 no rodapé do plot, e é o único ponto em que a
   * figura abre mão de um número que interessa: a LPG termina em R$ 18 mi e as
   * emendas, em R$ 27 mi, a nove milésimos de bilhão uma da outra. Nessa
   * distância os dois rótulos saem sobrepostos, e o de baixo cai por cima da
   * linha dos anos. Os dois valores estão na nota, onde cabem escritos por
   * extenso; o que fica na figura é a forma, que é o que ela sabe mostrar
   * melhor — uma linha despencando e outra correndo rente ao eixo.
   */
  const labelYears: Record<string, number[]> = {
    'Recurso Próprio (Estadual)': [2019, 2020, 2021, 2022, 2023, 2024, 2025],
    'Lei Aldir Blanc 1 (LAB 1)': [2020],
    'Lei Paulo Gustavo (LPG)': [2023, 2024],
    'PNAB (Aldir Blanc 2)': [2024, 2025],
    'Emendas Parlamentares (Cultura)': [2023],
  };

  const unidade = $derived(
    valores === 'real'
      ? `a preços médios de ${estadual.anoBaseDeflator}`
      : 'em valores nominais',
  );

  /** O deflator só se declara quando ele foi aplicado. */
  const fonte = $derived(
    'Fonte: Elaboração própria com base no SICONFI (MSC Orçamentária Estadual).' +
      (valores === 'real'
        ? ` Deflator: IPCA/SGS-BCB (série 433), a preços médios de ${estadual.anoBaseDeflator}.`
        : ''),
  );
</script>

<SerieHistoricaChart
  {series}
  colors={fonteMarcaColors}
  {yMax}
  {labelYears}
  maxGap={1}
  lineWidth={8.5}
  smooth
  legend
  hideYAxis
  xGuides
  formatValue={bi}
  title="Evolução do investimento estadual em cultura por fonte de recurso"
  subtitle={`Valores empenhados pelos estados e pelo Distrito Federal, fonte a fonte, em R$ bilhões ${unidade} · 2019–2025`}
  footnote={'LAB 1 = Lei Aldir Blanc 1 · LPG = Lei Paulo Gustavo · PNAB = Política Nacional Aldir Blanc, a Aldir Blanc 2. A linha se interrompe nos anos sem execução: as três leis de transferência não se sucedem, se revezam, e só 2024 tem duas ao mesmo tempo. A LAB 1 foi executada num ano só e por isso aparece como ponto, não como linha. Os R$ 18 milhões da LPG em 2025 são o resto de uma lei de valor fechado, não uma queda de política — quem assume no lugar dela é a PNAB, que sobe a R$ 1,2 bilhão no mesmo ano. As emendas parlamentares correm uma ordem de grandeza abaixo das demais fontes em todos os anos em que existem, de R$ 4 milhões em 2022 a R$ 27 milhões em 2025.'}
  source={fonte}
  {background}
  bind:svgEl
/>
