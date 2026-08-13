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
  import LegendChips from './LegendChips.svelte';
  import TextLines from './TextLines.svelte';
  import { layoutLegend } from './legend';
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
   *
   * `pct` é o percentual porque é o que estas figuras quase sempre medem, mas o
   * campo é só *o valor da série na unidade do gráfico*: com `formatValue` e
   * `formatTick`, ele carrega R$ bilhões, e é o par de formatadores que decide
   * como esse número é escrito. O nome ficou pelo que ele é na maioria dos
   * casos — renomeá-lo mexeria nos JSON de dados de todas as outras figuras.
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
     * Espessura do traço, nas mesmas unidades autorais do resto (multiplicada
     * por `a4Scale`). Por omissão, a da variante: 8,5 na faixa, 2,2 na fina.
     *
     * Serve para dar a uma série anual o peso de marca da faixa sem herdar o
     * resto dela — as guias por onda, os rótulos em todo ponto, o bloco de
     * ponta. O marcador acompanha, para não virar conta de rosário sobre um
     * traço grosso, e a busca de posição dos rótulos passa a medir contra a
     * espessura cheia, e não contra a linha de centro.
     */
    lineWidth?: number;
    /**
     * Curva monotônica no lugar da polilinha. Por omissão, a da variante:
     * suavizada na faixa, reta na fina. Ver `tracado` para o porquê de ser
     * monotônica, e não uma spline qualquer.
     */
    smooth?: boolean;
    /**
     * Faixa de pastilhas abaixo do eixo, no lugar do nome na ponta de cada
     * linha.
     *
     * O nome na ponta é sempre melhor quando cabe — poupa a ida e volta até a
     * legenda. Com oito séries, três delas acabando em anos diferentes e duas
     * reduzidas a um ponto, ele deixa de caber: os nomes disputam o mesmo
     * espaço em que as linhas se cruzam. A legenda devolve esse espaço ao plot.
     */
    legend?: boolean;
    /**
     * Tira o eixo Y e a grade horizontal da variante fina.
     *
     * O que sobra é a forma das séries, como na faixa. Vale quando os níveis
     * estão ditos de outro jeito — rótulo nos anos que importam — e o eixo só
     * competiria com eles.
     */
    hideYAxis?: boolean;
    /**
     * Guias verticais nos anos marcados no eixo X. Por omissão, as da variante:
     * a faixa tem, a fina não.
     *
     * A grade marca *quando* se mediu, não quanto — é a grade que sobra quando
     * o eixo Y sai. Ela acompanha `tickYears`, e não todos os anos: uma guia sem
     * rótulo embaixo não ancora nada, e 23 delas fechariam o plot.
     */
    xGuides?: boolean;
    /**
     * O que os rótulos dentro do plot dizem: o percentual medido ou o número
     * absoluto por trás dele (`n`). Com a régua de bolinhas ligada, o plot fica
     * com os absolutos e a régua com os percentuais, e o gráfico diz as duas
     * coisas sem repetir nenhuma.
     */
    valueFormat?: 'pct' | 'abs';
    /**
     * Como um valor é escrito dentro do plot e no bloco de ponta. Por omissão,
     * o percentual — ou o absoluto, conforme `valueFormat`.
     *
     * É o que permite à figura medir outra coisa que não uma proporção: com um
     * formatador de reais aqui e outro em `formatTick`, `pct` passa a carregar
     * R$ bilhões e nada mais no componente precisa saber disso.
     */
    formatValue?: (valor: number) => string;
    /** Rótulos do eixo Y. Por omissão, o valor com `%`. */
    formatTick?: (valor: number) => string;
    /**
     * Em que anos os valores são escritos sobre as linhas. Por omissão, todos —
     * o que é o certo para quatro ondas de pesquisa e insustentável para 23
     * anos seguidos, onde três séries dariam 69 rótulos. Numa série anual, a
     * lista guarda os anos que valem uma anotação: um pico, um vale, uma virada.
     *
     * Uma lista vale para todas as séries. Um mapa por `key` da série anota cada
     * uma nos seus próprios anos, e uma série ausente do mapa não é anotada —
     * que é o que permite marcar o pico de uma linha sem escrever, no mesmo ano
     * e no mesmo aperto, o valor das outras duas.
     */
    labelYears?: number[] | Record<string, number[]>;
    /** Anos que recebem marca no eixo X. Por omissão, todos. */
    tickYears?: number[];
    /**
     * Vão máximo, em anos, entre dois pontos que a linha ainda liga. Acima
     * disso ela se parte, e o trecho sem dado fica em branco.
     *
     * Por omissão não há limite: as ondas da MUNIC estão a 8 anos umas das
     * outras e é justamente entre elas que a linha tem de passar. Numa série
     * anual, porém, o ano que falta é informação — o MinC não aparece de 2019 a
     * 2022 porque foi extinto, e ligar 2018 a 2023 desenharia uma execução que
     * não houve. Com `1`, cada buraco parte a linha.
     */
    maxGap?: number;
    /**
     * Bloco de leitura na ponta de cada linha — valor final em destaque, nome
     * da série e nota — no lugar do nome solto. Por omissão, ligado na variante
     * de faixa e desligado na fina; ligá-lo na fina traz o bloco para uma série
     * densa, que é onde o nome sozinho deixa o valor final sem rótulo.
     */
    endBlocks?: boolean;
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
    lineWidth,
    smooth,
    legend = false,
    hideYAxis = false,
    xGuides,
    valueFormat = 'pct',
    formatValue,
    formatTick,
    labelYears,
    tickYears,
    maxGap = Infinity,
    endBlocks,
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

  /** O bloco de ponta é o padrão da faixa, mas não é exclusivo dela. */
  const blocos = $derived(endBlocks ?? faixa);

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
  const suave = $derived(smooth ?? faixa);

  const tracado = $derived(
    (xScale: (ano: number) => number, yScale: (pct: number) => number) =>
      line<Ponto>()
        .x((p) => xScale(p.ano))
        .y((p) => yScale(p.pct))
        .curve(suave ? curveMonotoneX : curveLinear),
  );

  /**
   * Os pedaços contínuos de uma série — ver `maxGap`.
   *
   * Cada pedaço vira um `<path>` seu. Um pedaço de um ponto só não desenha
   * traço nenhum, e é o certo: a Lei Paulo Gustavo foi executada num ano e em
   * nenhum outro, então o que existe dela é um ponto, não uma linha.
   */
  const trechos = $derived((pontos: Ponto[]) => {
    const partes: Ponto[][] = [];
    for (const ponto of pontos) {
      const atual = partes[partes.length - 1];
      const anterior = atual?.[atual.length - 1];
      if (anterior && ponto.ano - anterior.ano <= maxGap) atual.push(ponto);
      else partes.push([ponto]);
    }
    return partes;
  });

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
    formatValue
      ? formatValue(ponto.pct)
      : valueFormat === 'abs' && ponto.n !== undefined
        ? abreviado(ponto.n)
        : pct(ponto.pct);

  /** Rótulo do eixo Y — só existe na variante fina, que é a que tem eixo. */
  const rotuloDoTick = (v: number) => (formatTick ?? ((t: number) => `${t}%`))(v);

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

  const espessura = $derived((lineWidth ?? (faixa ? 8.5 : 2.2)) * k);

  /**
   * Folga no pé do plot, do tamanho da meia espessura do traço.
   *
   * Sem ela, uma série que encosta no zero sai com a ponta arredondada cortada
   * pela borda do plot — a PNAB desce a R$ 11 milhões em 2024 e o traço grosso
   * é serrado ao meio ali. Só existe quando a espessura foi pedida de fora: as
   * duas padrão já foram diagramadas sem essa folga, e criá-la agora moveria
   * todas as figuras existentes.
   */
  const insetInferior = $derived(lineWidth === undefined ? 0 : espessura / 2);

  /**
   * O marcador cresce com o traço, mas fica sempre um pouco dentro dele — a
   * proporção é a da faixa, 4 sobre 8,5. É o que faz dele um ponto *sobre* a
   * linha: maior, ele viraria uma conta de rosário enfiada nela; menor, um
   * furo. Num traço fino ele é a bolinha de sempre, maior que o traço.
   */
  const markerR = $derived(faixa ? 4 * k : Math.max(3.5 * k, espessura * (4 / 8.5)));

  /**
   * Um marcador que cabe dentro do traço só se vê se for de outro tom — o da
   * própria série some, e um branco abriria um furo na linha. Ver
   * `tomDoMarcador`.
   */
  const marcadorNoTraco = $derived(markerR * 2 <= espessura + 1);

  /**
   * Os anos em que uma série é um ponto solto, sem traço sob ele.
   *
   * O marcador escurece para se ver dentro do traço; num ponto solto não há
   * traço, e o tom escuro só o afastaria da cor com que a legenda o nomeia. A
   * Lei Paulo Gustavo é a figura inteira num ponto: ela tem de sair na cor dela.
   */
  const anosSoltos = $derived((pontos: Ponto[]) =>
    new Set(trechos(pontos).filter((t) => t.length === 1).map((t) => t[0].ano)),
  );

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
    // sem eixo Y a margem esquerda só precisa acomodar a metade do primeiro
    // rótulo de ano que transborda para fora do plot
    marginLeft: faixa
      ? margemEsquerda
      : hideYAxis
        ? 24 * k + measureLabel(String(anos[0]), type.md, 500) / 2
        : 46 * k,
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
    lineWidth: espessura,
    /**
     * Rótulo de valor acima do seu marcador: uma folga fixa mais a meia
     * espessura do traço, para que engrossar a linha afaste o rótulo dela em
     * vez de enterrá-lo. As constantes são as que reproduzem 17 e 13 nas
     * espessuras padrão de cada variante.
     */
    valueOffset: (faixa ? 12.75 : 11.9) * k + espessura / 2,
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
    /** Respiro da legenda até a primeira linha de nota. */
    legendGap: 16 * k,
    legendPadX: 10 * k,
    legendRowGap: 4 * k,
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

  /** Base do plot até o topo da faixa de legenda. `noteGap` cobre a linha dos anos. */
  const legendTop = $derived(axisTop + L.noteGap);

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
   *
   * Só entram as séries que chegam ao último ano, que são as que põem o nome na
   * margem. O nome de uma série que acaba antes fica ao lado da própria ponta,
   * dentro do plot, e reservar margem para ele daria uma calha vazia à direita.
   */
  const rotuloMaisLargo = $derived(
    Math.max(
      0,
      ...series
        .filter((s) => s.pontos[s.pontos.length - 1].ano === ultimoAno)
        .map((s) => measureLabel(s.label, type.sm, 600)),
    ),
  );

  /**
   * As margens laterais saem antes da inferior, e não junto com ela.
   *
   * A legenda quebra em linhas conforme a largura que sobra, e é o número de
   * linhas dela que fixa a margem inferior — então a largura útil precisa estar
   * decidida antes. Com tudo num objeto só, a conta se morderia pelo rabo.
   *
   * Com legenda não há nome na ponta das linhas, e a direita fica só com o
   * respiro do cartão: o espaço que a calha dos nomes ocupava volta para o plot.
   */
  const marginLeft = $derived(L.marginLeft);
  const marginRight = $derived(
    blocos
      ? L.seriesLabelGap + endWidth + L.cardPadding
      : legend
        ? L.cardPadding
        : L.seriesLabelGap + rotuloMaisLargo + L.cardPadding,
  );

  const larguraUtil = $derived(width - marginLeft - marginRight);

  const legendItems = $derived(
    legend ? series.map((s, index) => ({ label: s.label, color: seriesColor(index) })) : [],
  );

  /**
   * A legenda é diagramada aqui, e não dentro de `LegendChips`, porque é a
   * altura dela que decide a margem inferior — e, por ela, a altura do cartão.
   * Ver `layoutLegend`.
   */
  const legendLayout = $derived(
    legend
      ? layoutLegend(legendItems, {
          fontSize: Number(type.sm),
          fontWeight: 600,
          padX: L.legendPadX,
          maxWidth: larguraUtil,
          rowGap: L.legendRowGap,
        })
      : null,
  );

  /** Base do plot até a primeira linha de nota. */
  const notesTop = $derived(
    legendTop + (legendLayout ? legendLayout.height + L.legendGap : 0),
  );

  const MARGIN = $derived({
    left: marginLeft,
    right: marginRight,
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
      const y = scaleLinear().domain([0, topo]).range([innerHeight - insetInferior, L.gapBand]);
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
    /** `ano-série`: a chave do `{#each}`, já que a lista mistura anos. */
    id: string;
    /** Onde está o marcador que ele descreve — a âncora da busca de posição. */
    xPonto: number;
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
   * O nome de cada série, na ponta da sua linha.
   *
   * A ponta é a da própria série, e não a borda direita do plot: das oito
   * fontes federais, a Lei Aldir Blanc 1 acaba em 2020 e a Lei Paulo Gustavo em
   * 2023, e um nome na margem direita apontaria para um lugar onde essas linhas
   * não estão. Quem chega ao último ano põe o nome na margem, fora do plot,
   * como sempre; quem acaba antes põe ao lado da própria ponta, dentro dele.
   *
   * Na margem, os nomes são uma pilha: duas séries podem terminar coladas, e
   * dois nomes sobrepostos são pior que a legenda que eles substituem. Um passe
   * de cima para baixo abre os vãos preservando a ordem, para que o nome de
   * cima siga pertencendo à linha de cima.
   *
   * Dentro do plot não há pilha que resolva — há linhas em volta —, então o
   * nome procura posição em torno da sua ponta pelo mesmo critério dos rótulos
   * de valor: a primeira que não cruza traço nem nome já colocado.
   */
  function rotulosDeSerie(
    yDe: (index: number) => (v: number) => number,
    xScale: (ano: number) => number,
    innerWidth: number,
    innerHeight: number,
  ) {
    const alturaLinha = Number(type.sm) * 1.25;
    const meiaAltura = Number(type.sm) * 0.6;
    const linhas = polilinhas(yDe, xScale);

    const pendentes = series
      .map((s, index) => {
        const ultimo = s.pontos[s.pontos.length - 1];
        return {
          key: s.key,
          label: s.label,
          color: seriesColor(index),
          largura: measureLabel(s.label, Number(type.sm), 600),
          xPonto: xScale(ultimo.ano),
          y: yDe(index)(ultimo.pct),
          naMargem: ultimo.ano === ultimoAno,
          x: 0,
          anchor: 'start' as 'start' | 'end',
        };
      })
      .sort((a, b) => a.y - b.y);

    const caixas: Caixa[] = [];
    const cruzam = (a: Caixa, b: Caixa) =>
      a.x1 < b.x2 && b.x1 < a.x2 && a.y1 < b.y2 && b.y1 < a.y2;

    const naMargem = pendentes.filter((p) => p.naMargem);
    for (let i = 0; i < naMargem.length; i++) {
      if (i) naMargem[i].y = Math.max(naMargem[i].y, naMargem[i - 1].y + alturaLinha);
      naMargem[i].x = innerWidth + L.seriesLabelGap;
      caixas.push({
        x1: naMargem[i].x,
        x2: naMargem[i].x + naMargem[i].largura,
        y1: naMargem[i].y - meiaAltura,
        y2: naMargem[i].y + meiaAltura,
      });
    }

    for (const p of pendentes.filter((r) => !r.naMargem)) {
      const direita = p.xPonto + L.seriesLabelGap;
      const esquerda = p.xPonto - L.seriesLabelGap;

      const posicoes = [alturaLinha * 0, -alturaLinha, alturaLinha].flatMap((dy) => [
        { x: direita, anchor: 'start' as const, x1: direita, x2: direita + p.largura, y: p.y + dy },
        { x: esquerda, anchor: 'end' as const, x1: esquerda - p.largura, x2: esquerda, y: p.y + dy },
      ]);

      const caixaDe = (pos: (typeof posicoes)[number]) => ({
        x1: pos.x1,
        x2: pos.x2,
        y1: pos.y - meiaAltura,
        y2: pos.y + meiaAltura,
      });

      // o nome pode sair do plot — a margem direita é dele também — mas não do
      // cartão: passando do respiro, ele sairia cortado na borda
      const dentroDoCartao = (caixa: Caixa) =>
        caixa.x1 >= -MARGIN.left + L.cardPadding &&
        caixa.x2 <= innerWidth + MARGIN.right - L.cardPadding;

      const escolhida =
        posicoes.find((pos) => {
          const caixa = caixaDe(pos);
          if (caixa.y1 < 0 || caixa.y2 > innerHeight || !dentroDoCartao(caixa)) return false;
          return !cruzaAlgumaLinha(caixa, linhas) && !caixas.some((c) => cruzam(c, caixa));
        }) ?? posicoes[0];

      p.x = escolhida.x;
      p.y = escolhida.y;
      p.anchor = escolhida.anchor;
      caixas.push(caixaDe(escolhida));
    }

    // as caixas saem junto: os rótulos de valor são colocados depois e têm de
    // desviar destes também
    return { rotulos: pendentes, caixas };
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
  /**
   * As linhas desenhadas, em pixels — o que um rótulo tem de evitar.
   *
   * O teste de colisão do rótulo contra o *marcador* da série vizinha não basta
   * numa série anual: o marcador é um ponto, e o rótulo é largo o bastante para
   * cobrir uma banda inteira de ano, então quem ele atravessa é o traço entre
   * dois pontos, não o ponto. Com um trecho íngreme por perto — a transferência
   * a entes cai de R$ 3,9 bi a zero em um ano — o traço varre toda a altura do
   * plot dentro da largura de um único rótulo.
   */
  function polilinhas(
    yDe: (index: number) => (v: number) => number,
    xScale: (ano: number) => number,
  ) {
    // pelos trechos, e não pelos pontos: o vão que a linha não atravessa
    // também não deve barrar um rótulo
    return series.flatMap((s, index) =>
      trechos(s.pontos).map((trecho) => ({
        key: s.key,
        pontos: trecho.map((p) => ({ x: xScale(p.ano), y: yDe(index)(p.pct) })),
      })),
    );
  }

  type Caixa = { x1: number; x2: number; y1: number; y2: number };

  /** Se algum traço passa dentro da caixa que o rótulo ocupa. */
  function cruzaAlgumaLinha(caixa: Caixa, linhas: ReturnType<typeof polilinhas>) {
    for (const linha of linhas) {
      for (let i = 1; i < linha.pontos.length; i++) {
        const a = linha.pontos[i - 1];
        const b = linha.pontos[i];

        // o trecho recortado na faixa horizontal da caixa
        const de = Math.max(Math.min(a.x, b.x), caixa.x1);
        const ate = Math.min(Math.max(a.x, b.x), caixa.x2);
        if (de > ate) continue;

        const yEm = (x: number) =>
          a.x === b.x ? a.y : a.y + ((b.y - a.y) * (x - a.x)) / (b.x - a.x);
        const yDeTrecho = yEm(de);
        const yAte = yEm(ate);

        // a meia espessura entra na conta: o que o rótulo tem de evitar é o
        // traço desenhado, não a linha de centro por onde ele passa
        const meia = L.lineWidth / 2;
        if (
          Math.max(yDeTrecho, yAte) + meia >= caixa.y1 &&
          Math.min(yDeTrecho, yAte) - meia <= caixa.y2
        ) {
          return true;
        }
      }
    }
    return false;
  }

  function rotulosDaOnda(
    ano: number,
    yDe: (index: number) => (v: number) => number,
    xScale: (ano: number) => number,
    innerHeight: number,
  ): Rotulo[] {
    const x = xScale(ano);
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
        .map((s, index) => ({ s, index }))
        .filter(({ s }) => anosDaSerie(s.key).includes(ano))
        .map(({ s, index }) => ({
          key: s.key,
          text: rotuloDoPonto(s.pontos[0]),
          color: seriesColor(index),
          x: x - L.markerRadius - L.seriesLabelGap,
          marcadorY: yDe(index)(s.pontos[0].pct),
          anchor: 'end' as const,
          id: `${ano}-${s.key}`,
          xPonto: x,
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
      .filter((d) => d.ponto !== undefined && anosDaSerie(d.s.key).includes(ano))
      .map((d) => ({
        key: d.s.key,
        text: rotuloDoPonto(d.ponto!),
        color: seriesColor(d.index),
        // encostado no marcador, do lado que aponta para dentro do plot
        x: anchor === 'start' ? x + L.markerRadius : anchor === 'end' ? x - L.markerRadius : x,
        marcadorY: yDe(d.index)(d.ponto!.pct),
        anchor,
        id: `${ano}-${d.s.key}`,
        xPonto: x,
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

  /** Os anos em que uma série é anotada — ver `labelYears`. */
  const anosDaSerie = $derived((key: string) =>
    !labelYears ? anos : Array.isArray(labelYears) ? labelYears : (labelYears[key] ?? []),
  );

  /**
   * Anos em que alguma série é anotada — os que a figura precisa percorrer.
   *
   * O último ano sai da lista quando há bloco de ponta: o bloco já traz aquele
   * valor em corpo grande, e o rótulo sobre o marcador repetiria o mesmo número
   * a poucos pixels de distância.
   */
  const anosRotulados = $derived(
    [...new Set(series.flatMap((s) => anosDaSerie(s.key)))]
      .filter((ano) => !blocos || ano !== ultimoAno)
      .sort((a, b) => a - b),
  );

  /**
   * Todos os rótulos de valor da figura, colocados de uma vez.
   *
   * `rotulosDaOnda` resolve o que acontece *dentro* de um ano — qual rótulo vai
   * acima do marcador, qual desce, que folga fica entre eles. Isso bastava
   * enquanto os anos eram ondas de pesquisa, a oito anos de distância. Numa
   * série anual eles ficam a uma banda um do outro, e dois rótulos de anos
   * vizinhos se sobrepõem sem que nenhuma das duas passagens veja a outra — a
   * PNAB de 2023 e a Rouanet de 2024 saíam impressas uma por cima da outra.
   *
   * Então a colocação final é uma passagem só, sobre a lista inteira: cada
   * rótulo experimenta um punhado de posições em torno do seu marcador — a
   * altura que a passagem por ano lhe deu primeiro, e nela o centrado antes dos
   * encostados — e fica na primeira que não cruza traço, nome de série nem
   * rótulo já colocado. Nenhuma das posições o afasta do marcador mais que a
   * folga padrão, então qual delas saiu não muda a que ponto ele pertence.
   *
   * Só na variante fina. Na de faixa as ondas são poucas e largas, os rótulos
   * ficam longe do traço vizinho e a passagem por ano já resolve o que aparece
   * — mexer nisso ali só mudaria figuras que já estão certas.
   */
  function rotulosDeValor(
    yDe: (index: number) => (v: number) => number,
    xScale: (ano: number) => number,
    innerHeight: number,
    caixasDosNomes: Caixa[],
  ): Rotulo[] {
    const rotulos = anosRotulados.flatMap((ano) =>
      rotulosDaOnda(ano, yDe, xScale, innerHeight),
    );
    if (faixa) return rotulos;

    const linhas = polilinhas(yDe, xScale);
    const meiaAltura = Number(type.dado) * 0.6;
    const colocados = [...caixasDosNomes];

    const cruzam = (a: Caixa, b: Caixa) =>
      a.x1 < b.x2 && b.x1 < a.x2 && a.y1 < b.y2 && b.y1 < a.y2;

    for (const rotulo of rotulos) {
      const largura = measureLabel(rotulo.text, Number(type.dado), 600);
      const x = rotulo.xPonto;

      /** Nas ondas das pontas o lado é fixo: ver `ancoraDaOnda`. */
      const lados =
        rotulo.anchor === 'middle'
          ? [
              { anchor: 'middle' as const, x, x1: x - largura / 2, x2: x + largura / 2 },
              {
                anchor: 'end' as const,
                x: x - L.markerRadius,
                x1: x - L.markerRadius - largura,
                x2: x - L.markerRadius,
              },
              {
                anchor: 'start' as const,
                x: x + L.markerRadius,
                x1: x + L.markerRadius,
                x2: x + L.markerRadius + largura,
              },
            ]
          : [
              {
                anchor: rotulo.anchor,
                x: rotulo.x,
                x1: rotulo.anchor === 'end' ? rotulo.x - largura : rotulo.x,
                x2: rotulo.anchor === 'end' ? rotulo.x : rotulo.x + largura,
              },
            ];

      const alturas = [
        ...new Set([
          rotulo.y,
          rotulo.marcadorY - L.valueOffset,
          rotulo.marcadorY + L.valueOffset,
        ]),
      ];

      const posicoes = alturas.flatMap((y) => lados.map((lado) => ({ ...lado, y })));
      const caixaDe = (p: (typeof posicoes)[number]) => ({
        x1: p.x1,
        x2: p.x2,
        y1: p.y - meiaAltura,
        y2: p.y + meiaAltura,
      });

      // nenhuma posição livre: volta à primeira, que é onde o rótulo diz melhor
      // a que ponto pertence. Acontece quando um trecho íngreme fecha os dois
      // lados do ano — o sinal de que aquele ano não comporta a anotação, e de
      // que ela pertence a um vizinho
      const escolhida =
        posicoes.find((p) => {
          const caixa = caixaDe(p);
          if (caixa.y1 < 0 || caixa.y2 > innerHeight) return false;
          return !cruzaAlgumaLinha(caixa, linhas) && !colocados.some((c) => cruzam(c, caixa));
        }) ?? posicoes[0];

      rotulo.x = escolhida.x;
      rotulo.y = escolhida.y;
      rotulo.anchor = escolhida.anchor;
      colocados.push(caixaDe(escolhida));
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
    {@const yScale = scaleLinear()
      .domain([0, topo])
      .range([innerHeight - insetInferior, L.gapBand])}
    {@const yDe = escalaDaSerie(innerHeight)}
    {@const cardLeft = -margin.left + L.cardPadding}
    <!-- nomes primeiro: eles se prendem à ponta da sua linha e têm menos onde
         cair, então são os valores que desviam deles, e não o contrário -->
    {@const nomes =
      blocos || legend
        ? { rotulos: [], caixas: [] }
        : rotulosDeSerie(yDe, xScale, innerWidth, innerHeight)}
    {@const valores = rotulosDeValor(yDe, xScale, innerHeight, nomes.caixas)}

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
    {#if xGuides ?? faixa}
      <!-- uma vertical por ano marcado: a grade diz quando se mediu, não quanto -->
      {#each tickYears ?? anos as ano (ano)}
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
    {/if}

    {#if !faixa && !hideYAxis}
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
          text={rotuloDoTick(tick)}
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

      {#each trechos(pontos) as trecho, i (i)}
        <!-- um trecho de um ponto vira um segmento de comprimento zero, e não um
             `moveto` solto: só assim a ponta arredondada o pinta como um disco
             da largura do traço. Sem isso a Lei Paulo Gustavo, executada num ano
             só, ficaria com o marcador escuro sozinho, sem a cor da série -->
        {@const d =
          trecho.length === 1
            ? `M${xScale(trecho[0].ano)},${yDe(index)(trecho[0].pct)}l0,0`
            : (tracado(xScale, yDe(index))(trecho) ?? undefined)}
        <path
          {d}
          fill="none"
          stroke={color}
          stroke-width={L.lineWidth}
          stroke-linejoin="round"
          stroke-linecap="round"
        />
      {/each}

      {@const soltos = anosSoltos(pontos)}
      {#each pontos as ponto (ponto.ano)}
        <circle
          cx={xScale(ponto.ano)}
          cy={yDe(index)(ponto.pct)}
          r={blocos && ponto.ano === ultimoAno ? L.markerRadius * 1.5 : L.markerRadius}
          fill={marcadorNoTraco && !soltos.has(ponto.ano) ? tomDoMarcador(color) : color}
        />
      {/each}
    {/each}

    {#if blocos}
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
      {#each nomes.rotulos as rotulo (rotulo.key)}
        <Text
          x={rotulo.x}
          y={rotulo.y}
          textAnchor={rotulo.anchor}
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
    {#each valores as rotulo (rotulo.id)}
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

    <Axis
      orientation="bottom"
      scale={xScale}
      top={innerHeight + axisTop}
      tickValues={tickYears ?? anos}
      tickFormat={(v: number) => String(v)}
      hideAxisLine
      hideTicks
      tickLabelProps={tickLabelProps(
        faixa ? palette.neutral[300] : palette.neutral[200],
        faixa ? type.lg : type.md,
        500,
      )}
    />

    {#if legendLayout}
      <!-- alinhada à esquerda do plot, e não à do cartão: a faixa segmentada
           lê como uma régua sob as linhas que ela nomeia -->
      <LegendChips
        items={legendItems}
        left={0}
        top={innerHeight + legendTop}
        fontSize={Number(type.sm)}
        fontWeight={600}
        padX={L.legendPadX}
        rowGap={L.legendRowGap}
        maxWidth={larguraUtil}
        radius={4 * k}
      />
    {/if}

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
