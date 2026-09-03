<script lang="ts" module>
  /** Um ano: o rótulo do eixo e o valor de cada categoria naquele ano. */
  export type AnoRow = { label: string } & Record<string, number | string>;

  /**
   * Um trecho sem série, marcado com um colchete acima do plot — para o caso
   * em que zero não significa "não houve", significa "não foi medido", e uma
   * coluna cheia da fatia vizinha contaria a história errada sem a ressalva.
   */
  export type Span = { de: number; ate: number; texto: string };
</script>

<script lang="ts">
  /**
   * Composição: a mesma pergunta do histomap — de onde veio cada real, ano a
   * ano — respondida em colunas fechando em 100% em vez de faixas contínuas.
   *
   * As duas figuras leem a mesma tabela e divergem de propósito. O histomap
   * suaviza a transição entre os anos porque o fluxo é o assunto, e isso tem
   * um preço: um patamar interpolado não é uma medida, e escrever "44%" sobre
   * uma curva que nunca esteve naquela largura seria enganoso. Aqui, ao
   * contrário, a fatia muda em degrau na virada do ano, fiel à medida anual —
   * e é por isso que só esta figura escreve o percentual dentro do segmento.
   * As duas juntas são o par completo: uma mostra a forma, a outra o número.
   *
   * O topo de cada coluna é arredondado, como uma pastilha; a base não — ela
   * repousa sobre o eixo, como uma coluna comum. Numa fatia baixa o raio já
   * cobre a própria altura, e o topo da coluna acaba em cúpula — é o mesmo
   * efeito das barras mais curtas de uma figura de podium, e não um caso
   * especial: a fórmula é uma só, `min(raio, largura/2, altura)`.
   *
   * O que sustenta o número dentro do segmento é a largura da coluna, e uma
   * série de 20 anos e mais no espaço de um cartão de A4 retrato não sobra
   * muita largura por coluna — foi essa conta que tirou o percentual do
   * histomap. Aqui a geometria decide caso a caso: `columnRatio` encolhe o
   * vão entre colunas para lhes devolver largura, mas numa série densa a
   * fatia mais fina de cada ano continua sem o próprio número, e é a cor
   * mais a legenda que a identificam — ver `ComposicaoFederalChart` para as
   * duas densidades, sete anos-marco ou os 23 anos corridos.
   *
   * Desenhada em SVG puro e na paleta de `tokens`, como as demais figuras da
   * coleção — ver `HistomapChart` para o par em faixas contínuas.
   */
  import { a4Scale, fontFamily, fontSize as scale, labelFitsInBar, measureLabel, wrapText } from './tokens';
  import { layoutLegend } from './legend';

  /** Os mesmos cinzas das demais figuras da coleção. */
  const cinza = {
    titulo: '#2F2F2B',
    subtitulo: '#6E6E68',
    eixo: '#33332F',
    regua: '#C9C9C2',
    nota: '#8A8A84',
    borda: '#E8E8E4',
  };

  interface Props {
    data: AnoRow[];
    /** Categorias na ordem em que empilham, de baixo para cima. */
    keys: string[];
    labels?: Record<string, string>;
    /** Cores na ordem de `keys`. */
    colors: readonly string[];
    title: string;
    subtitle?: string;
    footnote?: string;
    source?: string;
    /** A faixa de pastilhas sob o subtítulo, na ordem de empilhamento. */
    legenda?: boolean;
    /** Anos rotulados sob o eixo. Por omissão, todos os anos de `data`. */
    tickYears?: number[];
    /** Trechos sem série, marcados com um colchete acima do plot. */
    spans?: Span[];
    /** Fração do intervalo anual ocupada pela coluna; o resto é o vão entre colunas. */
    columnRatio?: number;
    /**
     * Raio do topo da coluna, antes da escala de impressão. O padrão é
     * generoso porque a figura pensa em poucas colunas largas, não em uma
     * série densa — numa fatia mais baixa do que o raio, o topo vira cúpula.
     */
    radius?: number;
    /** Altura do plot, antes da escala de impressão. */
    plotHeight?: number;
    /**
     * Largura intrínseca, em unidades de SVG — ver `HistomapChart` para a
     * mesma decisão de dimensionamento.
     */
    width?: number;
    /** Sobrepõe a altura que o cartão calcula para si. */
    height?: number;
    /** `null` remove o cartão (fundo e borda), para exportar sobre a página. */
    background?: string | null;
    /** Bindable — o `<svg>` renderizado, para `downloadSvg`. */
    svgEl?: SVGSVGElement | null;
  }

  let {
    data,
    keys,
    labels = {},
    colors,
    title,
    subtitle,
    footnote,
    source,
    legenda = true,
    tickYears,
    spans = [],
    columnRatio = 0.62,
    radius = 10,
    plotHeight = 200,
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

  const L = $derived({
    pad: 16 * k,
    raioCartao: 10 * k,
    titleLine: 19 * k,
    subtitleLine: 15 * k,
    notaLine: 13.5 * k,
    legendaGap: 13 * k,
    legendaPlotGap: 16 * k,
    noteGap: 20 * k,
    noteSpacing: 3 * k,
    tickGap: 6 * k,
    axisLabelLine: 13 * k,
    plotHeight: plotHeight * k,
    radius: radius * k,
    /** Do colchete de cobertura ao seu traço, e dele ao topo do plot. */
    spanGap: 10 * k,
    spanTick: 4 * k,
    spanTextGap: 3 * k,
  });

  const cor = (index: number) => colors[index % colors.length];

  /** Branco ou o ink escuro — o que render mais contraste sobre o segmento. */
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

  const textWidth = $derived(width - L.pad * 2);
  const titleLines = $derived(wrapText(title, type.title, textWidth, 600));
  const subtitleLines = $derived(wrapText(subtitle ?? '', type.subtitle, textWidth));
  const footnoteLines = $derived(wrapText(footnote ?? '', type.sm, textWidth));
  const sourceLines = $derived(wrapText(source ?? '', type.sm, textWidth));

  /** A mesma faixa de pastilhas do histomap, na ordem de empilhamento. */
  const legendaLayout = $derived(
    legenda
      ? layoutLegend(
          keys.map((key, i) => ({ label: labels[key] ?? key, color: cor(i) })),
          { fontSize: type.sm, fontWeight: 600, padX: 8 * k, maxWidth: textWidth, rowGap: 4 * k },
        )
      : null,
  );

  const anos = $derived(data.map((d) => Number(d.label)));
  const valor = (row: AnoRow, key: string) => Number(row[key]) || 0;
  const totais = $derived(data.map((row) => keys.reduce((soma, key) => soma + valor(row, key), 0)));

  type Segmento = { keyIndex: number; bottom: number; top: number; share: number };

  /** As fronteiras acumuladas de um ano, de baixo para cima, em pontos percentuais. */
  const colunas = $derived(
    data.map((row, i) => {
      const total = totais[i] || 1;
      let cursor = 0;
      return keys.map((key, keyIndex): Segmento => {
        const share = (valor(row, key) / total) * 100;
        const seg = { keyIndex, bottom: cursor, top: cursor + share, share };
        cursor += share;
        return seg;
      });
    }),
  );

  /** O último segmento não nulo de cada coluna — o único que recebe o topo arredondado. */
  const topoDaColuna = $derived(
    colunas.map((segmentos) =>
      segmentos.reduce((acc, s, i) => (s.share > 1e-9 ? i : acc), -1),
    ),
  );

  // --- a moldura -----------------------------------------------------------

  const cabecalho = $derived(
    12 * k + titleLines.length * L.titleLine + subtitleLines.length * L.subtitleLine,
  );
  const legendaY = $derived(cabecalho + L.legendaGap);

  /** Espaço reservado ao colchete de cobertura, acima do plot. */
  const spanReserve = $derived(
    spans.length ? type.xs * 1.2 + L.spanTextGap + L.spanTick + L.spanGap : 0,
  );
  const plotTop = $derived(
    (legendaLayout ? legendaY + legendaLayout.height + L.legendaPlotGap : cabecalho + 12 * k) +
      spanReserve,
  );
  const plotBottom = $derived(plotTop + L.plotHeight);

  const axisLabelWidth = $derived(measureLabel('100%', type.sm, 500));
  const plotLeft = $derived(L.pad + axisLabelWidth + L.tickGap);
  const plotRight = $derived(width - L.pad);

  const slot = $derived(anos.length ? (plotRight - plotLeft) / anos.length : 0);
  const colW = $derived(slot * columnRatio);
  const xCentro = (i: number) => plotLeft + slot * (i + 0.5);
  const yDe = (share: number) => plotBottom - (share / 100) * L.plotHeight;

  const ticksVisiveis = $derived(new Set(tickYears ?? anos));

  const footTop = $derived(plotBottom + L.tickGap + L.axisLabelLine + L.noteGap);
  const sourceTop = $derived(
    footTop + footnoteLines.length * L.notaLine + (footnoteLines.length ? L.noteSpacing : 0),
  );
  const altura = $derived(height ?? sourceTop + sourceLines.length * L.notaLine + L.pad);

  /**
   * Um segmento de coluna: reto na base, arredondado só onde a pilha termina.
   * O raio nunca passa de metade da largura nem da própria altura, então uma
   * fatia mais baixa do que o raio pedido acaba em cúpula, não em retângulo
   * com cantos cortados.
   */
  function segmentoPath(x: number, y: number, w: number, h: number, radius: number) {
    const r = Math.max(0, Math.min(radius, w / 2, h));
    if (!r) return `M${x},${y} H${x + w} V${y + h} H${x} Z`;
    return [
      `M${x},${y + r}`,
      `A${r},${r} 0 0 1 ${x + r},${y}`,
      `H${x + w - r}`,
      `A${r},${r} 0 0 1 ${x + w},${y + r}`,
      `V${y + h}`,
      `H${x}`,
      'Z',
    ].join(' ');
  }

  /**
   * A participação escrita dentro do segmento — inteira, sem casa decimal — só
   * quando o corpo cabe nas duas dimensões: a altura mede contra a caixa alta
   * do tipo, não a entrelinha cheia, e a largura contra o texto real.
   */
  function participacao(seg: Segmento, w: number, h: number) {
    if (Math.round(seg.share) < 1) return null;
    const texto = `${Math.round(seg.share)}%`;
    const cabeAltura = h >= type.xs * 1.05 + 1 * k;
    return cabeAltura && labelFitsInBar(texto, type.xs, w, 600, 2 * k, 2 * k) ? texto : null;
  }

  /**
   * A pastilha da legenda: as pontas de cada linha arredondadas em meia-cana e
   * as fronteiras internas retas — a mesma peça do histomap.
   */
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
  viewBox="0 0 {width} {altura}"
  {width}
  height={altura}
  style="width: 100%; height: auto; font-family: {fontFamily};"
  role="img"
  aria-label={title}
>
  <!-- o cartão, recuado meia espessura para a borda não sair pelo viewBox -->
  {#if background !== null}
    <rect
      x={k / 2}
      y={k / 2}
      width={width - k}
      height={altura - k}
      rx={L.raioCartao}
      fill={background ?? '#FFFFFF'}
      stroke={cinza.borda}
      stroke-width={k}
    />
  {/if}

  <!-- título e subtítulo -->
  {#each titleLines as linha, i (i)}
    <text
      x={L.pad}
      y={12 * k + (i + 0.8) * L.titleLine}
      font-size={type.title}
      font-weight="600"
      fill={cinza.titulo}
      font-family={fontFamily}>{linha}</text
    >
  {/each}
  {#each subtitleLines as linha, i (i)}
    <text
      x={L.pad}
      y={12 * k + titleLines.length * L.titleLine + (i + 0.75) * L.subtitleLine}
      font-size={type.subtitle}
      fill={cinza.subtitulo}
      font-family={fontFamily}>{linha}</text
    >
  {/each}

  <!-- a legenda: as fontes na ordem em que empilham, encostadas umas nas outras -->
  {#if legendaLayout}
    {#each legendaLayout.chips as chip (chip.label)}
      <path
        d={pastilha(
          L.pad + chip.x,
          legendaY + chip.y,
          chip.width,
          legendaLayout.chipHeight,
          chip.first,
          chip.last,
        )}
        fill={chip.color}
      />
      <text
        x={L.pad + chip.x + chip.width / 2}
        y={legendaY + chip.y + legendaLayout.chipHeight / 2 + type.sm * 0.35}
        text-anchor="middle"
        font-size={type.sm}
        font-weight="600"
        fill={contraste(chip.color)}
        font-family={fontFamily}>{chip.label}</text
      >
    {/each}
  {/if}

  <!-- a escala de participação, só na margem: uma grade atrás da pilha ficaria
       escondida, porque a pilha cobre o plot inteiro de ponta a ponta -->
  {#each [0, 25, 50, 75, 100] as tick (tick)}
    <text
      x={plotLeft - L.tickGap}
      y={yDe(tick) + type.sm * 0.35}
      text-anchor="end"
      font-size={type.sm}
      font-weight="500"
      fill={cinza.regua}
      font-family={fontFamily}>{tick}%</text
    >
  {/each}

  <!-- colchete de cobertura: o texto começa na borda esquerda do trecho, e não
       centrado nele — a nota é sempre mais larga que os poucos anos que
       descreve, e centrada sairia do plot -->
  {#each spans as span (span.de)}
    {@const i0 = anos.indexOf(span.de)}
    {@const i1 = anos.indexOf(span.ate)}
    {#if i0 >= 0 && i1 >= 0}
      {@const esquerda = xCentro(i0) - colW / 2}
      {@const direita = xCentro(i1) + colW / 2}
      {@const yBarra = plotTop - L.spanGap}
      <path
        d={`M${esquerda},${yBarra - L.spanTick} V${yBarra} H${direita} V${yBarra - L.spanTick}`}
        fill="none"
        stroke={cinza.regua}
        stroke-width={k}
      />
      <text
        x={esquerda}
        y={yBarra - L.spanTick - L.spanTextGap}
        font-size={type.xs}
        font-weight="500"
        fill={cinza.nota}
        font-family={fontFamily}>{span.texto}</text
      >
    {/if}
  {/each}

  <!-- as colunas: cada ano fecha em 100%, empilhado de baixo para cima na
       ordem de `keys` -->
  {#each colunas as segmentos, i (anos[i])}
    {@const x = xCentro(i) - colW / 2}
    {#each segmentos as seg, idx (seg.keyIndex)}
      {#if seg.share > 1e-9}
        {@const y = yDe(seg.top)}
        {@const h = yDe(seg.bottom) - y}
        <path
          d={segmentoPath(x, y, colW, h, idx === topoDaColuna[i] ? L.radius : 0)}
          fill={cor(seg.keyIndex)}
        />
      {/if}
    {/each}
  {/each}

  <!-- a participação, escrita em todo segmento que a comporte -->
  {#each colunas as segmentos, i (anos[i])}
    {@const x = xCentro(i) - colW / 2}
    {#each segmentos as seg (seg.keyIndex)}
      {#if seg.share > 1e-9}
        {@const y = yDe(seg.top)}
        {@const h = yDe(seg.bottom) - y}
        {@const texto = participacao(seg, colW, h)}
        {#if texto}
          <text
            x={x + colW / 2}
            y={y + h / 2 + type.xs * 0.35}
            text-anchor="middle"
            font-size={type.xs}
            font-weight="600"
            fill={contraste(cor(seg.keyIndex))}
            font-family={fontFamily}>{texto}</text
          >
        {/if}
      {/if}
    {/each}
  {/each}

  <!-- o eixo do tempo: um traço de base e os anos que couberem sob ele -->
  <line x1={plotLeft} x2={plotRight} y1={plotBottom} y2={plotBottom} stroke={cinza.regua} stroke-width={k} />
  {#each anos as ano, i (ano)}
    {#if ticksVisiveis.has(ano)}
      <text
        x={xCentro(i)}
        y={plotBottom + L.tickGap + type.sm}
        text-anchor="middle"
        font-size={type.sm}
        font-weight="500"
        fill={cinza.eixo}
        font-family={fontFamily}>{ano}</text
      >
    {/if}
  {/each}

  <!-- notas -->
  {#each footnoteLines as linha, i (i)}
    <text
      x={L.pad}
      y={footTop + (i + 0.8) * L.notaLine}
      font-size={type.sm}
      fill={cinza.nota}
      font-family={fontFamily}>{linha}</text
    >
  {/each}
  {#each sourceLines as linha, i (i)}
    <text
      x={L.pad}
      y={sourceTop + (i + 0.8) * L.notaLine}
      font-size={type.sm}
      fill={cinza.nota}
      font-family={fontFamily}>{linha}</text
    >
  {/each}
</svg>
