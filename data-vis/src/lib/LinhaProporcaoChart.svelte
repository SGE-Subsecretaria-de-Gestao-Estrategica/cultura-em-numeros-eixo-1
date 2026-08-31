<script lang="ts" module>
  export type PontoAbs = { ano: number; valor: number; pct: number };
</script>

<script lang="ts">
  /**
   * Uma série absoluta como faixa grossa e, abaixo dela, a régua de bolinhas
   * com a proporção que esses absolutos representam — o segundo print.
   *
   * Os dois gráficos dividem um eixo de anos só, na base da régua, e a mesma
   * quebra de linha do tempo atravessa ambos. O plot carrega os absolutos,
   * todos rotulados; a régua carrega os percentuais, no tamanho e no rótulo de
   * cada bolinha — a figura diz as duas coisas sem repetir nenhuma.
   */
  import { curveMonotoneX, line } from 'd3';
  import { a4Scale, fontFamily, colors as marca, fontSize as scale, measureLabel, wrapText } from './tokens';

  let {
    pontos,
    title,
    subtitle,
    cor = marca.primary,
    corMarcador = marca.primaryVariant,
    corPontoFinal = marca.accent,
    formatValue = (v: number) => String(v),
    formatPct = (v: number) => `${v}%`,
    destaque,
    fraseDaRegua,
    destaqueDaRegua,
    quebraApos,
    footnote,
    source,
    width = 580,
    plotHeight = 210,
    svgEl = $bindable(null),
    background = null,
  }: {
    pontos: PontoAbs[];
    title: string;
    subtitle?: string;
    cor?: string;
    corMarcador?: string;
    /** Cor do último marcador e do valor do bloco de ponta — o verde do print. */
    corPontoFinal?: string;
    formatValue?: (valor: number) => string;
    formatPct?: (pct: number) => string;
    /** Bloco de ponta do plot: valor grande na cor do ponto final, mais a frase. */
    destaque: { valor: string; texto: string };
    /** Frase que apresenta a régua, entre o plot e as bolinhas. */
    fraseDaRegua: string;
    /** Leitura na ponta da régua: o percentual final em negrito, mais a frase. */
    destaqueDaRegua: { valor: string; texto: string };
    /**
     * Último ano antes do vão na linha do tempo. Só surte efeito se o ano
     * seguinte da série não for o consecutivo — ver `quebra`.
     */
    quebraApos?: number;
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
    ano: 12.5 * k,
    dado: scale.sm * k,
    destaqueValor: 19 * k,
    destaqueTexto: scale.md * k,
    frase: scale.md * k,
    regua: scale.sm * k,
    nota: scale.sm * k,
  };

  const cinza = {
    titulo: '#2F2F2B',
    subtitulo: '#6E6E68',
    dado: '#3F3F3B',
    ano: '#33332F',
    grade: '#E8E8E4',
    quebra: '#8F8F89',
    nota: '#8A8A84',
  };

  const pad = 16 * k;
  const espessura = 12 * k;
  const raio = 5 * k;
  const raioFinal = 8 * k;
  const VAO = 0.75;

  const anos = $derived(pontos.map((p) => p.ano));

  /**
   * O ano em que a linha do tempo realmente se interrompe — a única quebra que
   * a figura desenha, no plot e na régua.
   *
   * `quebraApos` diz onde a interrupção estaria, mas se o ano seguinte da série
   * é o consecutivo não há vão nenhum no eixo: o vão, o tracejado e o glifo
   * marcariam uma descontinuidade que o leitor não pode conferir em lugar
   * algum. Uma mudança de base sem salto de anos é assunto da nota de rodapé,
   * não do eixo.
   */
  const quebra = $derived.by(() => {
    if (quebraApos === undefined) return undefined;
    const depois = anos.find((ano) => ano > quebraApos);
    return depois !== undefined && depois > quebraApos + 1 ? quebraApos : undefined;
  });

  const passo = $derived((ano: number) => {
    const i = anos.indexOf(ano);
    return quebra !== undefined && ano > quebra ? i + VAO : i;
  });

  const sobraEsquerda = $derived(
    Math.max(
      measureLabel(String(anos[0]), type.ano, 600) / 2,
      measureLabel(formatValue(pontos[0].valor), type.dado, 600) / 2,
      measureLabel(formatPct(pontos[0].pct), type.regua, 600) / 2,
    ),
  );

  const larguraDestaque = $derived(
    Math.min(
      Math.max(
        118 * k,
        measureLabel(destaque.valor, type.destaqueValor, 700),
        measureLabel(destaqueDaRegua.valor, 13 * k, 700),
      ),
      150 * k,
    ),
  );

  const plotLeft = $derived(pad + sobraEsquerda);
  const plotRight = $derived(width - pad - larguraDestaque - 16 * k);

  const textWidth = $derived(width - pad * 2);
  const titleLines = $derived(wrapText(title, type.title, textWidth, 600));
  const subtitleLines = $derived(wrapText(subtitle ?? '', type.subtitle, textWidth));
  const footnoteLines = $derived(wrapText(footnote ?? '', type.nota, textWidth));
  const sourceLines = $derived(wrapText(source ?? '', type.nota, textWidth));

  const titleLine = 19 * k;
  const subtitleLine = 15 * k;
  const notaLine = 13.5 * k;

  const plotTop = $derived(
    12 * k + titleLines.length * titleLine + subtitleLines.length * subtitleLine + 20 * k,
  );
  const plotH = $derived(plotHeight * k);
  const plotBottom = $derived(plotTop + plotH);
  const headroom = 24 * k;

  /** A frase da régua, a linha dos rótulos, a linha das bolinhas. */
  const fraseY = $derived(plotBottom + 26 * k);
  const reguaRotuloY = $derived(fraseY + 22 * k);
  const reguaY = $derived(reguaRotuloY + 16 * k);
  const anosY = $derived(reguaY + 26 * k);

  const notasTop = $derived(anosY + (footnoteLines.length + sourceLines.length ? 16 * k : 0));
  const height = $derived(
    notasTop + (footnoteLines.length + sourceLines.length) * notaLine + pad,
  );

  const passos = $derived(passo(anos[anos.length - 1]));
  const x = $derived((ano: number) => plotLeft + (passo(ano) / passos) * (plotRight - plotLeft));

  const vMax = $derived(Math.max(...pontos.map((p) => p.valor)));
  const y = $derived(
    (v: number) => plotBottom - espessura / 2 - (v / vMax) * (plotH - headroom - espessura),
  );

  const tracado = $derived(
    line<PontoAbs>()
      .x((p) => x(p.ano))
      .y((p) => y(p.valor))
      .curve(curveMonotoneX),
  );

  const lados = $derived(
    quebra === undefined
      ? [pontos]
      : [pontos.filter((p) => p.ano <= quebra), pontos.filter((p) => p.ano > quebra)].filter(
          (l) => l.length > 1,
        ),
  );

  const travessia = $derived.by((): [PontoAbs, PontoAbs] | null => {
    if (quebra === undefined) return null;
    const antes = pontos.filter((p) => p.ano <= quebra).at(-1);
    const depois = pontos.find((p) => p.ano > quebra);
    return antes && depois ? [antes, depois] : null;
  });

  /**
   * O meio do vão: entre o último ano antes da quebra e o primeiro depois dela.
   * Os anos que faltam não estão no eixo, então `quebra + 1` não tem posição.
   */
  const centroDaQuebra = $derived.by(() => {
    if (quebra === undefined) return null;
    const depois = anos.find((ano) => ano > quebra)!;
    return (x(quebra) + x(depois)) / 2;
  });

  /** Raio de uma bolinha da régua, entre o piso e o teto, linear no percentual. */
  const pctMax = $derived(Math.max(...pontos.map((p) => p.pct)));
  const raioRegua = $derived((pct: number) => (3 + (pct / pctMax) * 5.5) * k);

  const final = $derived(pontos[pontos.length - 1]);
  const destaqueX = $derived(plotRight + 16 * k);
  const destaqueLinhas = $derived(wrapText(destaque.texto, type.destaqueTexto, larguraDestaque, 500));
  const reguaLinhas = $derived(
    wrapText(destaqueDaRegua.texto, type.dado, larguraDestaque, 500),
  );
