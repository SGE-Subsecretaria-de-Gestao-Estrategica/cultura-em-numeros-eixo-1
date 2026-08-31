<script lang="ts" module>
  export type Coluna = { key: string; label: string; cor: string };
  export type Linha = {
    key: string;
    label: string;
    /** Linha miúda sob o rótulo — normalmente a base da linha. */
    nota?: string;
    valores: number[];
  };
</script>

<script lang="ts">
  /**
   * Uma matriz de bolhas: duas variáveis categóricas cruzadas, com a área da
   * bolha medindo o valor da célula.
   *
   * A área, e não o diâmetro — `Math.sqrt` no raio. Área é o que o olho lê num
   * disco, e escalar o raio direto no valor faz uma célula de 50% parecer
   * quatro vezes uma de 12,5%, não duas.
   *
   * Os valores são lidos como percentual da linha, e é a linha que soma 100%:
   * é o que torna comparáveis linhas de base muito diferente — 105 municípios
   * numa, 2.355 noutra. A base de cada linha fica escrita ao lado do rótulo,
   * porque uma proporção sobre 105 casos não vale o mesmo que uma sobre 2.355 e
   * a figura não pode esconder isso.
   *
   * O rótulo de cada célula fica sob a bolha, numa linha de base comum a toda a
   * fileira — e não dentro dela. Dentro, o texto teria de trocar de cor
   * conforme a luminosidade do degrau em que caiu, e uma bolha pequena não o
   * comportaria de nenhuma cor.
   */
  import { a4Scale, fontFamily, fontSize as scale, measureLabel, wrapText } from './tokens';

  let {
    linhas,
    colunas,
    title,
    subtitle,
    formatValue = (v: number) => String(v),
    destaque,
    footnote,
    source,
    width = 580,
    svgEl = $bindable(null),
    background = null,
  }: {
    linhas: Linha[];
    colunas: Coluna[];
    title: string;
    subtitle?: string;
    formatValue?: (valor: number) => string;
    destaque?: { valor: string; cor: string; texto: string };
    footnote?: string;
    source?: string;
    width?: number;
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  // svelte-ignore state_referenced_locally -- a largura autoral é fixada na criação
  const k = a4Scale(width);

  const type = {
    title: 14 * k,
    subtitle: scale.md * k,
    coluna: scale.sm * k,
    linha: 11 * k,
    linhaNota: scale.xs * k,
    dado: scale.sm * k,
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
    guia: '#EDEDE9',
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
      ? Math.min(Math.max(118 * k, measureLabel(destaque.valor, type.destaqueValor, 700)), 150 * k)
      : 0,
  );

  /** Coluna dos rótulos de linha, medida no mais largo deles. */
  const larguraRotulos = $derived(
    Math.min(
      Math.max(...linhas.map((l) => measureLabel(l.label, type.linha, 600))) + 10 * k,
      132 * k,
    ),
  );

  const matrizLeft = $derived(pad + larguraRotulos);
  const matrizRight = $derived(width - pad - (destaque ? larguraDestaque + 16 * k : 0));
  const colW = $derived((matrizRight - matrizLeft) / colunas.length);
  const cx = $derived((j: number) => matrizLeft + colW * (j + 0.5));

  /** Cabeçalhos de coluna, quebrados na largura da coluna. */
  const cabecalhos = $derived(
    colunas.map((c) => wrapText(c.label, type.coluna, colW - 6 * k, 600)),
  );
  const linhasDeCabecalho = $derived(Math.max(...cabecalhos.map((c) => c.length)));
  const cabecalhoLine = 12.5 * k;

  const rMax = $derived(colW * 0.42);
  const dadoLine = 13 * k;
  const alturaLinha = $derived(2 * rMax + dadoLine + 10 * k);

  const vMax = $derived(Math.max(...linhas.flatMap((l) => l.valores)));
  const raio = $derived((v: number) => (v <= 0 ? 0 : rMax * Math.sqrt(v / vMax)));

  const topo = $derived(
    12 * k + titleLines.length * titleLine + subtitleLines.length * subtitleLine + 20 * k,
  );
  const matrizTop = $derived(topo + linhasDeCabecalho * cabecalhoLine + 10 * k);
  const matrizBottom = $derived(matrizTop + linhas.length * alturaLinha);

  /** Centro das bolhas e linha de base dos rótulos, por fileira. */
  const cy = $derived((i: number) => matrizTop + i * alturaLinha + rMax);
  const baseDoRotulo = $derived((i: number) => matrizTop + i * alturaLinha + 2 * rMax + dadoLine);

  const notasTop = $derived(
    matrizBottom + (footnoteLines.length + sourceLines.length ? 16 * k : 0),
  );
  const height = $derived(notasTop + (footnoteLines.length + sourceLines.length) * notaLine + pad);

  const destaqueLinhas = $derived(
    destaque ? wrapText(destaque.texto, type.destaqueTexto, larguraDestaque, 500) : [],
  );
  const destaqueX = $derived(matrizRight + 16 * k);
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

  <!-- cabeçalhos de coluna -->
  {#each colunas as coluna, j (coluna.key)}
    {#each cabecalhos[j] as linha, l}
      <text
        x={cx(j)}
        y={topo + (l + 0.8) * cabecalhoLine}
        text-anchor="middle"
        font-size={type.coluna}
        font-weight="600"
        fill={cinza.rotulo}
        font-family={fontFamily}>{linha}</text
      >
    {/each}
  {/each}

  <!-- guias horizontais, uma por fileira, atrás das bolhas -->
  {#each linhas as linha, i (linha.key)}
    <line
      x1={matrizLeft}
      y1={cy(i)}
      x2={matrizRight}
      y2={cy(i)}
      stroke={cinza.guia}
      stroke-width={1.2 * k}
    />
  {/each}

  <!-- rótulos de linha -->
  {#each linhas as linha, i (linha.key)}
    <text
      x={pad + larguraRotulos - 10 * k}
      y={cy(i) + type.linha * 0.35}
      text-anchor="end"
      font-size={type.linha}
      font-weight="600"
      fill={cinza.rotulo}
      font-family={fontFamily}>{linha.label}</text
    >
    {#if linha.nota}
      <text
        x={pad + larguraRotulos - 10 * k}
        y={cy(i) + type.linha * 0.35 + type.linhaNota + 3 * k}
        text-anchor="end"
        font-size={type.linhaNota}
        fill={cinza.detalhe}
        font-family={fontFamily}>{linha.nota}</text
      >
    {/if}
  {/each}

  <!-- bolhas e valores -->
  {#each linhas as linha, i (linha.key)}
    {#each colunas as coluna, j (coluna.key)}
      <circle cx={cx(j)} cy={cy(i)} r={raio(linha.valores[j])} fill={coluna.cor} />
      <text
        x={cx(j)}
        y={baseDoRotulo(i)}
        text-anchor="middle"
        font-size={type.dado}
        font-weight="600"
        fill={cinza.dado}
        font-family={fontFamily}>{formatValue(linha.valores[j])}</text
      >
    {/each}
  {/each}

  <!-- bloco de ponta -->
  {#if destaque}
    <text
      x={destaqueX}
      y={matrizTop + type.destaqueValor}
      font-size={type.destaqueValor}
      font-weight="700"
      fill={destaque.cor}
      font-family={fontFamily}>{destaque.valor}</text
    >
    {#each destaqueLinhas as linha, i}
      <text
        x={destaqueX}
        y={matrizTop + 21 * k + (i + 0.85) * 14.5 * k}
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
