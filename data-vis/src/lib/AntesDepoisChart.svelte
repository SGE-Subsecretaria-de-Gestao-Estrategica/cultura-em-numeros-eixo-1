<script lang="ts" module>
  /** Uma categoria e os dois valores que a comparação liga. */
  export type LinhaAntesDepois = {
    key: string;
    label: string;
    antes: number;
    depois: number;
  };
</script>

<script lang="ts">
  /**
   * Antes e depois: dois pontos por categoria, ligados por um traço grosso de
   * ponta redonda — a mesma peça da `CascataChart`, só curta e deitada, uma
   * por linha.
   *
   * É a forma certa para a categoria que não é ordenada e não é uma série
   * longa: uma coluna 100% empilhada existe para mostrar composição ao longo
   * de várias ondas, e com duas ondas ela só repete o mesmo par de números
   * duas vezes. Aqui o traço mede a distância entre os dois pontos direto — um
   * traço quase invisível é a categoria dizendo que não mudou, sem que o
   * leitor precise subtrair.
   *
   * Quando os dois pontos praticamente coincidem, os rótulos ainda se separam:
   * o de antes sempre puxa para a esquerda do próprio ponto, o de depois para
   * a direita — não colidem mesmo com distância zero entre os pontos.
   */
  import { a4Scale, fontFamily, fontSize as scale, measureLabel, wrapText } from './tokens';

  let {
    linhas,
    corAntes,
    corDepois,
    labelAntes,
    labelDepois,
    title,
    subtitle,
    formatValue = (v: number) => `${v}%`,
    destaque,
    footnote,
    source,
    width = 580,
    raio = 6,
    svgEl = $bindable(null),
    background = null,
  }: {
    linhas: LinhaAntesDepois[];
    corAntes: string;
    corDepois: string;
    labelAntes: string;
    labelDepois: string;
    title: string;
    subtitle?: string;
    formatValue?: (v: number) => string;
    destaque?: { valor: string; cor: string; texto: string };
    footnote?: string;
    source?: string;
    width?: number;
    raio?: number;
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  // svelte-ignore state_referenced_locally -- a largura autoral é fixada na criação
  const k = a4Scale(width);

  const type = {
    title: 14 * k,
    subtitle: scale.md * k,
    legenda: scale.sm * k,
    rotulo: scale.md * k,
    valor: scale.sm * k,
    destaqueValor: 19 * k,
    destaqueTexto: scale.md * k,
    nota: scale.sm * k,
  };

  const cinza = {
    titulo: '#2F2F2B',
    subtitulo: '#6E6E68',
    dado: '#2F2F2B',
    traco: '#C9C9C2',
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

  const headerBottom = $derived(
    12 * k + titleLines.length * titleLine + subtitleLines.length * subtitleLine,
  );

  const quadrado = 10 * k;
  const legendaY = $derived(headerBottom + 14 * k);
  const larguraLegendaAntes = $derived(measureLabel(labelAntes, type.legenda, 500) + quadrado + 6 * k);
  const offsetLegendaDepois = $derived(larguraLegendaAntes + 24 * k);

  const larguraDestaque = $derived(
    destaque
      ? Math.min(Math.max(118 * k, measureLabel(destaque.valor, type.destaqueValor, 700)), 150 * k)
      : 0,
  );
  const plotRight = $derived(width - pad - (destaque ? larguraDestaque + 16 * k : 0));

  const larguraRotulo = $derived(
    Math.max(...linhas.map((l) => measureLabel(l.label, type.rotulo, 600))),
  );
  const plotLeft = $derived(pad + larguraRotulo + 34 * k);

  const gapLinha = 16 * k;
  const plotTop = $derived(legendaY + 20 * k);

  const maxValor = $derived(Math.max(...linhas.flatMap((l) => [l.antes, l.depois]), 0));
  const maxDom = $derived(maxValor * 1.15 || 1);
  const x = $derived((v: number) => plotLeft + (v / maxDom) * (plotRight - plotLeft));

  const alturaLinha = 20 * k;
  const linhasPos = $derived(
    linhas.map((l, i) => {
      const y = plotTop + i * (alturaLinha + gapLinha);
      return { ...l, y, xAntes: x(l.antes), xDepois: x(l.depois) };
    }),
  );

  const plotBottom = $derived(
    linhasPos.length ? linhasPos[linhasPos.length - 1].y : plotTop,
  );

  const notasTop = $derived(plotBottom + 22 * k);
  const height = $derived(notasTop + (footnoteLines.length + sourceLines.length) * notaLine + pad);
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

  <circle cx={pad + quadrado / 2} cy={legendaY - quadrado * 0.3} r={quadrado / 2} fill={corAntes} />
  <text
    x={pad + quadrado + 6 * k}
    y={legendaY}
    font-size={type.legenda}
    font-weight="500"
    fill={cinza.dado}
    font-family={fontFamily}>{labelAntes}</text
  >
  <circle cx={pad + offsetLegendaDepois + quadrado / 2} cy={legendaY - quadrado * 0.3} r={quadrado / 2} fill={corDepois} />
  <text
    x={pad + offsetLegendaDepois + quadrado + 6 * k}
    y={legendaY}
    font-size={type.legenda}
    font-weight="500"
    fill={cinza.dado}
    font-family={fontFamily}>{labelDepois}</text
  >

  {#each linhasPos as l (l.key)}
    <text
      x={pad + larguraRotulo}
      y={l.y + type.rotulo * 0.35}
      text-anchor="end"
      font-size={type.rotulo}
      font-weight="600"
      fill={cinza.dado}
      font-family={fontFamily}>{l.label}</text
    >

    <line x1={l.xAntes} y1={l.y} x2={l.xDepois} y2={l.y} stroke={cinza.traco} stroke-width={5 * k} stroke-linecap="round" />

    <circle cx={l.xAntes} cy={l.y} r={raio * k} fill={corAntes} />
    <circle cx={l.xDepois} cy={l.y} r={raio * k} fill={corDepois} />

    <text
      x={l.xAntes - (raio + 6) * k}
      y={l.y - (raio + 5) * k}
      text-anchor="end"
      font-size={type.valor}
      font-weight="700"
      fill={corAntes}
      font-family={fontFamily}>{formatValue(l.antes)}</text
    >
    <text
      x={l.xDepois + (raio + 6) * k}
      y={l.y - (raio + 5) * k}
      text-anchor="start"
      font-size={type.valor}
      font-weight="700"
      fill={corDepois}
      font-family={fontFamily}>{formatValue(l.depois)}</text
    >
  {/each}

  {#if destaque}
    {@const destaqueX = plotRight + 16 * k}
    <text
      x={destaqueX}
      y={plotTop + type.destaqueValor}
      font-size={type.destaqueValor}
      font-weight="700"
      fill={destaque.cor}
      font-family={fontFamily}>{destaque.valor}</text
    >
    {#each wrapText(destaque.texto, type.destaqueTexto, larguraDestaque, 500) as linha, i}
      <text
        x={destaqueX}
        y={plotTop + 21 * k + (i + 0.85) * 14.5 * k}
        font-size={type.destaqueTexto}
        font-weight="500"
        fill={cinza.dado}
        font-family={fontFamily}>{linha}</text
      >
    {/each}
  {/if}

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
