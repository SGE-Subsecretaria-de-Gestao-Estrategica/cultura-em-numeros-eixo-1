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
   */
  import { scaleLinear } from 'd3';
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

  /** Um ponto da série: o ano da onda e o percentual medido nela. */
  export type Ponto = { ano: number; pct: number };
  export type Serie = { key: string; label: string; pontos: Ponto[] };

  interface Props {
    series: Serie[];
    title: string;
    subtitle?: string;
    footnote?: string;
    source?: string;
    /** Cores na ordem de `series`; por omissão, a paleta categórica do DS. */
    colors?: readonly string[];
    /** Teto do eixo; por omissão, o próximo múltiplo de 10 acima do maior valor. */
    yMax?: number;
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
    yMax,
    width = 1368,
    height,
    responsive = false,
    pillar = 1,
    background,
    svgEl = $bindable(null),
  }: Props = $props();

  /**
   * Tudo abaixo é escrito contra `fontSize.md` e multiplicado por isto — tipo e
   * cromo juntos — para o cartão imprimir nos mesmos tamanhos das figuras A4 do
   * RibbonChart, qualquer que seja a largura em que for escrito.
   */
  const k = $derived(a4Scale(width));

  const TITLE_FONT_SIZE = 20;

  const type = $derived({
    title: TITLE_FONT_SIZE * k,
    md: scale.md * k,
    sm: scale.sm * k,
    xs: scale.xs * k,
  });

  const theme = $derived(getPillarTheme(pillar));
  const palette = $derived(theme.palette);

  const seriesColor = (index: number) => colors[index % colors.length];

  const anos = $derived([...new Set(series.flatMap((s) => s.pontos.map((p) => p.ano)))].sort());

  /**
   * A margem direita é medida no rótulo de série mais largo, não chutada: é ela
   * que decide se "Teatro ou sala de espetáculo" cabe ao lado da linha ou sai
   * cortado na borda do cartão.
   */
  const rotuloMaisLargo = $derived(
    Math.max(...series.map((s) => measureLabel(s.label, type.sm, 600))),
  );

  const L = $derived({
    cardPadding: 24 * k,
    cardRadius: 12 * k,
    marginLeft: 46 * k,
    /** Espaço da ponta da linha até o texto, mais o texto. */
    seriesLabelGap: 10 * k,
    titleLine: 24 * k,
    subtitleLine: 15 * k,
    noteLine: 14 * k,
    titleBlockGap: 26 * k,
    /** Base do plot até a primeira linha de nota. */
    noteGap: 34 * k,
    noteSpacing: 3 * k,
    /** Altura do plot: fixa, para o cartão não mudar de forma com o nº de séries. */
    plotHeight: 250 * k,
    markerRadius: 4 * k,
    lineWidth: 2.2 * k,
    /** Rótulo de valor acima do seu marcador. */
    valueOffset: 13 * k,
    /** Afastamento mínimo entre dois rótulos de valor da mesma onda. */
    valueSpacing: 12 * k,
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

  const textWidth = $derived(width - L.cardPadding * 2);
  const titleLines = $derived(
    wrapText(title, type.title, textWidth, Number(titleStyle.fontWeight)),
  );
  const subtitleLines = $derived(
    wrapText(subtitle ?? '', type.md, textWidth, Number(subtitleStyle.fontWeight)),
  );
  const footnoteLines = $derived(wrapText(footnote ?? '', type.sm, textWidth));
  const sourceLines = $derived(wrapText(source ?? '', type.sm, textWidth));

  const MARGIN = $derived({
    left: L.marginLeft,
    right: L.seriesLabelGap + rotuloMaisLargo + L.cardPadding,
    top:
      L.cardPadding +
      titleLines.length * L.titleLine +
      subtitleLines.length * L.subtitleLine +
      L.titleBlockGap,
    bottom:
      L.noteGap +
      footnoteLines.length * L.noteLine +
      (footnoteLines.length && sourceLines.length ? L.noteSpacing : 0) +
      sourceLines.length * L.noteLine +
      L.cardPadding,
  });

  const cardHeight = $derived(height ?? MARGIN.top + L.plotHeight + MARGIN.bottom);

  const decimal = new Intl.NumberFormat('pt-BR', {
    minimumFractionDigits: 1,
    maximumFractionDigits: 1,
  });
  const pct = (v: number) => `${decimal.format(v)}%`;

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
    ano === anos[0] ? 'start' : ano === anos[anos.length - 1] ? 'end' : 'middle';

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
  function rotulosDaOnda(ano: number, yScale: (v: number) => number, x: number): Rotulo[] {
    const anchor = ancoraDaOnda(ano);
    /** Folga vertical de que um rótulo precisa para caber acima do marcador. */
    const folga = L.valueOffset + Number(type.xs) * 0.6;

    const pontos = series
      .map((s, index) => ({ s, index, ponto: s.pontos.find((p) => p.ano === ano) }))
      .filter((d) => d.ponto !== undefined)
      .map((d) => ({
        key: d.s.key,
        text: pct(d.ponto!.pct),
        color: seriesColor(d.index),
        // encostado no marcador, do lado que aponta para dentro do plot
        x: anchor === 'start' ? x + L.markerRadius : anchor === 'end' ? x - L.markerRadius : x,
        marcadorY: yScale(d.ponto!.pct),
        anchor,
      }))
      .sort((a, b) => a.marcadorY - b.marcadorY);

    const rotulos = pontos.map((p, i) => {
      const acima = i === 0 || p.marcadorY - pontos[i - 1].marcadorY >= folga;
      return { ...p, y: p.marcadorY + (acima ? -L.valueOffset : L.valueOffset) };
    });

    for (let i = 1; i < rotulos.length; i++) {
      rotulos[i].y = Math.max(rotulos[i].y, rotulos[i - 1].y + L.valueSpacing);
    }

    return rotulos;
  }
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
    {@const yScale = scaleLinear().domain([0, topo]).range([innerHeight, 0])}
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

    {#each series as serie, index (serie.key)}
      {@const color = seriesColor(index)}
      {@const pontos = serie.pontos.filter((p) => anos.includes(p.ano))}
      {@const d = pontos
        .map((p, i) => `${i ? 'L' : 'M'}${xScale(p.ano)},${yScale(p.pct)}`)
        .join(' ')}

      <path
        {d}
        fill="none"
        stroke={color}
        stroke-width={L.lineWidth}
        stroke-linejoin="round"
        stroke-linecap="round"
      />

      {#each pontos as ponto (ponto.ano)}
        <circle
          cx={xScale(ponto.ano)}
          cy={yScale(ponto.pct)}
          r={L.markerRadius}
          fill={color}
        />
      {/each}
    {/each}

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

    <!-- valores por último, sobre as linhas -->
    {#each anos as ano (ano)}
      {#each rotulosDaOnda(ano, (v) => yScale(v), xScale(ano)) as rotulo (rotulo.key)}
        <Text
          x={rotulo.x}
          y={rotulo.y}
          textAnchor={rotulo.anchor}
          verticalAnchor="middle"
          fontSize={type.xs}
          fontWeight={600}
          {fontFamily}
          fill={rotulo.color}
          text={rotulo.text}
        />
      {/each}
    {/each}

    <Axis
      orientation="bottom"
      scale={xScale}
      top={innerHeight}
      tickValues={anos}
      tickFormat={(v: number) => String(v)}
      hideAxisLine
      hideTicks
      tickLabelProps={tickLabelProps(palette.neutral[200], type.md)}
    />

    {@const notesTop = innerHeight + L.noteGap}

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
