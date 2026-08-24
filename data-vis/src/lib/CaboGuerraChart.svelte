<script lang="ts">
  import { max, scaleBand, scaleLinear } from 'd3';
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
  import { sniic } from './cores';
  import { a4Scale, fontFamily, fontSize as scale, labelFitsInBar, wrapText } from './tokens';

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

  const TITLE_FONT_SIZE = 14;

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
    /**
     * One row's share of the plot; the bar takes all but the band padding.
     * Same band and same padding as the sibling `PerfilPorPorteChart`, so the
     * two figures print with bars of identical weight.
     */
    band: 49 * k,
    barRadius: 2 * k,
    /** Half the surface gap that keeps the two bars off each other at zero. */
    baselineGap: 1 * k,
    /** Between a bar end and a value that had to be written past it. */
    valueGap: 8 * k,
    /** Room given up at an end of the plot for the values that don't fit inside. */
    valueGutter: 46 * k,
    /** Region name to the plot edge, and the saldo heading to the first row. */
    rowLabelGap: 12 * k,
    /** How far the zero line runs past the first and last bar. */
    zeroOverhang: 8 * k,
  });

  const theme = $derived(getPillarTheme(pillar));
  const palette = $derived(theme.palette);

  /**
   * The two poles, in the two brand hues that sit furthest apart.
   *
   * The pairing is not arbitrary either way round: blue is the colour every
   * figure in the collection gives the ente's own budget, and this chart's
   * positive pole is exactly that — the local money the transfer pulled in.
   * Red is the emergency law, the money that came from outside, which is what
   * the substitution pole is made of.
   *
   * They are also the safest pair the palette has: ΔE 32.5 for normal vision
   * and never below 23.7 under any form of colour blindness. That matters more
   * here than anywhere else — if the two poles merge, the chart is gone.
   */
  const INDUTOR = sniic.azul;
  const SUBSTITUICAO = sniic.vermelho;

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
  /**
   * O valor quando ele cai fora da barra, no vão reservado.
   *
   * Fora, ele é texto sobre o cartão e segue a regra da série histórica: peso
   * leve, negrito só em nome de categoria. Dentro, `valueStyle` mantém o 600 —
   * ali o texto disputa com um preenchimento saturado.
   */
  const valorForaStyle = $derived({ ...valueStyle, fontWeight: 400 });

  const rowStyle = $derived(
    resolveThemeStyle<ChartTheme, 'text'>(
      { fontSize: type.md, fontWeight: 600, fill: palette.neutral[300], fontFamily },
      theme.text,
      DefaultTheme.text,
    )!,
  );
  const saldoStyle = $derived(
    resolveThemeStyle<ChartTheme, 'dataLabel'>(
      { fontSize: type.md, fontWeight: 400, fill: palette.neutral[300], fontFamily },
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

  const labelFits = (value: number, barWidth: number) =>
    labelFitsInBar(
      pct(value),
      Number(valueStyle.fontSize),
      barWidth,
      Number(valueStyle.fontWeight),
    );

  /**
   * Where each side writes its values, and how much plot width that costs.
   *
   * Values ride inside their bar, as in the sibling `PerfilPorPorteChart` — but
   * the choice is made per side rather than per bar. One series written inside
   * on one row and outside on the next reads as a mistake rather than as a fit
   * rule, and the outside ones would sit at a different x on every row, since
   * each is hung off its own bar end. So a side goes out whole as soon as any
   * one of its bars is too short, and buys a `valueGutter` of plot width to do
   * it. At these shares that is the substitution side, whose bars run a
   * twentieth of the indutor ones.
   *
   * Two passes: reserving a gutter shrinks the bars, which can push the other
   * side out as well — never back in, so the answer settles after one repeat.
   */
  function layout(innerWidth: number) {
    const span = indutorMax + substituicaoMax || 1;
    let gutter = { left: 0, right: 0 };
    let inside = { left: true, right: true };

    for (let pass = 0; pass < 2; pass++) {
      const unit = (innerWidth - gutter.left - gutter.right) / span;
      inside = {
        left: data.every((d) => labelFits(d.substituicao, d.substituicao * unit)),
        right: data.every((d) => labelFits(d.indutor, d.indutor * unit)),
      };
      gutter = {
        left: inside.left ? 0 : L.valueGutter,
        right: inside.right ? 0 : L.valueGutter,
      };
    }

    return { gutter, inside };
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
  {#snippet children({
    width: cardWidth,
    innerWidth,
    innerHeight,
    margin,
  }: ChartDimensions)}
    {@const plot = layout(innerWidth)}
    {@const xScale = scaleLinear()
      .domain([-substituicaoMax, indutorMax])
      .range([plot.gutter.left, innerWidth - plot.gutter.right])}
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

      {@const indutorWidth = Math.max(indutorX - zeroX - L.baselineGap, 0)}
      {@const substituicaoWidth = Math.max(zeroX - L.baselineGap - substituicaoX, 0)}

      <path
        d={barPath(zeroX + L.baselineGap, y, indutorWidth, barHeight, 'right')}
        fill={INDUTOR}
      />
      <path
        d={barPath(substituicaoX, y, substituicaoWidth, barHeight, 'left')}
        fill={SUBSTITUICAO}
      />

      <!-- the value rides inside its own bar where the side has room for it,
           and past the bar end into the reserved gutter where it doesn't -->
      {#if plot.inside.right}
        <Text
          x={zeroX + L.baselineGap + indutorWidth / 2}
          y={centerY}
          textAnchor="middle"
          verticalAnchor="middle"
          fontSize={valueStyle.fontSize}
          fontWeight={valueStyle.fontWeight}
          fontFamily={valueStyle.fontFamily}
          fill={getContrastColor(INDUTOR)}
          text={pct(row.indutor)}
        />
      {:else}
        <Text
          x={indutorX + L.valueGap}
          y={centerY}
          textAnchor="start"
          verticalAnchor="middle"
          fontSize={valorForaStyle.fontSize}
          fontWeight={valorForaStyle.fontWeight}
          fontFamily={valorForaStyle.fontFamily}
          fill={valorForaStyle.fill}
          text={pct(row.indutor)}
        />
      {/if}

      {#if plot.inside.left}
        <Text
          x={substituicaoX + substituicaoWidth / 2}
          y={centerY}
          textAnchor="middle"
          verticalAnchor="middle"
          fontSize={valueStyle.fontSize}
          fontWeight={valueStyle.fontWeight}
          fontFamily={valueStyle.fontFamily}
          fill={getContrastColor(SUBSTITUICAO)}
          text={pct(row.substituicao)}
        />
      {:else}
        <Text
          x={substituicaoX - L.valueGap}
          y={centerY}
          textAnchor="end"
          verticalAnchor="middle"
          fontSize={valorForaStyle.fontSize}
          fontWeight={valorForaStyle.fontWeight}
          fontFamily={valorForaStyle.fontFamily}
          fill={valorForaStyle.fill}
          text={pct(row.substituicao)}
        />
      {/if}

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
