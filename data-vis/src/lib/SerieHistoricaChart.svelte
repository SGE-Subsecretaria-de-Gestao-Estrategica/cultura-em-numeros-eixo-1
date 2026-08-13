<script lang="ts">
  /**
   * Séries percentuais medidas em ondas de pesquisa, uma linha por indicador.
   *
   * A MUNIC não é anual: as ondas de 2006, 2014, 2018 e 2021 estão a 8, 4 e 3
   * anos de distância. O eixo é linear no ano, não uma banda por onda, para que
   * a inclinação de cada trecho signifique ritmo de mudança — numa banda, o
   * salto de 2006 a 2014 pareceria tão rápido quanto o de 2018 a 2021.
   *
   * As séries são rotuladas na ponta direita em vez de numa legenda: são poucas
   * e chegam bem separadas, então o nome ao lado da linha poupa o leitor de ir
   * e voltar até uma legenda para saber qual é qual.
   *
   * Duas variantes, ver `variant`: a fina, para séries que chegam agrupadas, e
   * a de faixa, para poucas séries bem separadas — traço grosso, tudo rotulado
   * dentro do plot e um bloco de leitura na ponta de cada linha.
   */
  import { curveLinear, curveMonotoneX, color as d3color, line, scaleLinear } from 'd3';
  import {
    Axis,
    Chart,
    DefaultTheme,
    categorical8,
    getPillarTheme,
    resolveThemeStyle,
    Text,
    type ChartDimensions,
    type ChartTheme,
  } from 'sniic-design-system';
  import TextLines from './TextLines.svelte';
  import {
    a4Scale,
    fontFamily,
    fontSize as scale,
    measureLabel,
    tickLabelProps,
    wrapText,
  } from './tokens';

  /**
   * Um ponto da série: o ano da onda e o percentual medido nela. `n` e `base`
   * são o numerador e o denominador desse percentual — opcionais, e usados só
   * pela variante de faixa, que os traz para dentro do gráfico.
   */
  export type Ponto = { ano: number; pct: number; n?: number; base?: number };
  export type Serie = { key: string; label: string; pontos: Ponto[] };

  /**
   * `linha` — traço de 2 px, grade horizontal, eixo Y percentual. Aguenta
   * séries que se aproximam ou se agrupam, porque a marca é fina.
   *
   * `faixa` — traço grosso de ponta arredondada, grade vertical nas ondas e
   * nenhum eixo Y: com todos os pontos rotulados, a escala vertical vira
   * redundante, e o espaço que ela ocupava vai para o plot e para o bloco de
   * leitura na ponta de cada linha. Pede séries poucas e separadas.
   */
  export type Variant = 'linha' | 'faixa';

  interface Props {
    series: Serie[];
    title: string;
    subtitle?: string;
    footnote?: string;
    source?: string;
    /**
     * Cores na ordem de `series`; por omissão, a paleta categórica do DS. A
     * lista é percorrida ciclicamente, então uma cor só pinta todas as séries.
     */
    colors?: readonly string[];
    /**
     * Cor dos marcadores na variante de faixa. Por omissão, a cor da própria
     * série um tom abaixo. Uma cor fixa aqui é o que permite desenhar todas as
     * séries numa cor só sem perder os instantes de medição de vista.
     */
    markerColor?: string;
    /** Cor do valor da última onda, no bloco de ponta. Por omissão, a da série. */
    endValueColor?: string;
    /** Teto do eixo; por omissão, o próximo múltiplo de 10 acima do maior valor. */
    yMax?: number;
    /** Peso da marca e o que cabe dentro do plot — ver `Variant`. */
    variant?: Variant;
    /**
     * O que os rótulos dentro do plot dizem: o percentual medido ou o número
     * absoluto por trás dele (`n`). Com a régua de bolinhas ligada, o plot fica
     * com os absolutos e a régua com os percentuais, e o gráfico diz as duas
     * coisas sem repetir nenhuma.
     */
    valueFormat?: 'pct' | 'abs';
    /**
     * Uma faixa horizontal por série, igualmente espaçadas, em vez de todas na
     * mesma escala vertical.
     *
     * Para séries que se amontoam — museu e teatro a 0,7 ponto de distância num
     * eixo que vai a 100% — a escala compartilhada empilha umas sobre as outras
     * e sobra plot vazio no meio. Separadas, cada uma ocupa a sua faixa e a
     * distância entre elas passa a ser sempre a mesma.
     *
     * A escala vertical continua **uma só**, em unidades por ponto percentual:
     * o que muda entre as faixas é o ponto de partida, não o quanto vale um
     * ponto. Sem isso, a variação de 1,8 ponto do cinema desenharia a mesma
     * montanha que os 8,8 pontos das bibliotecas.
     */
    rowPerSeries?: boolean;
    /**
     * Régua de bolinhas abaixo do plot: uma linha por série, um círculo por
     * onda dimensionado pelo percentual, com o percentual escrito acima.
     */
    dotStrip?: boolean;
    /** Frase que apresenta a régua de bolinhas, acima dela. */
    dotStripLead?: string;
    /**
     * Terceira linha do bloco de ponta, na variante de faixa: o que o valor
     * final esconde. Por omissão, o denominador — ou `n de base`, quando o
     * plot está em percentual.
     */
    endNote?: (serie: Serie, ultimo: Ponto) => string | undefined;
    /** Substantivo contado por `n` e `base` — "municípios", "estados". */
    unit?: string;
    /**
     * Largura intrínseca, em unidades de SVG. O tipo é absoluto nessas unidades,
     * então é isto que fixa o tamanho impresso dos rótulos — o cartão inteiro
     * escala para a largura física em que for colocado. Dimensionado para a
     * coluna de texto de um A4 retrato.
     */
    width?: number;
    /** Sobrepõe a altura que o cartão calcula para si. */
    height?: number;
    /** Re-diagrama na largura do contêiner em vez de escalar o cartão. */
    responsive?: boolean;
    /** Paleta do pilar com que o gráfico é tematizado — Eixo 1. */
    pillar?: number;
    /** `null` remove o cartão (fundo e borda), para exportar sobre a página. */
    background?: string | null;
    /** Bindable — o `<svg>` renderizado, para `downloadSvg`. */
    svgEl?: SVGSVGElement | null;
  }

  let {
    series,
    title,
    subtitle,
    footnote,
    source,
    colors = categorical8,
    markerColor,
    endValueColor,
    yMax,
    variant = 'linha',
    valueFormat = 'pct',
    rowPerSeries = false,
    dotStrip = false,
    dotStripLead,
    endNote,
    unit = 'municípios',
    width = 1368,
    height,
    responsive = false,
    pillar = 1,
    background,
    svgEl = $bindable(null),
  }: Props = $props();

  const faixa = $derived(variant === 'faixa');

  /**
   * Tudo abaixo é escrito contra `fontSize.md` e multiplicado por isto — tipo e
   * cromo juntos — para o cartão imprimir nos mesmos tamanhos das figuras A4 do
   * RibbonChart, qualquer que seja a largura em que for escrito.
   */
  const k = $derived(a4Scale(width));

  const TITLE_FONT_SIZE = 14;

  const type = $derived({
    title: TITLE_FONT_SIZE * k,
    /** Valor final, no topo do bloco de ponta: a maior marca dentro do plot. */
    destaque: 18 * k,
    lg: scale.lg * k,
    md: scale.md * k,
    /** Rótulo de valor sobre o marcador — maior na faixa, que tem espaço. */
    dado: (faixa ? 11.5 : scale.xs) * k,
    sm: scale.sm * k,
    xs: scale.xs * k,
  });

  const theme = $derived(getPillarTheme(pillar));
  const palette = $derived(theme.palette);

  const seriesColor = (index: number) => colors[index % colors.length];

  /**
   * O marcador é a mesma cor um tom abaixo, como no gráfico de referência: numa
   * faixa grossa, um ponto da própria cor some dentro dela, e um ponto branco
   * abriria um furo na linha. `markerColor` substitui esse tom por uma cor fixa.
   */
  const tomDoMarcador = (c: string) =>
    markerColor ?? d3color(c)?.darker(0.6).formatHex() ?? c;

  const anos = $derived([...new Set(series.flatMap((s) => s.pontos.map((p) => p.ano)))].sort());

  /**
   * O traçado de uma série.
   *
   * Na faixa a linha é suavizada, como no gráfico de referência: com faixas
   * grossas, o vértice em quina de uma polilinha vira um bico duro e chama
   * atenção para o instante da medição, que é justamente o que não se mediu —
   * entre duas ondas da MUNIC não há dado nenhum.
   *
   * A interpolação é monotônica, e não uma spline qualquer: ela nunca
   * ultrapassa os valores medidos. Uma Catmull-Rom passaria abaixo dos 8,4% de
   * 2014 no vale do Plano de Cultura, desenhando um mínimo que a pesquisa não
   * encontrou. Aqui a curva só arredonda o caminho entre pontos reais.
   */
  const tracado = $derived(
    (xScale: (ano: number) => number, yScale: (pct: number) => number) =>
      line<Ponto>()
        .x((p) => xScale(p.ano))
        .y((p) => yScale(p.pct))
        .curve(faixa ? curveMonotoneX : curveLinear),
  );

  const ultimoAno = $derived(anos[anos.length - 1]);

  const inteiro = new Intl.NumberFormat('pt-BR');
  const decimal = new Intl.NumberFormat('pt-BR', {
    minimumFractionDigits: 1,
    maximumFractionDigits: 1,
  });
  const pct = (v: number) => `${decimal.format(v)}%`;

  /**
   * Contagem em milhares: `2.352` vira `2,4 mil`.
   *
   * O rótulo dentro do gráfico é para dar ordem de grandeza de relance, e a
   * casa das unidades não ajuda nisso — quatro dígitos custam mais leitura do
   * que informam. Abaixo de mil não há o que abreviar, e `0,9 mil` seria uma
   * volta a mais para dizer `948`.
   */
  const abreviado = (v: number) =>
    v < 1000 ? inteiro.format(v) : `${decimal.format(v / 1000)} mil`;

  /**
   * O que um ponto diz dentro do plot.
   *
   * Em `abs` é o número de municípios, e não a proporção: com a régua de
   * bolinhas embaixo carregando os percentuais, repetir a proporção aqui gastaria
   * o rótulo duas vezes com a mesma informação. Um ponto sem `n` cai no
   * percentual, que é o que ele tem.
   */
  const rotuloDoPonto = (ponto: Ponto) =>
    valueFormat === 'abs' && ponto.n !== undefined ? abreviado(ponto.n) : pct(ponto.pct);

  /**
   * Terceira linha do bloco de ponta: o denominador do valor final.
   *
   * Com o plot em absolutos, o bloco já mostra `2,8 mil` e falta dizer de
   * quantos — `de 5.570 municípios`. Em percentual falta o contrário, o tamanho
   * absoluto que a proporção esconde.
   *
   * O denominador vem por extenso mesmo com os valores abreviados: ele não é
   * uma medida, é o universo da pesquisa, e 5.570 é o número que o leitor
   * reconhece. Abreviá-lo para `5,6 mil` custaria essa âncora sem economizar
   * leitura nenhuma — ele aparece uma vez por série.
   */
  const notaPadrao = (_serie: Serie, ponto: Ponto) => {
    if (ponto.base === undefined) return undefined;
    if (valueFormat === 'abs' && ponto.n !== undefined)
      return `de ${inteiro.format(ponto.base)} ${unit}`;
    return ponto.n === undefined
      ? undefined
      : `${abreviado(ponto.n)} de ${inteiro.format(ponto.base)} ${unit}`;
  };

  /** Espaço entre a ponta de uma linha e o texto que a descreve. */
  const gap = $derived((faixa ? 22 : 10) * k);
  const markerR = $derived((faixa ? 4 : 3.5) * k);

  /**
   * Margem esquerda da variante de faixa.
   *
   * Sem eixo Y ela não precisa acomodar uma escala, mas precisa acomodar duas
   * coisas: os valores da primeira onda, que ficam fora do plot (ver
   * `rotulosDaOnda`), e a metade esquerda do primeiro rótulo de ano, que é
   * centrado no ponto e portanto transborda meia palavra para fora.
   *
   * O respiro do cartão entra na conta para o rótulo mais à esquerda alinhar
   * com o título, e não encostar na borda.
   */
  const margemEsquerda = $derived(
    24 * k +
      Math.max(
        ...series.map((s) => measureLabel(rotuloDoPonto(s.pontos[0]), type.dado, 600) + gap + markerR),
        measureLabel(String(anos[0]), type.lg, 700) / 2,
      ),
  );

  const L = $derived({
    cardPadding: 24 * k,
    cardRadius: 12 * k,
    marginLeft: faixa ? margemEsquerda : 46 * k,
    /** Espaço da ponta da linha até o texto, mais o texto. */
    seriesLabelGap: gap,
    titleLine: 24 * k,
    subtitleLine: 15 * k,
    noteLine: 14 * k,
    titleBlockGap: 26 * k,
    /** Base do plot até a primeira linha de nota. */
    noteGap: (faixa ? 42 : 34) * k,
    noteSpacing: 3 * k,
    /**
     * Altura do plot: fixa, para o cartão não mudar de forma com o nº de
     * séries — exceto em faixas por série, onde é o número delas que a define.
     */
    plotHeight: rowPerSeries
      ? (26 + series.length * 84) * k
      : (faixa ? 298 : 250) * k,
    /** Altura de uma faixa de série, e o quanto dela fica reservado ao rótulo. */
    rowHeight: 84 * k,
    rowLabelLane: 30 * k,
    /**
     * Faixa reservada no topo do plot para a anotação de intervalo.
     *
     * A escala começa abaixo dela, e não em 0: sem essa reserva, uma série que
     * chegue perto do teto do eixo — bibliotecas ficam em 97,1% de um eixo que
     * vai a 100% — passa por cima do "8 anos". A anotação tem então uma faixa
     * só sua, onde nenhum dado entra.
     */
    gapBand: (faixa ? 26 : 0) * k,
    markerRadius: markerR,
    lineWidth: (faixa ? 8.5 : 2.2) * k,
    /** Rótulo de valor acima do seu marcador. */
    valueOffset: (faixa ? 17 : 13) * k,
    /** Afastamento mínimo entre dois rótulos de valor da mesma onda. */
    valueSpacing: (faixa ? 16 : 12) * k,
    /**
     * Bloco de ponta: valor em destaque, nome da série, nota. As entrelinhas
     * são curtas de propósito — as três linhas são uma frase só sobre a mesma
     * série, e um vão largo entre elas as faria ler como itens soltos.
     */
    endValueLine: 21 * k,
    endNameLine: 15 * k,
    endNoteLine: 13 * k,
    endBlockGap: 10 * k,
    /** Anotação do intervalo entre ondas, centrada na faixa reservada. */
    gapLabelTop: (faixa ? 13 : 9) * k,
    gapRulePad: 7 * k,
    /**
     * Base do plot até a frase que apresenta a régua. Curto porque os anos não
     * ficam mais aqui: com a régua ligada, eles descem para debaixo dela e
     * passam a rotular os dois gráficos de uma vez.
     */
    stripGap: 30 * k,
    stripLeadLine: 22 * k,
    /** Uma faixa da régua: o percentual em cima, a bolinha embaixo. */
    stripRow: 40 * k,
    stripLabelY: 8 * k,
    stripDotY: 27 * k,
    stripDotMax: 10 * k,
    stripDotMin: 2.5 * k,
    stripRuleWidth: 3.6 * k,
  });

  /** Altura total da régua de bolinhas, da base do plot à última bolinha. */
  const stripHeight = $derived(
    dotStrip
      ? L.stripGap + (dotStripLead ? L.stripLeadLine : 0) + series.length * L.stripRow
      : 0,
  );

  /**
   * Base do plot até a linha dos anos.
   *
   * Com a régua ligada os anos descem para depois dela: são as mesmas quatro
   * ondas nos dois gráficos, então um rótulo só serve aos dois — e é o que
   * permite às guias verticais atravessarem a figura inteira sem passar por
   * cima de uma linha de anos no meio do caminho.
   */
  const axisTop = $derived(dotStrip ? stripHeight : 0);

  /** Base do plot até a primeira linha de nota. `noteGap` cobre a linha dos anos. */
  const notesTop = $derived(axisTop + L.noteGap);

  /**
   * Os trechos de uma guia vertical, de cima do plot até o fim da régua.
   *
   * Ela é desenhada em pedaços e não de uma vez porque os percentuais da régua
   * ficam centrados sobre as bolinhas, ou seja, exatamente sobre a guia: inteira,
   * ela passaria riscando cada um deles. Os vãos são os únicos lugares onde há
   * texto no caminho — a frase de entrada e uma linha de rótulos por série.
   */
  function guias(innerHeight: number): [number, number][] {
    if (!dotStrip) return [[0, innerHeight]];

    const stripTop = innerHeight + L.stripGap;
    const rowsTop = stripTop + (dotStripLead ? L.stripLeadLine : 0);
    const meia = Number(type.dado) * 0.8;

    const vaos: [number, number][] = [];
    if (dotStripLead) vaos.push([stripTop - meia * 0.4, rowsTop - meia * 0.4]);
    for (let i = 0; i < series.length; i++) {
      const rotuloY = rowsTop + i * L.stripRow + L.stripLabelY;
      vaos.push([rotuloY - meia, rotuloY + meia]);
    }

    const segmentos: [number, number][] = [];
    let y = 0;
    for (const [de, ate] of vaos) {
      if (de > y) segmentos.push([y, de]);
      y = ate;
    }
    segmentos.push([y, innerHeight + stripHeight]);

    return segmentos;
  }

  const titleStyle = $derived(
    resolveThemeStyle<ChartTheme, 'text'>(
      { fontSize: type.title, fontWeight: 600, fill: palette.neutral[300], fontFamily },
      theme.text,
      DefaultTheme.text,
    )!,
  );
  const subtitleStyle = $derived(
    resolveThemeStyle<ChartTheme, 'text'>(
      { fontSize: type.sm, fill: palette.neutral[200], fontFamily },
      theme.text,
      DefaultTheme.text,
    )!,
  );
  const noteStyle = $derived(
    resolveThemeStyle<ChartTheme, 'text'>(
      { fontSize: type.sm, fontWeight: 400, fill: palette.neutral[100], fontFamily },
      theme.text,
      DefaultTheme.text,
    )!,
  );

  const textWidth = $derived(width - L.cardPadding * 2);
  const titleLines = $derived(
    wrapText(title, type.title, textWidth, Number(titleStyle.fontWeight)),
  );
  const subtitleLines = $derived(
    wrapText(subtitle ?? '', type.md, textWidth, Number(subtitleStyle.fontWeight)),
  );
  const footnoteLines = $derived(wrapText(footnote ?? '', type.sm, textWidth));
  const sourceLines = $derived(wrapText(source ?? '', type.sm, textWidth));

  /** O último ponto de cada série — o que o bloco de ponta descreve. */
  const pontasDeSerie = $derived(
    series.map((s, index) => {
      const ultimo = s.pontos[s.pontos.length - 1];
      return {
        index,
        key: s.key,
        label: s.label,
        color: seriesColor(index),
        valor: rotuloDoPonto(ultimo),
        nota: (endNote ?? notaPadrao)(s, ultimo),
        pctFinal: ultimo.pct,
      };
    }),
  );

  /**
   * Largura reservada para o bloco de ponta.
   *
   * Ela é medida no conteúdo — o valor em destaque, o nome, a nota — e não
   * chutada, mas com teto: a nota `2.804 de 5.570 municípios` é mais larga que
   * qualquer nome de série e, deixada solta, comeria um terço do plot. Passando
   * do teto, é o nome que quebra em duas linhas.
   */
  const END_WIDTH_MAX_RATIO = 0.29;

  const larguraNatural = $derived(
    Math.max(
      ...pontasDeSerie.map((p) =>
        Math.max(
          measureLabel(p.valor, type.destaque, 400),
          measureLabel(p.label, type.md, 600),
          p.nota ? measureLabel(p.nota, type.sm, 400) : 0,
        ),
      ),
    ),
  );

  const endWidth = $derived(Math.min(larguraNatural, width * END_WIDTH_MAX_RATIO));

  /**
   * Na variante fina a margem direita é medida no rótulo de série mais largo,
   * não chutada: é ela que decide se "Teatro ou sala de espetáculo" cabe ao
   * lado da linha ou sai cortado na borda do cartão.
   */
  const rotuloMaisLargo = $derived(
    Math.max(...series.map((s) => measureLabel(s.label, type.sm, 600))),
  );

  const MARGIN = $derived({
    left: L.marginLeft,
    right: L.seriesLabelGap + (faixa ? endWidth : rotuloMaisLargo) + L.cardPadding,
    top:
      L.cardPadding +
      titleLines.length * L.titleLine +
      subtitleLines.length * L.subtitleLine +
      L.titleBlockGap,
    bottom:
      notesTop +
      footnoteLines.length * L.noteLine +
      (footnoteLines.length && sourceLines.length ? L.noteSpacing : 0) +
      sourceLines.length * L.noteLine +
      L.cardPadding,
  });

  const cardHeight = $derived(height ?? MARGIN.top + L.plotHeight + MARGIN.bottom);

  /**
   * Maior percentual da figura inteira — a referência de tamanho das bolinhas.
   *
   * Uma escala por série faria cada faixa da régua ter o próprio máximo, e aí
   * a bolinha de 9,0% do cinema sairia do mesmo tamanho que a de 88,3% das
   * bibliotecas. Uma escala só para todas é o que deixa as faixas comparáveis.
   */
  const maiorPct = $derived(Math.max(...series.flatMap((s) => s.pontos.map((p) => p.pct))));

  /**
   * A maior variação de uma série entre a primeira e a última onda, em pontos
   * percentuais. É ela que fixa quantas unidades vale um ponto no modo de
   * faixas: a série que mais se mexeu preenche a sua faixa, e as outras se
   * mexem proporcionalmente menos dentro da delas.
   */
  const maiorAmplitude = $derived(
    Math.max(
      ...series.map((s) => {
        const v = s.pontos.map((p) => p.pct);
        return Math.max(...v) - Math.min(...v);
      }),
    ),
  );

  /**
   * A escala vertical de cada série.
   *
   * Fora do modo de faixas é sempre a mesma, e a posição vertical significa
   * nível. No modo de faixas cada série ganha uma faixa de mesma altura e é
   * centrada nela, de forma que a posição passa a significar variação — o
   * nível de cada uma está nos rótulos e na régua de bolinhas.
   */
  function escalaDaSerie(innerHeight: number) {
    if (!rowPerSeries) {
      const y = scaleLinear().domain([0, topo]).range([innerHeight, L.gapBand]);
      return () => (pct: number) => y(pct);
    }

    const faixaUtil = L.rowHeight - L.rowLabelLane;
    const unidadePorPonto = (faixaUtil - L.lineWidth) / (maiorAmplitude || 1);

    return (index: number) => {
      const valores = series[index].pontos.map((p) => p.pct);
      const meio = (Math.min(...valores) + Math.max(...valores)) / 2;
      const centro =
        L.gapBand + index * L.rowHeight + L.rowLabelLane + faixaUtil / 2;
      return (pct: number) => centro - (pct - meio) * unidadePorPonto;
    };
  }

  /** Teto arredondado para cima na dezena, para o eixo terminar num número redondo. */
  const topo = $derived(
    yMax ?? Math.ceil(Math.max(...series.flatMap((s) => s.pontos.map((p) => p.pct))) / 10) * 10,
  );

  type Rotulo = {
    key: string;
    text: string;
    color: string;
    x: number;
    y: number;
    marcadorY: number;
    anchor: 'start' | 'middle' | 'end';
  };

  /**
   * Rótulos das ondas das pontas encostam no ponto em vez de centrarem nele.
   *
   * Centrados, eles transbordam para os dois lados: na primeira onda o valor
   * cairia por cima dos rótulos percentuais do eixo, e na última, por cima do
   * nome da série que fica logo à direita da linha. Ancorá-los para dentro do
   * plot resolve os dois casos sem afastar o rótulo do ponto que ele descreve.
   */
  const ancoraDaOnda = (ano: number): 'start' | 'middle' | 'end' =>
    ano === anos[0] ? 'start' : ano === ultimoAno ? 'end' : 'middle';

  /**
   * Altura vertical de cada nome de série na ponta da sua linha.
   *
   * O nome fica na altura do último ponto, mas duas séries podem terminar
   * coladas — e dois nomes sobrepostos são pior do que a legenda que eles
   * substituem. Um passe de cima para baixo abre os vãos preservando a ordem,
   * para que o nome de cima siga pertencendo à linha de cima. O deslocamento
   * é de poucos pixels, e a cor é o que mantém cada nome ligado à sua linha.
   */
  function rotulosDeSerie(yScale: (v: number) => number) {
    const alturaLinha = Number(type.sm) * 1.25;

    const pendentes = series
      .map((s, index) => ({
        key: s.key,
        label: s.label,
        color: seriesColor(index),
        y: yScale(s.pontos[s.pontos.length - 1].pct),
      }))
      .sort((a, b) => a.y - b.y);

    for (let i = 1; i < pendentes.length; i++) {
      pendentes[i].y = Math.max(pendentes[i].y, pendentes[i - 1].y + alturaLinha);
    }

    return pendentes;
  }

  /**
   * Blocos de leitura na ponta das linhas, na variante de faixa: o valor final
   * em destaque, o nome da série e quantos municípios são aquele percentual.
   *
   * É a legenda, o rótulo do último ponto e a magnitude absoluta no mesmo
   * lugar — e é por isso que a última onda não recebe rótulo de valor sobre o
   * marcador: seria o mesmo número duas vezes, a poucos pixels de distância.
   *
   * O bloco é centrado no ponto que descreve e depois empurrado para baixo se
   * encostar no de cima, preservando a ordem das séries — é essa ordem, e mais
   * a proximidade com a ponta da linha, que diz a quem cada bloco pertence.
   */
  function blocosDePonta(yDe: (index: number) => (v: number) => number, innerHeight: number) {
    const pendentes = pontasDeSerie
      .map((p) => {
        const nameLines = wrapText(p.label, type.md, endWidth, 600);
        const notaLines = wrapText(p.nota ?? '', type.sm, endWidth, 400);
        const altura =
          L.endValueLine + nameLines.length * L.endNameLine + notaLines.length * L.endNoteLine;
        return { ...p, nameLines, notaLines, altura, ancoraY: yDe(p.index)(p.pctFinal) };
      })
      .sort((a, b) => a.ancoraY - b.ancoraY)
      .map((b) => ({ ...b, y: b.ancoraY - b.altura / 2 }));

    const n = pendentes.length;
    if (!n) return pendentes;

    /*
     * Dois passes, e não um.
     *
     * Só empurrando para baixo, a pilha transborda pela base quando as séries
     * chegam agrupadas: em equipamentos, três das quatro terminam entre 9% e
     * 30% de um eixo que vai a 100%, e os blocos delas precisam de mais altura
     * do que a que separa as linhas. O passe de volta, a partir da base, puxa
     * cada bloco para cima até caber — preservando a ordem, que é o que mantém
     * o bloco de cima pertencendo à linha de cima.
     */
    for (let i = 1; i < n; i++) {
      pendentes[i].y = Math.max(
        pendentes[i].y,
        pendentes[i - 1].y + pendentes[i - 1].altura + L.endBlockGap,
      );
    }

    pendentes[n - 1].y = Math.min(pendentes[n - 1].y, innerHeight - pendentes[n - 1].altura);
    for (let i = n - 2; i >= 0; i--) {
      pendentes[i].y = Math.min(
        pendentes[i].y,
        pendentes[i + 1].y - pendentes[i].altura - L.endBlockGap,
      );
    }

    // e nada sai pelo topo, nem que para isso a pilha volte a transbordar embaixo
    pendentes[0].y = Math.max(pendentes[0].y, 0);
    for (let i = 1; i < n; i++) {
      pendentes[i].y = Math.max(
        pendentes[i].y,
        pendentes[i - 1].y + pendentes[i - 1].altura + L.endBlockGap,
      );
    }

    return pendentes;
  }

  /**
   * Rótulos de valor de uma onda, colocados de modo a não cair sobre as linhas
   * nem uns sobre os outros.
   *
   * O rótulo fica acima do seu marcador por convenção, mas duas séries podem
   * passar perto uma da outra — museu e teatro estão a 0,7 ponto de distância
   * em 2006 — e aí o rótulo da de baixo aterrissaria em cima da linha da de
   * cima. Quando não há folga vertical para ele caber entre as duas linhas, o
   * rótulo desce para baixo do próprio marcador, onde o espaço está livre.
   *
   * Depois disso ainda pode sobrar sobreposição entre rótulos vizinhos — um que
   * desceu e outro que subiu podem se encontrar no meio — então um segundo
   * passe, de cima para baixo, abre os vãos preservando a ordem.
   */
  function rotulosDaOnda(
    ano: number,
    yDe: (index: number) => (v: number) => number,
    x: number,
  ): Rotulo[] {
    const anchor = ancoraDaOnda(ano);

    /**
     * Na faixa, os valores da primeira onda saem do plot e ficam à esquerda,
     * na altura do seu marcador.
     *
     * É a única onda em que as três séries chegam agrupadas — 17,0%, 11,6% e
     * 5,1% cabem em 12 pontos percentuais — e com faixas de 8 px não há vão
     * entre elas onde um rótulo caiba: acima ou abaixo, ele pousa sobre a linha
     * vizinha. Fora do plot cada um fica na sua altura, sem disputar espaço com
     * as faixas, e a margem esquerda que a variante libera ao dispensar o eixo
     * Y é justamente onde eles cabem.
     */
    if (faixa && ano === anos[0]) {
      const alturaLinha = Number(type.dado) * 1.2;
      const rotulos = series
        .map((s, index) => ({
          key: s.key,
          text: rotuloDoPonto(s.pontos[0]),
          color: seriesColor(index),
          x: x - L.markerRadius - L.seriesLabelGap,
          marcadorY: yDe(index)(s.pontos[0].pct),
          anchor: 'end' as const,
        }))
        .sort((a, b) => a.marcadorY - b.marcadorY)
        .map((r) => ({ ...r, y: r.marcadorY }));

      for (let i = 1; i < rotulos.length; i++) {
        rotulos[i].y = Math.max(rotulos[i].y, rotulos[i - 1].y + alturaLinha);
      }

      return rotulos;
    }

    /**
     * Folga vertical de que um rótulo precisa para caber acima do marcador.
     * Na faixa, a meia-espessura do traço entra na conta: é ela que o rótulo
     * da série de baixo tem de vencer para não pousar sobre a linha de cima.
     */
    const folga = L.valueOffset + Number(type.dado) * 0.6 + L.lineWidth / 2;

    const pontos = series
      .map((s, index) => ({ s, index, ponto: s.pontos.find((p) => p.ano === ano) }))
      .filter((d) => d.ponto !== undefined)
      .map((d) => ({
        key: d.s.key,
        text: rotuloDoPonto(d.ponto!),
        color: seriesColor(d.index),
        // encostado no marcador, do lado que aponta para dentro do plot
        x: anchor === 'start' ? x + L.markerRadius : anchor === 'end' ? x - L.markerRadius : x,
        marcadorY: yDe(d.index)(d.ponto!.pct),
        anchor,
      }))
      .sort((a, b) => a.marcadorY - b.marcadorY);

    const rotulos = pontos.map((p, i) => {
      const acima = i === 0 || p.marcadorY - pontos[i - 1].marcadorY >= folga;
      return { ...p, y: p.marcadorY + (acima ? -L.valueOffset : L.valueOffset) };
    });

    /**
     * Meia altura do rótulo mais a meia-espessura do traço: a distância mínima
     * entre o centro de um rótulo e o centro de uma faixa para que um não
     * encoste no outro.
     */
    const livre = L.lineWidth / 2 + Number(type.dado) * 0.72;

    for (let i = 0; i < rotulos.length; i++) {
      if (i) rotulos[i].y = Math.max(rotulos[i].y, rotulos[i - 1].y + L.valueSpacing);

      /*
       * Descer para abrir vão entre dois rótulos pode largar o de baixo em cima
       * de uma faixa — era o que acontecia com os 10,5% do cinema em 2014, que
       * saíam por trás da própria linha. As faixas estão ordenadas de cima para
       * baixo, então uma varredura basta: cada vez que o rótulo cai dentro de
       * uma, ele desce o suficiente para sair dela por baixo.
       */
      if (faixa) {
        for (const p of pontos) {
          if (Math.abs(rotulos[i].y - p.marcadorY) < livre) rotulos[i].y = p.marcadorY + livre;
        }
      }
    }

    return rotulos;
  }

  /**
   * Quantos anos separam duas ondas vizinhas, anotado no topo do plot.
   *
   * O eixo é linear no tempo justamente para que a inclinação signifique ritmo,
   * e essa é a informação que o leitor precisa ter à mão para lê-la — estava só
   * na nota de rodapé, e agora está sobre o trecho a que se refere.
   */
  const vaos = $derived(
    faixa
      ? anos.slice(1).map((ano, i) => ({
          de: anos[i],
          ate: ano,
          label: `${ano - anos[i]} anos`,
        }))
      : [],
  );
