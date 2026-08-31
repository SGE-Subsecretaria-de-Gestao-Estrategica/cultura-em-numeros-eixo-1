<script lang="ts" module>
  /** Um ano: o rótulo do eixo e o valor de cada categoria naquele ano. */
  export type AnoRow = { label: string } & Record<string, number | string>;

  /**
   * Uma nota escrita dentro do plot, sobre a linha de um ano.
   *
   * A cor sai da faixa em que ela pousa — o contraste é medido contra a
   * categoria que ocupa a posição `x` naquele ano — então a nota deve ser
   * posicionada dentro de uma massa larga o bastante para contê-la.
   */
  export type Anotacao = {
    ano: number;
    texto: string;
    /** Linha de destaque acima do texto, em corpo maior e negrito. */
    titulo?: string;
    /** Centro horizontal, em % do plot. Por omissão, o meio. */
    x?: number;
    /** Desloca a nota verticalmente, em frações de ano. */
    dy?: number;
  };

  /**
   * Um bloco de leitura na calha direita, ancorado na linha de um ano — o
   * mesmo bloco da ponta das linhas das figuras de série histórica: o valor em
   * destaque, um título em negrito e uma nota menor. É onde a figura conta o
   * que aconteceu num ano sem escrever por cima das faixas.
   */
  export type DestaqueAno = {
    ano: number;
    /** O valor em corpo grande — o total do ano, tipicamente. */
    valor?: string;
    titulo: string;
    nota?: string;
  };
</script>

