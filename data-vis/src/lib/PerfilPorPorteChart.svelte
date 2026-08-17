<script lang="ts">
  import { scaleBand, scaleLinear } from 'd3';
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
  import { rampaVermelha, sniic } from './cores';
  import {
    a4Scale,
    fontFamily,
    fontSize as scale,
    labelFitsInBar,
    measureLabel,
    wrapText,
  } from './tokens';

  /** One population band: a share per profile, plus the band's own count. */
  export type PerfilRow = { label: string; n: number } & Record<string, number | string>;

  interface Props {
    data: PerfilRow[];
    /** Profile keys, in the order they stack from the left. */
    keys: string[];
    labels?: Record<string, string>;
    title: string;
    subtitle?: string;
    footnote?: string;
    source?: string;
    /**
     * Intrinsic width, in SVG units. Type is absolute in those units, so this
     * is what fixes how large the labels print: the whole card scales to
     * whatever physical width it is placed at, and the ratio of font size to
     * width is what survives. Sized for an A4 portrait text column.
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
    keys,
    labels = {},
    title,
    subtitle,
    footnote,
    source,
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

  const TITLE_FONT_SIZE = 14;

  const type = $derived({
    title: TITLE_FONT_SIZE * k,
    md: scale.md * k,
    sm: scale.sm * k,
    xs: scale.xs * k,
  });

  /**
   * Fixed measures, in the same scaled units as the type.
   *
   * No value axis: the bars all run to 100%, so the scale carries no
   * information the segments don't. The left margin holds the band name and its
   * count — enough for "Pequeno Porte II" at `md`. The vertical margins are
   * derived further down, from how many lines the copy wraps to.
   */
  const L = $derived({
    cardPadding: 24 * k,
    cardRadius: 12 * k,
    marginLeft: 160 * k,
    marginRight: 40 * k,
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
    /** One row's share of the plot; the gap above each bar carries its rail. */
    band: 49 * k,
    segmentRadius: 2 * k,
    /** Half the surface gap between neighbouring segments. */
    segmentGap: 1 * k,
    /**
     * Vertical centre of a rail label, measured up from the top of its bar. The
     * rail sits in the gap between two rows, so it has to stay near the bottom
     * of that gap — a label hung midway reads as belonging to the row above.
     */
    railOffset: 11 * k,
    /** Between two rail labels pushed apart. */
    railSpacing: 6 * k,
    /** Band name to the plot edge, and the two lines of that name apart. */
    rowLabelGap: 16 * k,
    rowLabelRise: 7 * k,
    rowLabelDrop: 9 * k,
  });

  const theme = $derived(getPillarTheme(pillar));
  const palette = $derived(theme.palette);

  /**
   * The four profiles in the brand palette, split the way the chart is read:
   * cool for the halves where local money grew or held, warm for the two ways
   * it did not.
   *
   * `Despertados` takes the brand blue and `Substituição` the brand red — the
   * same poles, in the same hues, as the sibling `CaboGuerraChart`, and the
   * pair the palette separates best (ΔE 32.5, never below 23.7 under colour
   * blindness). They are the two ends the chart is read across, so they are the
   * pair that cannot merge.
   *
   * `Constantes` takes the brand cyan: three quarters of every bar carry no
   * movement, and cyan is the lightest step in the palette, so it holds the
   * area without shouting. `Inertes` takes the darkest red — it and
   * `Substituição` are adjacent slivers at the right end of every row, and two
   * steps of the same family put them ΔE 24.7 apart while keeping both on the
   * warm side, which is where they belong. Every pair clears the gate, not just
   * the adjacent ones: the worst is ΔE 20.6 under colour blindness and 24.7 for
   * normal vision.
   */
  const seriesPalette = [sniic.azul, sniic.ciano, rampaVermelha[0], sniic.vermelho];
  const seriesColor = (index: number) => seriesPalette[index % seriesPalette.length];

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
  const rowStyle = $derived(
    resolveThemeStyle<ChartTheme, 'text'>(
      { fontSize: type.md, fontWeight: 600, fill: palette.neutral[300], fontFamily },
      theme.text,
      DefaultTheme.text,
    )!,
  );
  const segmentStyle = $derived(
    resolveThemeStyle<ChartTheme, 'dataLabel'>(
      { fontSize: type.sm, fontWeight: 600, fontFamily },
      theme.dataLabel,
      DefaultTheme.dataLabel,
    )!,
  );
  /** Rail labels are ink on the card, not on a fill, so they carry their own colour. */
  const railStyle = $derived(
    resolveThemeStyle<ChartTheme, 'dataLabel'>(
      { fontSize: type.xs, fontWeight: 500, fill: palette.neutral[200], fontFamily },
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
  const integer = new Intl.NumberFormat('pt-BR');
  const pct = (v: number) => `${decimal.format(v)}%`;

  const categories = $derived(data.map((d) => d.label));
  const value = (row: PerfilRow, key: string) => Number(row[key]) || 0;

  const legendItems = $derived(
    keys.map((key, i) => ({ label: labels[key] ?? key, color: seriesColor(i) })),
  );

  type Segment = {
    key: string;
    keyIndex: number;
    value: number;
    x: number;
    width: number;
  };

  /**
   * Segments of one row, normalized to the row's own total so the bars end
   * flush at 100% even where the source shares don't sum exactly.
   */
  function layoutRow(row: PerfilRow, xScale: (v: number) => number): Segment[] {
    const total = keys.reduce((sum, key) => sum + value(row, key), 0) || 1;
    let cursor = 0;

    return keys.map((key, keyIndex) => {
      const share = (value(row, key) / total) * 100;
      const x = xScale(cursor);
      cursor += share;
      return { key, keyIndex, value: value(row, key), x, width: xScale(cursor) - x };
    });
  }

  type RailLabel = {
    key: string;
    text: string;
    color: string;
    /** Centre of the segment the leader points at. */
    anchorX: number;
    /** Centre of the label itself, after the row has been spread out. */
    x: number;
    width: number;
  };

  /**
   * Values for segments too thin to hold them, written on a rail above the bar.
   * `Inertes` and `Substituição` sit side by side at the right end of every row
   * and would otherwise overprint, so the labels are pushed apart along the
   * rail — the leader lines are what keeps each one attached to its segment.
   */
  function railLabels(segments: Segment[], plotWidth: number): RailLabel[] {
    const size = Number(railStyle.fontSize);
    const weight = Number(railStyle.fontWeight);

    const pending = segments
      .filter(
        (s) =>
          s.value > 0 &&
          !labelFitsInBar(
            pct(s.value),
            Number(segmentStyle.fontSize),
            s.width,
            Number(segmentStyle.fontWeight),
          ),
      )
      .map((s) => {
        const text = pct(s.value);
        const anchorX = s.x + s.width / 2;
        return {
          key: s.key,
          text,
          color: seriesColor(s.keyIndex),
          anchorX,
          x: anchorX,
          width: measureLabel(text, size, weight),
        };
      })
      .sort((a, b) => a.anchorX - b.anchorX);

    // left to right, then back again: the first pass opens the gaps, the second
    // pulls anything it pushed past the right edge back inside the plot
    for (let i = 1; i < pending.length; i++) {
      const previous = pending[i - 1];
      const floor = previous.x + previous.width / 2 + L.railSpacing + pending[i].width / 2;
      pending[i].x = Math.max(pending[i].x, floor);
    }
    for (let i = pending.length - 1; i >= 0; i--) {
      const ceiling =
        i === pending.length - 1
          ? plotWidth - pending[i].width / 2
          : pending[i + 1].x - pending[i + 1].width / 2 - L.railSpacing - pending[i].width / 2;
      pending[i].x = Math.min(pending[i].x, ceiling);
      pending[i].x = Math.max(pending[i].x, pending[i].width / 2);
    }

    return pending;
  }

  /** A stacked segment, rounded only where the bar itself ends. */
  function segmentPath(
    x: number,
    y: number,
    width: number,
    barHeight: number,
    radiusLeft: number,
    radiusRight: number,
  ) {
    const cap = Math.min(width / 2, barHeight / 2);
    const left = Math.max(0, Math.min(radiusLeft, cap));
    const right = Math.max(0, Math.min(radiusRight, cap));

    return [
      `M${x + left},${y}`,
      `H${x + width - right}`,
      right ? `A${right},${right} 0 0 1 ${x + width},${y + right}` : '',
      `V${y + barHeight - right}`,
      right ? `A${right},${right} 0 0 1 ${x + width - right},${y + barHeight}` : '',
      `H${x + left}`,
      left ? `A${left},${left} 0 0 1 ${x},${y + barHeight - left}` : '',
      `V${y + left}`,
      left ? `A${left},${left} 0 0 1 ${x + left},${y}` : '',
      'Z',
    ]
      .filter(Boolean)
      .join(' ');
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
    {@const xScale = scaleLinear().domain([0, 100]).range([0, innerWidth])}
    {@const yScale = scaleBand<string>()
      .domain(categories)
      .range([0, innerHeight])
      .padding(0.42)}
    {@const barHeight = yScale.bandwidth()}
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

    {#each data as row (row.label)}
      {@const y = yScale(row.label) ?? 0}
      {@const centerY = y + barHeight / 2}
      {@const segments = layoutRow(row, (v) => xScale(v))}

      <Text
        x={-L.rowLabelGap}
        y={centerY - L.rowLabelRise}
        textAnchor="end"
        verticalAnchor="middle"
        fontSize={rowStyle.fontSize}
        fontWeight={rowStyle.fontWeight}
        fontFamily={rowStyle.fontFamily}
        fill={rowStyle.fill}
        text={row.label}
      />
      <Text
        x={-L.rowLabelGap}
        y={centerY + L.rowLabelDrop}
        textAnchor="end"
        verticalAnchor="middle"
        fontSize={noteStyle.fontSize}
        fontWeight={noteStyle.fontWeight}
        fontFamily={noteStyle.fontFamily}
        fill={noteStyle.fill}
        text={`${integer.format(row.n)} municípios`}
      />

      {#each segments as segment, index (segment.key)}
        {@const first = index === 0}
        {@const last = index === segments.length - 1}
        {@const x = segment.x + (first ? 0 : L.segmentGap)}
        {@const segmentWidth = Math.max(
          segment.width - (first ? 0 : L.segmentGap) - (last ? 0 : L.segmentGap),
          0,
        )}
        {@const label = pct(segment.value)}
        {@const color = seriesColor(segment.keyIndex)}

        <path
          d={segmentPath(
            x,
            y,
            segmentWidth,
            barHeight,
            first ? L.segmentRadius : 0,
            last ? L.segmentRadius : 0,
          )}
          fill={color}
        />

        {#if labelFitsInBar( label, Number(segmentStyle.fontSize), segment.width, Number(segmentStyle.fontWeight), )}
          <Text
            x={segment.x + segment.width / 2}
            y={centerY}
            textAnchor="middle"
            verticalAnchor="middle"
            fontSize={segmentStyle.fontSize}
            fontWeight={segmentStyle.fontWeight}
            fontFamily={segmentStyle.fontFamily}
            fill={getContrastColor(color)}
            text={label}
          />
        {/if}
      {/each}

      <!-- leaders first, so no line is drawn across a label it doesn't belong to -->
      {@const rail = railLabels(segments, innerWidth)}
      {#each rail as item (item.key)}
        <polyline
          points={`${item.anchorX},${y - k} ${item.anchorX},${y - 4 * k} ${item.x},${y - 5.5 * k}`}
          fill="none"
          stroke={item.color}
          stroke-width={k}
        />
      {/each}
      {#each rail as item (item.key)}
        <Text
          x={item.x}
          y={y - L.railOffset}
          textAnchor="middle"
          verticalAnchor="middle"
          fontSize={railStyle.fontSize}
          fontWeight={railStyle.fontWeight}
          fontFamily={railStyle.fontFamily}
          fill={railStyle.fill}
          text={item.text}
        />
      {/each}
    {/each}

    <LegendChips
      items={legendItems}
      left={cardLeft}
      top={innerHeight + L.legendGap}
      fontSize={Number(segmentStyle.fontSize)}
      fontFamily={segmentStyle.fontFamily}
      fontWeight={segmentStyle.fontWeight}
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
