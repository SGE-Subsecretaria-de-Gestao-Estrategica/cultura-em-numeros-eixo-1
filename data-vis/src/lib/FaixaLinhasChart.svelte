<script lang="ts" module>
  export type Ponto = { ano: number; valor: number };

  /** Bloco de leitura na ponta direita: o valor grande colorido e a frase. */
  export type Destaque = { valor: string; cor: string; texto: string };

  export type Serie = {
    key: string;
    /** Cor da faixa. */
    cor: string;
    /** Cor dos marcadores sobre a faixa; por omissão, o rosa da marca. */
    corMarcador?: string;
    /** Cor do marcador do último ponto, quando ele merece outra — o verde. */
    corPontoFinal?: string;
    pontos: Ponto[];
    /** Anos que ganham rótulo de valor dentro do plot. */
    rotulos?: number[];
    /** Anos cujo rótulo desce para baixo da faixa, fugindo de outra série. */
    abaixo?: number[];
    destaque?: Destaque;
  };
</script>

<script lang="ts">
  /**
   * Séries anuais como faixas grossas de ponta redonda — o gráfico de linha
   * dos prints de referência.
   *
   * Não há eixo Y: os valores que importam estão escritos sobre os pontos e o
   * último vira o número grande do bloco de ponta, então a escala vertical
   * seria redundante. A grade é só vertical, uma guia por ano.
   *
   * `quebraApos` abre um vão na linha do tempo: o trecho que atravessa o vão é
   * tracejado e esmaecido, o eixo ganha o glifo de interrupção e a palavra
   * QUEBRA sobe na vertical — a gramática do print para uma mudança de base.
   * Só que a marcação é sobre o eixo, então ela só aparece quando o eixo de
   * fato salta: ver `quebra`.
   */
  import { curveMonotoneX, line } from 'd3';
  import { a4Scale, fontFamily, colors as marca, fontSize as scale, measureLabel, wrapText } from './tokens';

  let {
    series,
    title,
    subtitle,
    formatValue = (v: number) => String(v),
    quebraApos,
    footnote,
    source,
    width = 580,
    plotHeight = 235,
    svgEl = $bindable(null),
    background = null,
  }: {
    series: Serie[];
    title: string;
    subtitle?: string;
    formatValue?: (valor: number) => string;
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
    /** Rótulo de ano no eixo — o maior texto do plot, como nos prints. */
    ano: 12.5 * k,
    dado: scale.sm * k,
    destaqueValor: 19 * k,
    destaqueTexto: scale.md * k,
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

  /** Largura extra do vão da quebra, em frações de um passo anual. */
  const VAO = 0.75;

  const anos = $derived(
    [...new Set(series.flatMap((s) => s.pontos.map((p) => p.ano)))].sort((a, b) => a - b),
  );

  /**
   * O ano em que a linha do tempo realmente se interrompe — a única quebra que
   * a figura desenha.
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

  /** Posição de um ano em passos anuais, com o vão da quebra somado. */
  const passo = $derived((ano: number) => {
    const i = anos.indexOf(ano);
    return quebra !== undefined && ano > quebra ? i + VAO : i;
  });

  const rotuloDe = $derived((s: Serie, p: Ponto) =>
    (s.rotulos ?? []).includes(p.ano) ? formatValue(p.valor) : null,
  );

  /**
   * Margem esquerda: metade do primeiro rótulo de ano transborda do plot, e o
   * rótulo de valor do primeiro ponto também é centrado nele.
   */
  const sobraEsquerda = $derived(
    Math.max(
      measureLabel(String(anos[0]), type.ano, 600) / 2,
      ...series.map((s) => {
        const r = rotuloDe(s, s.pontos[0]);
        return r ? measureLabel(r, type.dado, 600) / 2 : 0;
      }),
    ),
  );

  /** Largura do bloco de ponta, medida no conteúdo e com teto. */
  const larguraDestaque = $derived(
    Math.min(
      Math.max(
        118 * k,
        ...series
          .filter((s) => s.destaque)
          .map((s) => measureLabel(s.destaque!.valor, type.destaqueValor, 700)),
      ),
      150 * k,
    ),
  );

  const temDestaque = $derived(series.some((s) => s.destaque));

  const plotLeft = $derived(pad + sobraEsquerda);
  const plotRight = $derived(width - pad - (temDestaque ? larguraDestaque + 16 * k : sobraEsquerda));

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

  /** Faixa no topo do plot onde só rótulos entram — nenhuma linha sobe até lá. */
  const headroom = 24 * k;

  const anosY = $derived(plotBottom + 20 * k);
  const notasTop = $derived(anosY + (footnoteLines.length + sourceLines.length ? 18 * k : 0));
  const height = $derived(
    notasTop + (footnoteLines.length + sourceLines.length) * notaLine + pad,
  );

  const passos = $derived(passo(anos[anos.length - 1]));
  const x = $derived((ano: number) => plotLeft + (passo(ano) / passos) * (plotRight - plotLeft));

  /**
   * O rótulo de ano encolhe quando a série é longa demais para o passo.
   *
   * Quinze anos num plot de 580 unidades deixam menos de 30 para cada rótulo, e
   * `2011 2012 2013` encosta um no outro. Encolher é melhor do que girar: a
   * linha de anos é a única âncora horizontal da figura, e na diagonal ela para
   * de se ler de relance.
   */
  const tamanhoDoAno = $derived.by(() => {
    const passoPx = (plotRight - plotLeft) / passos;
    const maisLargo = Math.max(...anos.map((a) => measureLabel(String(a), type.ano, 600)));
    const cabe = passoPx - 4 * k;
    return maisLargo <= cabe ? type.ano : Math.max(type.ano * (cabe / maisLargo), 8 * k);
  });

  const vMax = $derived(Math.max(...series.flatMap((s) => s.pontos.map((p) => p.valor))));
  const y = $derived(
    (v: number) => plotBottom - espessura / 2 - (v / vMax) * (plotH - headroom - espessura),
  );

  const tracado = $derived(
    line<Ponto>()
      .x((p) => x(p.ano))
      .y((p) => y(p.valor))
      .curve(curveMonotoneX),
  );

  /** Os dois lados da quebra; sem quebra, a série inteira é um lado só. */
  const lados = $derived((pontos: Ponto[]) =>
    quebra === undefined
      ? [pontos]
      : [pontos.filter((p) => p.ano <= quebra), pontos.filter((p) => p.ano > quebra)].filter(
          (l) => l.length > 1,
        ),
  );

  /** O par de pontos que atravessa o vão — vira o trecho tracejado. */
  const travessia = $derived((pontos: Ponto[]): [Ponto, Ponto] | null => {
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

  /** Rótulo acima (ou abaixo) do marcador, afastado da meia espessura da faixa. */
  const rotuloY = $derived((s: Serie, p: Ponto) =>
    (s.abaixo ?? []).includes(p.ano)
      ? y(p.valor) + espessura / 2 + type.dado + 5 * k
      : y(p.valor) - espessura / 2 - 6 * k,
  );

  type Bloco = {
    destaque: Destaque;
    linhas: string[];
    top: number;
    altura: number;
  };

  /**
   * Blocos de ponta na ordem vertical das linhas, empurrados para não se
   * sobreporem — duas séries que terminam próximas leem-se separadas.
   */
  const blocos = $derived.by((): Bloco[] => {
    const linhaValor = 21 * k;
    const linhaTexto = 14.5 * k;
    const desejados = series
      .filter((s) => s.destaque)
      .map((s) => {
        const final = s.pontos[s.pontos.length - 1];
        const linhas = wrapText(s.destaque!.texto, type.destaqueTexto, larguraDestaque, 500);
        return {
          destaque: s.destaque!,
          linhas,
          top: y(final.valor) - 12 * k,
          altura: linhaValor + linhas.length * linhaTexto,
        };
      })
      .sort((a, b) => a.top - b.top);

    let cursor = plotTop - 8 * k;
    for (const bloco of desejados) {
      bloco.top = Math.max(bloco.top, cursor);
      cursor = bloco.top + bloco.altura + 10 * k;
    }
    return desejados;
  });

  const destaqueX = $derived(plotRight + 16 * k);
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

  <!-- grade vertical: uma guia por ano -->
  {#each anos as ano}
    <line x1={x(ano)} y1={plotTop} x2={x(ano)} y2={plotBottom} stroke={cinza.grade} stroke-width={1.2 * k} />
  {/each}

  <!-- a quebra: palavra na vertical e glifo de interrupção no eixo -->
  {#if centroDaQuebra !== null}
    <text
      transform="rotate(-90 {centroDaQuebra} {plotBottom - 4 * k})"
      x={centroDaQuebra}
      y={plotBottom - 4 * k + type.dado * 0.35}
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

  <!-- faixas -->
  {#each series as s (s.key)}
    {@const cruza = travessia(s.pontos)}
    {#if cruza}
      <line
        x1={x(cruza[0].ano)}
        y1={y(cruza[0].valor)}
        x2={x(cruza[1].ano)}
        y2={y(cruza[1].valor)}
        stroke={s.cor}
        stroke-width={espessura}
        stroke-linecap="round"
        stroke-dasharray="{9 * k} {10 * k}"
        opacity="0.4"
      />
    {/if}
    {#each lados(s.pontos) as lado}
      <path
        d={tracado(lado)}
        fill="none"
        stroke={s.cor}
        stroke-width={espessura}
        stroke-linecap="round"
      />
    {/each}
  {/each}

  <!-- marcadores e rótulos, por cima de todas as faixas -->
  {#each series as s (s.key)}
    {@const final = s.pontos[s.pontos.length - 1]}
    {#each s.pontos as p (p.ano)}
      <circle
        cx={x(p.ano)}
        cy={y(p.valor)}
        r={p.ano === final.ano && (s.corPontoFinal || s.destaque) ? raioFinal : raio}
        fill={p.ano === final.ano && s.corPontoFinal ? s.corPontoFinal : (s.corMarcador ?? marca.primaryVariant)}
      />
      {#if rotuloDe(s, p)}
        <text
          x={x(p.ano)}
          y={rotuloY(s, p)}
          text-anchor="middle"
          font-size={type.dado}
          font-weight="600"
          fill={cinza.dado}
          font-family={fontFamily}>{rotuloDe(s, p)}</text
        >
      {/if}
    {/each}
  {/each}

  <!-- blocos de ponta -->
  {#each blocos as bloco}
    <text
      x={destaqueX}
      y={bloco.top + type.destaqueValor}
      font-size={type.destaqueValor}
      font-weight="700"
      fill={bloco.destaque.cor}
      font-family={fontFamily}>{bloco.destaque.valor}</text
    >
    {#each bloco.linhas as linha, i}
      <text
        x={destaqueX}
        y={bloco.top + 21 * k + (i + 0.85) * 14.5 * k}
        font-size={type.destaqueTexto}
        font-weight="500"
        fill={cinza.dado}
        font-family={fontFamily}>{linha}</text
      >
    {/each}
  {/each}

  <!-- eixo dos anos -->
  {#each anos as ano}
    <text
      x={x(ano)}
      y={anosY}
      text-anchor="middle"
      font-size={tamanhoDoAno}
      font-weight="600"
      fill={cinza.ano}
      font-family={fontFamily}>{ano}</text
    >
  {/each}

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
