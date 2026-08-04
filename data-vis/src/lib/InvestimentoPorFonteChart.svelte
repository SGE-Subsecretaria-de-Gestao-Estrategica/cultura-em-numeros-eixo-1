<script lang="ts">
  import {
    max,
    scaleBand,
    scaleLinear,
    stack,
    stackOrderAscending,
    type ScaleBand,
    type ScaleLinear,
  } from 'd3';
  import {
    Axis,
    Bar,
    BarStack,
    BRL,
    Chart,
    DefaultTheme,
    getCategoricalColor,
    getContrastColor,
    getPillarTheme,
    resolveThemeStyle,
    Text,
    type ChartDimensions,
    type ChartTheme,
    type ComputedBar,
    type StackedDatum,
  } from 'sniic-design-system';
  import {
    DEFAULT_CALLOUT_STYLE,
    placeCallouts,
    type Box,
    type CalloutColumn,
    type CalloutInput,
  } from './callouts';
  import ValueCallout from './ValueCallout.svelte';
  import LegendChips from './LegendChips.svelte';
  import {
    fontFamily,
    fontSize as scale,
    labelFitsInBar,
    measureLabel,
    tickLabelProps,
  } from './tokens';

  interface Props {
    data: StackedDatum[];
    keys: string[];
    /** Short display names for the legend; falls back to the raw key. */
    labels?: Record<string, string>;
    title: string;
    subtitle?: string;
    /** Expansion of the abbreviations used in the legend. */
    footnote?: string;
    source?: string;
    height?: number;
    /** Pillar palette to theme the chart with — Eixo 1. */
    pillar?: number;
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
    height = 460,
    pillar = 1,
    svgEl = $bindable(null),
  }: Props = $props();

  const CARD_PADDING = 24;
  // No y axis: values are read off the columns, so the plot starts at the card edge.
  const MARGIN = { top: 84, right: 24, bottom: 116, left: 24 };
  /** Segments shorter than this can't hold a legible label inside them. */
  const MIN_SEGMENT_LABEL_HEIGHT = 22;
  /** Square corners: the theme's rounding leaves notches between stacked segments. */
  const SEGMENT_RADIUS = 0;
  /** Headroom above the tallest column so its total label isn't clipped. */
  const Y_HEADROOM = 1.08;
  /**
   * Below this a segment is thinner than a hairline — Emendas is R$ 3 mi against
   * a R$ 5 bi column in some years — and a callout would point at nothing.
   */
  const MIN_ANNOTATED_HEIGHT = 3;
  const ANNOTATION = DEFAULT_CALLOUT_STYLE;

  const theme = $derived(getPillarTheme(pillar));
  const palette = $derived(theme.palette);

  // props > theme > default, the same cascade the core components apply
  /** The one display size in the card; the label scale tops out below it. */
  const TITLE_FONT_SIZE = 20;

  const titleStyle = $derived(
    resolveThemeStyle<ChartTheme, 'text'>(
      { fontSize: TITLE_FONT_SIZE, fontWeight: 600, fill: palette.neutral[300], fontFamily },
      theme.text,
      DefaultTheme.text,
    )!,
  );
  const subtitleStyle = $derived(
    resolveThemeStyle<ChartTheme, 'text'>(
      { fontSize: scale.md, fill: palette.neutral[200], fontFamily },
      theme.text,
      DefaultTheme.text,
    )!,
  );
  const noteStyle = $derived(
    resolveThemeStyle<ChartTheme, 'text'>(
      { fontSize: scale.sm, fontWeight: 400, fill: palette.neutral[100], fontFamily },
      theme.text,
      DefaultTheme.text,
    )!,
  );
  const totalStyle = $derived(
    resolveThemeStyle<ChartTheme, 'dataLabel'>(
      { fontSize: scale.lg, fill: palette.neutral[300], fontFamily },
      theme.dataLabel,
      DefaultTheme.dataLabel,
    )!,
  );
  const segmentStyle = $derived(
    resolveThemeStyle<ChartTheme, 'dataLabel'>(
      { fontSize: scale.sm, fontWeight: 600, fontFamily },
      theme.dataLabel,
      DefaultTheme.dataLabel,
    )!,
  );

  /**
   * Series colours in `keys` order. The two recurring sources (recurso próprio,
   * emendas) take muted neutrals so they read as the baseline, leaving the
   * theme's hues to mark the policy-specific transfers — which are the point of
   * the chart. Falls back to the categorical ramp for any extra series.
   */
  const seriesPalette = $derived([
    palette.neutral[100],
    palette.neutral[200],
    palette.accent,
    palette.primary,
    palette.secondary,
  ]);

  const seriesColor = (index: number) =>
    seriesPalette[index] ?? getCategoricalColor(index, theme);

  const legendItems = $derived(
    keys.map((key, i) => ({ label: labels[key] ?? key, color: seriesColor(i) })),
  );

  const rowTotal = (d: StackedDatum) =>
    keys.reduce((sum, key) => sum + (Number(d[key]) || 0), 0);

  const yMax = $derived(max(data, rowTotal) ?? 1);

  /**
   * Same stack `BarStack` builds internally — recomputed here because the
   * callouts have to be drawn after every column, so they can't be emitted from
   * inside the bar loop without later columns painting over them.
   */
  const stacked = $derived(
    stack<StackedDatum, string>()
      .keys(keys)
      .value((d, key) => Number(d[key]) || 0)
      .order(stackOrderAscending)(data),
  );

  /**
   * Splits each column's segments into the ones that carry their value inline —
   * obstacles the boxes must dodge — and the ones needing a callout.
   */
  function buildCallouts(
    xScale: ScaleBand<string>,
    yScale: ScaleLinear<number, number>,
  ) {
    const bandwidth = xScale.bandwidth();
    const fontSize = Number(segmentStyle.fontSize);

    const columns: CalloutColumn[] = data.map((row, rowIndex) => {
      const centerX = (xScale(String(row.label)) ?? 0) + bandwidth / 2;
      const total = BRL.format(rowTotal(row));
      const obstacles: Box[] = [];
      const items: CalloutInput[] = [];

      stacked.forEach((series, seriesIndex) => {
        const point = series[rowIndex];
        const label = BRL.format(point[1] - point[0]);
        const segmentTop = yScale(point[1]);
        const segmentHeight = Math.abs(yScale(point[0]) - segmentTop);

        if (
          segmentHeight >= MIN_SEGMENT_LABEL_HEIGHT &&
          labelFitsInBar(label, fontSize, bandwidth, Number(segmentStyle.fontWeight))
        ) {
          const width = measureLabel(label, fontSize, Number(segmentStyle.fontWeight));
          obstacles.push({
            x: centerX - width / 2,
            y: segmentTop + segmentHeight / 2 - fontSize,
            width,
            height: fontSize * 2,
          });
          return;
        }
        // a lone source is already named by the column total
        if (label === total || segmentHeight < MIN_ANNOTATED_HEIGHT) return;

        items.push({
          key: `${seriesIndex}-${rowIndex}`,
          label,
          color: seriesColor(seriesIndex),
          segmentTop,
          segmentHeight,
        });
      });

      // the leader runs off-centre so it doesn't cross the inline labels it
      // passes on the way down to its segment
      return { centerX, lineX: centerX - bandwidth / 4, items, obstacles };
    });

    return placeCallouts(columns, measureLabel, ANNOTATION);
  }
