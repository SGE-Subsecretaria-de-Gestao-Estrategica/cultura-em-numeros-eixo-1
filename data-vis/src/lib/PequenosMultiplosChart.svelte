<script lang="ts" module>
  export type PainelSerie = {
    key: string;
    /** Nome do painel, na calha da esquerda. */
    label: string;
    valores: (number | null)[];
    /** Denominador, dito uma vez sob o valor final. */
    nota?: string;
  };
</script>

<script lang="ts">
  /**
   * Pequenos múltiplos: um painel por série, empilhados, dividindo uma escala
   * vertical e um eixo de anos.
   *
   * Por que não cinco linhas num plot só — que é o que a figura original faz.
   * Cinco matizes da paleta da marca não se separam: vermelho e rosa ficam a
   * ΔE 14,6 em visão normal, abaixo do piso de 15, e rosa e verde caem a 7,6 sob
   * deuteranopia. Das 3.125 combinações possíveis das rampas, só duas passam nos
   * seis checks, e ambas são escuras demais para esta família de figuras. Aqui a
   * posição identifica a série, então a cor fica livre para ser uma só — e o
   * problema deixa de existir em vez de ser contornado.
   *
   * A escala vertical é comum aos painéis: é ela que faz a comparação valer. Com
   * cada painel na sua própria escala, o Sul — que vai a 15,9% — teria o mesmo
   * desenho do Nordeste, que vai a 46,8%.
   *
   * A série de referência corre esmaecida atrás de cada painel, de modo que cada
   * série se lê contra o conjunto sem que o leitor precise ir e voltar.
   */
  import { curveMonotoneX, line } from 'd3';
  import { a4Scale, fontFamily, colors as marca, fontSize as scale, measureLabel, wrapText } from './tokens';

  let {
    anos,
    paineis,
    referencia,
    labelReferencia,
    title,
    subtitle,
    cor = marca.primary,
    corMarcador = marca.primaryVariant,
    formatValue = (v: number) => `${v}%`,
    rotulos,
    footnote,
    source,
    width = 580,
    alturaPainel = 96,
    svgEl = $bindable(null),
    background = null,
  }: {
    anos: number[];
    paineis: PainelSerie[];
    /** Série de fundo, repetida em todos os painéis. */
    referencia?: (number | null)[];
    labelReferencia?: string;
    title: string;
    subtitle?: string;
    cor?: string;
    corMarcador?: string;
    formatValue?: (valor: number) => string;
    /** Anos rotulados dentro de cada painel; por omissão, o primeiro e o último. */
    rotulos?: number[];
    footnote?: string;
    source?: string;
    width?: number;
    alturaPainel?: number;
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  // svelte-ignore state_referenced_locally -- a largura autoral é fixada na criação
  const k = a4Scale(width);

  const type = {
    title: 14 * k,
    subtitle: scale.md * k,
    ano: 12.5 * k,
    painel: 11.5 * k,
    dado: scale.sm * k,
    nota: scale.sm * k,
  };

  const cinza = {
    titulo: '#2F2F2B',
    subtitulo: '#6E6E68',
    dado: '#3F3F3B',
    ano: '#33332F',
    grade: '#EDEDE9',
    base: '#DCDCD6',
    fantasma: '#C9C9C2',
    nota: '#8A8A84',
  };

  const pad = 16 * k;
  const espessura = 12 * k;
  const raio = 5 * k;
  /**
   * A série de referência corre atrás, então ela é fina — mas não tanto que
   * desapareça ao lado de uma faixa de 12. Um terço da espessura mantém a
   * hierarquia sem que a linha do país vire um fio.
   */
  const espessuraFantasma = 4 * k;

  const textWidth = $derived(width - pad * 2);
  const titleLines = $derived(wrapText(title, type.title, textWidth, 600));
  const subtitleLines = $derived(wrapText(subtitle ?? '', type.subtitle, textWidth));
  const footnoteLines = $derived(wrapText(footnote ?? '', type.nota, textWidth));
  const sourceLines = $derived(wrapText(source ?? '', type.nota, textWidth));

  const titleLine = 19 * k;
  const subtitleLine = 15 * k;
  const notaLine = 13.5 * k;

  /**
   * Calha esquerda: o nome do painel e, sob ele, o seu denominador.
   *
   * O denominador anda com o nome, e não com o valor final na outra ponta:
   * lá ele disputaria a mesma linha com o número numa região de valor baixo —
   * o Sul termina em 15,9%, perto da base do painel, exatamente onde a nota
   * estaria. Aqui os dois textos são a identidade do painel e leem-se juntos.
   */
  const calhaEsquerda = $derived(
    Math.max(
      ...paineis.map((p) =>
        Math.max(
          measureLabel(p.label, type.painel, 600),
          p.nota ? measureLabel(p.nota, type.nota, 400) : 0,
        ),
      ),
    ) + 12 * k,
  );

  /** Calha direita: só o valor final. */
  const calhaDireita = $derived(
    Math.max(
      ...paineis.map((p) => measureLabel(formatValue(p.valores.at(-1) ?? 0), type.dado, 700)),
    ) + 12 * k,
  );

  /**
   * O rótulo do primeiro ano é centrado na borda esquerda do plot, então metade
   * dele transborda para dentro da calha — sem esta folga, "11,9%" encosta em
   * "Centro-Oeste". Vale para o valor e para o próprio número do ano.
   */
  const transbordoEsquerdo = $derived(
    Math.max(
      measureLabel(String(anos[0]), type.ano, 600) / 2,
      ...paineis.map((p) =>
        p.valores[0] === null ? 0 : measureLabel(formatValue(p.valores[0]), type.dado, 600) / 2,
      ),
    ),
  );

  const plotLeft = $derived(pad + calhaEsquerda + transbordoEsquerdo);
  const plotRight = $derived(width - pad - calhaDireita);

  const topo = $derived(
    12 * k + titleLines.length * titleLine + subtitleLines.length * subtitleLine + 18 * k,
  );

  const alturaLinha = $derived(alturaPainel * k);
  /**
   * Folga no topo de cada painel para o rótulo de valor não sair do quadro.
   *
   * O rótulo do ponto mais alto sobe meia espessura da faixa antes de começar,
   * então a folga tem de comportar a faixa também: com 12 de espessura, os 13
   * que bastavam para uma linha fina deixariam o número do painel de cima
   * pousado sobre a linha de base do painel de baixo.
   */
  const respiro = $derived(espessura / 2 + 18 * k);

  const anosY = $derived(topo + paineis.length * alturaLinha + 17 * k);
  /** A legenda desce para debaixo dos anos: na mesma linha ela bateria no primeiro. */
  const legendaY = $derived(anosY + 17 * k);
  const temLegenda = $derived(Boolean(referencia && labelReferencia));
  const notasTop = $derived(
    (temLegenda ? legendaY : anosY) + (footnoteLines.length + sourceLines.length ? 16 * k : 0),
  );
  const height = $derived(
    notasTop + (footnoteLines.length + sourceLines.length) * notaLine + pad,
  );

  const x = $derived(
    (ano: number) =>
      plotLeft + (anos.indexOf(ano) / (anos.length - 1)) * (plotRight - plotLeft),
  );

  /** Teto comum a todos os painéis — ver o comentário do componente. */
  const vMax = $derived(
    Math.max(
      ...paineis.flatMap((p) => p.valores.filter((v): v is number => v !== null)),
      ...(referencia ?? []).filter((v): v is number => v !== null),
    ),
  );

  const baseDoPainel = $derived((i: number) => topo + (i + 1) * alturaLinha - 8 * k);
  const y = $derived(
    (i: number, v: number) =>
      baseDoPainel(i) - (v / vMax) * (alturaLinha - respiro - 8 * k),
  );

  type Ponto = { ano: number; valor: number };

  const tracado = $derived((i: number) =>
    line<Ponto>()
      .x((p) => x(p.ano))
      .y((p) => y(i, p.valor))
      .curve(curveMonotoneX),
  );

  const pontosDe = $derived((valores: (number | null)[]): Ponto[] =>
    valores
      .map((valor, j) => ({ ano: anos[j], valor }))
      .filter((p): p is Ponto => p.valor !== null),
  );

  const anosRotulados = $derived(rotulos ?? [anos[0], anos[anos.length - 1]]);
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

  {#each paineis as painel, i (painel.key)}
    {@const pontos = pontosDe(painel.valores)}
    {@const final = pontos[pontos.length - 1]}

    <!-- guias verticais e linha de base do painel -->
    {#each anos as ano}
      <line
        x1={x(ano)}
        y1={topo + i * alturaLinha + respiro * 0.4}
        x2={x(ano)}
        y2={baseDoPainel(i)}
        stroke={cinza.grade}
        stroke-width={1.1 * k}
      />
    {/each}
    <line
      x1={plotLeft}
      y1={baseDoPainel(i)}
      x2={plotRight}
      y2={baseDoPainel(i)}
      stroke={cinza.base}
      stroke-width={1.1 * k}
    />

    <!-- a série de referência, esmaecida, atrás da série do painel -->
    {#if referencia}
      <path
        d={tracado(i)(pontosDe(referencia))}
        fill="none"
        stroke={cinza.fantasma}
        stroke-width={espessuraFantasma}
        stroke-linecap="round"
      />
    {/if}

    <path
      d={tracado(i)(pontos)}
      fill="none"
      stroke={cor}
      stroke-width={espessura}
      stroke-linecap="round"
    />

    {#each pontos as p (p.ano)}
      <circle cx={x(p.ano)} cy={y(i, p.valor)} r={raio} fill={corMarcador} />
      {#if anosRotulados.includes(p.ano)}
        <text
          x={x(p.ano)}
          y={y(i, p.valor) - espessura / 2 - 5 * k}
          text-anchor="middle"
          font-size={type.dado}
          font-weight="600"
          fill={cinza.dado}
          font-family={fontFamily}>{formatValue(p.valor)}</text
        >
      {/if}
    {/each}

    <!-- nome do painel e denominador, na calha esquerda -->
    <text
      x={pad}
      y={baseDoPainel(i) - (painel.nota ? 14 : 1) * k}
      font-size={type.painel}
      font-weight="600"
      fill={cinza.titulo}
      font-family={fontFamily}>{painel.label}</text
    >
    {#if painel.nota}
      <text
        x={pad}
        y={baseDoPainel(i) - 1 * k}
        font-size={type.nota}
        fill={cinza.nota}
        font-family={fontFamily}>{painel.nota}</text
      >
    {/if}

    <!-- valor final, na calha direita, na altura da ponta da linha -->
    {#if final}
      <text
        x={plotRight + 12 * k}
        y={y(i, final.valor) + type.dado * 0.36}
        font-size={type.dado}
        font-weight="700"
        fill={cor}
        font-family={fontFamily}>{formatValue(final.valor)}</text
      >
    {/if}
  {/each}

  <!-- eixo dos anos, comum aos painéis -->
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

  <!-- a legenda é uma frase só: a única outra marca é a linha cinza -->
  {#if temLegenda}
    <line
      x1={pad}
      y1={legendaY - type.nota * 0.3}
      x2={pad + 14 * k}
      y2={legendaY - type.nota * 0.3}
      stroke={cinza.fantasma}
      stroke-width={espessuraFantasma}
      stroke-linecap="round"
    />
    <text
      x={pad + 19 * k}
      y={legendaY}
      font-size={type.nota}
      fill={cinza.nota}
      font-family={fontFamily}>{labelReferencia}</text
    >
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
