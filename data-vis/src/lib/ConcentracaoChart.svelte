<script lang="ts" module>
  /** Um ponto da curva: percentual acumulado da população e do total. */
  export type PontoLorenz = [populacao: number, total: number];

  /**
   * Uma leitura marcada sobre a curva.
   *
   * `topo` é a fração do fim da ordenação a que a leitura se refere — os 10%
   * que mais gastam —, e é o que decide onde o marcador pousa. `rotulo` é a
   * frase inteira, escrita pelo chamador: o valor de um marco não é a altura
   * do ponto em que ele está desenhado, é o que falta dali até o topo, e um
   * número solto ao lado do ponto seria lido como a altura. A frase é o que
   * impede essa leitura.
   */
  export type Marco = { topo: number; rotulo: string };
</script>

<script lang="ts">
  /**
   * Curva de concentração: quanto do total sai de que fração da população.
   *
   * A diagonal é a distribuição perfeitamente igual — cada município com a
   * mesma parcela do gasto. A curva é o que há; a distância entre as duas é a
   * desigualdade, e é a única coisa que a figura mede.
   *
   * É a leitura mais literal que a coleção tem, no sentido de que a forma
   * desenhada *é* o argumento: nenhuma outra figura da publicação fala de
   * desigualdade territorial de recurso, e ela é o subtexto do capítulo
   * municipal inteiro.
   *
   * Os marcos são lidos da direita para a esquerda — "os 10% que mais gastam" —
   * mas a curva corre da esquerda para a direita, do município que menos gasta
   * ao que mais gasta. Cada marco é desenhado no ponto da curva a que
   * corresponde, com a leitura escrita ao lado: é o que evita que o leitor
   * tenha de inverter a conta de cabeça.
   */
  import { line } from 'd3';
  import { a4Scale, fontFamily, fontSize as scale, measureLabel, wrapText } from './tokens';

  let {
    pontos,
    marcos,
    cor,
    corMarcador,
    title,
    subtitle,
    destaque,
    legendaDiagonal,
    rotuloX,
    rotuloY,
    footnote,
    source,
    width = 580,
    plotHeight = 300,
    svgEl = $bindable(null),
    background = null,
  }: {
    pontos: PontoLorenz[];
    marcos: Marco[];
    cor: string;
    corMarcador: string;
    title: string;
    subtitle?: string;
    destaque?: { valor: string; cor: string; texto: string };
    legendaDiagonal: string;
    rotuloX: string;
    rotuloY: string;
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
    eixo: scale.sm * k,
    rotuloEixo: scale.sm * k,
    marco: scale.sm * k,
    destaqueValor: 19 * k,
    destaqueTexto: scale.md * k,
    nota: scale.sm * k,
  };

  const cinza = {
    titulo: '#2F2F2B',
    subtitulo: '#6E6E68',
    dado: '#3F3F3B',
    eixo: '#8A8A84',
    grade: '#EDEDE9',
    diagonal: '#A8A8A2',
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

  const larguraDestaque = $derived(
    destaque
      ? Math.min(Math.max(128 * k, measureLabel(destaque.valor, type.destaqueValor, 700)), 160 * k)
      : 0,
  );

  /** Coluna do eixo vertical: os rótulos de percentual, alinhados à direita. */
  const larguraEixoY = $derived(measureLabel('100%', type.eixo, 500) + 8 * k);

  const plotLeft = $derived(pad + larguraEixoY);
  const plotRight = $derived(width - pad - (destaque ? larguraDestaque + 18 * k : 0));

  const plotTop = $derived(
    12 * k + titleLines.length * titleLine + subtitleLines.length * subtitleLine + 20 * k,
  );
  const plotH = $derived(plotHeight * k);
  const plotBottom = $derived(plotTop + plotH);

  const x = $derived((v: number) => plotLeft + (v / 100) * (plotRight - plotLeft));
  const y = $derived((v: number) => plotBottom - (v / 100) * plotH);

  const eixoXY = $derived(plotBottom + 16 * k);
  const rotulosY = $derived(eixoXY + 14 * k);
  const legendaY = $derived(rotulosY + 16 * k);
  const notasTop = $derived(legendaY + (footnoteLines.length + sourceLines.length ? 12 * k : 0));
  const height = $derived(notasTop + (footnoteLines.length + sourceLines.length) * notaLine + pad);

  const marcas = [0, 25, 50, 75, 100];

  const curva = $derived(
    line<PontoLorenz>()
      .x((p) => x(p[0]))
      .y((p) => y(p[1])),
  );

  /**
   * Cada marco no ponto da curva a que corresponde. "Os 10% que mais gastam"
   * é o trecho à direita de 90%, então o ponto marcado é o de 90% da
   * população — e o que ele concentra é o que falta dali até 100%.
   */
  const marcados = $derived(
    marcos.map((m) => {
      const populacao = 100 - m.topo;
      const acumulado = pontos.find((p) => p[0] >= populacao)?.[1] ?? 0;
      return { ...m, populacao, acumulado };
    }),
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

  <!-- grade -->
  {#each marcas as v}
    <line
      x1={x(v)}
      y1={plotTop}
      x2={x(v)}
      y2={plotBottom}
      stroke={cinza.grade}
      stroke-width={1.2 * k}
    />
    <line
      x1={plotLeft}
      y1={y(v)}
      x2={plotRight}
      y2={y(v)}
      stroke={cinza.grade}
      stroke-width={1.2 * k}
    />
    <text
      x={x(v)}
      y={eixoXY}
      text-anchor="middle"
      font-size={type.eixo}
      font-weight="500"
      fill={cinza.eixo}
      font-family={fontFamily}>{v}%</text
    >
    <text
      x={plotLeft - 8 * k}
      y={y(v) + type.eixo * 0.35}
      text-anchor="end"
      font-size={type.eixo}
      font-weight="500"
      fill={cinza.eixo}
      font-family={fontFamily}>{v}%</text
    >
  {/each}

  <!-- a diagonal da igualdade perfeita -->
  <line
    x1={x(0)}
    y1={y(0)}
    x2={x(100)}
    y2={y(100)}
    stroke={cinza.diagonal}
    stroke-width={1.6 * k}
    stroke-linecap="round"
    stroke-dasharray="{5 * k} {5 * k}"
  />

  <!-- a curva -->
  <path
    d={curva(pontos) ?? ''}
    fill="none"
    stroke={cor}
    stroke-width={5 * k}
    stroke-linecap="round"
    stroke-linejoin="round"
  />

  <!-- os marcos, sobre a curva -->
  {#each marcados as m}
    <line
      x1={x(m.populacao)}
      y1={y(m.acumulado)}
      x2={x(m.populacao)}
      y2={plotBottom}
      stroke={corMarcador}
      stroke-width={1 * k}
      stroke-dasharray="{3 * k} {3 * k}"
      opacity="0.55"
    />
    <circle cx={x(m.populacao)} cy={y(m.acumulado)} r={4 * k} fill={corMarcador} />
    <text
      x={x(m.populacao) - 9 * k}
      y={y(m.acumulado) + type.marco * 0.35}
      text-anchor="end"
      font-size={type.marco}
      font-weight="600"
      fill={cinza.dado}
      font-family={fontFamily}>{m.rotulo}</text
    >
  {/each}

  <!-- rótulos dos eixos -->
  <text
    x={plotLeft}
    y={rotulosY}
    font-size={type.rotuloEixo}
    fill={cinza.eixo}
    font-family={fontFamily}>{rotuloX}</text
  >
  <text
    transform="rotate(-90 {pad - 2 * k} {plotTop + plotH / 2})"
    x={pad - 2 * k}
    y={plotTop + plotH / 2}
    text-anchor="middle"
    font-size={type.rotuloEixo}
    fill={cinza.eixo}
    font-family={fontFamily}>{rotuloY}</text
  >

  <!-- legenda da diagonal -->
  <line
    x1={pad}
    y1={legendaY - type.eixo * 0.3}
    x2={pad + 14 * k}
    y2={legendaY - type.eixo * 0.3}
    stroke={cinza.diagonal}
    stroke-width={1.6 * k}
    stroke-dasharray="{5 * k} {5 * k}"
  />
  <text
    x={pad + 20 * k}
    y={legendaY}
    font-size={type.eixo}
    font-weight="500"
    fill={cinza.dado}
    font-family={fontFamily}>{legendaDiagonal}</text
  >

  <!-- bloco de ponta -->
  {#if destaque}
    <text
      x={plotRight + 18 * k}
      y={plotTop + type.destaqueValor}
      font-size={type.destaqueValor}
      font-weight="700"
      fill={destaque.cor}
      font-family={fontFamily}>{destaque.valor}</text
    >
    {#each wrapText(destaque.texto, type.destaqueTexto, larguraDestaque, 500) as linha, i}
      <text
        x={plotRight + 18 * k}
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