</script>

<Chart
  responsive
  {height}
  {theme}
  margin={MARGIN}
  ariaLabel={title}
  role="img"
  bind:innerRef={svgEl}
>
  {#snippet children({ width, innerWidth, innerHeight, margin }: ChartDimensions)}
    {@const xScale = scaleBand<string>()
      .domain(data.map((d: StackedDatum) => String(d.label)))
      .range([0, innerWidth])
      .padding(0.28)}
    {@const yScale = scaleLinear()
      .domain([0, yMax * Y_HEADROOM])
      .range([innerHeight, 0])}
    {@const cardLeft = -margin.left + CARD_PADDING}

    <rect
      x={-margin.left}
      y={-margin.top}
      width={width}
      {height}
      rx={12}
      fill={palette.base[100]}
      stroke={palette.base[300]}
      stroke-width={1}
    />

    <Text
      x={cardLeft}
      y={-margin.top + CARD_PADDING}
      verticalAnchor="start"
      fontSize={titleStyle.fontSize}
      fontWeight={titleStyle.fontWeight}
      fontFamily={titleStyle.fontFamily}
      fill={titleStyle.fill}
      text={title}
    />

    {#if subtitle}
      <Text
        x={cardLeft}
        y={-margin.top + CARD_PADDING + 28}
        verticalAnchor="start"
        fontSize={subtitleStyle.fontSize}
        fontWeight={subtitleStyle.fontWeight}
        fontFamily={subtitleStyle.fontFamily}
        fill={subtitleStyle.fill}
        text={subtitle}
      />
    {/if}

    <BarStack
      {data}
      {keys}
      category={(d: StackedDatum) => String(d.label)}
      value={(d: StackedDatum, key: string) => Number(d[key]) || 0}
      color={(_key: string, i: number) => seriesColor(i)}
      {xScale}
      {yScale}
      order={stackOrderAscending}
      rx={SEGMENT_RADIUS}
    >
      {#snippet children({ barStacks }: { barStacks: { key: string; bars: ComputedBar[] }[] })}
        {#each barStacks as stack (stack.key)}
          {#each stack.bars as bar (`${stack.key}-${bar.index}`)}
            {@const label = BRL.format(bar.value)}
            {@const fits =
              bar.height >= MIN_SEGMENT_LABEL_HEIGHT &&
              labelFitsInBar(
                label,
                Number(segmentStyle.fontSize),
                bar.width,
                Number(segmentStyle.fontWeight),
              )}
            <!-- compared as formatted text: a segment that rounds to the same
                 value as the total would just repeat the label above it -->
            {@const redundant = label === BRL.format(rowTotal(data[bar.index]))}

            <Bar
              x={bar.x}
              y={bar.y}
              width={bar.width}
              height={bar.height}
              fill={bar.color}
              rx={SEGMENT_RADIUS}
            />

            {#if fits && !redundant}
              <Text
                x={bar.x + bar.width / 2}
                y={bar.y + bar.height / 2}
                textAnchor="middle"
                verticalAnchor="middle"
                fontSize={segmentStyle.fontSize}
                fontWeight={segmentStyle.fontWeight}
                fontFamily={segmentStyle.fontFamily}
                fill={getContrastColor(bar.color)}
                text={label}
              />
            {/if}
          {/each}
        {/each}
      {/snippet}
    </BarStack>

    <!-- callouts for the segments that couldn't hold their value inline -->
    {@const callouts = buildCallouts(xScale, yScale)}

    <!-- every leader first, so no line is drawn across a box -->
    {#each callouts as c (c.key)}
      <line
        x1={c.lineX}
        y1={c.lineFromY}
        x2={c.lineX}
        y2={c.y + c.height}
        stroke={c.color}
        stroke-width={1}
      />
    {/each}

    {#each callouts as c (c.key)}
      <ValueCallout
        callout={c}
        style={ANNOTATION}
        background={palette.base[100]}
        textColor={palette.neutral[300]}
        fontFamily={segmentStyle.fontFamily}
        fontWeight={segmentStyle.fontWeight}
      />
    {/each}

    <!-- column totals replace the y axis. Dropped altogether rather than
         half-labelled when the columns get too narrow to hold them. -->
    {@const widestTotal = Math.max(
      ...data.map((d: StackedDatum) =>
        measureLabel(
          BRL.format(rowTotal(d)),
          Number(totalStyle.fontSize),
          Number(totalStyle.fontWeight),
        ),
      ),
    )}
    {#if widestTotal + 4 <= xScale.step()}
      {#each data as d (String(d.label))}
        {@const cat = String(d.label)}
        <Text
          x={(xScale(cat) ?? 0) + xScale.bandwidth() / 2}
          y={yScale(rowTotal(d)) - 8}
          textAnchor="middle"
          verticalAnchor="end"
          fontSize={totalStyle.fontSize}
          fontWeight={totalStyle.fontWeight}
          fontFamily={totalStyle.fontFamily}
          fill={totalStyle.fill}
          text={BRL.format(rowTotal(d))}
        />
      {/each}
    {/if}

    <Axis
      orientation="bottom"
      scale={xScale}
      top={innerHeight}
      tickLabelProps={tickLabelProps(palette.neutral[200])}
    />

    <LegendChips
      items={legendItems}
      top={innerHeight + 42}
      fontSize={Number(segmentStyle.fontSize)}
      fontFamily={segmentStyle.fontFamily}
      fontWeight={segmentStyle.fontWeight}
    />

    {#if footnote}
      <Text
        x={cardLeft}
        y={innerHeight + 76}
        verticalAnchor="start"
        fontSize={noteStyle.fontSize}
        fontWeight={noteStyle.fontWeight}
        fontFamily={noteStyle.fontFamily}
        fill={noteStyle.fill}
        text={footnote}
      />
    {/if}

    {#if source}
      <Text
        x={cardLeft}
        y={innerHeight + 92}
        verticalAnchor="start"
        fontSize={noteStyle.fontSize}
        fontWeight={noteStyle.fontWeight}
        fontFamily={noteStyle.fontFamily}
        fill={noteStyle.fill}
        text={source}
      />
    {/if}
  {/snippet}
</Chart>