</script>

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

  <!-- grade vertical, só na área do plot -->
  {#each anos as ano}
    <line x1={x(ano)} y1={plotTop} x2={x(ano)} y2={plotBottom} stroke={cinza.grade} stroke-width={1.2 * k} />
  {/each}

  {#if centroDaQuebra !== null}
    <text
      transform="rotate(-90 {centroDaQuebra} {reguaY + 14 * k})"
      x={centroDaQuebra}
      y={reguaY + 14 * k + type.dado * 0.35}
      font-size={type.dado}
      font-weight="500"
      letter-spacing={1.5 * k}
      fill={cinza.quebra}
      font-family={fontFamily}>QUEBRA</text
    >
    <g stroke={cinza.quebra} stroke-width={1.4 * k} stroke-linecap="round">
      <line x1={centroDaQuebra - 10 * k} y1={anosY - 4 * k} x2={centroDaQuebra - 4 * k} y2={anosY - 4 * k} />
      <line x1={centroDaQuebra + 4 * k} y1={anosY - 4 * k} x2={centroDaQuebra + 10 * k} y2={anosY - 4 * k} />
      <line x1={centroDaQuebra - 3 * k} y1={anosY - 0.5 * k} x2={centroDaQuebra + 0.5 * k} y2={anosY - 7.5 * k} />
      <line x1={centroDaQuebra - 0.5 * k} y1={anosY - 0.5 * k} x2={centroDaQuebra + 3 * k} y2={anosY - 7.5 * k} />
    </g>
  {/if}

  <!-- a faixa -->
  {#if travessia}
    <line
      x1={x(travessia[0].ano)}
      y1={y(travessia[0].valor)}
      x2={x(travessia[1].ano)}
      y2={y(travessia[1].valor)}
      stroke={cor}
      stroke-width={espessura}
      stroke-linecap="round"
      stroke-dasharray="{9 * k} {10 * k}"
      opacity="0.4"
    />
  {/if}
  {#each lados as lado}
    <path d={tracado(lado)} fill="none" stroke={cor} stroke-width={espessura} stroke-linecap="round" />
  {/each}

  {#each pontos as p (p.ano)}
    <circle
      cx={x(p.ano)}
      cy={y(p.valor)}
      r={p.ano === final.ano ? raioFinal : raio}
      fill={p.ano === final.ano ? corPontoFinal : corMarcador}
    />
    {#if p.ano !== final.ano}
      <text
        x={x(p.ano)}
        y={y(p.valor) - espessura / 2 - 6 * k}
        text-anchor="middle"
        font-size={type.dado}
        font-weight="600"
        fill={cinza.dado}
        font-family={fontFamily}>{formatValue(p.valor)}</text
      >
    {/if}
  {/each}

  <!-- bloco de ponta do plot -->
  <text
    x={destaqueX}
    y={y(final.valor) - 4 * k}
    font-size={type.destaqueValor}
    font-weight="700"
    fill={corPontoFinal}
    font-family={fontFamily}>{destaque.valor}</text
  >
  {#each destaqueLinhas as linha, i}
    <text
      x={destaqueX}
      y={y(final.valor) + 6 * k + (i + 0.85) * 14.5 * k}
      font-size={type.destaqueTexto}
      font-weight="500"
      fill={cinza.dado}
      font-family={fontFamily}>{linha}</text
    >
  {/each}

  <!-- frase da régua -->
  <text
    x={pad}
    y={fraseY}
    font-size={type.frase}
    font-weight="600"
    fill={cinza.titulo}
    font-family={fontFamily}>{fraseDaRegua}</text
  >

  <!-- régua de bolinhas: a linha fina, as bolinhas, os percentuais -->
  {#each pontos as p, i}
    {#if i > 0}
      {@const cruzaQuebra = quebra !== undefined && pontos[i - 1].ano <= quebra && p.ano > quebra}
      <line
        x1={x(pontos[i - 1].ano)}
        y1={reguaY}
        x2={x(p.ano)}
        y2={reguaY}
        stroke={cor}
        stroke-width={2 * k}
        stroke-dasharray={cruzaQuebra ? `${5 * k} ${6 * k}` : undefined}
        opacity={cruzaQuebra ? 0.4 : 1}
      />
    {/if}
  {/each}
  <!-- o percentual do último ponto mora no bloco da ponta, não sobre a bolinha -->
  {#each pontos as p (p.ano)}
    <circle cx={x(p.ano)} cy={reguaY} r={raioRegua(p.pct)} fill={cor} />
    {#if p.ano !== final.ano}
      <text
        x={x(p.ano)}
        y={reguaRotuloY}
        text-anchor="middle"
        font-size={type.regua}
        font-weight="600"
        fill={cinza.dado}
        font-family={fontFamily}>{formatPct(p.pct)}</text
      >
    {/if}
  {/each}

  <!-- leitura na ponta da régua -->
  <text
    x={destaqueX}
    y={reguaRotuloY}
    font-size={13 * k}
    font-weight="700"
    fill={cinza.titulo}
    font-family={fontFamily}>{destaqueDaRegua.valor}</text
  >
  {#each reguaLinhas as linha, i}
    <text
      x={destaqueX}
      y={reguaRotuloY + (i + 1) * 13.5 * k}
      font-size={type.dado}
      font-weight="500"
      fill={cinza.dado}
      font-family={fontFamily}>{linha}</text
    >
  {/each}

  <!-- eixo dos anos, servindo aos dois gráficos -->
  {#each anos as ano}
    <text
      x={x(ano)}
      y={anosY}
      text-anchor="middle"
      font-size={type.ano}
      font-weight="600"
      fill={cinza.ano}
      font-family={fontFamily}>{ano}</text
    >
  {/each}

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
