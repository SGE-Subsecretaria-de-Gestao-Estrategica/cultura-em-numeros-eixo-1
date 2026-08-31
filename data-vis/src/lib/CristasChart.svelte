<script lang="ts" module>
  export type Crista = {
    key: string;
    label: string;
    /** Linha miúda sob o rótulo — normalmente a base do grupo. */
    nota?: string;
    /** Densidade avaliada na grade, já normalizada para somar 1. */
    densidade: number[];
    /** Valor escrito na ponta direita da fileira. */
    destaque?: string;
  };
</script>

<script lang="ts">
  /**
   * Cristas de densidade: a forma da distribuição de cada grupo, uma sob a
   * outra, sobre um eixo horizontal comum.
   *
   * É a figura que faltava à coleção inteira. Todas as outras medem agregado —
   * uma média, uma contagem, uma proporção —, e nenhuma mostra que há 5.191
   * municípios por trás de cada uma dessas medidas, nem como eles se
   * distribuem. Uma proporção de 36,6% acima de 2% não diz que a massa está
   * colada no zero, e é isso que a crista diz de relance.
   *
   * A área sob cada curva é a mesma nas cinco, porque a densidade é normalizada
   * por grupo: o que se compara é a forma, não o tamanho do grupo. O tamanho
   * fica escrito ao lado do rótulo, porque uma curva de 396 municípios e uma de
   * 1.694 não valem o mesmo como evidência.
   *
   * A curva é partida na linha de referência e as duas partes têm cores
   * diferentes, então a fração da área que está acima da meta se lê sem
   * nenhum número — e o número, que é o mesmo da figura de linhas por região,
   * fica na ponta direita para as duas leituras se reconhecerem.
   */
  import { area, curveBasis, line } from 'd3';
  import { a4Scale, fontFamily, fontSize as scale, measureLabel, wrapText } from './tokens';

  let {
    cristas,
    xMax,
    referencia,
    corAbaixo,
    corAcima,
    corTraco,
    title,
    subtitle,
    formatX = (v: number) => String(v),
    legendaReferencia,
    footnote,
    source,
    width = 580,
    alturaDaCrista = 52,
    svgEl = $bindable(null),
    background = null,
  }: {
    cristas: Crista[];
    xMax: number;
    /** A linha vertical que parte as curvas — a meta. */
    referencia: number;
    corAbaixo: string;
    corAcima: string;
    corTraco: string;
    title: string;
    subtitle?: string;
    formatX?: (v: number) => string;
    legendaReferencia: string;
    footnote?: string;
    source?: string;
    width?: number;
    alturaDaCrista?: number;
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  // svelte-ignore state_referenced_locally -- a largura autoral é fixada na criação
  const k = a4Scale(width);

  const type = {
    title: 14 * k,
    subtitle: scale.md * k,
    rotulo: 11 * k,
    nota: scale.xs * k,
    dado: scale.sm * k,
    eixo: scale.sm * k,
    legenda: scale.sm * k,
    notaRodape: scale.sm * k,
  };

  const cinza = {
    titulo: '#2F2F2B',
    subtitulo: '#6E6E68',
    rotulo: '#33332F',
    detalhe: '#8A8A84',
    dado: '#3F3F3B',
    grade: '#EDEDE9',
    ref: '#262622',
    nota: '#8A8A84',
  };

  const pad = 16 * k;

  const textWidth = $derived(width - pad * 2);
  const titleLines = $derived(wrapText(title, type.title, textWidth, 600));
  const subtitleLines = $derived(wrapText(subtitle ?? '', type.subtitle, textWidth));
  const footnoteLines = $derived(wrapText(footnote ?? '', type.notaRodape, textWidth));
  const sourceLines = $derived(wrapText(source ?? '', type.notaRodape, textWidth));

  const titleLine = 19 * k;
  const subtitleLine = 15 * k;
  const notaLine = 13.5 * k;

  /** Coluna dos rótulos à esquerda e a do valor de ponta à direita. */
  const larguraRotulos = $derived(
    Math.max(...cristas.map((c) => measureLabel(c.label, type.rotulo, 600))) + 12 * k,
  );
  const larguraDestaque = $derived(
    cristas.some((c) => c.destaque)
      ? Math.max(...cristas.map((c) => measureLabel(c.destaque ?? '', type.dado, 700))) + 12 * k
      : 0,
  );

  const plotLeft = $derived(pad + larguraRotulos);
  const plotRight = $derived(width - pad - larguraDestaque);

  const topo = $derived(
    12 * k + titleLines.length * titleLine + subtitleLines.length * subtitleLine + 22 * k,
  );

  const alturaCrista = $derived(alturaDaCrista * k);
  const passoFileira = $derived(alturaCrista + 16 * k);
  const baseDe = $derived((i: number) => topo + (i + 1) * alturaCrista + i * 16 * k);
  const fimDasCristas = $derived(baseDe(cristas.length - 1));

  /**
   * O eixo desce o bastante para não encostar na nota do último rótulo, que é
   * escrita abaixo da linha de base da sua fileira.
   */
  const eixoY = $derived(fimDasCristas + 24 * k);
  const legendaY = $derived(eixoY + 18 * k);
  const notasTop = $derived(legendaY + (footnoteLines.length + sourceLines.length ? 14 * k : 0));
  const height = $derived(notasTop + (footnoteLines.length + sourceLines.length) * notaLine + pad);

  const grade = $derived(cristas[0].densidade.length);
  const x = $derived(
    (i: number) => plotLeft + (i / (grade - 1)) * (plotRight - plotLeft),
  );
  const xValor = $derived(
    (v: number) => plotLeft + (v / xMax) * (plotRight - plotLeft),
  );

  /** Escala vertical comum às cinco: a maior densidade enche a fileira. */
  const dMax = $derived(Math.max(...cristas.flatMap((c) => c.densidade)));

  /**
   * O índice de grade da referência. A grade é regular, então ele quase sempre
   * cai num ponto exato; quando não cai, o corte vai para o ponto seguinte e a
   * borda vertical fica desenhada no valor exato pelo próprio caminho.
   */
  const iRef = $derived(Math.round((referencia / xMax) * (grade - 1)));

  type Ponto = { i: number; d: number };

  const areaAte = $derived((base: number) =>
    area<Ponto>()
      .x((p) => x(p.i))
      .y0(base)
      .y1((p) => base - (p.d / dMax) * alturaCrista)
      .curve(curveBasis),
  );

  const tracoDe = $derived((base: number) =>
    line<Ponto>()
      .x((p) => x(p.i))
      .y((p) => base - (p.d / dMax) * alturaCrista)
      .curve(curveBasis),
  );

  const pontosDe = $derived((c: Crista, de: number, ate: number): Ponto[] =>
    c.densidade.slice(de, ate + 1).map((d, j) => ({ i: de + j, d })),
  );

  /** Marcas do eixo: as unidades inteiras que cabem, mais a referência. */
  const marcas = $derived(
    Array.from({ length: Math.floor(xMax) + 1 }, (_, i) => i).filter((v) => v !== referencia),
  );
</script>

<svg
  bind:this={svgEl}
  viewBox="0 0 {width} {height}"
  {width}
  {height}
  style="width: 100%; height: auto; font-family: {fontFamily};"
  role="img"
  aria-label={title}
>
  {#if background}
    <rect x="0" y="0" {width} {height} rx={10 * k} fill={background} />
  {/if}

  {#each titleLines as linha, i}
    <text
      x={pad}
      y={12 * k + (i + 0.8) * titleLine}
      font-size={type.title}
      font-weight="600"
      fill={cinza.titulo}
      font-family={fontFamily}>{linha}</text
    >
  {/each}
  {#each subtitleLines as linha, i}
    <text
      x={pad}
      y={12 * k + titleLines.length * titleLine + (i + 0.75) * subtitleLine}
      font-size={type.subtitle}
      fill={cinza.subtitulo}
      font-family={fontFamily}>{linha}</text
    >
  {/each}

  <!-- grade vertical, atrás das curvas -->
  {#each marcas as v}
    <line
      x1={xValor(v)}
      y1={topo}
      x2={xValor(v)}
      y2={fimDasCristas}
      stroke={cinza.grade}
      stroke-width={1.2 * k}
    />
  {/each}

  <!-- as cristas -->
  {#each cristas as c, i (c.key)}
    {@const base = baseDe(i)}
    <path d={areaAte(base)(pontosDe(c, 0, iRef)) ?? ''} fill={corAbaixo} />
    <path d={areaAte(base)(pontosDe(c, iRef, grade - 1)) ?? ''} fill={corAcima} />
    <path
      d={tracoDe(base)(pontosDe(c, 0, grade - 1)) ?? ''}
      fill="none"
      stroke={corTraco}
      stroke-width={1.6 * k}
      stroke-linecap="round"
      stroke-linejoin="round"
    />
    <line
      x1={plotLeft}
      y1={base}
      x2={plotRight}
      y2={base}
      stroke={corTraco}
      stroke-width={1 * k}
      opacity="0.35"
    />

    <text
      x={pad}
      y={base - 2 * k}
      font-size={type.rotulo}
      font-weight="600"
      fill={cinza.rotulo}
      font-family={fontFamily}>{c.label}</text
    >
    {#if c.nota}
      <text
        x={pad}
        y={base + type.nota + 1 * k}
        font-size={type.nota}
        fill={cinza.detalhe}
        font-family={fontFamily}>{c.nota}</text
      >
    {/if}
    {#if c.destaque}
      <text
        x={width - pad}
        y={base - 2 * k}
        text-anchor="end"
        font-size={type.dado}
        font-weight="700"
        fill={corAcima}
        font-family={fontFamily}>{c.destaque}</text
      >
    {/if}
  {/each}

  <!-- a linha da meta, por cima de todas as curvas -->
  <line
    x1={xValor(referencia)}
    y1={topo - 4 * k}
    x2={xValor(referencia)}
    y2={fimDasCristas + 4 * k}
    stroke={cinza.ref}
    stroke-width={1.8 * k}
  />

  <!-- eixo -->
  {#each [...marcas, referencia] as v}
    <text
      x={xValor(v)}
      y={eixoY}
      text-anchor="middle"
      font-size={type.eixo}
      font-weight={v === referencia ? 700 : 500}
      fill={v === referencia ? cinza.ref : cinza.detalhe}
      font-family={fontFamily}>{formatX(v)}</text
    >
  {/each}
  <!-- legenda da referência -->
  <line
    x1={pad}
    y1={legendaY - type.legenda * 0.3}
    x2={pad + 12 * k}
    y2={legendaY - type.legenda * 0.3}
    stroke={cinza.ref}
    stroke-width={1.8 * k}
  />
  <text
    x={pad + 18 * k}
    y={legendaY}
    font-size={type.legenda}
    font-weight="500"
    fill={cinza.dado}
    font-family={fontFamily}>{legendaReferencia}</text
  >

  {#each [...footnoteLines, ...sourceLines] as linha, i}
    <text
      x={pad}
      y={notasTop + (i + 0.8) * notaLine}
      font-size={type.notaRodape}
      fill={cinza.nota}
      font-family={fontFamily}>{linha}</text
    >
  {/each}
</svg>
