<script lang="ts">
  import { max, scaleBand, scaleLinear } from 'd3';
  import {
    Chart,
    DefaultTheme,
    colorScales,
    getPillarTheme,
    resolveThemeStyle,
    Text,
    type ChartDimensions,
    type ChartTheme,
  } from 'sniic-design-system';
  import LegendChips from './LegendChips.svelte';
  import TextLines from './TextLines.svelte';
  import { a4Scale, fontFamily, fontSize as scale, wrapText } from './tokens';

  export type CaboGuerraRow = {
    label: string;
    /** Share of the region's municipalities with an inducing effect, in %. */
    indutor: number;
    /** Same, for the substitution effect — a magnitude; the side carries the sign. */
    substituicao: number;
    /** `indutor - substituicao`, in percentage points. */
    liquido: number;
  };

  interface Props {
    data: CaboGuerraRow[];
    title: string;
    subtitle?: string;
    footnote?: string;
    source?: string;
    /** Heading over the right-hand gutter that carries the net balance. */
    saldoLabel?: string;
    indutorLabel?: string;
    substituicaoLabel?: string;
    /**
     * Intrinsic width, in SVG units. The card scales as a whole to whatever
     * physical width it is placed at; type and chrome are scaled off this by
     * `a4Scale`, so the printed sizes come out the same at any authoring width.
     * The default matches the RibbonChart A4 figures.
     */
    width?: number;
    /**
     * Overrides the height the card computes for itself. Left alone, the card
     * is exactly as tall as its rows and its copy need — which is what keeps
     * the row height constant however many lines the title wraps to.
     */
    height?: number;
    /**
     * Re-lays the chart out at the container's width instead of scaling the
     * card. Type stays at its unit size, so a wide container makes the labels
     * proportionally smaller — off by default for that reason.
     */
    responsive?: boolean;
    /** Pillar palette to theme the chart with — Eixo 1. */
    pillar?: number;
    /**
     * Card fill. `null` drops the card — background and border both — leaving
     * the marks and the type on whatever is behind them, which is what an
     * export placed into an already-designed page wants. Everything drawn is
     * dark ink, so a transparent card still needs a light surface under it.
     */
    background?: string | null;
    /** Bindable — the rendered `<svg>`, for `downloadSvg`. */
    svgEl?: SVGSVGElement | null;
  }

  let {
    data,
    title,
    subtitle,
    footnote,
    source,
    saldoLabel = 'Saldo líquido',
    indutorLabel = 'Efeito indutor (+)',
    substituicaoLabel = 'Efeito substituição (−)',
    width = 1368,
    height,
    responsive = false,
    pillar = 1,
    background,
    svgEl = $bindable(null),
  }: Props = $props();

  /**
   * Everything below is authored against `fontSize.md`, then multiplied by this
   * — type and chrome alike — so the card prints at the same sizes as the
   * RibbonChart A4 figures whatever width it is authored at.
   */
  const k = $derived(a4Scale(width));

  const TITLE_FONT_SIZE = 20;

  const type = $derived({
    title: TITLE_FONT_SIZE * k,
    md: scale.md * k,
    sm: scale.sm * k,
  });

  /**
   * Fixed measures, in the same scaled units as the type.
   *
   * The side margins hold the region names and the saldo: `left` fits
   * "Centro-Oeste" at `md`, `right` fits the "Saldo líquido" heading. The
   * vertical margins are derived further down, from how many lines the copy
   * actually wraps to.
   */
  const L = $derived({
    cardPadding: 24 * k,
    cardRadius: 12 * k,
    marginLeft: 128 * k,
    marginRight: 112 * k,
    titleLine: 24 * k,
    subtitleLine: 15 * k,
    noteLine: 14 * k,
    /** Between the subtitle and the top of the plot. */
    titleBlockGap: 22 * k,
    /** Plot bottom to the legend strip, and the legend strip's own height. */
    legendGap: 26 * k,
    legendHeight: 20 * k,
    /** Legend strip to the first note line. */
    noteGap: 18 * k,
    /** Between the footnote block and the source block. */
    noteSpacing: 3 * k,
    /** One row's share of the plot; the bar takes all but the band padding. */
    band: 38 * k,
    barRadius: 4 * k,
    /** Half the surface gap that keeps the two bars off each other at zero. */
    baselineGap: 1 * k,
    /** Between a bar end and the value written past it. */
    valueGap: 8 * k,
    /** Room reserved at each end of the plot for those values. */
    valueGutter: 46 * k,
    /** Region name to the plot edge, and the saldo heading to the first row. */
    rowLabelGap: 12 * k,
    /** How far the zero line runs past the first and last bar. */
    zeroOverhang: 8 * k,
  });

  const theme = $derived(getPillarTheme(pillar));
  const palette = $derived(theme.palette);

  /**
   * The two poles, drawn from the same scales as the RibbonChart A4 figures so
   * the set reads as one collection.
   *
   * Lime rather than teal for the positive pole: against this purple, teal
   * separates by only ΔE 3.0 under deuteranopia and 3.4 under tritanopia — the
   * two halves of the chart collapse into one colour, which is the one thing
   * this chart cannot afford. Lime clears it at ΔE 19.3 (deutan) and 29.6 for
   * normal vision, and is the same pair the municipal ribbon figure runs on.
   */
  const INDUTOR = colorScales.lime[2];
  const SUBSTITUICAO = colorScales.purple[2];

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
  const valueStyle = $derived(
    resolveThemeStyle<ChartTheme, 'dataLabel'>(
      { fontSize: type.sm, fontWeight: 600, fill: palette.neutral[200], fontFamily },
      theme.dataLabel,
      DefaultTheme.dataLabel,
    )!,
  );
  const rowStyle = $derived(
    resolveThemeStyle<ChartTheme, 'text'>(
      { fontSize: type.md, fontWeight: 600, fill: palette.neutral[300], fontFamily },
      theme.text,
      DefaultTheme.text,
    )!,
  );
  const saldoStyle = $derived(
    resolveThemeStyle<ChartTheme, 'dataLabel'>(
      { fontSize: type.md, fontWeight: 600, fill: palette.neutral[300], fontFamily },
      theme.dataLabel,
      DefaultTheme.dataLabel,
    )!,
  );

  /**
   * The copy is wrapped before the chart is laid out, so the card can reserve
   * exactly the vertical space it needs — a two-line title pushes the plot down
   * instead of printing over it.
   */
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
    right: L.marginRight,
    top:
      L.cardPadding +
      titleLines.length * L.titleLine +
      subtitleLines.length * L.subtitleLine +
      L.titleBlockGap,
    bottom:
      L.legendGap +
      L.legendHeight +
      L.noteGap +
      footnoteLines.length * L.noteLine +
      (footnoteLines.length && sourceLines.length ? L.noteSpacing : 0) +
      sourceLines.length * L.noteLine +
      L.cardPadding,
  });

  const cardHeight = $derived(
    height ?? MARGIN.top + data.length * L.band + MARGIN.bottom,
  );

  const decimal = new Intl.NumberFormat('pt-BR', {
    minimumFractionDigits: 1,
    maximumFractionDigits: 1,
  });
  const pct = (v: number) => `${decimal.format(v)}%`;
  /** The saldo is a difference between two shares, so it is read in p.p. */
  const saldo = (v: number) => `${v > 0 ? '+' : v < 0 ? '−' : ''}${decimal.format(Math.abs(v))} p.p.`;

  const categories = $derived(data.map((d) => d.label));
  const indutorMax = $derived(max(data, (d) => d.indutor) ?? 1);
  const substituicaoMax = $derived(max(data, (d) => d.substituicao) ?? 1);

  const legendItems = $derived([
    { label: indutorLabel, color: INDUTOR },
    { label: substituicaoLabel, color: SUBSTITUICAO },
  ]);

  /**
   * Widens the domain so a `valueGutter` of plot pixels stays free at each end
   * for the values written past the bars. Solved rather than guessed: padding
   * the domain changes the pixels-per-unit that the padding is measured in.
   */
  function domainFor(innerWidth: number): [number, number] {
    const span = indutorMax + substituicaoMax;
    const usable = Math.max(innerWidth - L.valueGutter * 2, 1);
    const padded = (span * innerWidth) / usable;
    const pad = (padded - span) / 2;
    return [-substituicaoMax - pad, indutorMax + pad];
  }

  /**
   * A bar rounded on its outer end only: the ends at zero stay square so the
   * two halves read as one rope pulled from both sides.
   */
  function barPath(
    x: number,
    y: number,
    width: number,
    barHeight: number,
    side: 'left' | 'right',
  ) {
    const r = Math.max(0, Math.min(L.barRadius, width, barHeight / 2));
    if (r === 0) return `M${x},${y} h${width} v${barHeight} h${-width} Z`;

    return side === 'right'
      ? [
          `M${x},${y}`,
          `H${x + width - r}`,
          `A${r},${r} 0 0 1 ${x + width},${y + r}`,
          `V${y + barHeight - r}`,
          `A${r},${r} 0 0 1 ${x + width - r},${y + barHeight}`,
          `H${x}`,
          'Z',
        ].join(' ')
      : [
          `M${x + width},${y}`,
          `H${x + r}`,
          `A${r},${r} 0 0 0 ${x},${y + r}`,
          `V${y + barHeight - r}`,
          `A${r},${r} 0 0 0 ${x + r},${y + barHeight}`,
          `H${x + width}`,
          'Z',
        ].join(' ');
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
  {#snippet children({
    width: cardWidth,
    innerWidth,
    innerHeight,
    margin,
  }: ChartDimensions)}
    {@const xScale = scaleLinear().domain(domainFor(innerWidth)).range([0, innerWidth])}
    {@const yScale = scaleBand<string>()
      .domain(categories)
      .range([0, innerHeight])
      .padding(0.42)}
    {@const barHeight = yScale.bandwidth()}
    {@const zeroX = xScale(0)}
    {@const cardLeft = -margin.left + L.cardPadding}
    {@const cardRight = innerWidth + margin.right - L.cardPadding}

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

    <!-- the only rule in the plot: the line both effects are measured from -->
    <line
      x1={zeroX}
      y1={-L.zeroOverhang}
      x2={zeroX}
      y2={innerHeight + L.zeroOverhang}
      stroke={palette.base[300]}
      stroke-width={k}
    />

    <Text
      x={cardRight}
      y={-L.rowLabelGap}
      textAnchor="end"
      verticalAnchor="end"
      fontSize={noteStyle.fontSize}
      fontWeight={noteStyle.fontWeight}
      fontFamily={noteStyle.fontFamily}
      fill={noteStyle.fill}
      text={saldoLabel}
    />

    {#each data as row (row.label)}
      {@const y = yScale(row.label) ?? 0}
      {@const centerY = y + barHeight / 2}
      {@const indutorX = xScale(row.indutor)}
      {@const substituicaoX = xScale(-row.substituicao)}

      <Text
        x={-L.rowLabelGap}
        y={centerY}
        textAnchor="end"
        verticalAnchor="middle"
        fontSize={rowStyle.fontSize}
        fontWeight={rowStyle.fontWeight}
        fontFamily={rowStyle.fontFamily}
        fill={rowStyle.fill}
        text={row.label}
      />

      <path
        d={barPath(
          zeroX + L.baselineGap,
          y,
          Math.max(indutorX - zeroX - L.baselineGap, 0),
          barHeight,
          'right',
        )}
        fill={INDUTOR}
      />
      <path
        d={barPath(
          substituicaoX,
          y,
          Math.max(zeroX - L.baselineGap - substituicaoX, 0),
          barHeight,
          'left',
        )}
        fill={SUBSTITUICAO}
      />

      <Text
        x={indutorX + L.valueGap}
        y={centerY}
        textAnchor="start"
        verticalAnchor="middle"
        fontSize={valueStyle.fontSize}
        fontWeight={valueStyle.fontWeight}
        fontFamily={valueStyle.fontFamily}
        fill={valueStyle.fill}
        text={pct(row.indutor)}
      />
      <Text
        x={substituicaoX - L.valueGap}
        y={centerY}
        textAnchor="end"
        verticalAnchor="middle"
        fontSize={valueStyle.fontSize}
        fontWeight={valueStyle.fontWeight}
        fontFamily={valueStyle.fontFamily}
        fill={valueStyle.fill}
        text={pct(row.substituicao)}
      />

      <!-- the saldo sits in its own gutter rather than on the bars: at these
           values it always falls inside the indutor bar, where a marker would
           read as a segment boundary -->
      <Text
        x={cardRight}
        y={centerY}
        textAnchor="end"
        verticalAnchor="middle"
        fontSize={saldoStyle.fontSize}
        fontWeight={saldoStyle.fontWeight}
        fontFamily={saldoStyle.fontFamily}
        fill={saldoStyle.fill}
        text={saldo(row.liquido)}
      />
    {/each}

    <LegendChips
      items={legendItems}
      left={cardLeft}
      top={innerHeight + L.legendGap}
      fontSize={Number(valueStyle.fontSize)}
      fontFamily={valueStyle.fontFamily}
      fontWeight={valueStyle.fontWeight}
    />

    {@const notesTop = innerHeight + L.legendGap + L.legendHeight + L.noteGap}

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
      y={notesTop +
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
