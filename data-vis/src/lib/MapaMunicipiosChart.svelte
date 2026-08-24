<script lang="ts">
  /**
   * Coroplético municipal do Brasil: cada um dos 5.570 municípios pintado pela
   * classe a que pertence, com as divisas estaduais por cima como referência.
   *
   * A malha vem da API de malhas do IBGE (qualidade mínima) e fica no bundle
   * como TopoJSON — 1,4 MB contra ~4 MB do GeoJSON equivalente, porque as
   * fronteiras compartilhadas são guardadas uma vez só. É também o que permite
   * derivar as divisas estaduais por `mesh`, exatamente coincidentes com as
   * bordas municipais, em vez de sobrepor um segundo arquivo que não casaria.
   *
   * Os municípios não viram 5.570 `<path>`: os polígonos de uma mesma classe
   * são concatenados num único `d`. O SVG cai de dezenas de milhares de nós
   * para meia dúzia, o que o export a 4× e o navegador agradecem.
   */
  import { geoConicEqualArea, geoPath } from 'd3';
  import { feature, mesh } from 'topojson-client';
  import {
    Chart,
    DefaultTheme,
    getPillarTheme,
    resolveThemeStyle,
    type ChartDimensions,
    type ChartTheme,
  } from 'sniic-design-system';
  import LegendChips from './LegendChips.svelte';
  import TextLines from './TextLines.svelte';
  import { layoutLegend } from './legend';
  import malhaJson from '../data/malha-municipios.json';
  import { a4Scale, fontFamily, fontSize as scale, wrapText } from './tokens';

  /** Uma classe da legenda: o rótulo e a cor com que os municípios dela saem. */
  export type ClasseMapa = { label: string; color: string };

  interface Props {
    /** Código IBGE (7 dígitos) → índice em `classes`; null = sem informação. */
    valores: Record<string, number | null>;
    /** As classes, na ordem da legenda. */
    classes: ClasseMapa[];
    /** Cor e rótulo dos municípios com valor null; a legenda só os mostra se existirem. */
    semInfo?: ClasseMapa;
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
    valores,
    classes,
    semInfo,
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

  /**
   * Geometria estática, computada uma vez por módulo e não por instância: a
   * malha é a mesma para todo mapa, e expandir 16.490 arcos é o trabalho caro.
   */
  const topo = malhaJson as any;
  const municipios = feature(topo, topo.objects.BRMU) as any;
  const uf = (g: any) => String(g.properties.codarea).slice(0, 2);
  /** Divisas entre municípios de estados diferentes — as linhas estaduais internas. */
  const divisasEstaduais = mesh(topo, topo.objects.BRMU, (a: any, b: any) => uf(a) !== uf(b));
  /** A borda externa do país — arcos que pertencem a um único polígono. */
  const contorno = mesh(topo, topo.objects.BRMU, (a: any, b: any) => a === b);

  const k = $derived(a4Scale(width));

  const TITLE_FONT_SIZE = 14;

  const type = $derived({
    title: TITLE_FONT_SIZE * k,
    md: scale.md * k,
    sm: scale.sm * k,
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
    legendGap: 24 * k,
    legendRowGap: 4 * k,
    legendRadius: 2 * k,
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

  /** Só entra "sem informação" na legenda se algum município estiver de fato sem valor. */
  const temSemInfo = $derived(
    semInfo != null && Object.values(valores).some((v) => v == null),
  );
  const legendItems = $derived([...classes, ...(temSemInfo && semInfo ? [semInfo] : [])]);

  const legend = $derived(
    layoutLegend(legendItems, {
      fontSize: type.sm,
      fontWeight: 600,
      padX: 10 * k,
      maxWidth: textWidth,
      rowGap: L.legendRowGap,
    }),
  );

  /**
   * Cônica equivalente ajustada ao Brasil — num coroplético a variável está na
   * *área* pintada, então a projeção precisa preservar áreas: em Mercator a
   * Amazônia sairia inflada em relação ao Sul e o mapa mentiria exatamente no
   * que ele quantifica. Paralelos em −5° e −30,5°, os padrão para o país.
   */
  const projecao = $derived(
    geoConicEqualArea().parallels([-5, -30.5]).rotate([54, 0]).fitWidth(textWidth, municipios),
  );
  /** Uma casa decimal chega: a unidade autoral já é ~0,1 mm impresso. */
  const caminho = $derived(geoPath(projecao).digits(1));
  const alturaMapa = $derived(Math.ceil(caminho.bounds(municipios)[1][1]));

  /** O `d` concatenado de cada classe — um `<path>` por cor, não por município. */
  const grupos = $derived.by(() => {
    const porCor = new Map<string, string[]>();
    for (const f of municipios.features) {
      const valor = valores[String(f.properties.codarea)];
      const cor = valor == null ? (semInfo?.color ?? palette.base[300]) : classes[valor].color;
      const d = caminho(f);
      if (!d) continue;
      const lista = porCor.get(cor);
      if (lista) lista.push(d);
      else porCor.set(cor, [d]);
    }
    return [...porCor.entries()].map(([cor, ds]) => ({ cor, d: ds.join('') }));
  });

  const MARGIN = $derived({
    left: L.cardPadding,
    right: L.cardPadding,
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

  const cardHeight = $derived(MARGIN.top + alturaMapa + MARGIN.bottom);
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
  {#snippet children({ width: cardWidth, innerHeight, margin }: ChartDimensions)}
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

    <!-- o traço da própria cor fecha as frestas de antialiasing entre polígonos vizinhos -->
    {#each grupos as grupo (grupo.cor)}
      <path d={grupo.d} fill={grupo.cor} stroke={grupo.cor} stroke-width={0.5 * k} />
    {/each}

    <path
      d={caminho(divisasEstaduais) ?? ''}
      fill="none"
      stroke={background ?? palette.base[100]}
      stroke-width={1.2 * k}
      stroke-linejoin="round"
    />
    <path
      d={caminho(contorno) ?? ''}
      fill="none"
      stroke={palette.neutral[100]}
      stroke-width={0.6 * k}
      stroke-linejoin="round"
    />

    <LegendChips
      items={legendItems}
      left={cardLeft}
      top={innerHeight + L.legendGap}
      padX={10 * k}
      maxWidth={textWidth}
      rowGap={L.legendRowGap}
      fontSize={type.sm}
      {fontFamily}
      fontWeight={600}
      radius={L.legendRadius}
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
