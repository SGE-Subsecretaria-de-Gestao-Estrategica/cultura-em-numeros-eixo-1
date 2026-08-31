<script lang="ts" module>
  export type Fatia = { key: string; label: string; n: number; cor: string };
  export type Painel = { key: string; titulo: string; fatias: Fatia[] };
</script>

<script lang="ts">
  /**
   * Uma matriz de pontos: um ponto por pessoa, a mesma grade repetida em vários
   * painéis, repartida de um jeito diferente em cada um.
   *
   * É a figura de contagem literal — a única da coleção em que a unidade do
   * dado é a unidade do desenho. Um percentual diz "6,2% das pessoas
   * delegadas"; setenta e cinco pontos destacados numa grade de 1.201 dizem
   * quantas pessoas são, que é o que a frase esconde.
   *
   * Os pontos são preenchidos em ordem de leitura e as fatias entram em
   * sequência, então cada categoria ocupa um bloco contíguo. Espalhar as cores
   * pela grade daria ruído: a área de cada bloco é o que se lê, e ela só se lê
   * se o bloco for um bloco.
   *
   * A grade é a mesma nos quatro painéis — mesmas colunas, mesmas linhas,
   * mesmo total. O que muda de um para outro é só onde caem as fronteiras entre
   * as cores, e é essa comparação que a figura existe para permitir.
   */
  import { a4Scale, fontFamily, fontSize as scale, measureLabel, wrapText } from './tokens';

  let {
    paineis,
    total,
    colunasDaGrade = 40,
    colunasDePaineis = 2,
    title,
    subtitle,
    footnote,
    source,
    width = 580,
    svgEl = $bindable(null),
    background = null,
  }: {
    paineis: Painel[];
    total: number;
    /** Pontos por linha da grade. */
    colunasDaGrade?: number;
    /** Painéis por linha do cartão. */
    colunasDePaineis?: number;
    title: string;
    subtitle?: string;
    footnote?: string;
    source?: string;
    width?: number;
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  // svelte-ignore state_referenced_locally -- a largura autoral é fixada na criação
  const k = a4Scale(width);

  const inteiro = new Intl.NumberFormat('pt-BR');
  const decimal = new Intl.NumberFormat('pt-BR', {
    minimumFractionDigits: 1,
    maximumFractionDigits: 1,
  });

  const type = {
    title: 14 * k,
    subtitle: scale.md * k,
    painel: 11.5 * k,
    legenda: scale.xs * k,
    nota: scale.sm * k,
  };

  const cinza = {
    titulo: '#2F2F2B',
    subtitulo: '#6E6E68',
    painel: '#2F2F2B',
    legenda: '#4A4A45',
    nota: '#8A8A84',
  };

  const pad = 16 * k;
  const gapPaineis = 20 * k;

  const textWidth = $derived(width - pad * 2);
  const titleLines = $derived(wrapText(title, type.title, textWidth, 600));
  const subtitleLines = $derived(wrapText(subtitle ?? '', type.subtitle, textWidth));
  const footnoteLines = $derived(wrapText(footnote ?? '', type.nota, textWidth));
  const sourceLines = $derived(wrapText(source ?? '', type.nota, textWidth));

  const titleLine = 19 * k;
  const subtitleLine = 15 * k;
  const notaLine = 13.5 * k;

  const painelW = $derived(
    (textWidth - gapPaineis * (colunasDePaineis - 1)) / colunasDePaineis,
  );

  /** Passo da grade; o ponto ocupa pouco mais de metade dele, e o resto é ar. */
  const passo = $derived(painelW / colunasDaGrade);
  const raio = $derived(passo * 0.34);
  const linhasDaGrade = $derived(Math.ceil(total / colunasDaGrade));
  const gradeH = $derived(linhasDaGrade * passo);

  const painelTituloLine = 15 * k;
  const legendaLine = 12 * k;

  /**
   * As legendas de cada painel, quebradas na largura do painel menos o espaço
   * da bolinha. Uma legenda de duas linhas empurra o painel inteiro, então a
   * altura de linha é contada aqui e não estimada.
   */
  const legendas = $derived(
    paineis.map((p) =>
      p.fatias.map((f) => ({
        fatia: f,
        linhas: wrapText(
          `${f.label} — ${inteiro.format(f.n)} (${decimal.format((f.n / total) * 100)}%)`,
          type.legenda,
          painelW - 12 * k,
          500,
        ),
      })),
    ),
  );

  const linhasDeLegenda = $derived(
    legendas.map((l) => l.reduce((soma, entrada) => soma + entrada.linhas.length, 0)),
  );

  /** Todas as fileiras de painéis têm a altura da mais alta, para alinharem. */
  const painelH = $derived(
    painelTituloLine + gradeH + 8 * k + Math.max(...linhasDeLegenda) * legendaLine,
  );

  const fileiras = $derived(Math.ceil(paineis.length / colunasDePaineis));

  const topo = $derived(
    12 * k + titleLines.length * titleLine + subtitleLines.length * subtitleLine + 18 * k,
  );
  const painelX = $derived((i: number) => pad + (i % colunasDePaineis) * (painelW + gapPaineis));
  const painelY = $derived(
    (i: number) => topo + Math.floor(i / colunasDePaineis) * (painelH + gapPaineis),
  );

  const fim = $derived(topo + fileiras * painelH + (fileiras - 1) * gapPaineis);
  const notasTop = $derived(fim + (footnoteLines.length + sourceLines.length ? 16 * k : 0));
  const height = $derived(notasTop + (footnoteLines.length + sourceLines.length) * notaLine + pad);

  /** A cor de cada ponto da grade, por painel: as fatias em sequência. */
  const coresDosPontos = $derived(
    paineis.map((p) => {
      const cores: string[] = [];
      for (const fatia of p.fatias) {
        for (let i = 0; i < fatia.n; i++) cores.push(fatia.cor);
      }
      return cores;
    }),
  );

  const pontos = $derived(
    Array.from({ length: total }, (_, i) => ({
      cx: (i % colunasDaGrade) * passo + passo / 2,
      cy: Math.floor(i / colunasDaGrade) * passo + passo / 2,
    })),
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

  {#each paineis as painel, p (painel.key)}
    <g transform="translate({painelX(p)} {painelY(p)})">
      <text
        x="0"
        y={painelTituloLine * 0.72}
        font-size={type.painel}
        font-weight="600"
        fill={cinza.painel}
        font-family={fontFamily}>{painel.titulo}</text
      >

      <g transform="translate(0 {painelTituloLine})">
        {#each pontos as ponto, i}
          <circle cx={ponto.cx} cy={ponto.cy} r={raio} fill={coresDosPontos[p][i]} />
        {/each}
      </g>

      {#each legendas[p] as entrada, e}
        {@const antes = legendas[p]
          .slice(0, e)
          .reduce((soma, x) => soma + x.linhas.length, 0)}
        <circle
          cx={3 * k}
          cy={painelTituloLine + gradeH + 8 * k + (antes + 0.55) * legendaLine}
          r={3 * k}
          fill={entrada.fatia.cor}
        />
        {#each entrada.linhas as linha, l}
          <text
            x={11 * k}
            y={painelTituloLine + gradeH + 8 * k + (antes + l + 0.8) * legendaLine}
            font-size={type.legenda}
            font-weight="500"
            fill={cinza.legenda}
            font-family={fontFamily}>{linha}</text
          >
        {/each}
      {/each}
    </g>
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