</script>

<Chart
  {responsive}
  {width}
  height={cardHeight}
  {theme}
  margin={MARGIN}
  ariaLabel={title}
  role="img"
  bind:innerRef={svgEl}
>
  {#snippet children({ width: cardWidth, innerWidth, innerHeight, margin }: ChartDimensions)}
    {@const xScale = scaleLinear()
      .domain([anos[0], anos[anos.length - 1]])
      .range([0, innerWidth])}
    {@const yScale = scaleLinear().domain([0, topo]).range([innerHeight, L.gapBand])}
    {@const yDe = escalaDaSerie(innerHeight)}
    {@const cardLeft = -margin.left + L.cardPadding}

    {#if background !== null}
      <rect
        x={-margin.left}
        y={-margin.top}
        width={cardWidth}
        height={cardHeight}
        rx={L.cardRadius}
        fill={background ?? palette.base[100]}
        stroke={palette.base[300]}
        stroke-width={k}
      />
    {/if}

    <TextLines
      lines={titleLines}
      x={cardLeft}
      y={-margin.top + L.cardPadding}
      lineHeight={L.titleLine}
      fontSize={titleStyle.fontSize}
      fontWeight={titleStyle.fontWeight}
      fontFamily={titleStyle.fontFamily}
      fill={titleStyle.fill}
    />

    <TextLines
      lines={subtitleLines}
      x={cardLeft}
      y={-margin.top + L.cardPadding + titleLines.length * L.titleLine}
      lineHeight={L.subtitleLine}
      fontSize={subtitleStyle.fontSize}
      fontWeight={subtitleStyle.fontWeight}
      fontFamily={subtitleStyle.fontFamily}
      fill={subtitleStyle.fill}
    />

    <!-- grade primeiro, para as linhas passarem por cima dela -->
    {#if faixa}
      <!-- uma vertical por onda: a grade marca quando se mediu, não quanto -->
      {#each anos as ano (ano)}
        {#each guias(innerHeight) as [y1, y2], i (i)}
          <line
            x1={xScale(ano)}
            {y1}
            x2={xScale(ano)}
            {y2}
            stroke={palette.base[300]}
            stroke-width={k}
          />
        {/each}
      {/each}
    {:else}
      {#each yScale.ticks(5) as tick (tick)}
        <line
          x1={0}
          y1={yScale(tick)}
          x2={innerWidth}
          y2={yScale(tick)}
          stroke={palette.base[300]}
          stroke-width={k}
        />
        <Text
          x={-L.seriesLabelGap}
          y={yScale(tick)}
          textAnchor="end"
          verticalAnchor="middle"
          fontSize={type.sm}
          fontWeight={500}
          {fontFamily}
          fill={palette.neutral[200]}
          text={`${tick}%`}
        />
      {/each}
    {/if}

    <!-- distância entre ondas, sobre o trecho a que se refere -->
    {#each vaos as vao (vao.ate)}
      {@const x1 = xScale(vao.de)}
      {@const x2 = xScale(vao.ate)}
      {@const meio = (x1 + x2) / 2}
      {@const meiaLargura = measureLabel(vao.label, type.xs, 500) / 2}
      <line
        x1={x1 + L.gapRulePad}
        y1={L.gapLabelTop}
        x2={meio - meiaLargura - L.gapRulePad}
        y2={L.gapLabelTop}
        stroke={palette.base[300]}
        stroke-width={k}
      />
      <line
        x1={meio + meiaLargura + L.gapRulePad}
        y1={L.gapLabelTop}
        x2={x2 - L.gapRulePad}
        y2={L.gapLabelTop}
        stroke={palette.base[300]}
        stroke-width={k}
      />
      <Text
        x={meio}
        y={L.gapLabelTop}
        textAnchor="middle"
        verticalAnchor="middle"
        fontSize={type.xs}
        fontWeight={500}
        {fontFamily}
        fill={palette.neutral[100]}
        text={vao.label}
      />
    {/each}

    {#each series as serie, index (serie.key)}
      {@const color = seriesColor(index)}
      {@const pontos = serie.pontos.filter((p) => anos.includes(p.ano))}

      <path
        d={tracado(xScale, yDe(index))(pontos) ?? undefined}
        fill="none"
        stroke={color}
        stroke-width={L.lineWidth}
        stroke-linejoin="round"
        stroke-linecap="round"
      />

      {#each pontos as ponto (ponto.ano)}
        <circle
          cx={xScale(ponto.ano)}
          cy={yDe(index)(ponto.pct)}
          r={faixa && ponto.ano === ultimoAno ? L.markerRadius * 1.5 : L.markerRadius}
          fill={faixa ? tomDoMarcador(color) : color}
        />
      {/each}
    {/each}

    {#if faixa}
      <!-- bloco de leitura na ponta: valor final, nome da série e o absoluto -->
      {#each blocosDePonta(yDe, innerHeight) as bloco (bloco.key)}
        {@const x = innerWidth + L.seriesLabelGap}

        <Text
          {x}
          y={bloco.y}
          textAnchor="start"
          verticalAnchor="start"
          fontSize={type.destaque}
          fontWeight={600}
          {fontFamily}
          fill={endValueColor ?? bloco.color}
          text={bloco.valor}
        />
        <TextLines
          lines={bloco.nameLines}
          {x}
          y={bloco.y + L.endValueLine}
          lineHeight={L.endNameLine}
          fontSize={type.md}
          fontWeight={600}
          {fontFamily}
          fill={palette.neutral[300]}
        />
        <TextLines
          lines={bloco.notaLines}
          {x}
          y={bloco.y + L.endValueLine + bloco.nameLines.length * L.endNameLine}
          lineHeight={L.endNoteLine}
          fontSize={type.sm}
          fontWeight={400}
          {fontFamily}
          fill={palette.neutral[300]}
        />
      {/each}
    {:else}
      <!-- nomes das séries na ponta das linhas, no lugar de uma legenda -->
      {#each rotulosDeSerie((v) => yScale(v)) as rotulo (rotulo.key)}
        <Text
          x={innerWidth + L.seriesLabelGap}
          y={rotulo.y}
          textAnchor="start"
          verticalAnchor="middle"
          fontSize={type.sm}
          fontWeight={600}
          {fontFamily}
          fill={rotulo.color}
          text={rotulo.label}
        />
      {/each}
    {/if}

    <!-- valores por último, sobre as linhas -->
    {#each faixa ? anos.slice(0, -1) : anos as ano (ano)}
      {#each rotulosDaOnda(ano, yDe, xScale(ano)) as rotulo (rotulo.key)}
        <Text
          x={rotulo.x}
          y={rotulo.y}
          textAnchor={rotulo.anchor}
          verticalAnchor="middle"
          fontSize={type.dado}
          fontWeight={faixa ? 500 : 600}
          {fontFamily}
          fill={faixa ? palette.neutral[200] : rotulo.color}
          text={rotulo.text}
        />
      {/each}
    {/each}

    <Axis
      orientation="bottom"
      scale={xScale}
      top={innerHeight + axisTop}
      tickValues={anos}
      tickFormat={(v: number) => String(v)}
      hideAxisLine
      hideTicks
      tickLabelProps={tickLabelProps(
        faixa ? palette.neutral[300] : palette.neutral[200],
        faixa ? type.lg : type.md,
        500,
      )}
    />

    {#if dotStrip}
      <!--
        A régua de bolinhas, abaixo do eixo: a mesma escala de tempo, uma faixa
        por série, e o percentual que o plot deixou de dizer quando passou a
        mostrar números absolutos. O tamanho do círculo cresce com a raiz do
        percentual, para que seja a área — e não o raio — a crescer com o valor.
      -->
      {@const stripTop = innerHeight + L.stripGap}
      {@const rowsTop = stripTop + (dotStripLead ? L.stripLeadLine : 0)}

      {#if dotStripLead}
        <Text
          x={0}
          y={stripTop}
          textAnchor="start"
          verticalAnchor="start"
          fontSize={type.md}
          fontWeight={500}
          {fontFamily}
          fill={palette.neutral[200]}
          text={dotStripLead}
        />
      {/if}

      {#each series as serie, index (serie.key)}
        {@const color = seriesColor(index)}
        {@const pontos = serie.pontos.filter((p) => anos.includes(p.ano))}
        {@const dotY = rowsTop + index * L.stripRow + L.stripDotY}

        <line
          x1={xScale(pontos[0].ano)}
          y1={dotY}
          x2={xScale(pontos[pontos.length - 1].ano)}
          y2={dotY}
          stroke={color}
          stroke-width={L.stripRuleWidth}
        />

        {#each pontos as ponto (ponto.ano)}
          {@const ultimo = ponto.ano === ultimoAno}
          <circle
            cx={xScale(ponto.ano)}
            cy={dotY}
            r={Math.max(L.stripDotMin, L.stripDotMax * Math.sqrt(ponto.pct / maiorPct))}
            fill={color}
          />
          <Text
            x={xScale(ponto.ano)}
            y={rowsTop + index * L.stripRow + L.stripLabelY}
            textAnchor="middle"
            verticalAnchor="middle"
            fontSize={type.dado}
            fontWeight={ultimo ? 600 : 500}
            {fontFamily}
            fill={ultimo ? (endValueColor ?? color) : palette.neutral[200]}
            text={pct(ponto.pct)}
          />
        {/each}

        <Text
          x={innerWidth + L.seriesLabelGap}
          y={dotY}
          textAnchor="start"
          verticalAnchor="middle"
          fontSize={type.sm}
          fontWeight={600}
          {fontFamily}
          fill={palette.neutral[300]}
          text={serie.label}
        />
      {/each}
    {/if}

    <TextLines
      lines={footnoteLines}
      x={cardLeft}
      y={innerHeight + notesTop}
      lineHeight={L.noteLine}
      fontSize={noteStyle.fontSize}
      fontWeight={noteStyle.fontWeight}
      fontFamily={noteStyle.fontFamily}
      fill={noteStyle.fill}
    />

    <TextLines
      lines={sourceLines}
      x={cardLeft}
      y={innerHeight +
        notesTop +
        footnoteLines.length * L.noteLine +
        (footnoteLines.length ? L.noteSpacing : 0)}
      lineHeight={L.noteLine}
      fontSize={noteStyle.fontSize}
      fontWeight={noteStyle.fontWeight}
      fontFamily={noteStyle.fontFamily}
      fill={noteStyle.fill}
    />
  {/snippet}
</Chart>
