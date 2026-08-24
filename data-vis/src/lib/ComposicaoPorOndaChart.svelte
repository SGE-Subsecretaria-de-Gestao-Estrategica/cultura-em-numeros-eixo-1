<script lang="ts">
  /**
   * Composição percentual de uma variável categórica, uma coluna por onda de
   * pesquisa, empilhada até 100%.
   *
   * Aqui as ondas são bandas iguais, e não posições num eixo de tempo como no
   * `SerieHistoricaChart`: o que se lê numa barra empilhada é a repartição
   * interna de cada onda, não a velocidade da mudança entre elas, então a
   * distância real entre os anos não carrega informação e só estreitaria as
   * colunas mais próximas.
   */
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
  import { layoutLegend } from './legend';
  import { categoricaMarca } from './cores';
  import {
    a4Scale,
    fontFamily,
    fontSize as scale,
    labelFitsInBar,
    wrapText,
  } from './tokens';

  /** Uma onda: o rótulo do eixo, a base de respostas válidas e uma fatia por categoria. */
  export type OndaRow = { label: string; base: number } & Record<string, number | string>;

  interface Props {
    data: OndaRow[];
    /** Categorias, na ordem em que empilham de baixo para cima. */
    categorias: string[];
    /** Cores na ordem de `categorias`; por omissão, a paleta categórica do DS. */
    colors?: readonly string[];
    title: string;
    subtitle?: string;
    footnote?: string;
    source?: string;
    /** Escreve a base de respostas sob o rótulo de cada onda. */
    showBase?: boolean;
    /** Largura intrínseca, em unidades de SVG — ver `SerieHistoricaChart`. */
    width?: number;
    height?: number;
    responsive?: boolean;
    pillar?: number;
    background?: string | null;
    svgEl?: SVGSVGElement | null;
  }

  let {
    data,
    categorias,
    colors = categoricaMarca,
    title,
    subtitle,
    footnote,
    source,
    showBase = true,
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
    /** Rótulo da onda — o mesmo corpo do eixo X da série histórica. */
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
    marginLeft: 46 * k,
    marginRight: 24 * k,
    titleLine: 24 * k,
    subtitleLine: 15 * k,
    noteLine: 14 * k,
    titleBlockGap: 26 * k,
    plotHeight: 260 * k,
    /** Base do plot ao rótulo da onda, e daí à linha da base de respostas. */
    ondaLabelGap: 20 * k,
    baseLabelGap: 34 * k,
    /** Base do plot até a faixa de legenda. */
    legendGap: 52 * k,
    legendRowGap: 4 * k,
    noteGap: 18 * k,
    noteSpacing: 3 * k,
    segmentRadius: 2 * k,
    /** Metade do vão de superfície entre segmentos vizinhos. */
    segmentGap: 1 * k,
    /** Rótulo puxado para fora, à direita do topo da coluna. */
    railGap: 8 * k,
    railSpacing: 4 * k,
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
      { fontSize: type.sm, fontWeight: 600, fontFamily },
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
    categorias.map((c, i) => ({ label: c, color: categoriaColor(i) })),
  );

  /**
   * A legenda é diagramada antes do cartão para a margem inferior reservar a
   * altura que ela realmente vai ocupar. Cinco categorias com nomes como
   * "Não possui estrutura" não cabem numa linha só na coluna de um A4, e sem
   * isto a última pastilha sairia pela borda do cartão.
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
      legend.height +
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
  const integer = new Intl.NumberFormat('pt-BR');
  const pct = (v: number) => `${decimal.format(v)}%`;

  const labels = $derived(data.map((d) => d.label));
  const value = (row: OndaRow, key: string) => Number(row[key]) || 0;

  type Segment = {
    key: string;
    keyIndex: number;
    value: number;
    y: number;
    height: number;
  };

  /**
   * Segmentos de uma coluna, normalizados ao próprio total da onda para as
   * colunas fecharem exatamente em 100% mesmo onde as fatias de origem não
   * somam certo por arredondamento.
   */
  function layoutColuna(row: OndaRow, yScale: (v: number) => number): Segment[] {
    const total = categorias.reduce((sum, c) => sum + value(row, c), 0) || 1;
    let cursor = 0;

    return categorias.map((key, keyIndex) => {
      const share = (value(row, key) / total) * 100;
      const y0 = yScale(cursor);
      cursor += share;
      const y1 = yScale(cursor);
      return { key, keyIndex, value: value(row, key), y: y1, height: y0 - y1 };
    });
  }

  type Rail = { key: string; text: string; color: string; anchorY: number; y: number };

  /**
   * Valores de segmentos finos demais para os conterem, escritos à direita da
   * coluna. `Administração indireta` fica em 2% nas quatro ondas e nunca cabe;
   * sem isto, a única categoria que não se move seria também a única sem número.
   */
  function railLabels(segments: Segment[]): Rail[] {
    const size = Number(segmentStyle.fontSize);
    const altura = size * 1.15;

    const pendentes = segments
      .filter((s) => s.value > 0 && s.height < altura + 2 * k)
      .map((s) => ({
        key: s.key,
        text: pct(s.value),
        color: categoriaColor(s.keyIndex),
        anchorY: s.y + s.height / 2,
        y: s.y + s.height / 2,
      }))
      .sort((a, b) => a.anchorY - b.anchorY);

    for (let i = 1; i < pendentes.length; i++) {
      const piso = pendentes[i - 1].y + altura + L.railSpacing;
      pendentes[i].y = Math.max(pendentes[i].y, piso);
    }

    return pendentes;
  }

  /** Um segmento empilhado, arredondado só onde a coluna termina. */
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
    {@const xScale = scaleBand<string>()
      .domain(labels)
      .range([0, innerWidth])
      .padding(0.45)}
    {@const yScale = scaleLinear().domain([0, 100]).range([innerHeight, 0])}
    {@const bandwidth = xScale.bandwidth()}
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

    <!-- eixo de referência: as colunas vão todas a 100%, então bastam 0 e 100 -->
    {#each [0, 25, 50, 75, 100] as tick (tick)}
      <Text
        x={-L.railGap}
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

    {#each data as row (row.label)}
      {@const x = xScale(row.label) ?? 0}
      {@const segments = layoutColuna(row, (v) => yScale(v))}

      {#each segments as segment, index (segment.key)}
        {@const first = index === 0}
        {@const last = index === segments.length - 1}
        {@const y = segment.y + (last ? 0 : L.segmentGap)}
        {@const altura = Math.max(
          segment.height - (first ? 0 : L.segmentGap) - (last ? 0 : L.segmentGap),
          0,
        )}
        {@const label = pct(segment.value)}
        {@const color = categoriaColor(segment.keyIndex)}

        <path
          d={segmentPath(
            x,
            y,
            bandwidth,
            altura,
            last ? L.segmentRadius : 0,
            first ? L.segmentRadius : 0,
          )}
          fill={color}
        />

        {#if segment.height >= Number(segmentStyle.fontSize) * 1.15 + 2 * k && labelFitsInBar( label, Number(segmentStyle.fontSize), bandwidth, Number(segmentStyle.fontWeight), )}
          <Text
            x={x + bandwidth / 2}
            y={segment.y + segment.height / 2}
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

      <!-- guias primeiro, para nenhuma linha cruzar um rótulo que não é seu -->
      {@const rail = railLabels(segments)}
      {#each rail as item (item.key)}
        <polyline
          points={`${x + bandwidth},${item.anchorY} ${x + bandwidth + L.railGap / 2},${item.anchorY} ${x + bandwidth + L.railGap},${item.y}`}
          fill="none"
          stroke={item.color}
          stroke-width={k}
        />
      {/each}
      {#each rail as item (item.key)}
        <Text
          x={x + bandwidth + L.railGap * 1.4}
          y={item.y}
          textAnchor="start"
          verticalAnchor="middle"
          fontSize={type.xs}
          fontWeight={500}
          {fontFamily}
          fill={palette.neutral[200]}
          text={item.text}
        />
      {/each}

      <Text
        x={x + bandwidth / 2}
        y={innerHeight + L.ondaLabelGap}
        textAnchor="middle"
        verticalAnchor="middle"
        fontSize={type.lg}
        fontWeight={500}
        {fontFamily}
        fill={palette.neutral[300]}
        text={row.label}
      />

      {#if showBase}
        <Text
          x={x + bandwidth / 2}
          y={innerHeight + L.baseLabelGap}
          textAnchor="middle"
          verticalAnchor="middle"
          fontSize={type.xs}
          fontWeight={400}
          {fontFamily}
          fill={palette.neutral[100]}
          text={`${integer.format(row.base)} municípios`}
        />
      {/if}
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
