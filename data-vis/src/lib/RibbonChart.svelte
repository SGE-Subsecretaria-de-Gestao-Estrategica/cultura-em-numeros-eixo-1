<script lang="ts" module>
  /** Um ano: o rótulo do eixo e o valor de cada fonte naquele ano. */
  export type ColunaRow = { label: string } & Record<string, number | string>;

  /**
   * Um período demarcado acima do plot — para uma fonte que a figura não
   * empilha, mas cuja vigência ainda importa contar. Ver o comentário de
   * `spans` mais abaixo.
   */
  export type Periodo = {
    de: number;
    ate: number;
    texto: string;
    /** Por omissão, o cinza neutro das demais notas do plot. */
    cor?: string;
  };
</script>

<script lang="ts">
  /**
   * Fita: colunas empilhadas por valor absoluto, reordenadas a cada ano pelo
   * próprio valor, e ligadas de um ano ao seguinte por uma fita — a mesma
   * fonte lida através do tempo mesmo quando ela troca de posição na pilha.
   *
   * Difere de `ComposicaoChart` no que mede: lá a pergunta é "que fatia do
   * total", aqui é "quanto, em valor" — por isso a coluna não fecha em 100% e
   * as fontes se reordenam. É a reordenação que a fita torna visível: quando
   * a Lei Paulo Gustavo ultrapassa a Aldir Blanc 1 de um ano para o outro, a
   * fita cruza; quando a ordem se mantém, as fitas correm paralelas.
   *
   * Como em `CascataChart`, não há eixo Y: o valor de cada segmento está
   * escrito dentro dele, e uma escala vertical repetiria o número. O nome da
   * fonte também entra no segmento, e não só o valor — ver o comentário de
   * `fonteColors` em `fontes.ts`: sob a opacidade da fita, dois vermelhos
   * vizinhos (LAB 1 e LPG) ficam próximos demais para a cor sozinha carregar
   * a identidade.
   *
   * Cada segmento é um `rect` independente com cantos arredondados — como o
   * degrau da cascata, e pela mesma razão: aqui, ao contrário das colunas de
   * `ComposicaoChart`, há um vão entre segmentos (`segmentGap`), então nada
   * encosta e o raio nunca precisa ceder para um lado só.
   *
   * A fita entre dois anos é sempre uma Bézier cúbica, nunca um cotovelo: um
   * ângulo reto dentro do dado sugeriria uma transição abrupta que a fita não
   * mede — ela liga dois pontos no tempo, não descreve o que aconteceu entre
   * eles. Uma fonte com valor zero num dos dois anos não tem segmento para
   * ligar, então a fita simplesmente não é desenhada — melhor um buraco do
   * que uma fita que nasce ou morre no vazio.
   *
   * Desenhada em SVG puro e na paleta de `tokens`/`cores`, como as demais
   * figuras da coleção.
   *
   * Nem toda fonte precisa virar segmento. Quando uma delas é pequena demais
   * para pesar na pilha — o caso do recurso municipal, onde o próprio nunca
   * cai abaixo de 85% —, `spans` marca a vigência dela como um colchete acima
   * do plot, na linguagem de `ComposicaoChart`, em vez de abrir uma fatia que
   * ninguém veria. Períodos que se sobrepõem (duas leis emergenciais no mesmo
   * ano) ganham uma linha cada, empilhadas como um Gantt.
   *
   * `mostrarFitas` desliga as fitas quando só sobra uma fonte empilhada: sem
   * uma segunda série para reordenar, a fita conectaria o mesmo segmento ano
   * a ano sem nada para mostrar, e a figura vira uma coluna comum. `mostrarNomes`
   * desliga a tentativa de escrever o nome da fonte dentro do segmento pela
   * mesma razão — com uma fonte só, o nome se repete em toda coluna sem
   * distinguir nada, e só o valor interessa.
   *
   * Um valor que não cabe em lugar nenhum do próprio segmento — a régua que
   * `rotuloDoSegmento` aplica — não fica em branco: vira uma pastilha do
   * tamanho do texto, na cor da fonte, centrada no segmento e sobreposta a ele
   * (e, quando é preciso, aos vizinhos). É a mesma pastilha que a implementação
   * em cima das primitivas do design system desenhava para os segmentos que
   * não cabiam — aqui sem linha de chamada, porque a posição sobre o próprio
   * segmento já diz de quem é o número.
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
    data: ColunaRow[];
    /** Fontes, na ordem da legenda — a ordem da pilha é o valor, não esta. */
    keys: string[];
    labels?: Record<string, string>;
    /** Cores na ordem de `keys`; as fitas herdam a cor do segmento à esquerda. */
    colors: readonly string[];
    title: string;
    subtitle?: string;
    /**
     * Desenha o título e o subtítulo. Desligado, eles somem do desenho mas
     * `title` continua o `aria-label` do `<svg>` — a página que incorpora o
     * gráfico decide título e legenda por conta própria (o `<h1>` de cada
     * folha em `A4.svelte`, por exemplo), e o espaço que o cabeçalho reservava
     * volta para o plot.
     */
    mostrarTitulo?: boolean;
    footnote?: string;
    source?: string;
    /** A faixa de pastilhas sob o subtítulo, na ordem de `keys`. */
    legenda?: boolean;
    formatValue?: (v: number) => string;
    /** Fração do intervalo anual ocupada pela coluna; o resto sustenta as fitas. */
    columnRatio?: number;
    /** Vão entre segmentos empilhados, antes da escala de impressão. */
    segmentGap?: number;
    /** As fitas são desenhadas mais claras que os segmentos que ligam. */
    ribbonOpacity?: number;
    /** `desc` põe a maior fonte no topo de cada coluna, a leitura natural. */
    rankDirection?: 'desc' | 'asc';
    /**
     * Raio do segmento, antes da escala de impressão — cede se o segmento for
     * baixo. Pequeno de propósito: um canto muito arredondado desalinha a
     * fita da borda reta do segmento bem na altura em que ela encosta, e o
     * olho lê esse desalinhamento como um degrau na curva.
     */
    radius?: number;
    /** Desliga as fitas — a coluna comum que sobra quando há uma fonte só. */
    mostrarFitas?: boolean;
    /** Desliga o nome da fonte dentro do segmento, deixando só o valor. */
    mostrarNomes?: boolean;
    /** Períodos demarcados acima do plot, para fontes que a figura não empilha. */
    spans?: Periodo[];
    /** Anos rotulados sob o eixo. Por omissão, todos os anos de `data`. */
    tickYears?: number[];
    /** Altura do plot, antes da escala de impressão. */
    plotHeight?: number;
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
    mostrarTitulo = true,
    footnote,
    source,
    legenda = true,
    formatValue = (v: number) => String(v),
    columnRatio = 0.55,
    segmentGap = 5,
    ribbonOpacity = 0.55,
    rankDirection = 'desc',
    radius = 3,
    mostrarFitas = true,
    mostrarNomes = true,
    spans = [],
    tickYears,
    plotHeight = 230,
    width = 580,
    height,
    background,
    svgEl = $bindable(null),
  }: Props = $props();

  const k = $derived(a4Scale(width));

  const type = $derived({
    title: 14 * k,
    subtitle: scale.md * k,
    ano: 12.5 * k,
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
    segmentGap: segmentGap * k,
    /** Faixa no topo do plot onde só um valor que transbordou o topo entra. */
    headroom: 22 * k,
    /** Do colchete de período ao seu traço, dele ao texto, e de uma linha à seguinte. */
    spanGap: 10 * k,
    spanTick: 4 * k,
    spanTextGap: 3 * k,
    spanRowGap: 6 * k,
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
  const titleLines = $derived(mostrarTitulo ? wrapText(title, type.title, textWidth, 600) : []);
  const subtitleLines = $derived(
    mostrarTitulo ? wrapText(subtitle ?? '', type.subtitle, textWidth) : [],
  );
  const footnoteLines = $derived(wrapText(footnote ?? '', type.sm, textWidth));
  const sourceLines = $derived(wrapText(source ?? '', type.sm, textWidth));

  const legendaLayout = $derived(
    legenda
      ? layoutLegend(
          keys.map((key, i) => ({ label: labels[key] ?? key, color: cor(i) })),
          { fontSize: type.sm, fontWeight: 600, padX: 8 * k, maxWidth: textWidth, rowGap: 4 * k },
        )
      : null,
  );

  const anos = $derived(data.map((d) => Number(d.label)));
  const valor = (row: ColunaRow, key: string) => Number(row[key]) || 0;

  type Segmento = { keyIndex: number; valor: number; y: number; height: number };

  /**
   * Uma coluna por ano, com as fontes presentes reordenadas pelo próprio
   * valor — é essa reordenação que as fitas tornam visível. Fontes com valor
   * zero saem da pilha em vez de abrir um vão para um segmento que ninguém
   * veria.
   */
  const colunas = $derived(
    data.map((row) => {
      const presentes = keys
        .map((key, keyIndex) => ({ key, keyIndex, valor: valor(row, key) }))
        .filter((s) => s.valor > 0)
        .sort((a, b) => (rankDirection === 'desc' ? b.valor - a.valor : a.valor - b.valor));
      return presentes;
    }),
  );

  const vMax = $derived(Math.max(1, ...colunas.map((c) => c.reduce((soma, s) => soma + s.valor, 0))));

  /** O vão reservado no topo do plot para a coluna com mais segmentos empilhados. */
  const gapReserve = $derived(
    (Math.max(1, ...colunas.map((c) => c.length)) - 1) * L.segmentGap,
  );

  // --- a moldura -------------------------------------------------------------

  const cabecalho = $derived(
    12 * k + titleLines.length * L.titleLine + subtitleLines.length * L.subtitleLine,
  );
  const legendaY = $derived(cabecalho + L.legendaGap);
  const molduraTop = $derived(
    legendaLayout ? legendaY + legendaLayout.height + L.legendaPlotGap : cabecalho + 12 * k,
  );

  /**
   * Os períodos em linhas: cada uma só recebe colchetes que não se tocam no
   * tempo, como as barras de um Gantt. Duas leis emergenciais no mesmo ano —
   * a LPG e a PNAB em 2024 — pedem uma linha cada.
   */
  const linhasDePeriodo = $derived.by(() => {
    const ordenados = [...spans].sort((a, b) => a.de - b.de);
    const linhas: Periodo[][] = [];
    for (const periodo of ordenados) {
      const linha = linhas.find((l) => l[l.length - 1].ate < periodo.de);
      if (linha) linha.push(periodo);
      else linhas.push([periodo]);
    }
    return linhas;
  });

  const spanRowHeight = $derived(type.xs * 1.2 + L.spanTextGap + L.spanTick + L.spanGap);
  const spanReserve = $derived(
    linhasDePeriodo.length ? linhasDePeriodo.length * spanRowHeight + L.spanRowGap * (linhasDePeriodo.length - 1) : 0,
  );

  const plotTop = $derived(molduraTop + spanReserve);
  const plotH = $derived(L.plotHeight);
  const plotBottom = $derived(plotTop + plotH);

  const plotLeft = $derived(L.pad);
  const plotRight = $derived(width - L.pad);

  const slot = $derived(anos.length ? (plotRight - plotLeft) / anos.length : 0);
  const colW = $derived(slot * columnRatio);
  const xCentro = (i: number) => plotLeft + slot * (i + 0.5);

  const usableH = $derived(Math.max(0, plotH - gapReserve - L.headroom));
  const y = $derived((v: number) => plotBottom - (v / vMax) * usableH);

  /** Layout vertical de uma coluna: empilhada de cima para baixo a partir do topo. */
  const layouts = $derived(
    colunas.map((coluna) => {
      const heights = coluna.map((s) => y(0) - y(s.valor));
      const stackHeight = heights.reduce((soma, h) => soma + h, 0) + L.segmentGap * Math.max(0, heights.length - 1);
      let cursor = y(0) - stackHeight;
      const segmentos: Segmento[] = coluna.map((s, i) => {
        const seg = { keyIndex: s.keyIndex, valor: s.valor, y: cursor, height: heights[i] };
        cursor += heights[i] + L.segmentGap;
        return seg;
      });
      return segmentos;
    }),
  );

  type Pilula = { keyIndex: number; x: number; y: number; w: number; h: number; linhas: string[] };

  /**
   * As pastilhas de uma coluna: uma para cada segmento cujo valor não coube
   * em lugar nenhum de `rotuloDoSegmento`. Nascem centradas no próprio
   * segmento — daí "sobrepostas" — mas um segmento muito fino ao lado de
   * outro deixaria as duas pastilhas cobrindo o mesmo texto uma da outra, que
   * é a única sobreposição que atrapalha a leitura. Por isso a pilha empurra
   * cada pastilha para baixo da anterior quando as duas se tocariam, na mesma
   * lógica dos blocos de ponta de `FaixaLinhasChart` — só entre pastilhas da
   * mesma coluna, nunca contra o segmento que cada uma nomeia.
   *
   * Com `mostrarNomes` ligado, a pastilha carrega o nome da fonte além do
   * valor — sem ele, um segmento pequeno demais para o rótulo interno
   * também ficaria pequeno demais para a legenda ajudar, se a figura estiver
   * sem legenda.
   *
   * O cursor também avança sobre o segmento que já coube um rótulo interno
   * (`rotuloDoSegmento` verdadeiro): sem isso, uma pastilha maior que a fatia
   * fina que ela nomeia cresceria por cima do texto do segmento vizinho, que
   * nem chegou a competir pela pilha por já ter o próprio rótulo resolvido.
   */
  const pilulasPorColuna = $derived(
    layouts.map((segmentos, i) => {
      const x = xCentro(i) - colW / 2;
      let cursor = -Infinity;

      return segmentos.reduce<Pilula[]>((pilulas, seg) => {
        if (rotuloDoSegmento(seg.keyIndex, seg.valor, colW, seg.height)) {
          cursor = Math.max(cursor, seg.y + seg.height);
          return pilulas;
        }

        const valorTxt = formatValue(seg.valor);
        const nome = mostrarNomes ? (labels[keys[seg.keyIndex]] ?? keys[seg.keyIndex]) : null;
        const linhas = nome ? [nome, valorTxt] : [valorTxt];
        const entrelinha = type.sm * 1.3;
        const h = nome ? entrelinha * 2 + 10 * k : type.sm * 1.9;
        const w = Math.max(...linhas.map((l) => measureLabel(l, type.sm, 700))) + 16 * k;
        const y = Math.max(seg.y + seg.height / 2 - h / 2, cursor);
        cursor = y + h + 3 * k;

        pilulas.push({
          keyIndex: seg.keyIndex,
          x: Math.min(Math.max(x + colW / 2 - w / 2, plotLeft), plotRight - w),
          y,
          w,
          h,
          linhas,
        });
        return pilulas;
      }, []);
    }),
  );

  const ticksVisiveis = $derived(new Set(tickYears ?? anos));

  /**
   * Quanto as pastilhas descem abaixo da linha de base, na pior coluna. O
   * segmento mais baixo de uma pilha nasce encostado no zero, então a
   * pastilha dele já nasce cruzando essa linha — e mais pastilhas empurradas
   * por cima dele descem ainda mais. O eixo dos anos recua o que for preciso
   * para nenhuma pastilha cair sobre o rótulo do ano.
   */
  const pilulaOverflow = $derived(
    Math.max(
      0,
      ...pilulasPorColuna.map((pilulas) =>
        pilulas.length ? pilulas[pilulas.length - 1].y + pilulas[pilulas.length - 1].h - plotBottom : 0,
      ),
    ),
  );
  const eixoY = $derived(plotBottom + pilulaOverflow + L.tickGap + type.ano);

  const footTop = $derived(eixoY + L.axisLabelLine - type.ano + L.noteGap);
  const sourceTop = $derived(
    footTop + footnoteLines.length * L.notaLine + (footnoteLines.length ? L.noteSpacing : 0),
  );
  const altura = $derived(height ?? sourceTop + sourceLines.length * L.notaLine + L.pad);

  /** Segmento com cantos arredondados, cedendo quando é baixo demais para o raio pedido. */
  function segmentoPath(x: number, y: number, w: number, h: number) {
    const r = Math.max(0, Math.min(L.radius, w / 2, h / 2));
    if (!r) return `M${x},${y} H${x + w} V${y + h} H${x} Z`;
    return [
      `M${x + r},${y}`,
      `H${x + w - r}`,
      `A${r},${r} 0 0 1 ${x + w},${y + r}`,
      `V${y + h - r}`,
      `A${r},${r} 0 0 1 ${x + w - r},${y + h}`,
      `H${x + r}`,
      `A${r},${r} 0 0 1 ${x},${y + h - r}`,
      `V${y + r}`,
      `A${r},${r} 0 0 1 ${x + r},${y}`,
      'Z',
    ].join(' ');
  }

  /**
   * A pastilha da legenda: as pontas de cada linha arredondadas em meia-cana
   * e as fronteiras internas retas — a mesma peça do histomap e de
   * `ComposicaoChart`.
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

  /** Fita cúbica entre o mesmo segmento em duas colunas vizinhas. */
  function fitaPath(x1: number, x2: number, top1: number, bottom1: number, top2: number, bottom2: number) {
    const meio = (x1 + x2) / 2;
    return [
      `M${x1},${top1}`,
      `C${meio},${top1} ${meio},${top2} ${x2},${top2}`,
      `L${x2},${bottom2}`,
      `C${meio},${bottom2} ${meio},${bottom1} ${x1},${bottom1}`,
      'Z',
    ].join(' ');
  }

  const fitas = $derived.by(() => {
    type Fita = { key: string; color: string; path: string };
    const resultado: Fita[] = [];
    for (let i = 0; i < layouts.length - 1; i++) {
      const x1 = xCentro(i) + colW / 2;
      const x2 = xCentro(i + 1) - colW / 2;
      for (const de of layouts[i]) {
        const para = layouts[i + 1].find((s) => s.keyIndex === de.keyIndex);
        if (!para) continue;
        resultado.push({
          key: `${de.keyIndex}-${i}`,
          color: cor(de.keyIndex),
          path: fitaPath(x1, x2, de.y, de.y + de.height, para.y, para.y + para.height),
        });
      }
    }
    return resultado;
  });

  /**
   * O que cabe dentro do segmento: nome e valor em duas linhas quando há
   * espaço para as duas, só o nome quando falta altura ou largura para o
   * valor, e nada quando nem o nome cabe — a cor e a legenda seguem
   * carregando a identidade, como no comentário de `fonteColors`. Com
   * `mostrarNomes` desligado o nome nunca entra: só o valor importa.
   */
  function rotuloDoSegmento(keyIndex: number, valorSeg: number, w: number, h: number) {
    const nome = labels[keys[keyIndex]] ?? keys[keyIndex];
    const valorTxt = formatValue(valorSeg);
    const largura = (texto: string, size: number, peso: number) =>
      w >= measureLabel(texto, size, peso) + 6 * k;

    if (mostrarNomes) {
      const duasLinhas =
        h >= type.sm * 2.6 + 3 * k && largura(nome, type.sm, 600) && largura(valorTxt, type.sm, 500);
      if (duasLinhas) return { linhas: [nome, valorTxt], size: type.sm };

      if (h >= type.sm * 1.3 && largura(nome, type.sm, 600)) return { linhas: [nome], size: type.sm };
    }
    if (h >= type.xs * 1.3 && largura(valorTxt, type.xs, 600)) return { linhas: [valorTxt], size: type.xs };
    return null;
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

  <!-- a legenda: as fontes na ordem declarada, não a ordem da pilha -->
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

  <!-- os períodos demarcados: um colchete por linha, para os que se sobrepõem -->
  {#each linhasDePeriodo as linha, l (l)}
    {@const yBarra = plotTop - spanReserve + l * (spanRowHeight + L.spanRowGap) + L.spanTick + L.spanTextGap + type.xs}
    {#each linha as periodo (periodo.texto)}
      {@const i0 = anos.indexOf(periodo.de)}
      {@const i1 = anos.indexOf(periodo.ate)}
      {#if i0 >= 0 && i1 >= 0}
        {@const esquerda = xCentro(i0) - colW / 2}
        {@const direita = xCentro(i1) + colW / 2}
        <path
          d={`M${esquerda},${yBarra - L.spanTick} V${yBarra} H${direita} V${yBarra - L.spanTick}`}
          fill="none"
          stroke={periodo.cor ?? cinza.regua}
          stroke-width={k}
        />
        <text
          x={(esquerda + direita) / 2}
          y={yBarra - L.spanTick - L.spanTextGap}
          text-anchor="middle"
          font-size={type.xs}
          font-weight="600"
          fill={periodo.cor ?? cinza.nota}
          font-family={fontFamily}>{periodo.texto}</text
        >
      {/if}
    {/each}
  {/each}

  <!-- as fitas, atrás dos segmentos que ligam — eles leem como as âncoras sólidas -->
  {#if mostrarFitas}
    {#each fitas as fita (fita.key)}
      <path d={fita.path} fill={fita.color} fill-opacity={ribbonOpacity} />
    {/each}
  {/if}

  <!-- os segmentos -->
  {#each layouts as segmentos, i (anos[i])}
    {@const x = xCentro(i) - colW / 2}
    {#each segmentos as seg (seg.keyIndex)}
      <path d={segmentoPath(x, seg.y, colW, seg.height)} fill={cor(seg.keyIndex)} />
    {/each}
  {/each}

  <!-- o nome e o valor de cada segmento que os comporte -->
  {#each layouts as segmentos, i (anos[i])}
    {@const x = xCentro(i) - colW / 2}
    {#each segmentos as seg (seg.keyIndex)}
      {@const rotulo = rotuloDoSegmento(seg.keyIndex, seg.valor, colW, seg.height)}
      {#if rotulo}
        {@const centroY = seg.y + seg.height / 2}
        {@const entrelinha = rotulo.size * 1.3}
        {@const topoTexto = centroY - ((rotulo.linhas.length - 1) * entrelinha) / 2}
        {#each rotulo.linhas as linha, j (j)}
          <text
            x={x + colW / 2}
            y={topoTexto + j * entrelinha + rotulo.size * 0.35}
            text-anchor="middle"
            font-size={rotulo.size}
            font-weight={j === 0 ? 600 : 500}
            fill={contraste(cor(seg.keyIndex))}
            font-family={fontFamily}>{linha}</text
          >
        {/each}
      {/if}
    {/each}
  {/each}

  <!--
    As pastilhas: o valor dos segmentos que não coube em lugar nenhum acima,
    na cor da fonte, sobrepostas ao segmento que nomeiam — a pastilha da
    implementação anterior, sem linha de chamada porque a posição já diz de
    quem é o número. `pilulasPorColuna` já resolveu a sobreposição entre
    pastilhas vizinhas da mesma coluna.
  -->
  {#each pilulasPorColuna as pilulas, i (anos[i])}
    {#each pilulas as p (p.keyIndex)}
      <path d={pastilha(p.x, p.y, p.w, p.h, true, true)} fill={cor(p.keyIndex)} />
      {@const entrelinha = type.sm * 1.3}
      {@const topo = p.y + p.h / 2 - ((p.linhas.length - 1) * entrelinha) / 2}
      {#each p.linhas as linha, j (j)}
        <text
          x={p.x + p.w / 2}
          y={topo + j * entrelinha + type.sm * 0.35}
          text-anchor="middle"
          font-size={type.sm}
          font-weight={p.linhas.length > 1 ? (j === 0 ? 600 : 500) : 700}
          fill={contraste(cor(p.keyIndex))}
          font-family={fontFamily}>{linha}</text
        >
      {/each}
    {/each}
  {/each}

  <!--
    O eixo do tempo: só os anos, sem traço de base. Um segmento nasce
    encostado no zero e as pastilhas descem ainda mais — um traço bem na
    linha de base cortaria as duas coisas em vez de servir de régua.
  -->
  {#each anos as ano, i (ano)}
    {#if ticksVisiveis.has(ano)}
      <text
        x={xCentro(i)}
        y={eixoY}
        text-anchor="middle"
        font-size={type.ano}
        font-weight="600"
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
