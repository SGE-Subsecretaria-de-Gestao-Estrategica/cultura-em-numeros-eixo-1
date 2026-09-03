<script lang="ts" module>
  /** Uma categoria nomeada e o valor que decide o comprimento da barra. */
  export type LinhaRanking = {
    key: string;
    label: string;
    valor: number;
    /** Substitui `formatValue(valor)` no rótulo desenhado sobre a barra. */
    rotuloValor?: string;
  };
</script>

<script lang="ts">
  /**
   * Ranking em barras horizontais: uma categoria nomeada por linha, todas
   * partindo do mesmo zero à esquerda — o caso mais simples da família de
   * `BarraDivergenteChart`, sem a segunda direção.
   *
   * As linhas chegam pré-ordenadas por quem chama: um ranking lido de cima
   * para baixo é maior primeiro, e a ordem é dado, não capricho de layout.
   */
  import { a4Scale, fontFamily, fontSize as scale, labelFitsInBar, measureLabel, wrapText } from './tokens';

  let {
    linhas,
    cor,
    title,
    subtitle,
    formatValue = (v: number) => `${v}%`,
    destaque,
    footnote,
    source,
    width = 580,
    alturaBarra = 22,
    svgEl = $bindable(null),
    background = null,
  }: {
    linhas: LinhaRanking[];
    cor: string;
    title: string;
    subtitle?: string;
    formatValue?: (v: number) => string;
    destaque?: { valor: string; cor: string; texto: string };
    footnote?: string;
    source?: string;
    width?: number;
    alturaBarra?: number;
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  // svelte-ignore state_referenced_locally -- a largura autoral é fixada na criação
  const k = a4Scale(width);

  const type = {
    title: 14 * k,
    subtitle: scale.md * k,
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

  const larguraDestaque = $derived(
    destaque
      ? Math.min(Math.max(118 * k, measureLabel(destaque.valor, type.destaqueValor, 700)), 150 * k)
      : 0,
  );
  const plotRight = $derived(width - pad - (destaque ? larguraDestaque + 16 * k : 0));

  /** As categorias podem ser longas — a figura reserva o texto em até duas linhas. */
  const larguraRotuloMax = $derived(0.42 * (width - pad * 2));
  const rotulosQuebrados = $derived(
    linhas.map((l) => wrapText(l.label, type.rotulo, larguraRotuloMax, 600)),
  );
  const larguraRotulo = $derived(
    Math.max(...rotulosQuebrados.flat().map((linha) => measureLabel(linha, type.rotulo, 600))),
  );
  const plotLeft = $derived(pad + larguraRotulo + 14 * k);

  const gapLinha = 10 * k;
  const plotTop = $derived(headerBottom + 20 * k);

  const maxValor = $derived(Math.max(...linhas.map((l) => l.valor), 0));
  const maxDom = $derived(maxValor * 1.25);
  const x = $derived((v: number) => plotLeft + (v / maxDom) * (plotRight - plotLeft));

  const luminancia = (hex: string) => {
    const canal = (i: number) => {
      const v = parseInt(hex.slice(1 + i * 2, 3 + i * 2), 16) / 255;
      return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4;
    };
    return 0.2126 * canal(0) + 0.7152 * canal(1) + 0.0722 * canal(2);
  };
  const contraste = (a: number, b: number) => (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05);
  const corDoTexto = $derived.by(() => {
    const l = luminancia(cor);
    return contraste(l, 1) >= contraste(l, luminancia(cinza.titulo)) ? '#FFFFFF' : cinza.titulo;
  });

  const rotuloAltura = 13 * k;

  const linhasPos = $derived.by(() => {
    let cursor = plotTop;
    return linhas.map((l, i) => {
      const nLinhasRotulo = Math.max(rotulosQuebrados[i].length, 1);
      const alturaLinha = Math.max(alturaBarra * k, nLinhasRotulo * rotuloAltura);
      const top = cursor + (alturaLinha - alturaBarra * k) / 2;
      const meio = top + (alturaBarra * k) / 2;
      const centro = cursor + alturaLinha / 2;
      const xFim = x(l.valor);
      const largura = xFim - plotLeft;
      const texto = l.rotuloValor ?? formatValue(l.valor);
      const dentro = labelFitsInBar(texto, type.valor, largura, 700);
      cursor += alturaLinha + gapLinha;
      return { ...l, top, meio, centro, xFim, largura, texto, dentro, rotuloLinhas: rotulosQuebrados[i] };
    });
  });

  const plotBottom = $derived(linhasPos.length ? linhasPos[linhasPos.length - 1].top + alturaBarra * k : plotTop);

  const notasTop = $derived(plotBottom + 14 * k);
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

  {#each linhasPos as l (l.key)}
    {#each l.rotuloLinhas as linha, i}
      <text
        x={pad + larguraRotulo}
        y={l.centro - (l.rotuloLinhas.length - 1) * rotuloAltura * 0.5 + (i + 0.35) * rotuloAltura}
        text-anchor="end"
        font-size={type.rotulo}
        font-weight="600"
        fill={cinza.dado}
        font-family={fontFamily}>{linha}</text
      >
    {/each}

    <rect x={plotLeft} y={l.top} width={Math.max(l.largura, 0)} height={alturaBarra * k} rx={(alturaBarra * k) / 2} fill={cor} />

    {#if l.dentro}
      <text
        x={l.xFim - 8 * k}
        y={l.meio + type.valor * 0.35}
        text-anchor="end"
        font-size={type.valor}
        font-weight="700"
        fill={corDoTexto}
        font-family={fontFamily}>{l.texto}</text
      >
    {:else}
      <text
        x={l.xFim + 8 * k}
        y={l.meio + type.valor * 0.35}
        text-anchor="start"
        font-size={type.valor}
        font-weight="700"
        fill={cinza.dado}
        font-family={fontFamily}>{l.texto}</text
      >
    {/if}
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