<script lang="ts">
  /**
   * Histomap: a composição de um total anual com o tempo correndo para baixo.
   *
   * A inspiração é o "Histomap" de John B. Sparks (1931), que desenha quatro
   * mil anos de "poder relativo" como faixas verticais que se alargam e se
   * estreitam. Aqui a régua é a mesma: cada ano é uma linha, a largura de cada
   * faixa é a participação da categoria no total daquele ano, e a soma fecha em
   * 100% de ponta a ponta.
   *
   * É a mesma pergunta das figuras de composição — de onde veio cada real — com
   * duas trocas deliberadas:
   *
   * - **o tempo desce.** Com o ano no eixo Y a figura fica retrato, que é o
   *   formato da página, e os 23 anos ganham cada um a sua linha legível — no
   *   eixo X eles disputam a largura da coluna de texto.
   * - **as transições são suavizadas.** As outras figuras de composição mudam
   *   em degrau, fiéis à medida anual; esta interpola entre os anos porque o
   *   fluxo é o assunto — o alargar e estreitar das faixas é o que se lê. O
   *   preço está dito na nota de rodapé: uma fonte de um ano só entra e sai em
   *   rampa que não houve. `curveBumpY` e não uma spline qualquer, porque ela
   *   não ultrapassa os pontos que liga — os controles do Bézier ficam no x
   *   dos próprios pontos, e as fronteiras são somas acumuladas: uma curva que
   *   passasse do medido faria duas fronteiras se cruzarem, uma faixa de
   *   largura negativa. E ela entra e sai de cada ponto na vertical, que é a
   *   direção dos platôs (ver `plateau`): cada transição vira um S contínuo
   *   entre dois patamares, sem o vinco que a monotônica deixava na junção.
   *
   * A identidade das faixas é carregada duas vezes. Dentro do plot, pelo nome
   * escrito na própria faixa, no ano em que ela está mais larga — como no
   * original, onde a legenda é o próprio mapa. E no topo, pela faixa de
   * pastilhas: elas saem na ordem de empilhamento, encostadas umas nas outras,
   * então a legenda é a mesma barra segmentada que o plot desenha logo abaixo —
   * quem procura uma fonte fina, que não coube com o nome dentro, acha a cor
   * dela sem sair da figura.
   *
   * A largura de cada faixa fica plana num platô em torno da linha do ano
   * (ver `plateau`) e só transiciona no vão entre dois anos. Sem o platô, uma
   * categoria executada num ano só — cercada de zeros — vira uma elipse: a
   * curva gasta os dois anos vizinhos inteiros inflando e murchando. Com ele,
   * a faixa segura a largura medida sobre a linha do próprio ano, que é onde o
   * olho a compara com a régua.
   *
   * O que a normalização esconde — o total também se move — os blocos de
   * destaque da calha direita devolvem: o valor do ano em corpo grande, nos
   * anos em que a figura tem algo a contar. Não há calha de totais linha a
   * linha: dezenove números empilhados são uma tabela colada no mapa, e a
   * leitura de fluxo que a forma existe para dar não depende deles.
   *
   * Desenhada em SVG puro e na paleta de `tokens`, como as demais figuras da
   * coleção: o tipo é General Sans declarado em cada `<text>`, porque o cartão
   * é exportado como arquivo solto, onde não há nada em volta de que herdar.
   */
  import { area, curveBumpY, scaleLinear } from 'd3';
  import { layoutLegend } from './legend';
  import { a4Scale, fontFamily, fontSize as scale, measureLabel, wrapText } from './tokens';

  /** Os cinzas da coleção: os mesmos das figuras de linha e de pequenos múltiplos. */
  const cinza = {
    titulo: '#2F2F2B',
    subtitulo: '#6E6E68',
    ano: '#33332F',
    anoFraco: '#77776F',
    regua: '#C9C9C2',
    bloco: '#3F3F3B',
    nota: '#8A8A84',
    borda: '#E8E8E4',
  };

  interface Props {
    data: AnoRow[];
    /** Categorias na ordem em que empilham, da esquerda para a direita. */
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
    /** Notas dentro do plot — ver `Anotacao`. */
    anotacoes?: Anotacao[];
    /** Anos cujo rótulo sai em negrito na régua do tempo, além dos que têm bloco. */
    anosDestacados?: number[];
    /**
     * Blocos de leitura na calha direita, um por ano anotado — ver
     * `DestaqueAno`. É a calha deles que estreita o plot: as faixas pagam a
     * largura que as anotações ocupam.
     */
    destaques?: DestaqueAno[];
    /**
     * Cor do valor em destaque dos blocos. Por omissão o ink, e não uma cor da
     * marca: as cinco matizes já estão todas em uso dentro do plot, e um número
     * colorido encostado na calha seria lido como pertencendo à faixa que
     * terminasse ao lado dele. O que destaca o valor é o corpo, não a cor.
     */
    destaqueValueColor?: string;
    /**
     * Fração do ano em que a faixa segura a largura medida, de cada lado da
     * linha dele; a transição fica no que sobra do vão entre dois anos.
     *
     * O valor é um compromisso entre dois defeitos: sem platô nenhum, uma
     * categoria de um ano só vira uma elipse; com um platô largo, as
     * transições viram diagonais duras e a figura sai facetada. Em 0,15 a
     * largura medida ainda existe como patamar sobre a linha do ano, e 70% do
     * vão entre anos fica com a curva.
     */
    plateau?: number;
    /**
     * Em que anos o nome de uma categoria pode ser ancorado. Por omissão, o
     * rótulo de cada trecho contínuo vai para o ano em que a faixa está mais
     * larga; uma chave presente aqui restringe a escolha aos anos listados —
     * para quando o ano mais largo é justamente o que uma anotação manda não
     * ler ao pé da letra.
     */
    labelYears?: Record<string, number[]>;
    /**
     * Em que anos a participação de uma categoria pode ser escrita na faixa.
     * Por omissão, todos — quem decide é a geometria, como nas figuras de
     * composição: uma faixa que não contenha o próprio número fica sem ele.
     * Uma chave presente aqui restringe aos anos listados — para o trecho em
     * que o número seria verdadeiro só na aritmética, como os 100% do MinC
     * antes de a renúncia ser medida.
     */
    shareYears?: Record<string, number[]>;
    /** Altura da linha de um ano, antes da escala de impressão. */
    rowHeight?: number;
    /**
     * Largura intrínseca, em unidades de SVG. O tipo é absoluto nessas
     * unidades, então é isto que fixa o tamanho impresso dos rótulos — o cartão
     * inteiro escala para a largura física em que for colocado. Dimensionado
     * para a coluna de texto de um A4 retrato.
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
    anotacoes = [],
    anosDestacados = [],
    destaques = [],
    destaqueValueColor = cinza.titulo,
    plateau = 0.15,
    labelYears,
    shareYears,
    rowHeight = 22,
    width = 580,
    height,
    background,
    svgEl = $bindable(null),
  }: Props = $props();

  /**
   * Tudo abaixo é escrito contra `fontSize.md` e multiplicado por isto — tipo e
   * cromo juntos — para o cartão imprimir nos mesmos tamanhos das outras
   * figuras, qualquer que seja a largura em que for escrito.
   */
  const k = $derived(a4Scale(width));

  const type = $derived({
    title: 14 * k,
    subtitle: scale.md * k,
    /** Valor dos blocos da calha direita: a maior marca fora do plot. */
    destaque: 18 * k,
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
    /** Do bloco de título à faixa de pastilhas. */
    legendaGap: 13 * k,
    /** Da faixa de pastilhas ao primeiro ano. */
    legendaPlotGap: 16 * k,
    /** Do fim do plot às notas — não há eixo nem legenda entre os dois. */
    noteGap: 20 * k,
    noteSpacing: 3 * k,
    /** Da régua do tempo ao plot. */
    tickGap: 8 * k,
    /**
     * Bloco de destaque: valor grande, título e nota. As entrelinhas são as do
     * bloco de ponta das figuras de linha — curtas, porque as três linhas são
     * uma frase só sobre o mesmo ano.
     */
    endValueLine: 21 * k,
    endNameLine: 15 * k,
    endNoteLine: 13 * k,
    /** Vão mínimo entre dois blocos empilhados. */
    blockGap: 10 * k,
    /** Do plot à calha de blocos. */
    gutterGap: 18 * k,
    /**
     * Meio vão de superfície entre duas faixas vizinhas — o mesmo respiro que
     * separa os segmentos das figuras empilhadas. Aplicado só nas fronteiras
     * internas: contra a borda do plot a faixa corre inteira.
     */
    streamGap: 0.7 * k,
  });

  const cor = (index: number) => colors[index % colors.length];

  /**
   * Branco ou o ink escuro — o que render mais contraste sobre a faixa.
   *
   * A paleta tem faixas claras (os rosas da renúncia) e escuras (o roxo do FSA)
   * lado a lado, e o rótulo é escrito por dentro delas: decidir a cor do texto
   * por família de matiz erraria justamente nas pontas de cada rampa.
   */
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

  /**
   * A faixa de pastilhas, na ordem de empilhamento e encostadas umas nas
   * outras: lida da esquerda para a direita, ela é a ordem em que as faixas
   * entram no plot.
   */
  const legendaLayout = $derived(
    legenda
      ? layoutLegend(
          keys.map((key, i) => ({ label: labels[key] ?? key, color: cor(i) })),
          {
            fontSize: type.sm,
            fontWeight: 600,
            padX: 8 * k,
            maxWidth: textWidth,
            rowGap: 4 * k,
          },
        )
      : null,
  );

  const anos = $derived(data.map((d) => Number(d.label)));
  const valor = (row: AnoRow, key: string) => Number(row[key]) || 0;

  const totais = $derived(data.map((row) => keys.reduce((soma, key) => soma + valor(row, key), 0)));

  /**
   * As fronteiras acumuladas de um ano, normalizadas ao próprio total, em
   * pontos percentuais. Uma categoria zerada não é omitida como nas figuras de
   * coluna: a faixa dela precisa do ponto para se fechar em bico — `left` e
   * `right` coincidem, e é isso que desenha a entrada e a saída.
   */
  const fatias = $derived(
    data.map((row, i) => {
      const total = totais[i] || 1;
      let cursor = 0;
      return keys.map((key) => {
        const share = (valor(row, key) / total) * 100;
        const fatia = { left: cursor, right: cursor + share, share };
        cursor += share;
        return fatia;
      });
    }),
  );

  /**
   * Onde cada faixa escreve o próprio nome: um rótulo por trecho contínuo de
   * anos com execução, ancorado no ano em que a faixa está mais larga — que é
   * onde o nome tem mais chance de caber, e onde a categoria é assunto. Um
   * trecho cujos anos permitidos (`labelYears`) ficaram todos de fora não é
   * rotulado; a faixa de pastilhas o cobre.
   */
  const rotulos = $derived.by(() => {
    const out: { keyIndex: number; i: number }[] = [];

    keys.forEach((key, keyIndex) => {
      const permitidos = labelYears?.[key];
      let trecho: number[] = [];

      const fecha = () => {
        const candidatos = permitidos ? trecho.filter((i) => permitidos.includes(anos[i])) : trecho;
        if (candidatos.length) {
          const pico = candidatos.reduce((melhor, i) =>
            fatias[i][keyIndex].share > fatias[melhor][keyIndex].share ? i : melhor,
          );
          out.push({ keyIndex, i: pico });
        }
        trecho = [];
      };

      anos.forEach((_, i) => {
        if (fatias[i][keyIndex].share > 0) trecho.push(i);
        else fecha();
      });
      fecha();
    });

    return out;
  });

  /**
   * Folga entre o rótulo e as fronteiras da própria faixa, de cada lado.
   *
   * Curta de propósito, como nas figuras de coluna: o FSA vive numa faixa de
   * poucas unidades onde o próprio nome já mal cabe, e qualquer folga generosa
   * o apagaria. A folga é sobre cor chapada, e meio milímetro impresso basta.
   */
  const LABEL_PADDING = $derived(2 * k);

  /**
   * O rótulo escrito dentro da faixa, do mais completo que couber: nome com a
   * participação na mesma linha, depois só o nome, cada um em dois corpos.
   * Quando sobra só o nome, `comShare` avisa — e a participação desce para uma
   * segunda linha, se couber lá. Uma faixa em que nem o nome em `xs` cabe fica
   * sem rótulo, e é a pastilha do topo que a nomeia.
   */
  function escolheRotulo(nome: string, share: number, largura: number) {
    const completo = `${nome} · ${Math.round(share)}%`;
    const opcoes: [string, number, boolean][] = [
      [completo, type.sm, true],
      [completo, type.xs, true],
      [nome, type.sm, false],
      [nome, type.xs, false],
    ];
    for (const [texto, size, comShare] of opcoes) {
      if (measureLabel(texto, size, 700) <= largura) return { texto, size, comShare };
    }
    return null;
  }

  /**
   * A participação que uma faixa escreve num ano — ou `null`, quando ela não
   * cabe ou não vale: no ano do rótulo de nome (que já a traz consigo), sob
   * uma nota pousada na mesma faixa, fora dos anos de `shareYears`, ou
   * arredondando a zero.
   */
  function participacaoEm(keyIndex: number, i: number, largura: number) {
    const fatia = fatias[i][keyIndex];
    const rounded = Math.round(fatia.share);
    if (rounded < 1) return null;

    if (rotulos.some((r) => r.keyIndex === keyIndex && r.i === i)) return null;

    const notaEmCima = anotacoes.some(
      (a) => a.ano === anos[i] && fatia.left <= (a.x ?? 50) && (a.x ?? 50) <= fatia.right,
    );
    if (notaEmCima) return null;

    const permitidos = shareYears?.[keys[keyIndex]];
    if (permitidos && !permitidos.includes(anos[i])) return null;

    const texto = `${rounded}%`;
    return measureLabel(texto, type.xs, 600) <= largura ? texto : null;
  }

  /**
   * Largura da calha de blocos, medida no conteúdo com teto — a nota mais
   * larga, deixada solta, comeria um terço do plot. Passando do teto, é o
   * título ou a nota que quebra em duas linhas, não o plot que encolhe mais.
   */
  const GUTTER_MAX_RATIO = 0.26;

  const gutterWidth = $derived(
    destaques.length
      ? Math.min(
          Math.max(
            ...destaques.map((d) =>
              Math.max(
                d.valor ? measureLabel(d.valor, type.destaque, 700) : 0,
                measureLabel(d.titulo, type.md, 600),
                d.nota ? measureLabel(d.nota, type.sm, 400) : 0,
              ),
            ),
          ),
          width * GUTTER_MAX_RATIO,
        )
      : 0,
  );

  /** Anos com bloco: engrossam na régua do tempo. */
  const anosComBloco = $derived(new Set(destaques.map((d) => d.ano)));

  // --- a moldura -----------------------------------------------------------

  const cabecalho = $derived(
    12 * k + titleLines.length * L.titleLine + subtitleLines.length * L.subtitleLine,
  );
  const legendaY = $derived(cabecalho + L.legendaGap);
  const plotTop = $derived(
    legendaLayout ? legendaY + legendaLayout.height + L.legendaPlotGap : cabecalho + 12 * k,
  );
  const plotH = $derived(anos.length * rowHeight * k);
  const plotBottom = $derived(plotTop + plotH);

  // os 2k extras são o recuo do rótulo do ano, que cede lugar ao traço da régua
  const plotLeft = $derived(
    L.pad + measureLabel(String(anos[0] ?? ''), type.sm, 500) + L.tickGap + 2 * k,
  );
  const plotRight = $derived(
    width - L.pad - (destaques.length ? L.gutterGap + gutterWidth : 0),
  );

  const footTop = $derived(plotBottom + L.noteGap);
  const sourceTop = $derived(
    footTop + footnoteLines.length * L.notaLine + (footnoteLines.length ? L.noteSpacing : 0),
  );
  const altura = $derived(
    height ?? sourceTop + sourceLines.length * L.notaLine + L.pad,
  );

  const xScale = $derived(scaleLinear().domain([0, 100]).range([plotLeft, plotRight]));
  const yScale = $derived(
    scaleLinear()
      .domain([anos[0], anos[anos.length - 1]])
      .range([plotTop, plotBottom]),
  );

  type Ponto = { y: number; x0: number; x1: number };

  /**
   * `area` com o ano como parâmetro: a curva desce pelo tempo e as duas
   * fronteiras da faixa são interpoladas juntas, na mesma monotonia.
   */
  const faixaArea = area<Ponto>()
    .y((p) => p.y)
    .x0((p) => p.x0)
    .x1((p) => p.x1)
    .curve(curveBumpY);

  /**
   * Dois pontos por ano, nas bordas do platô: a largura fica plana sobre a
   * linha do ano e a transição corre só no vão entre dois platôs — sem isso,
   * uma categoria de um ano só vira uma elipse.
   */
  const pontosDe = $derived(
    (keyIndex: number): Ponto[] =>
      anos.flatMap((ano, i) => {
        const fatia = fatias[i][keyIndex];
        const esquerda = xScale(fatia.left);
        const direita = xScale(fatia.right);
        // o vão só nas fronteiras internas, e nunca maior que a meia largura:
        // uma faixa ausente fecha em bico exatamente sobre a própria fronteira
        const g = Math.min(L.streamGap, (direita - esquerda) / 2);
        const x0 = esquerda + (fatia.left > 1e-6 ? g : 0);
        const x1 = direita - (fatia.right < 100 - 1e-6 ? g : 0);
        // nas pontas da série o platô não atravessa a borda do plot
        const antes = i === 0 ? ano : ano - plateau;
        const depois = i === anos.length - 1 ? ano : ano + plateau;
        return [
          { y: yScale(antes), x0, x1 },
          { y: yScale(depois), x0, x1 },
        ];
      }),
  );

  /** Preso dentro do plot: um pico no primeiro ou no último ano poria o centro do rótulo sobre a borda. */
  const dentroDoPlot = $derived(
    (y: number, size: number) =>
      Math.min(Math.max(y, plotTop + size * 0.75), plotBottom - size * 0.75),
  );

  /**
   * Os blocos da calha, centrados na linha do seu ano e depois desempilhados —
   * o mesmo par de passes do bloco de ponta das figuras de linha: descendo
   * para abrir os vãos, voltando da base para nada sair do plot, e preservando
   * sempre a ordem, que é o que mantém cada bloco pertencendo ao seu ano.
   */
  const blocos = $derived.by(() => {
    const pendentes = destaques
      .map((d) => {
        const tituloLines = wrapText(d.titulo, type.md, gutterWidth, 600);
        const notaLines = wrapText(d.nota ?? '', type.sm, gutterWidth, 400);
        const altura =
          (d.valor ? L.endValueLine : 0) +
          tituloLines.length * L.endNameLine +
          notaLines.length * L.endNoteLine;
        return { ...d, tituloLines, notaLines, altura, ancoraY: yScale(d.ano) };
      })
      .sort((a, b) => a.ancoraY - b.ancoraY)
      .map((b) => ({ ...b, y: b.ancoraY - b.altura / 2 }));

    const n = pendentes.length;
    if (!n) return pendentes;

    for (let i = 1; i < n; i++) {
      pendentes[i].y = Math.max(
        pendentes[i].y,
        pendentes[i - 1].y + pendentes[i - 1].altura + L.blockGap,
      );
    }

    pendentes[n - 1].y = Math.min(pendentes[n - 1].y, plotBottom - pendentes[n - 1].altura);
    for (let i = n - 2; i >= 0; i--) {
      pendentes[i].y = Math.min(
        pendentes[i].y,
        pendentes[i + 1].y - pendentes[i].altura - L.blockGap,
      );
    }

    pendentes[0].y = Math.max(pendentes[0].y, plotTop);
    for (let i = 1; i < n; i++) {
      pendentes[i].y = Math.max(
        pendentes[i].y,
        pendentes[i - 1].y + pendentes[i - 1].altura + L.blockGap,
      );
    }

    return pendentes;
  });

  /**
   * A pastilha da legenda: as pontas de cada linha arredondadas em meia-cana e
   * as fronteiras internas retas, que é o que faz a faixa inteira ler como uma
   * barra segmentada — a mesma que o plot desenha logo abaixo.
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

  <!-- as faixas -->
  {#each keys as key, keyIndex (key)}
    <path d={faixaArea(pontosDe(keyIndex))} fill={cor(keyIndex)} />
  {/each}

  <!-- a participação escrita em toda faixa que a comporte, como nas figuras
       de composição: quem decide é a geometria, e o ano do rótulo de nome
       fica de fora porque o nome já a traz consigo -->
  {#each anos as ano, i (ano)}
    {#each keys as key, keyIndex (key)}
      {@const fatia = fatias[i][keyIndex]}
      {@const largura = xScale(fatia.right) - xScale(fatia.left) - LABEL_PADDING * 2}
      {@const texto = participacaoEm(keyIndex, i, largura)}
      {#if texto}
        <text
          x={xScale((fatia.left + fatia.right) / 2)}
          y={dentroDoPlot(yScale(ano), type.xs) + type.xs * 0.35}
          text-anchor="middle"
          font-size={type.xs}
          font-weight="600"
          fill={contraste(cor(keyIndex))}
          font-family={fontFamily}>{texto}</text
        >
      {/if}
    {/each}
  {/each}

  <!-- cada faixa se nomeia onde está mais larga; a cor reforça, não carrega -->
  {#each rotulos as rotulo (`${rotulo.keyIndex}-${rotulo.i}`)}
    {@const fatia = fatias[rotulo.i][rotulo.keyIndex]}
    {@const largura = xScale(fatia.right) - xScale(fatia.left) - LABEL_PADDING * 2}
    {@const nome = labels[keys[rotulo.keyIndex]] ?? keys[rotulo.keyIndex]}
    {@const fit = escolheRotulo(nome, fatia.share, largura)}
    {#if fit}
      {@const yRotulo = dentroDoPlot(yScale(anos[rotulo.i]), fit.size)}
      <text
        x={xScale((fatia.left + fatia.right) / 2)}
        y={yRotulo + fit.size * 0.35}
        text-anchor="middle"
        font-size={fit.size}
        font-weight="700"
        fill={contraste(cor(rotulo.keyIndex))}
        font-family={fontFamily}>{fit.texto}</text
      >
      <!-- quando a participação não coube ao lado do nome, ela desce uma
           linha: o número é bem mais estreito que o nome e cabe onde ele
           não coube -->
      {#if !fit.comShare && measureLabel(`${Math.round(fatia.share)}%`, type.xs, 600) <= largura}
        <text
          x={xScale((fatia.left + fatia.right) / 2)}
          y={Math.min(yRotulo + 12 * k, plotBottom - type.xs * 0.75) + type.xs * 0.35}
          text-anchor="middle"
          font-size={type.xs}
          font-weight="600"
          fill={contraste(cor(rotulo.keyIndex))}
          font-family={fontFamily}>{Math.round(fatia.share)}%</text
        >
      {/if}
    {/if}
  {/each}

  <!-- notas dentro do plot, na cor de contraste da faixa em que pousam -->
  {#each anotacoes as anotacao (anotacao.ano)}
    {@const i = anos.indexOf(anotacao.ano)}
    {#if i >= 0}
      {@const posX = anotacao.x ?? 50}
      {@const sob = fatias[i].findIndex((f) => f.share > 0 && f.left <= posX && f.right >= posX)}
      {@const tinta = sob >= 0 ? contraste(cor(sob)) : cinza.subtitulo}
      {@const yNota = yScale(anotacao.ano + (anotacao.dy ?? 0))}
      {#if anotacao.titulo}
        <text
          x={xScale(posX)}
          y={yNota - 7.5 * k + type.sm * 0.35}
          text-anchor="middle"
          font-size={type.sm}
          font-weight="700"
          fill={tinta}
          font-family={fontFamily}>{anotacao.titulo}</text
        >
      {/if}
      <text
        x={xScale(posX)}
        y={(anotacao.titulo ? yNota + 7.5 * k : yNota) + type.xs * 0.35}
        text-anchor="middle"
        font-size={type.xs}
        font-weight="500"
        fill={tinta}
        opacity="0.92"
        font-family={fontFamily}>{anotacao.texto}</text
      >
    {/if}
  {/each}

  <!-- a régua do tempo: todos os anos, um por linha, como no original; os
       anos que uma anotação destaca saem em negrito na régua e na calha.
       O traço curto liga o rótulo à faixa dele — é o par das linhas de
       fronteira riscadas sobre o mapa -->
  {#each anos as ano (ano)}
    {@const destacado = anosDestacados.includes(ano) || anosComBloco.has(ano)}
    {@const yAno = yScale(ano)}
    <line
      x1={plotLeft - L.tickGap + 2 * k}
      x2={plotLeft - 1.5 * k}
      y1={yAno}
      y2={yAno}
      stroke={cinza.regua}
      stroke-width={k}
    />
    <text
      x={plotLeft - L.tickGap - 2 * k}
      y={yAno + type.sm * 0.35}
      text-anchor="end"
      font-size={type.sm}
      font-weight={destacado ? 700 : 500}
      fill={destacado ? cinza.ano : cinza.anoFraco}
      font-family={fontFamily}>{ano}</text
    >
  {/each}

  <!-- blocos de leitura por ano: valor em destaque, título e nota -->
  {#each blocos as bloco (bloco.ano)}
    {@const xBloco = plotRight + L.gutterGap}
    {#if bloco.valor}
      <text
        x={xBloco}
        y={bloco.y + type.destaque * 0.82}
        font-size={type.destaque}
        font-weight="700"
        fill={destaqueValueColor}
        font-family={fontFamily}>{bloco.valor}</text
      >
    {/if}
    {#each bloco.tituloLines as linha, i (i)}
      <text
        x={xBloco}
        y={bloco.y + (bloco.valor ? L.endValueLine : 0) + (i + 0.8) * L.endNameLine}
        font-size={type.md}
        font-weight="600"
        fill={cinza.titulo}
        font-family={fontFamily}>{linha}</text
      >
    {/each}
    {#each bloco.notaLines as linha, i (i)}
      <text
        x={xBloco}
        y={bloco.y +
          (bloco.valor ? L.endValueLine : 0) +
          bloco.tituloLines.length * L.endNameLine +
          (i + 0.8) * L.endNoteLine}
        font-size={type.sm}
        font-weight="400"
        fill={cinza.bloco}
        font-family={fontFamily}>{linha}</text
      >
    {/each}
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
