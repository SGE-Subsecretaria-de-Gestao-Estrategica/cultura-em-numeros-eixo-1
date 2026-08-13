<script lang="ts">
  /**
   * Barras horizontais com o rótulo da categoria à esquerda e o valor na ponta.
   *
   * Horizontal e não vertical porque as categorias destes gráficos são frases —
   * "Ensino médio a pós-graduação lato sensu", "Mais de 90%" — que na vertical
   * teriam de ser giradas ou abreviadas. Deitadas, elas se leem na horizontal e
   * o comprimento da barra fica livre para carregar a comparação.
   */
  import { scaleBand, scaleLinear } from 'd3';
  import {
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
    wrapText,
  } from './tokens';

  /** Uma barra: a categoria, o comprimento e o texto escrito na ponta. */
  export type Barra = { label: string; valor: number; rotulo: string };

  interface Props {
    itens: Barra[];
    title: string;
    subtitle?: string;
    footnote?: string;
    source?: string;
    /** Cor das barras; por omissão, a primeira da paleta categórica do DS. */
    color?: string;
    /** Teto do eixo; por omissão, o maior valor. */
    xMax?: number;
    /** Altura de cada faixa, em unidades autorais. */
    bandHeight?: number;
    /** Largura intrínseca, em unidades de SVG — ver `SerieHistoricaChart`. */
    width?: number;
    height?: number;
    responsive?: boolean;
    pillar?: number;
    background?: string | null;
    svgEl?: SVGSVGElement | null;
  }

  let {
    itens,
    title,
    subtitle,
    footnote,
    source,
    color,
    xMax,
    bandHeight = 34,
    width = 1368,
    height,
    responsive = false,
    pillar = 1,
    background,
    svgEl = $bindable(null),
  }: Props = $props();

  const k = $derived(a4Scale(width));

  const TITLE_FONT_SIZE = 14;

  const type = $derived({
    title: TITLE_FONT_SIZE * k,
    md: scale.md * k,
    sm: scale.sm * k,
    xs: scale.xs * k,
  });

  const theme = $derived(getPillarTheme(pillar));
  const palette = $derived(theme.palette);

  /**
   * A paleta do pilar traz só três matizes reais — o resto da rampa são tons da
   * mesma cor — então a cor da barra vem da escala categórica do sistema, que é
   * a mesma de onde os gráficos vizinhos tiram as suas. O tema do pilar segue
   * mandando nos neutros: tipo, base do cartão e bordas.
   */
  const barColor = $derived(color ?? categorical8[0]);

  const L = $derived({
    cardPadding: 24 * k,
    cardRadius: 12 * k,
    titleLine: 24 * k,
    subtitleLine: 15 * k,
    noteLine: 14 * k,
    titleBlockGap: 22 * k,
    noteGap: 26 * k,
    noteSpacing: 3 * k,
    band: bandHeight * k,
    barRadius: 3 * k,
    /** Rótulo da categoria até a borda do plot. */
    labelGap: 12 * k,
    /** Ponta da barra até o valor escrito ao lado dela. */
    valueGap: 8 * k,
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

  /**
   * As duas margens laterais são medidas no texto que vai ocupá-las, não
   * fixadas: à direita, o valor mais largo, que fica pendurado para fora da
   * barra mais comprida; à esquerda, o nome de categoria mais largo. Uma coluna
   * de rótulos arbitrada corta frases como "Ensino médio a pós-graduação lato
   * sensu" — e o corte só aparece depois de exportar.
   */
  const valorMaisLargo = $derived(
    Math.max(...itens.map((i) => measureLabel(i.rotulo, type.sm, 600))),
  );
  const categoriaMaisLarga = $derived(
    Math.max(...itens.map((i) => measureLabel(i.label, type.md, 500))),
  );

  const MARGIN = $derived({
    left: L.labelGap + categoriaMaisLarga + L.cardPadding,
    right: L.valueGap + valorMaisLargo + L.cardPadding,
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

  const cardHeight = $derived(height ?? MARGIN.top + itens.length * L.band + MARGIN.bottom);

  const categorias = $derived(itens.map((i) => i.label));
  const topo = $derived(xMax ?? Math.max(...itens.map((i) => i.valor)));
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
    {@const xScale = scaleLinear().domain([0, topo]).range([0, innerWidth])}
    {@const yScale = scaleBand<string>()
      .domain(categorias)
      .range([0, innerHeight])
      .padding(0.3)}
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

    {#each itens as item (item.label)}
      {@const y = yScale(item.label) ?? 0}
      {@const centerY = y + barHeight / 2}
      {@const larguraBarra = Math.max(xScale(item.valor), 0)}

      <Text
        x={-L.labelGap}
        y={centerY}
        textAnchor="end"
        verticalAnchor="middle"
        fontSize={type.md}
        fontWeight={600}
        {fontFamily}
        fill={palette.neutral[300]}
        text={item.label}
      />

      <rect
        x={0}
        y={y}
        width={larguraBarra}
        height={barHeight}
        rx={L.barRadius}
        fill={barColor}
      />

      <Text
        x={larguraBarra + L.valueGap}
        y={centerY}
        textAnchor="start"
        verticalAnchor="middle"
        fontSize={type.sm}
        fontWeight={400}
        {fontFamily}
        fill={palette.neutral[200]}
        text={item.rotulo}
      />
    {/each}

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
