<script lang="ts" module>
  /**
   * Um degrau da cascata.
   *
   * `base` e `total` pousam no chão e medem um estoque; `delta` flutua entre o
   * acumulado que encontrou e o que deixa, e mede uma variação. É a diferença
   * que faz a figura ser uma ponte entre dois estoques em vez de uma barra
   * empilhada deitada.
   */
  export type Bloco = {
    key: string;
    label: string;
    valor: number;
    tipo: 'base' | 'delta' | 'total';
    cor: string;
    /** Linhas miúdas sob o rótulo — a abertura de um bloco agregado. */
    detalhe?: string[];
  };

  /** Bloco de leitura na ponta direita: o valor grande colorido e a frase. */
  export type Destaque = { valor: string; cor: string; texto: string };
</script>

<script lang="ts">
  /**
   * Cascata: dois estoques e as parcelas que levam de um ao outro.
   *
   * Cada degrau é uma faixa grossa de ponta redonda — a mesma marca da
   * `FaixaLinhasChart`, girada de lado. Não há eixo Y: como nas demais figuras
   * da publicação, o valor de cada degrau está escrito sobre ele, e uma escala
   * vertical repetiria o que o rótulo já diz.
   *
   * O degrau é um `rect` com raio, e não um traço de ponta redonda como nas
   * figuras de linha, justamente porque aqui o comprimento é o dado. A tampa
   * redonda de um `stroke` transborda meia espessura de cada lado, então o
   * bloco desenhado mediria sempre uma espessura a mais do que vale — o
   * suficiente para o degrau pequeno parecer o dobro do que é, e para os
   * conectores não encostarem em nada. O `rect` ocupa exatamente o intervalo,
   * e o raio cede quando a altura é menor que a espessura.
   *
   * O conector entre dois degraus é horizontal porque os dois estão na mesma
   * altura — um `delta` começa exatamente onde o anterior parou. Não há
   * cotovelo a desenhar, então não há curva a fazer: a regra de "conector é
   * Bézier, nunca cotovelo" existe para não haver ângulo reto dentro de um
   * dado, e aqui não há ângulo nenhum.
   *
   * Um `delta` pequeno demais para caber na escala continua pequeno: a figura
   * não tem largura mínima de bloco. Um degrau que quase não aparece é o dado
   * dizendo que ele quase não pesou, e inflá-lo para ficar visível seria mentir
   * exatamente sobre o que a figura mede. Quando a parcela é pequena mas
   * precisa ser nomeada, ela entra agregada, com a abertura em `detalhe`.
   */
  import { a4Scale, fontFamily, fontSize as scale, measureLabel, wrapText } from './tokens';

  let {
    blocos,
    title,
    subtitle,
    formatValue = (v: number) => String(v),
    formatDelta,
    destaque,
    footnote,
    source,
    width = 580,
    plotHeight = 250,
    svgEl = $bindable(null),
    background = null,
  }: {
    blocos: Bloco[];
    title: string;
    subtitle?: string;
    formatValue?: (valor: number) => string;
    /** Formato dos `delta`, que levam sinal; por omissão, `formatValue`. */
    formatDelta?: (valor: number) => string;
    destaque?: Destaque;
    footnote?: string;
    source?: string;
    width?: number;
    plotHeight?: number;
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  // svelte-ignore state_referenced_locally -- a largura autoral é fixada na criação
  const k = a4Scale(width);

  const type = {
    title: 14 * k,
    subtitle: scale.md * k,
    dado: scale.sm * k,
    rotulo: 11 * k,
    detalhe: scale.xs * k,
    destaqueValor: 19 * k,
    destaqueTexto: scale.md * k,
    nota: scale.sm * k,
  };

  const cinza = {
    titulo: '#2F2F2B',
    subtitulo: '#6E6E68',
    dado: '#3F3F3B',
    rotulo: '#33332F',
    detalhe: '#8A8A84',
    conector: '#D8D8D3',
    nota: '#8A8A84',
  };

  const pad = 16 * k;

  const fmtDelta = $derived(formatDelta ?? formatValue);

  /** Cada degrau com o intervalo que ocupa na escala vertical. */
  const degraus = $derived.by(() => {
    let acumulado = 0;
    return blocos.map((b) => {
      if (b.tipo === 'delta') {
        const inicio = acumulado;
        acumulado += b.valor;
        return { ...b, inicio, fim: acumulado };
      }
      acumulado = b.valor;
      return { ...b, inicio: 0, fim: b.valor };
    });
  });

  const textWidth = $derived(width - pad * 2);
  const titleLines = $derived(wrapText(title, type.title, textWidth, 600));
  const subtitleLines = $derived(wrapText(subtitle ?? '', type.subtitle, textWidth));
  const footnoteLines = $derived(wrapText(footnote ?? '', type.nota, textWidth));
  const sourceLines = $derived(wrapText(source ?? '', type.nota, textWidth));

  const titleLine = 19 * k;
  const subtitleLine = 15 * k;
  const notaLine = 13.5 * k;

  /** Largura do bloco de ponta, medida no conteúdo e com teto. */
  const larguraDestaque = $derived(
    destaque
      ? Math.min(Math.max(118 * k, measureLabel(destaque.valor, type.destaqueValor, 700)), 150 * k)
      : 0,
  );

  const plotTop = $derived(
    12 * k + titleLines.length * titleLine + subtitleLines.length * subtitleLine + 20 * k,
  );
  const plotH = $derived(plotHeight * k);
  const plotBottom = $derived(plotTop + plotH);

  const plotLeft = pad;
  const plotRight = $derived(width - pad - (destaque ? larguraDestaque + 16 * k : 0));

  /** Faixa no topo do plot onde só rótulos de valor entram. */
  const headroom = 22 * k;

  const banda = $derived((plotRight - plotLeft) / degraus.length);
  const espessura = $derived(Math.min(banda * 0.5, 34 * k));
  const cx = $derived((i: number) => plotLeft + banda * (i + 0.5));

  const vMax = $derived(Math.max(...degraus.flatMap((d) => [d.inicio, d.fim])));
  const y = $derived((v: number) => plotBottom - (v / vMax) * (plotH - headroom));

  /** Rótulos sob o eixo, quebrados na largura da banda. */
  const rotulos = $derived(
    degraus.map((d) => wrapText(d.label, type.rotulo, banda - 6 * k, 600)),
  );
  const linhasDeRotulo = $derived(Math.max(...rotulos.map((r) => r.length)));
  const linhasDeDetalhe = $derived(Math.max(0, ...degraus.map((d) => d.detalhe?.length ?? 0)));

  const rotuloLine = 13 * k;
  const detalheLine = 11 * k;

  const rotulosTop = $derived(plotBottom + 14 * k);
  const detalheTop = $derived(rotulosTop + linhasDeRotulo * rotuloLine + 3 * k);
  const notasTop = $derived(
    detalheTop +
      linhasDeDetalhe * detalheLine +
      (footnoteLines.length + sourceLines.length ? 16 * k : 0),
  );
  const height = $derived(notasTop + (footnoteLines.length + sourceLines.length) * notaLine + pad);

  const destaqueLinhas = $derived(
    destaque ? wrapText(destaque.texto, type.destaqueTexto, larguraDestaque, 500) : [],
  );
  const destaqueX = $derived(plotRight + 16 * k);
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

  <!-- título -->
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

  <!-- conectores, atrás dos degraus: cada delta começa onde o anterior parou -->
  {#each degraus.slice(0, -1) as d, i}
    <line
      x1={cx(i)}
      y1={y(d.fim)}
      x2={cx(i + 1)}
      y2={y(d.fim)}
      stroke={cinza.conector}
      stroke-width={1.4 * k}
      stroke-linecap="round"
      stroke-dasharray="{4 * k} {4 * k}"
    />
  {/each}

  <!-- degraus -->
  {#each degraus as d, i (d.key)}
    {@const topo = Math.min(y(d.inicio), y(d.fim))}
    {@const altura = Math.abs(y(d.fim) - y(d.inicio))}
    <rect
      x={cx(i) - espessura / 2}
      y={topo}
      width={espessura}
      height={altura}
      rx={Math.min(espessura / 2, altura / 2)}
      fill={d.cor}
    />
    <text
      x={cx(i)}
      y={topo - 6 * k}
      text-anchor="middle"
      font-size={type.dado}
      font-weight={d.tipo === 'delta' ? 600 : 700}
      fill={cinza.dado}
      font-family={fontFamily}>{d.tipo === 'delta' ? fmtDelta(d.valor) : formatValue(d.valor)}</text
    >
  {/each}

  <!-- rótulos e a abertura miúda de cada degrau -->
  {#each degraus as d, i (d.key)}
    {#each rotulos[i] as linha, j}
      <text
        x={cx(i)}
        y={rotulosTop + (j + 0.8) * rotuloLine}
        text-anchor="middle"
        font-size={type.rotulo}
        font-weight="600"
        fill={cinza.rotulo}
        font-family={fontFamily}>{linha}</text
      >
    {/each}
    {#each d.detalhe ?? [] as linha, j}
      <text
        x={cx(i)}
        y={detalheTop + (j + 0.8) * detalheLine}
        text-anchor="middle"
        font-size={type.detalhe}
        fill={cinza.detalhe}
        font-family={fontFamily}>{linha}</text
      >
    {/each}
  {/each}

  <!-- bloco de ponta -->
  {#if destaque}
    <text
      x={destaqueX}
      y={plotTop + type.destaqueValor}
      font-size={type.destaqueValor}
      font-weight="700"
      fill={destaque.cor}
      font-family={fontFamily}>{destaque.valor}</text
    >
    {#each destaqueLinhas as linha, i}
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

  <!-- notas -->
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
