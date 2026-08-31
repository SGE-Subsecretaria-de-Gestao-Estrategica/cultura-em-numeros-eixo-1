<script lang="ts" module>
  export type ValorUf = {
    uf: string;
    /** Barra da esquerda. Zero desenha só o rótulo — a barra some sozinha. */
    a: number;
    /** Barra da direita. */
    b: number;
  };
</script>

<script lang="ts">
  /**
   * O mapa hexagonal do Brasil do terceiro print: um hexágono por UF, agrupados
   * por região no desenho aproximado do país, com um par de colunas dentro de
   * cada um.
   *
   * A linha preta que atravessa as colunas é a mesma em todos os hexágonos — a
   * média nacional — e o que passa dela é pintado de verde: a figura inteira
   * responde "quem está acima da média, e por quanto" de relance, antes de
   * qualquer número ser lido.
   *
   * A geometria é herdada do print: hexágonos de topo plano numa malha de
   * colunas, cada região um aglomerado contíguo com o contorno externo
   * engrossado, e as regiões afastadas umas das outras para o país respirar.
   */
  import { CONTORNOS, LARGURA_PRINT, REGIOES, caminhoHex, centro } from './mapaUf';
  import { a4Scale, fontFamily, colors as marca, fontSize as scale, measureLabel, wrapText } from './tokens';

  let {
    valores,
    referencia,
    title,
    subtitle,
    corA = marca.secondary,
    corB = marca.primary,
    corExcedente = marca.accent,
    formatPct = (v: number) => `${Math.round(v)}%`,
    legendas,
    footnote,
    source,
    width = 580,
    svgEl = $bindable(null),
    background = null,
  }: {
    valores: ValorUf[];
    /** O valor da linha preta — a média nacional. */
    referencia: number;
    title: string;
    subtitle?: string;
    corA?: string;
    corB?: string;
    corExcedente?: string;
    formatPct?: (v: number) => string;
    /** As quatro entradas da legenda, na ordem: excedente, referência, A, B. */
    legendas: { excedente: string; referencia: string; a: string; b: string };
    footnote?: string;
    source?: string;
    width?: number;
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  // svelte-ignore state_referenced_locally -- a largura autoral é fixada na criação
  const k = a4Scale(width);

  /**
   * O mapa é desenhado no domínio de pixels do print e escalado para a largura
   * autoral — as medidas da malha são as do print, e vivem em `mapaUf.ts`
   * porque a figura territorial de contagem usa a mesma geografia.
   */
  const km = $derived(width / LARGURA_PRINT);

  const contornos = CONTORNOS;

  const porUf = $derived(new Map(valores.map((v) => [v.uf, v])));

  /**
   * Escala das colunas: o maior valor dentro da escala enche `TETO_PX`. Um
   * valor fora dela — o DF — é cortado um pouco acima do teto, alto o bastante
   * para se ler como "fora da escala" e baixo o bastante para não engolir o
   * rótulo da UF.
   */
  const TETO_PX = 78;
  const vTeto = $derived(Math.max(...valores.flatMap((v) => [v.a, v.b]).filter((x) => x <= 50)));
  const pxPorUnidade = $derived(TETO_PX / vTeto);
  const altura = $derived((v: number) => Math.min(v * pxPorUnidade, TETO_PX + 10));

  const BARRA_W = 30;
  const BARRA_GAP = 7;
  const BARRA_BASE = 42;
  const refY = $derived(-referencia * pxPorUnidade + BARRA_BASE);

  const type = {
    title: 14 * k,
    subtitle: scale.md * k,
    nota: scale.sm * k,
  };

  const cinza = {
    titulo: '#2F2F2B',
    subtitulo: '#6E6E68',
    uf: '#33332F',
    valor: '#6A6A64',
    regiao: '#3F3F3B',
    borda: '#E2E2DE',
    contorno: '#ABABA4',
    ref: '#262622',
    nota: '#8A8A84',
  };

  const pad = 16 * k;
  const textWidth = $derived(width - pad * 2);
  const titleLines = $derived(wrapText(title, type.title, textWidth, 600));
  const subtitleLines = $derived(wrapText(subtitle ?? '', type.subtitle, textWidth));
  const footnoteLines = $derived(wrapText(footnote ?? '', type.nota, textWidth));
  const sourceLines = $derived(wrapText(source ?? '', type.nota, textWidth));

  const titleLine = 19 * k;
  const subtitleLine = 15 * k;
  const notaLine = 13.5 * k;

  const mapaTop = $derived(
    12 * k + titleLines.length * titleLine + subtitleLines.length * subtitleLine + 8 * k,
  );
  /** Altura do domínio do print realmente usada pelo mapa. */
  const MAPA_ALTURA_PX = 1105;
  const notasTop = $derived(mapaTop + MAPA_ALTURA_PX * km + 6 * k);
  const height = $derived(
    notasTop + (footnoteLines.length + sourceLines.length) * notaLine + pad,
  );

  /** Legenda: um hexágono de amostra e as quatro leituras ao lado. */
  const LEGENDA = { x: 95, y: 640, hex: [180, 855] as [number, number], textoX: 300 };
  const legendaItens = $derived([
    { cor: corExcedente, texto: legendas.excedente },
    { cor: cinza.ref, texto: legendas.referencia, linha: true },
    { cor: corA, texto: legendas.a },
    { cor: corB, texto: legendas.b },
  ]);
  const LEGENDA_TEXTO = 17.5;
  const legendaLinhas = $derived(
    legendaItens.map((item) => wrapText(item.texto, LEGENDA_TEXTO, 240, 500)),
  );
</script>

{#snippet colunas(cx: number, cy: number, a: number, b: number, rotular = true)}
  {@const base = cy + BARRA_BASE}
  {@const ref = cy + refY}
  <!-- rótulos largos — o "100%" do DF — são afastados para não se tocarem -->
  {@const meioVao = BARRA_GAP / 2 + BARRA_W / 2}
  {@const larguras = [a, b].map((v) => measureLabel(formatPct(v), 17, 500))}
  {@const afastamento = Math.max(0, (larguras[0] + larguras[1]) / 2 + 6 - meioVao * 2) / 2}
  {#each [
    { v: a, cor: corA, x: cx - BARRA_GAP / 2 - BARRA_W, desloca: -afastamento },
    { v: b, cor: corB, x: cx + BARRA_GAP / 2, desloca: afastamento },
  ] as barra}
    {@const topo = base - altura(barra.v)}
    {#if barra.v > 0}
      <rect x={barra.x} y={Math.max(topo, ref)} width={BARRA_W} height={base - Math.max(topo, ref)} fill={barra.cor} />
      {#if topo < ref}
        <rect x={barra.x} y={topo} width={BARRA_W} height={ref - topo} fill={corExcedente} />
      {/if}
    {/if}
    {#if rotular}
      <text
        x={barra.x + BARRA_W / 2 + barra.desloca}
        y={base + 22}
        text-anchor="middle"
        font-size="17"
        font-weight="500"
        fill={cinza.valor}
        font-family={fontFamily}>{formatPct(barra.v)}</text
      >
    {/if}
  {/each}
  <line x1={cx - 52} y1={ref} x2={cx + 52} y2={ref} stroke={cinza.ref} stroke-width="3" />
{/snippet}

<svg
  bind:this={svgEl}
  viewBox="0 0 {width} {height}"
  {width}
  height={height}
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

  <g transform="translate(0 {mapaTop}) scale({km})">
    <!-- hexágonos -->
    {#each Object.entries(REGIOES) as [regiao, { celulas }]}
      {#each Object.keys(celulas) as uf}
        {@const [cx, cy] = centro(regiao, uf)}
        <path d={caminhoHex(cx, cy)} fill="#FFFFFF" stroke={cinza.borda} stroke-width="1.5" />
      {/each}
    {/each}

    <!-- contorno externo de cada região -->
    {#each contornos as { arestas }}
      {#each arestas as [x1, y1, x2, y2]}
        <line {x1} {y1} {x2} {y2} stroke={cinza.contorno} stroke-width="4" stroke-linecap="round" />
      {/each}
    {/each}

    <!-- rótulos de região -->
    {#each Object.entries(REGIOES) as [regiao, { rotulo }]}
      <text
        x={rotulo[0]}
        y={rotulo[1]}
        text-anchor="middle"
        font-size="21"
        font-weight="700"
        fill={cinza.regiao}
        font-family={fontFamily}>{regiao}</text
      >
    {/each}

    <!-- as colunas de cada UF -->
    {#each Object.entries(REGIOES) as [regiao, { celulas }]}
      {#each Object.keys(celulas) as uf}
        {@const [cx, cy] = centro(regiao, uf)}
        {@const v = porUf.get(uf)}
        {#if v}
          <text
            x={cx}
            y={cy - 50}
            text-anchor="middle"
            font-size="20"
            font-weight="600"
            fill={cinza.uf}
            font-family={fontFamily}>{uf}</text
          >
          {@render colunas(cx, cy, v.a, v.b)}
        {/if}
      {/each}
    {/each}

    <!-- legenda: título, hexágono de amostra, as quatro leituras -->
    <text
      x={LEGENDA.x}
      y={LEGENDA.y}
      font-size="24"
      font-weight="600"
      fill={cinza.titulo}
      font-family={fontFamily}>Legenda</text
    >
    <path
      d={caminhoHex(...LEGENDA.hex)}
      fill="#FFFFFF"
      stroke={cinza.contorno}
      stroke-width="2.5"
    />
    <text
      x={LEGENDA.hex[0]}
      y={LEGENDA.hex[1] - 50}
      text-anchor="middle"
      font-size="20"
      font-weight="600"
      fill={cinza.uf}
      font-family={fontFamily}>UF</text
    >
    <!-- uma abaixo da linha e outra acima: é o contraste que a legenda explica -->
    {@render colunas(LEGENDA.hex[0], LEGENDA.hex[1], referencia * 0.62, referencia * 1.45, false)}

    {#each legendaLinhas as linhas, i}
      {@const itemY = LEGENDA.y + 55 + legendaLinhas.slice(0, i).reduce((soma, l) => soma + l.length * 22 + 16, 0)}
      {@const item = legendaItens[i]}
      {#if item.linha}
        <line
          x1={LEGENDA.textoX - 26}
          y1={itemY + 8}
          x2={LEGENDA.textoX - 8}
          y2={itemY + 8}
          stroke={item.cor}
          stroke-width="3"
        />
      {:else}
        <rect x={LEGENDA.textoX - 26} y={itemY} width="16" height="16" fill={item.cor} />
      {/if}
      {#each linhas as linha, j}
        <text
          x={LEGENDA.textoX}
          y={itemY + 13 + j * 22}
          font-size={LEGENDA_TEXTO}
          font-weight="500"
          fill={cinza.regiao}
          font-family={fontFamily}>{linha}</text
        >
      {/each}
    {/each}
  </g>

  {#each [...footnoteLines, ...sourceLines] as linha, i}
    <text
      x={pad}
      y={notasTop + (i + 0.8) * notaLine}
      font-size={type.nota}
      fill={cinza.nota}
      font-family={fontFamily}>{linha}</text
    >
  {/each}
</svg>
