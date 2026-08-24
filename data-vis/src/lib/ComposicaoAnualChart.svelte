<script lang="ts">
  /**
   * Composição percentual de um total anual — cada categoria como fatia de
   * 100%, ano a ano, num eixo de tempo.
   *
   * Difere do `ComposicaoPorOndaChart` no que o eixo X significa. Lá as ondas
   * são bandas iguais, porque entre 2006 e 2014 não se mediu nada e a distância
   * real não carregaria informação. Aqui há um valor por ano seguido, então o
   * eixo é linear no ano: os anos ficam à distância que têm, e a figura pode
   * ser lida ao lado da série de valores absolutos sem que os dois eixos
   * discordem.
   *
   * Duas formas, ver `forma`, e a diferença entre elas é só o vão lateral: em
   * `colunas` cada ano é uma coluna sua, em `area` os anos vizinhos se encostam
   * e cada categoria vira uma faixa contínua. Nenhuma das duas interpola: a
   * faixa muda de altura em degrau, na virada do ano, porque entre dois anos de
   * execução orçamentária não existe valor intermediário — e uma fonte que
   * durou um ano só (a Lei Paulo Gustavo) viraria um pico triangular se a
   * altura fosse interpolada, desenhando uma entrada e uma saída graduais que
   * não houve.
   *
   * O que a figura **não** tem, de propósito:
   *
   * - grade horizontal. Numa pilha que fecha em 100% o desenho cobre o plot
   *   inteiro, e qualquer linha atrás dela fica escondida. Sobram os rótulos do
   *   eixo Y na margem.
   * - eixo Y de valor. A pilha vai sempre de 0 a 100, então o teto é uma
   *   constante e não uma medida.
   * - rótulo em todo segmento. A figura escreve a participação onde ela cabe, e
   *   o que decide não é uma lista de anos escolhidos a dedo, é a geometria: um
   *   segmento que não contenha o próprio número fica sem ele. Das 86 parcelas
   *   não nulas da série federal, 64 recebem número; das 22 que ficam de fora,
   *   19 são finas demais — abaixo de ~4%, onde o número encostaria nas duas
   *   fronteiras ao mesmo tempo — e 3 são largas demais, os anos de fonte única
   *   em que `100%` não cabe na coluna. Ver `labelYears` para restringir isso
   *   ainda mais.
   */
  import { curveMonotoneX, line as d3Line, scaleLinear } from 'd3';
  import {
    Chart,
    DefaultTheme,
    getContrastColor,
    getPillarTheme,
    resolveThemeStyle,
    Text,
    type ChartDimensions,
    type ChartTheme,
  } from 'sniic-design-system';
  import LegendChips from './LegendChips.svelte';
  import TextLines from './TextLines.svelte';
  import { layoutLegend } from './legend';
  import { categoricaMarca } from './cores';
  import {
    a4Scale,
    fontFamily,
    fontSize as scale,
    labelFitsInBar,
    wrapText,
  } from './tokens';

  /** Um ano: o rótulo do eixo e o valor de cada categoria naquele ano. */
  export type AnoRow = { label: string } & Record<string, number | string>;

  /**
   * `colunas` — uma coluna por ano, separadas por um vão. A unidade de leitura
   * é o ano, e é a forma certa quando o que se compara é a repartição interna
   * de cada um.
   *
   * `area` — os anos encostados, cada categoria como faixa contínua em degrau.
   * A unidade de leitura passa a ser a categoria: dá para seguir uma faixa da
   * esquerda à direita, que é o que a coluna isolada não deixa fazer.
   */
  export type Forma = 'colunas' | 'area';

  /**
   * Onde a curva de fronteira passa, na forma `colunas`.
   *
   * `borda`, o padrão — dois pontos por ano, um em cada borda da coluna. A
   * curva sai plana sobre a coluna, caindo dentro do vão de superfície entre os
   * dois segmentos, e curva só no vão entre colunas. É a fiel à medida: o valor
   * é constante dentro do exercício, e a curva só se move na virada do ano, que
   * é onde a mudança aconteceu. A transição é curta — o vão entre colunas mede
   * 4,4 unidades — mas basta para o olho seguir a fronteira de ponta a ponta.
   *
   * `centro` — um ponto por ano, no meio da coluna, que é a convenção de
   * qualquer linha desenhada sobre barras. A transição passa a ocupar a faixa
   * inteira do ano, então a curvatura é bem maior; o preço é que a curva
   * atravessa a coluna em diagonal, encostando na fronteira exata só no centro
   * dela, e por isso precisa de um casing largo para não sumir dentro da
   * própria fatia — que corta a pilha em faixas brancas.
   */
  export type AncoragemCurva = 'borda' | 'centro';

  /**
   * Uma anotação sobre um trecho do eixo — a chave em `de`..`ate`, e o texto
   * acima dela.
   *
   * Existe para o caso em que a figura precisa dizer algo sobre a *cobertura*
   * de alguns anos, e não sobre o valor deles. Num gráfico de participação
   * qualquer buraco na série vira afirmação: uma fonte que falta não fica em
   * branco, ela empurra a participação de todas as outras para cima.
   */
  export type Span = { de: number; ate: number; texto: string };

  interface Props {
    data: AnoRow[];
    /** Categorias na ordem em que empilham, da base para o topo. */
    keys: string[];
    labels?: Record<string, string>;
    /** Cores na ordem de `keys`; por omissão, a paleta categórica do DS. */
    colors?: readonly string[];
    forma?: Forma;
    /**
     * Desenha a fronteira de cima de cada categoria como curva, por sobre a
     * pilha.
     *
     * O que a figura ganha com isso: a pilha sozinha diz a repartição de cada
     * ano, mas não deixa seguir uma categoria da esquerda para a direita —
     * cada fatia começa numa altura diferente, decidida por quem está embaixo.
     * A curva liga as fronteiras de uma mesma categoria e devolve a
     * trajetória, sem tirar a composição: a distância vertical entre duas
     * curvas vizinhas continua sendo a participação da categoria entre elas.
     *
     * Só faz sentido na forma `colunas`. Em `area` as faixas já são contínuas,
     * e é justamente por isso que aquela forma existe.
     */
    curvas?: boolean;
    /** Ver `AncoragemCurva`. Só vale com `curvas`. */
    ancoragemCurva?: AncoragemCurva;
    title: string;
    subtitle?: string;
    footnote?: string;
    source?: string;
    /**
     * Em que anos a participação é escrita dentro do segmento. Por omissão,
     * todos — o que sobra depois é decidido pelo espaço, não pela lista.
     *
     * Uma lista vale para todas as categorias; um mapa por chave anota cada uma
     * nos seus próprios anos, e uma categoria ausente do mapa não é anotada.
     * Serve para uma figura em que a leitura seja outra — poucos anos marcados
     * como argumento, e não a matriz inteira legível.
     *
     * De qualquer modo o rótulo só sai se couber no segmento: a lista tira
     * números, nunca força um a aparecer onde não há espaço. Ver `participacao`
     * e `cabe`.
     */
    labelYears?: number[] | Record<string, number[]>;
    /** Anos marcados no eixo X. Por omissão, todos. */
    tickYears?: number[];
    /** Anotações de cobertura sobre trechos do eixo — ver `Span`. */
    spans?: Span[];
    /**
     * Fatia da faixa anual ocupada pela coluna, na forma `colunas`.
     *
     * Muito mais largo do que a proporção habitual de uma figura de colunas, e
     * por uma razão de rótulo: nesta largura de cartão um ano ocupa 54,9
     * unidades e o rótulo mais largo da série federal — `44%` — mede 44,3.
     * O vão entre colunas é o que sobra depois de garantir que o número caiba
     * dentro delas, e não o contrário. Ver `participacao`.
     *
     * O que sobra são 4,4 unidades, 0,54 mm no impresso, e é o bastante: a
     * pilha é lida por cor, não por contorno, e o vão só precisa dizer onde uma
     * coluna acaba. Um rótulo que ainda assim não couber simplesmente não é
     * escrito — o ajuste é medido a cada rótulo, não presumido.
     */
    columnRatio?: number;
    /**
     * Largura intrínseca, em unidades de SVG. O tipo é absoluto nessas
     * unidades, então é isto que fixa o tamanho impresso dos rótulos — o cartão
     * inteiro escala para a largura física em que for colocado. Dimensionado
     * para a coluna de texto de um A4 retrato.
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
    data,
    keys,
    labels = {},
    colors = categoricaMarca,
    forma = 'colunas',
    curvas = false,
    ancoragemCurva = 'borda',
    title,
    subtitle,
    footnote,
    source,
    labelYears,
    tickYears,
    spans = [],
    columnRatio = 0.92,
    width = 1368,
    height,
    responsive = false,
    pillar = 1,
    background,
    svgEl = $bindable(null),
  }: Props = $props();

  /**
   * Tudo abaixo é escrito contra `fontSize.md` e multiplicado por isto — tipo e
   * cromo juntos — para o cartão imprimir nos mesmos tamanhos das outras
   * figuras, qualquer que seja a largura em que for escrito.
   */
  const k = $derived(a4Scale(width));

  const TITLE_FONT_SIZE = 14;

  const type = $derived({
    title: TITLE_FONT_SIZE * k,
    lg: scale.lg * k,
    md: scale.md * k,
    sm: scale.sm * k,
    xs: scale.xs * k,
  });

  const theme = $derived(getPillarTheme(pillar));
  const palette = $derived(theme.palette);

  const categoriaColor = (index: number) => colors[index % colors.length];

  const L = $derived({
    cardPadding: 24 * k,
    cardRadius: 12 * k,
    /**
     * As duas margens do plot são as mais estreitas que o cartão sustenta, e a
     * largura que elas devolvem vai toda para a coluna — é ela que precisa
     * caber um rótulo de participação.
     *
     * À esquerda sobram 4 unidades sobre `100%` mais o seu vão; à direita não
     * há nada para reservar, porque a última coluna termina no fim do plot e o
     * recuo do cartão já a afasta da borda.
     */
    marginLeft: 38 * k,
    marginRight: 14 * k,
    titleLine: 24 * k,
    subtitleLine: 15 * k,
    noteLine: 14 * k,
    titleBlockGap: 26 * k,
    /**
     * Mais alto que o cartão de ondas: 23 anos numa largura de coluna de A4
     * dão uma faixa de ~50 unidades por ano, e num plot baixo a figura sairia
     * mais larga que alta com fatias de poucas unidades de altura.
     */
    plotHeight: 320 * k,
    /** Base do plot ao rótulo do ano. */
    anoLabelGap: 20 * k,
    /** Base do plot à faixa de legenda. */
    legendGap: 46 * k,
    legendRowGap: 4 * k,
    noteGap: 18 * k,
    noteSpacing: 3 * k,
    segmentRadius: 2 * k,
    /** Metade do vão de superfície entre segmentos vizinhos. */
    segmentGap: 1 * k,
    /**
     * Espessura da curva de fronteira, mais o casing de cada lado.
     *
     * As duas somam exatamente o vão de superfície entre dois segmentos — o
     * dobro de `segmentGap` — e é essa a razão da conta: sobre a coluna a curva
     * cai dentro do vão que já existia, com um fio de superfície de cada lado,
     * e a pilha sai com a mesma geometria que tinha sem curva nenhuma. A figura
     * ganha a trajetória sem pagar um pixel de fatia.
     *
     * O casing não é enfeite: sem ele a curva se cola na fatia de baixo, que é
     * da mesma cor, e some — a fronteira passaria a parecer só o topo da faixa,
     * que é o que já era.
     */
    fronteiraWidth: 1.2 * k,
    fronteiraCasing: 0.4 * k,
    /** Traço e vão da ponte sobre os anos sem execução. */
    fronteiraDash: `${3.5 * k} ${2.5 * k}`,
    /** Do topo do plot ao colchete de cobertura, e dele ao seu texto. */
    spanGap: 10 * k,
    spanTick: 5 * k,
    spanTextGap: 6 * k,
    /** Do eixo Y ao plot. */
    tickGap: 8 * k,
  });

  const titleStyle = $derived(
    resolveThemeStyle<ChartTheme, 'text'>(
      { fontSize: type.title, fontWeight: 600, fill: palette.neutral[300], fontFamily },
      theme.text,
      DefaultTheme.text,
    )!,
  );
  const subtitleStyle = $derived(
    resolveThemeStyle<ChartTheme, 'text'>(
      { fontSize: type.md, fill: palette.neutral[200], fontFamily },
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
  const segmentStyle = $derived(
    resolveThemeStyle<ChartTheme, 'dataLabel'>(
      { fontSize: type.xs, fontWeight: 600, fontFamily },
      theme.dataLabel,
      DefaultTheme.dataLabel,
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

  const legendItems = $derived(
    keys.map((key, i) => ({ label: labels[key] ?? key, color: categoriaColor(i) })),
  );

  /**
   * A legenda é diagramada antes do cartão para a margem inferior reservar a
   * altura que ela realmente vai ocupar — oito categorias não cabem numa linha
   * só na coluna de um A4.
   */
  const legend = $derived(
    layoutLegend(legendItems, {
      fontSize: Number(segmentStyle.fontSize),
      fontWeight: Number(segmentStyle.fontWeight),
      padX: 10 * k,
      maxWidth: textWidth,
      rowGap: L.legendRowGap,
    }),
  );

  const spanBlock = $derived(
    spans.length ? L.spanGap + L.spanTextGap + type.xs * 1.2 : 0,
  );

  const MARGIN = $derived({
    left: L.marginLeft,
    right: L.marginRight,
    top:
      L.cardPadding +
      titleLines.length * L.titleLine +
      subtitleLines.length * L.subtitleLine +
      L.titleBlockGap +
      spanBlock,
    bottom:
      L.legendGap +
      legend.height +
      L.noteGap +
      footnoteLines.length * L.noteLine +
      (footnoteLines.length && sourceLines.length ? L.noteSpacing : 0) +
      sourceLines.length * L.noteLine +
      L.cardPadding,
  });

  const cardHeight = $derived(height ?? MARGIN.top + L.plotHeight + MARGIN.bottom);

  const anos = $derived(data.map((d) => Number(d.label)));
  const valor = (row: AnoRow, key: string) => Number(row[key]) || 0;

  /** Todos os anos, quando `tickYears` não escolhe alguns. */
  const ticks = $derived(tickYears ?? anos);

  const anotados = $derived((key: string): number[] =>
    labelYears === undefined
      ? anos
      : Array.isArray(labelYears)
        ? labelYears
        : (labelYears[key] ?? []),
  );

  type Segmento = {
    key: string;
    keyIndex: number;
    /** Participação no total do ano, em pontos percentuais. */
    share: number;
    /** Geometria já com o vão de superfície descontado. */
    y: number;
    height: number;
    /**
     * A fronteira de cima antes do vão — a soma acumulada até esta categoria,
     * inclusive. É por onde a curva passa, e não por `y`: `y` já está deslocado
     * para dentro do segmento para abrir o vão de superfície, e uma curva ali
     * sairia meio ponto percentual acima do que mede.
     */
    fronteira: number;
    /** Esta categoria fecha a pilha do ano — a fronteira dela é o teto de 100%. */
    noTopo: boolean;
  };

  /**
   * Os segmentos de um ano, normalizados ao próprio total — assim as colunas
   * fecham exatamente em 100% mesmo onde as parcelas não somam certo por
   * arredondamento.
   *
   * Uma categoria zerada é omitida, e não desenhada com altura zero: zero aqui
   * quase nunca é uma medida, é ausência — a fonte não existia naquele ano — e
   * um segmento invisível ainda abriria o seu vão de superfície.
   */
  function layoutAno(row: AnoRow, yScale: (v: number) => number): Segmento[] {
    const total = keys.reduce((soma, key) => soma + valor(row, key), 0) || 1;

    const presentes = keys
      .map((key, keyIndex) => ({ key, keyIndex, valor: valor(row, key) }))
      .filter((s) => s.valor > 0);

    let cursor = 0;
    const brutos = presentes.map(({ key, keyIndex, valor: v }) => {
      const share = (v / total) * 100;
      const base = yScale(cursor);
      cursor += share;
      const topo = yScale(cursor);
      return { key, keyIndex, share, y: topo, height: base - topo, fronteira: topo };
    });

    // o vão só existe entre dois segmentos: as pontas da pilha são 0% e 100%
    return brutos.map((s, i) => {
      const primeiro = i === 0;
      const ultimo = i === brutos.length - 1;
      return {
        ...s,
        noTopo: ultimo,
        y: s.y + (ultimo ? 0 : L.segmentGap),
        height: Math.max(
          s.height - (primeiro ? 0 : L.segmentGap) - (ultimo ? 0 : L.segmentGap),
          0,
        ),
      };
    });
  }

  /**
   * Trechos de anos seguidos em que a categoria existe, na forma `area`.
   *
   * Cada trecho vira uma faixa sua, e o buraco entre dois deles fica em branco:
   * o Ministério da Cultura não aparece de 2019 a 2022 porque foi extinto, e
   * uma faixa única atravessando esses quatro anos desenharia um ministério que
   * não existia.
   */
  function trechos(indices: number[]): number[][] {
    const partes: number[][] = [];
    for (const i of indices) {
      const atual = partes[partes.length - 1];
      if (atual && anos[i] - anos[atual[atual.length - 1]] === 1) atual.push(i);
      else partes.push([i]);
    }
    return partes;
  }

  /**
   * A faixa de uma categoria ao longo de um trecho: a borda de cima da esquerda
   * para a direita, a de baixo na volta.
   *
   * Cada ano contribui com dois pontos na mesma altura — o degrau é o que
   * mantém a faixa fiel ao que se mediu, um valor por exercício, sem inventar a
   * rampa entre dois anos.
   */
  function faixaPath(
    segmentos: (Segmento | undefined)[],
    indices: number[],
    x: (ano: number) => number,
    meia: number,
  ) {
    const topo: string[] = [];
    const base: string[] = [];

    indices.forEach((i, ordem) => {
      const s = segmentos[i]!;
      const [esquerda, direita] = [x(anos[i]) - meia, x(anos[i]) + meia];
      // a volta é escrita da direita para a esquerda, e cada ano entra na
      // frente da lista já invertido — o par na ordem de ida fecharia a faixa
      // em laço, cruzando o próprio contorno
      topo.push(`${ordem === 0 ? 'M' : 'L'}${esquerda},${s.y}`, `L${direita},${s.y}`);
      base.unshift(`L${direita},${s.y + s.height}`, `L${esquerda},${s.y + s.height}`);
    });

    return [...topo, ...base, 'Z'].join(' ');
  }

  /**
   * Os trechos em que a fronteira de cima de uma categoria é desenhável.
   *
   * Há duas maneiras de um ano ficar sem fronteira, e elas não se tratam igual:
   *
   * - **A categoria não existe naquele ano.** A fronteira fica indefinida e o
   *   trecho continua por cima do buraco: o Ministério da Cultura não aparece
   *   de 2019 a 2022 porque foi extinto, e a curva atravessa os quatro anos
   *   ligando 2018 a 2023. Partir a curva aí deixaria a maior série da figura
   *   em dois pedaços que ninguém liga de olho — mas a ponte é desenhada
   *   tracejada, porque ela cruza quatro colunas inteiras e um traço contínuo
   *   afirmaria uma trajetória que não foi medida. Ver `tracosDeFronteira`.
   * - **A categoria fecha a pilha.** Aí a fronteira dela não é indefinida, é o
   *   teto de 100% — que a borda do plot e o rótulo do eixo já marcam. O trecho
   *   quebra, porque uma curva ali seria uma linha de cor deitada sobre a borda
   *   do plot, e porque a participação da categoria continua legível como o vão
   *   entre a curva de baixo e o teto. É o caso da ANCINE, que fecha a pilha de
   *   2006 a 2019 e só ganha curva quando a PNAB entra por cima dela.
   *
   * Um trecho de um ano só não vira curva: não há para onde ir.
   */
  function trechosDeFronteira(porAno: (Segmento | undefined)[]): number[][] {
    const partes: number[][] = [];
    let atual: number[] | null = null;

    porAno.forEach((s, i) => {
      if (s?.noTopo) atual = null;
      else if (s) {
        if (!atual) partes.push((atual = []));
        atual.push(i);
      }
    });

    return partes.filter((trecho) => trecho.length > 1);
  }

  /**
   * `curveMonotoneX` e não uma spline qualquer: ela não ultrapassa os pontos
   * que liga. Numa figura de participação isso não é preferência — uma spline
   * comum poria a fronteira acima do maior dos dois valores medidos, e como a
   * fronteira é uma soma acumulada, a curva de cima cruzaria a de baixo e
   * desenharia uma fatia de espessura negativa.
   */
  const curvaFronteira = d3Line<[number, number]>()
    .x((p) => p[0])
    .y((p) => p[1])
    .curve(curveMonotoneX);

  /** Os pontos com que um ano entra na curva. Ver `AncoragemCurva`. */
  const pontosDoAno = (
    fronteira: number,
    centro: number,
    meia: number,
  ): [number, number][] =>
    ancoragemCurva === 'centro'
      ? [[centro, fronteira]]
      : [
          [centro - meia, fronteira],
          [centro + meia, fronteira],
        ];

  /**
   * Os traços que desenham a fronteira de uma categoria ao longo de um trecho.
   *
   * Um traço contínuo por corrida de anos seguidos, e entre duas corridas uma
   * ponte tracejada sobre os anos em que a categoria não existiu. A ponte é
   * desenhada à parte, e não como um pedaço tracejado da mesma curva, porque
   * `curveMonotoneX` calcula a tangente de cada ponto a partir dos vizinhos:
   * uma curva só, cortada depois, sairia com um desenho diferente do que estes
   * dois traços dão, e as pontas não encostariam.
   */
  function tracosDeFronteira(
    porAno: (Segmento | undefined)[],
    trecho: number[],
    x: (ano: number) => number,
    meia: number,
  ): { d: string; ponte: boolean }[] {
    const corridas: number[][] = [];
    for (const i of trecho) {
      const atual = corridas[corridas.length - 1];
      if (atual && anos[i] - anos[atual[atual.length - 1]] === 1) atual.push(i);
      else corridas.push([i]);
    }

    const pontos = (indices: number[]) =>
      indices.flatMap((i) => pontosDoAno(porAno[i]!.fronteira, x(anos[i]), meia));

    const tracos = corridas
      .map((corrida) => curvaFronteira(pontos(corrida)))
      .filter((d): d is string => d !== null)
      .map((d) => ({ d, ponte: false }));

    for (const [n, corrida] of corridas.entries()) {
      const proxima = corridas[n + 1];
      if (!proxima) continue;
      const d = curvaFronteira(pontos([corrida[corrida.length - 1], proxima[0]]));
      if (d) tracos.push({ d, ponte: true });
    }

    return tracos;
  }

  /** Um segmento de coluna, arredondado só onde a pilha termina. */
  function segmentPath(
    x: number,
    y: number,
    largura: number,
    altura: number,
    radiusTop: number,
    radiusBottom: number,
  ) {
    const cap = Math.min(largura / 2, altura / 2);
    const top = Math.max(0, Math.min(radiusTop, cap));
    const bottom = Math.max(0, Math.min(radiusBottom, cap));

    return [
      `M${x},${y + top}`,
      top ? `A${top},${top} 0 0 1 ${x + top},${y}` : '',
      `H${x + largura - top}`,
      top ? `A${top},${top} 0 0 1 ${x + largura},${y + top}` : '',
      `V${y + altura - bottom}`,
      bottom ? `A${bottom},${bottom} 0 0 1 ${x + largura - bottom},${y + altura}` : '',
      `H${x + bottom}`,
      bottom ? `A${bottom},${bottom} 0 0 1 ${x},${y + altura - bottom}` : '',
      'Z',
    ]
      .filter(Boolean)
      .join(' ');
  }

  /**
   * A participação escrita dentro do segmento: inteiro, com o sinal.
   *
   * A casa decimal fica na tabela por fonte, que é onde ela vale — aqui ela
   * custaria 14 unidades de largura para separar 30,8% de 31%, distinção que
   * nenhuma decisão desta figura depende.
   *
   * O sinal custa outras 13, e é o resto do cartão que paga por ele: com ele o
   * rótulo mais largo mede 44,3 unidades num ano que ocupa 54,9, então as
   * margens do plot são as mais estreitas que o cartão sustenta, a coluna é
   * larga (ver `columnRatio`) e a folga lateral do rótulo é curta
   * (`LABEL_PADDING`). Vale a despesa porque o número aparece longe do eixo —
   * no meio de uma pilha alta, com outros números por perto —, e sem o sinal
   * `31` ao lado de `2023` é apenas um número solto.
   */
  const participacao = (share: number) => `${Math.round(share)}%`;

  /**
   * Folga entre o rótulo e a borda do segmento, de cada lado.
   *
   * Curta de propósito: 0,32 mm no impresso. É o que sobra depois de garantir
   * que `44%` caiba dentro de uma coluna, e ainda assim basta, porque a folga é
   * sobre cor chapada — não há nada de que o número precise se afastar além da
   * própria borda, e a coluna vizinha está a mais de meio milímetro.
   */
  const LABEL_PADDING = $derived(1.2 * k);

  /**
   * Cabe escrever a participação dentro deste segmento?
   *
   * A altura é medida contra o corpo do tipo mais uma folga curta, e não contra
   * a entrelinha cheia: o que ocupa espaço num dígito é a altura de versal —
   * uns 70% do corpo — e exigir a linha inteira cobraria por um espaço que o
   * número não usa. A conta é feita sobre a altura já desenhada, com o vão de
   * superfície descontado, então a folga que sobra é folga de verdade.
   *
   * Onde isso cai, na série federal: uma fatia de 4% ainda recebe o seu número,
   * uma de 3% não.
   */
  const cabe = $derived((label: string, segmento: Segmento, largura: number) => {
    const size = Number(segmentStyle.fontSize);
    return (
      segmento.height >= size * 1.05 + 1 * k &&
      labelFitsInBar(
        label,
        size,
        largura,
        Number(segmentStyle.fontWeight),
        LABEL_PADDING,
        LABEL_PADDING,
      )
    );
  });
</script>

<Chart
  {fontFamily}
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
    <!-- meio ano de folga de cada lado: o eixo é linear no ano, mas o que ele
         posiciona é uma coluna, e a coluna tem largura -->
    {@const xScale = scaleLinear()
      .domain([anos[0] - 0.5, anos[anos.length - 1] + 0.5])
      .range([0, innerWidth])}
    {@const yScale = scaleLinear().domain([0, 100]).range([innerHeight, 0])}
    {@const x = (ano: number) => xScale(ano)}
    {@const faixaAnual = innerWidth / anos.length}
    {@const largura = faixaAnual * (forma === 'colunas' ? columnRatio : 1)}
    {@const colunas = data.map((row) => layoutAno(row, (v) => yScale(v)))}
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

    <!-- a pilha vai de 0 a 100 e cobre o plot inteiro, então a escala só pode
         viver na margem: uma grade atrás dela ficaria escondida -->
    {#each [0, 25, 50, 75, 100] as tick (tick)}
      <Text
        x={-L.tickGap}
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

    <!-- colchete de cobertura: o texto começa na borda esquerda do trecho, e
         não centrado nele — a nota é sempre mais larga que os poucos anos que
         descreve, e centrada sairia do plot -->
    {#each spans as span (span.de)}
      {@const esquerda = x(span.de) - largura / 2}
      {@const direita = x(span.ate) + largura / 2}
      {@const y = -L.spanGap}
      <path
        d={`M${esquerda},${y - L.spanTick} V${y} H${direita} V${y - L.spanTick}`}
        fill="none"
        stroke={palette.neutral[100]}
        stroke-width={k}
      />
      <Text
        x={esquerda}
        y={y - L.spanTick - L.spanTextGap}
        textAnchor="start"
        verticalAnchor="end"
        fontSize={type.xs}
        fontWeight={500}
        {fontFamily}
        fill={palette.neutral[100]}
        text={span.texto}
      />
    {/each}

    {#if forma === 'area'}
      {#each keys as key, keyIndex (key)}
        {@const porAno = colunas.map((segmentos) => segmentos.find((s) => s.key === key))}
        {@const presentes = porAno.flatMap((s, i) => (s ? [i] : []))}
        {#each trechos(presentes) as trecho (trecho[0])}
          <path
            d={faixaPath(porAno, trecho, x, largura / 2)}
            fill={categoriaColor(keyIndex)}
          />
        {/each}
      {/each}
    {:else}
      {#each colunas as segmentos, i (anos[i])}
        {#each segmentos as segmento, index (segmento.key)}
          <path
            d={segmentPath(
              x(anos[i]) - largura / 2,
              segmento.y,
              largura,
              segmento.height,
              index === segmentos.length - 1 ? L.segmentRadius : 0,
              index === 0 ? L.segmentRadius : 0,
            )}
            fill={categoriaColor(segmento.keyIndex)}
          />
        {/each}
      {/each}
    {/if}

    <!--
      A curva de fronteira, entre a pilha e os rótulos: por cima das fatias,
      que é o que a torna visível, e por baixo dos números, que continuam
      sendo o que se lê primeiro dentro de um segmento.

      Cada curva sai em dois traços. O de baixo é da cor da superfície e mais
      grosso — sem ele, o trecho da curva que corre por dentro da própria fatia
      ficaria invisível, porque é da mesma cor dela, e a curva apareceria
      picotada, aparecendo só quando cruza para a fatia de cima.
    -->
    {#if curvas}
      {#each keys as key, keyIndex (key)}
        {@const porAno = colunas.map((segmentos) => segmentos.find((s) => s.key === key))}
        {#each trechosDeFronteira(porAno) as trecho (trecho[0])}
          {#each tracosDeFronteira(porAno, trecho, x, largura / 2) as traco, n (n)}
            {@const dash = traco.ponte ? L.fronteiraDash : undefined}
            <path
              d={traco.d}
              fill="none"
              stroke={background ?? palette.base[100]}
              stroke-width={L.fronteiraWidth + L.fronteiraCasing * 2}
              stroke-linecap="round"
              stroke-dasharray={dash}
            />
            <path
              d={traco.d}
              fill="none"
              stroke={categoriaColor(keyIndex)}
              stroke-width={L.fronteiraWidth}
              stroke-linecap="round"
              stroke-dasharray={dash}
            />
          {/each}
        {/each}
      {/each}
    {/if}

    <!-- os rótulos depois de toda a pilha, para nenhum ficar sob a faixa
         vizinha na forma de área, onde as faixas se encostam -->
    {#each colunas as segmentos, i (anos[i])}
      {#each segmentos as segmento (segmento.key)}
        {#if anotados(segmento.key).includes(anos[i])}
          {@const label = participacao(segmento.share)}
          {#if cabe(label, segmento, largura)}
            <Text
              x={x(anos[i])}
              y={segmento.y + segmento.height / 2}
              textAnchor="middle"
              verticalAnchor="middle"
              fontSize={segmentStyle.fontSize}
              fontWeight={segmentStyle.fontWeight}
              fontFamily={segmentStyle.fontFamily}
              fill={getContrastColor(categoriaColor(segmento.keyIndex))}
              text={label}
            />
          {/if}
        {/if}
      {/each}
    {/each}

    {#each ticks as ano (ano)}
      <Text
        x={x(ano)}
        y={innerHeight + L.anoLabelGap}
        textAnchor="middle"
        verticalAnchor="middle"
        fontSize={type.sm}
        fontWeight={500}
        {fontFamily}
        fill={palette.neutral[200]}
        text={String(ano)}
      />
    {/each}

    <LegendChips
      items={legendItems}
      left={cardLeft}
      top={innerHeight + L.legendGap}
      padX={10 * k}
      maxWidth={textWidth}
      rowGap={L.legendRowGap}
      fontSize={Number(segmentStyle.fontSize)}
      fontFamily={segmentStyle.fontFamily}
      fontWeight={segmentStyle.fontWeight}
      radius={L.segmentRadius}
    />

    {@const notesTop = innerHeight + L.legendGap + legend.height + L.noteGap}

    <TextLines
      lines={footnoteLines}
      x={cardLeft}
      y={notesTop}
      lineHeight={L.noteLine}
      fontSize={noteStyle.fontSize}
      fontWeight={noteStyle.fontWeight}
      fontFamily={noteStyle.fontFamily}
      fill={noteStyle.fill}
    />

    <TextLines
      lines={sourceLines}
      x={cardLeft}
      y={notesTop + footnoteLines.length * L.noteLine + (footnoteLines.length ? L.noteSpacing : 0)}
      lineHeight={L.noteLine}
      fontSize={noteStyle.fontSize}
      fontWeight={noteStyle.fontWeight}
      fontFamily={noteStyle.fontFamily}
      fill={noteStyle.fill}
    />
  {/snippet}
</Chart>
