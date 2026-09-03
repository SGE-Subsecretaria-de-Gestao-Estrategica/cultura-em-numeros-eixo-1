<script lang="ts" module>
  /** Uma categoria com duas parcelas em direções opostas a partir do zero. */
  export type LinhaDivergente = {
    key: string;
    label: string;
    /** Cresce para a direita. */
    positivo: number;
    /** Sua magnitude cresce para a esquerda — entra positiva, não negativa. */
    negativo: number;
  };
</script>

<script lang="ts">
  /**
   * Barras divergentes: uma categoria por linha, duas parcelas correndo em
   * direções opostas a partir de um zero comum — o "cabo de guerra" da
   * publicação de referência.
   *
   * A escala é uma só para as duas direções, e não duas escalas espelhadas: é
   * o que deixa o desequilíbrio entre as parcelas visível em vez de escondido.
   * Quando uma parcela é pequena por definição do fenômeno — não por acaso —,
   * a barra curta *é* o dado, e inflar sua escala mentiria sobre isso.
   *
   * O rótulo de cada barra sai de dentro dela quando cabe e migra para fora
   * quando não cabe — a mesma régua de `labelFitsInBar` usada nas figuras de
   * faixa. A barra estreita da parcela pequena quase sempre escreve por fora.
   */
  import {
    a4Scale,
    fontFamily,
    fontSize as scale,
    labelFitsInBar,
    measureLabel,
    wrapText,
  } from './tokens';

  let {
    linhas,
    corPositivo,
    corNegativo,
    labelPositivo,
    labelNegativo,
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
    linhas: LinhaDivergente[];
    corPositivo: string;
    corNegativo: string;
    labelPositivo: string;
    labelNegativo: string;
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
    zero: '#B9B9B3',
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

  /** A régua de duas cores, entre o subtítulo e o gráfico. */
  const quadrado = 10 * k;
  const legendaY = $derived(headerBottom + 14 * k);
  const larguraLegendaNegativo = $derived(
    measureLabel(labelNegativo, type.legenda, 500) + quadrado + 6 * k,
  );
  const offsetLegendaPositivo = $derived(larguraLegendaNegativo + 24 * k);

  const larguraDestaque = $derived(
    destaque
      ? Math.min(Math.max(118 * k, measureLabel(destaque.valor, type.destaqueValor, 700)), 150 * k)
      : 0,
  );
  const plotRight = $derived(width - pad - (destaque ? larguraDestaque + 16 * k : 0));

  const larguraRotulo = $derived(
    Math.max(...linhas.map((l) => measureLabel(l.label, type.rotulo, 600))),
  );
  const plotLeft = $derived(pad + larguraRotulo + 14 * k);

  const gapLinha = 12 * k;
  const plotTop = $derived(legendaY + 18 * k);
  const plotBottom = $derived(plotTop + linhas.length * alturaBarra * k + (linhas.length - 1) * gapLinha);

  const maxPositivo = $derived(Math.max(...linhas.map((l) => l.positivo), 0));
  const maxNegativo = $derived(Math.max(...linhas.map((l) => l.negativo), 0));
  const maxDom = $derived(maxPositivo * 1.15);

  /**
   * O lado negativo carrega, além da barra, o rótulo que não coube dentro
   * dela — e quando a parcela negativa é pequena por definição do fenômeno,
   * a barra é curta demais para o rótulo do lado de dentro. `minDom` cresce
   * até garantir em pixels a largura do maior rótulo negativo possível, e só
   * então recua para o mínimo que os dados pedem — o excesso é margem em
   * branco, não distorção: a proporção entre as barras negativas entre si não
   * muda, só o espaço vazio ao redor de todas elas.
   */
  const plotWidth = $derived(plotRight - plotLeft);
  const larguraRotuloNegExterno = $derived(
    Math.max(...linhas.map((l) => measureLabel(formatValue(l.negativo), type.valor, 700)), 0) + 16 * k,
  );
  const minDom = $derived.by(() => {
    const porDados = maxNegativo * 1.3;
    // A folga tem de sobrar depois da própria barra do maior negativo, não só
    // do rótulo: por isso `maxNegativo * plotWidth` entra no numerador — é o
    // que a barra come da faixa antes de o rótulo ter onde caber.
    const denom = plotWidth - larguraRotuloNegExterno;
    const porRotulo =
      denom > 0
        ? (larguraRotuloNegExterno * maxDom + maxNegativo * plotWidth) / denom
        : porDados;
    return -Math.max(porDados, porRotulo);
  });

  const x = $derived((v: number) => plotLeft + ((v - minDom) / (maxDom - minDom)) * (plotRight - plotLeft));
  const x0 = $derived(x(0));

  const luminancia = (hex: string) => {
    const canal = (i: number) => {
      const v = parseInt(hex.slice(1 + i * 2, 3 + i * 2), 16) / 255;
      return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4;
    };
    return 0.2126 * canal(0) + 0.7152 * canal(1) + 0.0722 * canal(2);
  };
  const contraste = (a: number, b: number) => (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05);
  const corDoTexto = (fundo: string) => {
    const l = luminancia(fundo);
    return contraste(l, 1) >= contraste(l, luminancia(cinza.titulo)) ? '#FFFFFF' : cinza.titulo;
  };

  const linhasPos = $derived(
    linhas.map((l, i) => {
      const top = plotTop + i * (alturaBarra * k + gapLinha);
      const meio = top + (alturaBarra * k) / 2;
      const xPos = x(l.positivo);
      const xNeg = x(-l.negativo);
      const larguraPos = xPos - x0;
      const larguraNeg = x0 - xNeg;
      const posDentro = labelFitsInBar(formatValue(l.positivo), type.valor, larguraPos, 700);
      const negDentro = labelFitsInBar(formatValue(l.negativo), type.valor, larguraNeg, 700);
      return { ...l, top, meio, xPos, xNeg, larguraPos, larguraNeg, posDentro, negDentro };
    }),
  );

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

  <!-- legenda: um quadrado por direção -->
  <rect x={pad} y={legendaY - quadrado * 0.8} width={quadrado} height={quadrado} rx={2 * k} fill={corNegativo} />
  <text
    x={pad + quadrado + 6 * k}
    y={legendaY}
    font-size={type.legenda}
    font-weight="500"
    fill={cinza.dado}
    font-family={fontFamily}>{labelNegativo}</text
  >
  <rect
    x={pad + offsetLegendaPositivo}
    y={legendaY - quadrado * 0.8}
    width={quadrado}
    height={quadrado}
    rx={2 * k}
    fill={corPositivo}
  />
  <text
    x={pad + offsetLegendaPositivo + quadrado + 6 * k}
    y={legendaY}
    font-size={type.legenda}
    font-weight="500"
    fill={cinza.dado}
    font-family={fontFamily}>{labelPositivo}</text
  >

  <!-- o zero comum às duas direções -->
  <line x1={x0} y1={plotTop} x2={x0} y2={plotBottom} stroke={cinza.zero} stroke-width={1.2 * k} />

  {#each linhasPos as l (l.key)}
    <text
      x={pad + larguraRotulo}
      y={l.meio + type.rotulo * 0.35}
      text-anchor="end"
      font-size={type.rotulo}
      font-weight="600"
      fill={cinza.dado}
      font-family={fontFamily}>{l.label}</text
    >

    <rect x={x0} y={l.top} width={Math.max(l.larguraPos, 0)} height={alturaBarra * k} rx={(alturaBarra * k) / 2} fill={corPositivo} />
    <rect x={l.xNeg} y={l.top} width={Math.max(l.larguraNeg, 0)} height={alturaBarra * k} rx={(alturaBarra * k) / 2} fill={corNegativo} />

    {#if l.posDentro}
      <text
        x={l.xPos - 8 * k}
        y={l.meio + type.valor * 0.35}
        text-anchor="end"
        font-size={type.valor}
        font-weight="700"
        fill={corDoTexto(corPositivo)}
        font-family={fontFamily}>{formatValue(l.positivo)}</text
      >
    {:else}
      <text
        x={l.xPos + 8 * k}
        y={l.meio + type.valor * 0.35}
        text-anchor="start"
        font-size={type.valor}
        font-weight="700"
        fill={cinza.dado}
        font-family={fontFamily}>{formatValue(l.positivo)}</text
      >
    {/if}

    {#if l.negDentro}
      <text
        x={l.xNeg + 8 * k}
        y={l.meio + type.valor * 0.35}
        text-anchor="start"
        font-size={type.valor}
        font-weight="700"
        fill={corDoTexto(corNegativo)}
        font-family={fontFamily}>{formatValue(l.negativo)}</text
      >
    {:else}
      <text
        x={l.xNeg - 8 * k}
        y={l.meio + type.valor * 0.35}
        text-anchor="end"
        font-size={type.valor}
        font-weight="700"
        fill={cinza.dado}
        font-family={fontFamily}>{formatValue(l.negativo)}</text
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
