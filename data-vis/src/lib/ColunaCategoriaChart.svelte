<script lang="ts" module>
  /** Uma categoria: o rótulo do eixo e o valor de cada série naquela categoria. */
  export type CategoriaRow = { label: string } & Record<string, number | string>;
</script>

<script lang="ts">
  /**
   * Colunas empilhadas por categoria, em valor absoluto — o par de
   * `ComposicaoChart` para quando o eixo não é o tempo e as colunas não fecham
   * em 100%: aqui o que se compara é o volume acumulado de cada categoria, e
   * categorias de tamanhos diferentes têm de aparecer com alturas diferentes.
   *
   * O topo de cada coluna é arredondado, a base repousa sobre o eixo — a mesma
   * pastilha de `ComposicaoChart`. A diferença é a escala: uma só, do zero ao
   * maior total, comum a todas as colunas, e não uma fração de cada uma.
   */
  import { a4Scale, fontFamily, fontSize as scale, labelFitsInBar, measureLabel, wrapText } from './tokens';
  import { layoutLegend } from './legend';

  const cinza = {
    titulo: '#2F2F2B',
    subtitulo: '#6E6E68',
    eixo: '#8A8A84',
    grade: '#EDEDE9',
    nota: '#8A8A84',
  };

  interface Props {
    data: CategoriaRow[];
    /** Categorias na ordem em que empilham, de baixo para cima. */
    keys: string[];
    labels?: Record<string, string>;
    /** Cores na ordem de `keys`. */
    colors: readonly string[];
    title: string;
    subtitle?: string;
    formatValue?: (v: number) => string;
    footnote?: string;
    source?: string;
    legenda?: boolean;
    columnRatio?: number;
    radius?: number;
    plotHeight?: number;
    width?: number;
    height?: number;
    background?: string | null;
    svgEl?: SVGSVGElement | null;
  }

  let {
    data,
    keys,
    labels = {},
    colors,
    title,
    subtitle,
    formatValue = (v: number) => String(v),
    footnote,
    source,
    legenda = true,
    columnRatio = 0.6,
    radius = 8,
    plotHeight = 220,
    width = 580,
    height,
    background,
    svgEl = $bindable(null),
  }: Props = $props();

  const k = $derived(a4Scale(width));

  const type = $derived({
    title: 14 * k,
    subtitle: scale.md * k,
    md: scale.md * k,
    sm: scale.sm * k,
    xs: scale.xs * k,
  });

  const pad = $derived(16 * k);

  const cor = (i: number) => colors[i % colors.length];

  const canal = (v: number) => (v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4);
  const luminancia = (hex: string) => {
    const n = parseInt(hex.slice(1), 16);
    const [r, g, b] = [(n >> 16) & 255, (n >> 8) & 255, n & 255].map((c) => canal(c / 255));
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  };
  const razao = (a: string, b: string) => {
    const [claro, escuro] = [luminancia(a), luminancia(b)].sort((p, q) => q - p);
    return (claro + 0.05) / (escuro + 0.05);
  };
  const contraste = (fundo: string) =>
    razao(fundo, '#FFFFFF') >= razao(fundo, cinza.titulo) ? '#FFFFFF' : cinza.titulo;

  const textWidth = $derived(width - pad * 2);
  const titleLines = $derived(wrapText(title, type.title, textWidth, 600));
  const subtitleLines = $derived(wrapText(subtitle ?? '', type.subtitle, textWidth));
  const footnoteLines = $derived(wrapText(footnote ?? '', type.sm, textWidth));
  const sourceLines = $derived(wrapText(source ?? '', type.sm, textWidth));

  const legendaLayout = $derived(
    legenda
      ? layoutLegend(
          keys.map((key, i) => ({ label: labels[key] ?? key, color: cor(i) })),
          { fontSize: type.sm, fontWeight: 600, padX: 8 * k, maxWidth: textWidth, rowGap: 4 * k },
        )
      : null,
  );

  const valor = (row: CategoriaRow, key: string) => Number(row[key]) || 0;
  const totais = $derived(data.map((row) => keys.reduce((soma, key) => soma + valor(row, key), 0)));
  const maxTotal = $derived(Math.max(...totais, 1));

  type Segmento = { keyIndex: number; bottom: number; top: number; valor: number };

  const colunas = $derived(
    data.map((row, i) => {
      let cursor = 0;
      return keys.map((key, keyIndex): Segmento => {
        const v = valor(row, key);
        const seg = { keyIndex, bottom: cursor, top: cursor + v, valor: v };
        cursor += v;
        return seg;
      });
    }),
  );

  const topoDaColuna = $derived(
    colunas.map((segmentos) => segmentos.reduce((acc, s, i) => (s.valor > 0 ? i : acc), -1)),
  );

  const cabecalho = $derived(
    12 * k + titleLines.length * type.title * 1.36 + subtitleLines.length * type.subtitle * 1.25,
  );
  const titleLine = $derived(19 * k);
  const subtitleLine = $derived(15 * k);
  const notaLine = $derived(13.5 * k);
  const legendaY = $derived(cabecalho + 13 * k);

  const plotTop = $derived(
    (legendaLayout ? legendaY + legendaLayout.height + 20 * k : cabecalho + 20 * k) + 22 * k,
  );
  const plotH = $derived(plotHeight * k);
  const plotBottom = $derived(plotTop + plotH);

  const axisLabelWidth = $derived(measureLabel(formatValue(maxTotal), type.sm, 500));
  const plotLeft = $derived(pad + axisLabelWidth + 8 * k);
  const plotRight = $derived(width - pad);

  const slot = $derived(data.length ? (plotRight - plotLeft) / data.length : 0);
  const colW = $derived(slot * columnRatio);
  const xCentro = (i: number) => plotLeft + slot * (i + 0.5);
  const yDe = (v: number) => plotBottom - (v / maxTotal) * plotH;

  const rotulosCategoria = $derived(
    data.map((row) => wrapText(row.label, type.md, Math.max(slot - 4 * k, 40 * k), 600)),
  );
  const categoriaLine = $derived(13 * k);

  const eixoY = $derived(
    plotBottom + 10 * k + Math.max(...rotulosCategoria.map((l) => l.length)) * categoriaLine,
  );
  const notasTop = $derived(eixoY + 10 * k);
  const alturaFinal = $derived(
    height ?? notasTop + (footnoteLines.length + sourceLines.length) * notaLine + pad,
  );

  function segmentoPath(x: number, y: number, w: number, h: number, r: number) {
    const raio = Math.max(0, Math.min(r, w / 2, h));
    if (!raio) return `M${x},${y} H${x + w} V${y + h} H${x} Z`;
    return [
      `M${x},${y + raio}`,
      `A${raio},${raio} 0 0 1 ${x + raio},${y}`,
      `H${x + w - raio}`,
      `A${raio},${raio} 0 0 1 ${x + w},${y + raio}`,
      `V${y + h}`,
      `H${x}`,
      'Z',
    ].join(' ');
  }

  function pastilha(x: number, y: number, w: number, h: number, first: boolean, last: boolean) {
    const r = h / 2;
    const rL = first ? Math.min(r, w / 2) : 0;
    const rR = last ? Math.min(r, w / 2) : 0;
    return [
      `M${x + rL},${y}`,
      `H${x + w - rR}`,
      rR ? `A${rR},${rR} 0 0 1 ${x + w - rR},${y + h}` : `V${y + h}`,
      `H${x + rL}`,
      rL ? `A${rL},${rL} 0 0 1 ${x + rL},${y}` : `V${y}`,
      'Z',
    ].join(' ');
  }
