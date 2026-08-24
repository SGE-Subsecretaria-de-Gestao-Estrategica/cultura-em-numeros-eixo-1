<script lang="ts">
  /**
   * Uma tabela desenhada como figura: cabeçalho de colunas, seções com faixa
   * própria e células que podem carregar um fundo — é o que permite usá-la como
   * heatmap de leitura ("table lens") e exportá-la em PNG junto dos gráficos.
   *
   * Existe ao lado de `FederalFontesTable`, que é HTML de propósito: aquela é
   * material de consulta dentro do relatório, esta é uma *figura* — entra no
   * pipeline de export, que captura `figure > div > svg`, e por isso precisa
   * ser SVG e carregar o próprio chrome de cartão.
   */
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
  import TextLines from './TextLines.svelte';
  import { a4Scale, fontFamily, fontSize as scale, measureLabel, wrapText } from './tokens';

  /** Uma célula: o texto e, opcionalmente, um fundo e um peso próprios. */
  export type Celula = {
    text: string;
    fill?: string;
    textColor?: string;
    fontWeight?: number;
  };

  export type LinhaTabela = { label?: string; cells: Celula[] };

  /** Um bloco de linhas sob uma faixa de título — uma região, uma onda. */
  export type SecaoTabela = { label?: string; rows: LinhaTabela[] };

  interface Props {
    /** Cabeçalho das colunas de valor; quebra em mais de uma linha se preciso. */
    colunas: string[];
    /** Título da coluna de rótulos das linhas, quando as linhas têm rótulo. */
    rotuloLinhas?: string;
    secoes: SecaoTabela[];
    title: string;
    subtitle?: string;
    footnote?: string;
    source?: string;
    /** Largura intrínseca, em unidades de SVG — ver `SerieHistoricaChart`. */
    width?: number;
    responsive?: boolean;
    pillar?: number;
    background?: string | null;
    svgEl?: SVGSVGElement | null;
  }

  let {
    colunas,
    rotuloLinhas,
    secoes,
    title,
    subtitle,
    footnote,
    source,
    width = 1368,
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

  const L = $derived({
    cardPadding: 24 * k,
    cardRadius: 12 * k,
    titleLine: 24 * k,
    subtitleLine: 15 * k,
    noteLine: 14 * k,
    titleBlockGap: 20 * k,
    /** Altura de uma linha de dados e da faixa de seção. */
    row: 21 * k,
    secao: 22 * k,
    /** Respiro entre o fim de uma seção e a faixa da próxima. */
    secaoGap: 6 * k,
    headerLine: 12 * k,
    headerGap: 8 * k,
    /** Folga horizontal interna das células e dos rótulos. */
    cellPadX: 8 * k,
    noteGap: 18 * k,
    noteSpacing: 3 * k,
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
   * A coluna de rótulos é medida no rótulo mais largo, como as margens dos
   * gráficos de barras; zero quando nenhuma linha tem rótulo e as colunas de
   * valor ocupam a largura toda.
   */
  const temRotulos = $derived(secoes.some((s) => s.rows.some((r) => r.label)));
  const labelColWidth = $derived(
    temRotulos
      ? Math.max(
          ...secoes.flatMap((s) => s.rows.map((r) => measureLabel(r.label ?? '', type.sm, 500))),
          measureLabel(rotuloLinhas ?? '', type.xs, 600),
        ) +
          L.cellPadX * 2
      : 0,
  );
  const colWidth = $derived((textWidth - labelColWidth) / colunas.length);

  /** Cabeçalhos quebrados de antemão, para a altura do cabeçalho ser conhecida. */
  const headerLines = $derived(
    colunas.map((c) => wrapText(c, type.xs, colWidth - L.cellPadX)),
  );
  const headerHeight = $derived(
    Math.max(...headerLines.map((l) => l.length)) * L.headerLine + L.headerGap,
  );

  const corpoAltura = $derived(
    secoes.reduce(
      (soma, s, i) =>
        soma +
        (s.label ? L.secao : 0) +
        s.rows.length * L.row +
        (i > 0 ? L.secaoGap : 0),
      0,
    ),
  );

  const MARGIN = $derived({
    left: L.cardPadding,
    right: L.cardPadding,
    top:
      L.cardPadding +
      titleLines.length * L.titleLine +
      subtitleLines.length * L.subtitleLine +
      L.titleBlockGap +
      headerHeight,
    bottom:
      L.noteGap +
      footnoteLines.length * L.noteLine +
      (footnoteLines.length && sourceLines.length ? L.noteSpacing : 0) +
      sourceLines.length * L.noteLine +
      L.cardPadding,
  });

  const cardHeight = $derived(MARGIN.top + corpoAltura + MARGIN.bottom);

  /** y do topo de cada seção, acumulado na ordem. */
  const secaoTops = $derived.by(() => {
    const tops: number[] = [];
    let y = 0;
    for (const [i, s] of secoes.entries()) {
      if (i > 0) y += L.secaoGap;
      tops.push(y);
      y += (s.label ? L.secao : 0) + s.rows.length * L.row;
    }
    return tops;
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
  {#snippet children({ width: cardWidth, margin }: ChartDimensions)}
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

    <!-- cabeçalho das colunas, alinhado à direita como os números que encabeça -->
    {#if rotuloLinhas && temRotulos}
      <Text
        x={L.cellPadX}
        y={-L.headerGap}
        textAnchor="start"
        verticalAnchor="end"
        fontSize={type.xs}
        fontWeight={600}
        {fontFamily}
        fill={palette.neutral[200]}
        text={rotuloLinhas}
      />
    {/if}
    {#each headerLines as lines, c (c)}
      {@const x = labelColWidth + (c + 1) * colWidth - L.cellPadX}
      {#each lines as line, i (i)}
        <Text
          {x}
          y={-L.headerGap - (lines.length - 1 - i) * L.headerLine}
          textAnchor="end"
          verticalAnchor="end"
          fontSize={type.xs}
          fontWeight={600}
          {fontFamily}
          fill={palette.neutral[200]}
          text={line}
        />
      {/each}
    {/each}
    <line
      x1={0}
      x2={textWidth}
      y1={0}
      y2={0}
      stroke={palette.base[300]}
      stroke-width={k}
    />

    {#each secoes as secao, s (s)}
      {@const top = secaoTops[s]}

      {#if secao.label}
        <rect
          x={0}
          y={top}
          width={textWidth}
          height={L.secao}
          fill={palette.base[200]}
        />
        <Text
          x={L.cellPadX}
          y={top + L.secao / 2}
          textAnchor="start"
          verticalAnchor="middle"
          fontSize={type.sm}
          fontWeight={600}
          {fontFamily}
          fill={palette.neutral[300]}
          text={secao.label}
        />
      {/if}

      {#each secao.rows as row, r (r)}
        {@const rowTop = top + (secao.label ? L.secao : 0) + r * L.row}
        {@const rowMid = rowTop + L.row / 2}

        {#if row.label}
          <Text
            x={L.cellPadX}
            y={rowMid}
            textAnchor="start"
            verticalAnchor="middle"
            fontSize={type.sm}
            fontWeight={500}
            {fontFamily}
            fill={palette.neutral[300]}
            text={row.label}
          />
        {/if}

        {#each row.cells as cell, c (c)}
          {@const x = labelColWidth + c * colWidth}
          {#if cell.fill}
            <rect x={x + 0.5 * k} y={rowTop + 0.5 * k} width={colWidth - k} height={L.row - k} fill={cell.fill} />
          {/if}
          <Text
            x={x + colWidth - L.cellPadX}
            y={rowMid}
            textAnchor="end"
            verticalAnchor="middle"
            fontSize={type.sm}
            fontWeight={cell.fontWeight ?? 400}
            {fontFamily}
            fill={cell.textColor ?? (cell.fill ? getContrastColor(cell.fill) : palette.neutral[200])}
            text={cell.text}
          />
        {/each}

        <line
          x1={0}
          x2={textWidth}
          y1={rowTop + L.row}
          y2={rowTop + L.row}
          stroke={palette.base[200]}
          stroke-width={0.75 * k}
        />
      {/each}
    {/each}

    {@const notesTop = corpoAltura + L.noteGap}

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