</script>

<svg
  bind:this={svgEl}
  viewBox="0 0 {width} {alturaFinal}"
  {width}
  height={alturaFinal}
  style="width: 100%; height: auto; font-family: {fontFamily};"
  role="img"
  aria-label={title}
>
  {#if background}
    <rect x="0" y="0" {width} height={alturaFinal} rx={10 * k} fill={background} />
  {/if}

  {#each titleLines as linha, i (i)}
    <text
      x={pad}
      y={12 * k + (i + 0.8) * titleLine}
      font-size={type.title}
      font-weight="600"
      fill={cinza.titulo}
      font-family={fontFamily}>{linha}</text
    >
  {/each}
  {#each subtitleLines as linha, i (i)}
    <text
      x={pad}
      y={12 * k + titleLines.length * titleLine + (i + 0.75) * subtitleLine}
      font-size={type.subtitle}
      fill={cinza.subtitulo}
      font-family={fontFamily}>{linha}</text
    >
  {/each}

  {#if legendaLayout}
    {#each legendaLayout.chips as chip (chip.label)}
      <path
        d={pastilha(pad + chip.x, legendaY + chip.y, chip.width, legendaLayout.chipHeight, chip.first, chip.last)}
        fill={chip.color}
      />
      <text
        x={pad + chip.x + chip.width / 2}
        y={legendaY + chip.y + legendaLayout.chipHeight / 2 + type.sm * 0.35}
        text-anchor="middle"
        font-size={type.sm}
        font-weight="600"
        fill={contraste(chip.color)}
        font-family={fontFamily}>{chip.label}</text
      >
    {/each}
  {/if}

  {#each [0, 0.25, 0.5, 0.75, 1] as f (f)}
    <line
      x1={plotLeft}
      y1={yDe(f * maxTotal)}
      x2={plotRight}
      y2={yDe(f * maxTotal)}
      stroke={cinza.grade}
      stroke-width={1.2 * k}
    />
    <text
      x={plotLeft - 8 * k}
      y={yDe(f * maxTotal) + type.sm * 0.35}
      text-anchor="end"
      font-size={type.sm}
      font-weight="500"
      fill={cinza.eixo}
      font-family={fontFamily}>{formatValue(f * maxTotal)}</text
    >
  {/each}

  {#each colunas as segmentos, i (data[i].label)}
    {@const x = xCentro(i) - colW / 2}
    {#each segmentos as seg (seg.keyIndex)}
      {#if seg.valor > 0}
        {@const y = yDe(seg.top)}
        {@const h = yDe(seg.bottom) - y}
        <path d={segmentoPath(x, y, colW, h, seg.keyIndex === topoDaColuna[i] ? radius * k : 0)} fill={cor(seg.keyIndex)} />
        {#if labelFitsInBar(formatValue(seg.valor), type.xs, colW, 600, 4 * k, 4 * k) && h >= type.xs * 1.3}
          <text
            x={x + colW / 2}
            y={y + h / 2 + type.xs * 0.35}
            text-anchor="middle"
            font-size={type.xs}
            font-weight="600"
            fill={contraste(cor(seg.keyIndex))}
            font-family={fontFamily}>{formatValue(seg.valor)}</text
          >
        {/if}
      {/if}
    {/each}

    <text
      x={xCentro(i)}
      y={yDe(totais[i]) - 12 * k}
      text-anchor="middle"
      font-size={type.sm}
      font-weight="700"
      fill={cinza.titulo}
      font-family={fontFamily}>{formatValue(totais[i])}</text
    >

    {#each rotulosCategoria[i] as linha, j (j)}
      <text
        x={xCentro(i)}
        y={plotBottom + 10 * k + (j + 0.8) * categoriaLine}
        text-anchor="middle"
        font-size={type.sm}
        font-weight="500"
        fill={cinza.eixo}
        font-family={fontFamily}>{linha}</text
      >
    {/each}
  {/each}

  <line x1={plotLeft} x2={plotRight} y1={plotBottom} y2={plotBottom} stroke={cinza.grade} stroke-width={1.2 * k} />

  {#each footnoteLines as linha, i (i)}
    <text
      x={pad}
      y={notasTop + (i + 0.8) * notaLine}
      font-size={type.sm}
      fill={cinza.nota}
      font-family={fontFamily}>{linha}</text
    >
  {/each}
  {#each sourceLines as linha, i (i)}
    <text
      x={pad}
      y={notasTop + (footnoteLines.length + i + 0.8) * notaLine}
      font-size={type.sm}
      fill={cinza.nota}
      font-family={fontFamily}>{linha}</text
    >
  {/each}
</svg>
