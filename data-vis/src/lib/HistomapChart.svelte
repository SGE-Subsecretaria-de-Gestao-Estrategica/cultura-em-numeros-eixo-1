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
   * É a mesma pergunta do `ComposicaoAnualChart` — de onde veio cada real — com
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
   * A identidade das faixas é carregada pelo nome escrito dentro delas, no ano
   * em que cada uma está mais larga — como no original, onde a legenda é o
   * próprio mapa. E é só ele: não há faixa de pastilhas, porque uma legenda
   * embaixo pediria ao leitor sair do mapa para nomear o que o mapa já nomeia.
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
   */
  import { area, curveBumpY, scaleLinear } from 'd3';
  import {
    Chart,
    DefaultTheme,
    getContrastColor,
    getPillarTheme,
    resolveThemeStyle,
    Text,
    type ChartDimensions,
    type ChartTheme,
  } from 'sniic-design-system';
  import TextLines from './TextLines.svelte';
  import { categoricaMarca, sniic } from './cores';
  import { a4Scale, fontFamily, fontSize as scale, measureLabel, wrapText } from './tokens';

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
   * mesmo bloco da ponta das linhas do `SerieHistoricaChart`: o valor em
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

  interface Props {
    data: AnoRow[];
    /** Categorias na ordem em que empilham, da esquerda para a direita. */
    keys: string[];
    labels?: Record<string, string>;
    /** Cores na ordem de `keys`; por omissão, a paleta categórica da marca. */
    colors?: readonly string[];
    title: string;
    subtitle?: string;
    footnote?: string;
    source?: string;
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
    /** Cor do valor em destaque dos blocos. */
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
    /** Re-diagrama na largura do contêiner em vez de escalar o cartão. */
    responsive?: boolean;
    /** Paleta do pilar com que o gráfico é tematizado — Eixo 1. */
    pillar?: number;
    /** `null` remove o cartão (fundo e borda), para exportar sobre a página. */
    background?: string | null;
    /** Bindable — o `<svg>` renderizado, para `downloadSvg`. */
    svgEl?: SVGSVGElement | null;
  }

  let {
    data,
    keys,
    labels = {},
    colors = categoricaMarca,
    title,
    subtitle,
    footnote,
    source,
    anotacoes = [],
    anosDestacados = [],
    destaques = [],
    destaqueValueColor = sniic.azul,
    plateau = 0.15,
    labelYears,
    shareYears,
    rowHeight = 22,
    width = 1368,
    height,
    responsive = false,
    pillar = 1,
    background,
    svgEl = $bindable(null),
  }: Props = $props();

  /**
   * Tudo abaixo é escrito contra `fontSize.md` e multiplicado por isto — tipo e
   * cromo juntos — para o cartão imprimir nos mesmos tamanhos das outras
   * figuras, qualquer que seja a largura em que for escrito.
   */
  const k = $derived(a4Scale(width));

  const TITLE_FONT_SIZE = 14;

  const type = $derived({
    title: TITLE_FONT_SIZE * k,
    /** Valor dos blocos da calha direita: a maior marca fora do plot. */
    destaque: 18 * k,
    md: scale.md * k,
    sm: scale.sm * k,
    xs: scale.xs * k,
  });

  const theme = $derived(getPillarTheme(pillar));
  const palette = $derived(theme.palette);

  const categoriaColor = (index: number) => colors[index % colors.length];

  const L = $derived({
    cardPadding: 24 * k,
    cardRadius: 12 * k,
    titleLine: 24 * k,
    subtitleLine: 15 * k,
    noteLine: 14 * k,
    titleBlockGap: 26 * k,
    /** Do fim do plot às notas — não há eixo nem legenda entre os dois. */
    noteGap: 24 * k,
    noteSpacing: 3 * k,
    /** Das calhas laterais ao plot. */
    tickGap: 8 * k,
    /**
     * Bloco de destaque: valor grande, título e nota. As entrelinhas são as do
     * bloco de ponta do `SerieHistoricaChart` — curtas, porque as três linhas
     * são uma frase só sobre o mesmo ano.
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

  const titleStyle = $derived(
    resolveThemeStyle<ChartTheme, 'text'>(
      { fontSize: type.title, fontWeight: 600, fill: palette.neutral[300], fontFamily },
      theme.text,
      DefaultTheme.text,
    )!,
  );
  const subtitleStyle = $derived(
    resolveThemeStyle<ChartTheme, 'text'>(
      { fontSize: type.md, fill: palette.neutral[200], fontFamily },
      theme.text,
      DefaultTheme.text,
    )!,
  );
  const noteStyle = $derived(
    resolveThemeStyle<ChartTheme, 'text'>(
      { fontSize: type.sm, fontWeight: 400, fill: palette.neutral[100], fontFamily },
      theme.text,
      DefaultTheme.text,
    )!,
  );
  const textWidth = $derived(width - L.cardPadding * 2);
  const titleLines = $derived(
    wrapText(title, type.title, textWidth, Number(titleStyle.fontWeight)),
  );
  const subtitleLines = $derived(
    wrapText(subtitle ?? '', type.md, textWidth, Number(subtitleStyle.fontWeight)),
  );
  const footnoteLines = $derived(wrapText(footnote ?? '', type.sm, textWidth));
  const sourceLines = $derived(wrapText(source ?? '', type.sm, textWidth));

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
   * rotulado; a legenda o cobre.
   */
  const rotulos = $derived.by(() => {
    const out: { keyIndex: number; i: number }[] = [];

    keys.forEach((key, keyIndex) => {
      const permitidos = labelYears?.[key];
      let trecho: number[] = [];

      const fecha = () => {
        const candidatos = permitidos
          ? trecho.filter((i) => permitidos.includes(anos[i]))
          : trecho;
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
   * Curta de propósito, como nas figuras de coluna: sem legenda, um rótulo que
   * não sai é uma faixa que ninguém consegue nomear — o FSA vive numa faixa de
   * ~50 unidades onde o próprio nome mede 36, e qualquer folga generosa o
   * apagaria. A folga é sobre cor chapada, e meio milímetro impresso basta.
   */
  const LABEL_PADDING = $derived(2 * k);

  /**
   * O rótulo escrito dentro da faixa, do mais completo que couber: nome com a
   * participação na mesma linha, depois só o nome, cada um em dois corpos.
   * Quando sobra só o nome, `comShare` avisa — e a participação desce para uma
   * segunda linha, se couber lá. Uma faixa em que nem o nome em `xs` cabe fica
   * sem rótulo.
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
                d.valor ? measureLabel(d.valor, type.destaque, 600) : 0,
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

  /**
   * Os blocos da calha, centrados na linha do seu ano e depois desempilhados —
   * o mesmo par de passes do bloco de ponta do `SerieHistoricaChart`: descendo
   * para abrir os vãos, voltando da base para nada sair do plot, e preservando
   * sempre a ordem, que é o que mantém cada bloco pertencendo ao seu ano.
   */
  function blocosDeAno(yScale: (ano: number) => number, innerHeight: number) {
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

    pendentes[n - 1].y = Math.min(pendentes[n - 1].y, innerHeight - pendentes[n - 1].altura);
    for (let i = n - 2; i >= 0; i--) {
      pendentes[i].y = Math.min(
        pendentes[i].y,
        pendentes[i + 1].y - pendentes[i].altura - L.blockGap,
      );
    }

    pendentes[0].y = Math.max(pendentes[0].y, 0);
    for (let i = 1; i < n; i++) {
      pendentes[i].y = Math.max(
        pendentes[i].y,
        pendentes[i - 1].y + pendentes[i - 1].altura + L.blockGap,
      );
    }

    return pendentes;
  }

  const MARGIN = $derived({
    // os 2k extras são o recuo do rótulo do ano, que cede lugar ao traço da régua
    left:
      L.cardPadding +
      measureLabel(String(anos[anos.length - 1] ?? ''), type.sm, 500) +
      L.tickGap +
      2 * k,
    right: L.cardPadding + (destaques.length ? L.gutterGap + gutterWidth : 0),
    top:
      L.cardPadding +
      titleLines.length * L.titleLine +
      subtitleLines.length * L.subtitleLine +
      L.titleBlockGap,
    bottom:
      L.noteGap +
      footnoteLines.length * L.noteLine +
      (footnoteLines.length && sourceLines.length ? L.noteSpacing : 0) +
      sourceLines.length * L.noteLine +
      L.cardPadding,
  });

  const plotHeight = $derived(anos.length * rowHeight * k);
  const cardHeight = $derived(height ?? MARGIN.top + plotHeight + MARGIN.bottom);

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
</script>

<Chart
  {fontFamily}
  {responsive}
  {width}
  height={cardHeight}
  {theme}
  margin={MARGIN}
  ariaLabel={title}
  role="img"
  bind:innerRef={svgEl}
>
  {#snippet children({ width: cardWidth, innerWidth, innerHeight, margin }: ChartDimensions)}
    {@const xScale = scaleLinear().domain([0, 100]).range([0, innerWidth])}
    {@const yScale = scaleLinear()
      .domain([anos[0], anos[anos.length - 1]])
      .range([0, innerHeight])}
    {@const cardLeft = -margin.left + L.cardPadding}
    <!-- dois pontos por ano, nas bordas do platô: a largura fica plana sobre a
         linha do ano e a transição corre só no vão entre dois platôs — sem
         isso, uma categoria de um ano só vira uma elipse -->
    {@const pontosDe = (keyIndex: number): Ponto[] =>
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
      })}

    {#if background !== null}
      <rect
        x={-margin.left}
        y={-margin.top}
        width={cardWidth}
        height={cardHeight}
        rx={L.cardRadius}
        fill={background ?? palette.base[100]}
        stroke={palette.base[300]}
        stroke-width={k}
      />
    {/if}

    <TextLines
      lines={titleLines}
      x={cardLeft}
      y={-margin.top + L.cardPadding}
      lineHeight={L.titleLine}
      fontSize={titleStyle.fontSize}
      fontWeight={titleStyle.fontWeight}
      fontFamily={titleStyle.fontFamily}
      fill={titleStyle.fill}
    />

    <TextLines
      lines={subtitleLines}
      x={cardLeft}
      y={-margin.top + L.cardPadding + titleLines.length * L.titleLine}
      lineHeight={L.subtitleLine}
      fontSize={subtitleStyle.fontSize}
      fontWeight={subtitleStyle.fontWeight}
      fontFamily={subtitleStyle.fontFamily}
      fill={subtitleStyle.fill}
    />

    {#each keys as key, keyIndex (key)}
      <path d={faixaArea(pontosDe(keyIndex))} fill={categoriaColor(keyIndex)} />
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
          <!-- preso dentro do plot, como os rótulos de nome: no primeiro e no
               último ano o centro da banda é a própria borda -->
          <Text
            x={xScale((fatia.left + fatia.right) / 2)}
            y={Math.min(
              Math.max(yScale(ano), type.xs * 0.75),
              innerHeight - type.xs * 0.75,
            )}
            textAnchor="middle"
            verticalAnchor="middle"
            fontSize={type.xs}
            fontWeight={600}
            {fontFamily}
            fill={getContrastColor(categoriaColor(keyIndex))}
            text={texto}
          />
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
        <!-- preso dentro do plot: um pico no primeiro ou no último ano poria o
             centro do rótulo exatamente sobre a borda, cortando-o ao meio -->
        {@const yRotulo = Math.min(
          Math.max(yScale(anos[rotulo.i]), fit.size * 0.75),
          innerHeight - fit.size * 0.75,
        )}
        <Text
          x={xScale((fatia.left + fatia.right) / 2)}
          y={yRotulo}
          textAnchor="middle"
          verticalAnchor="middle"
          fontSize={fit.size}
          fontWeight={700}
          {fontFamily}
          fill={getContrastColor(categoriaColor(rotulo.keyIndex))}
          text={fit.texto}
        />
        <!-- quando a participação não coube ao lado do nome, ela desce uma
             linha: o número é bem mais estreito que o nome e cabe onde ele
             não coube -->
        {#if !fit.comShare && measureLabel(`${Math.round(fatia.share)}%`, type.xs, 600) <= largura}
          <Text
            x={xScale((fatia.left + fatia.right) / 2)}
            y={Math.min(yRotulo + 12 * k, innerHeight - type.xs * 0.75)}
            textAnchor="middle"
            verticalAnchor="middle"
            fontSize={type.xs}
            fontWeight={600}
            {fontFamily}
            fill={getContrastColor(categoriaColor(rotulo.keyIndex))}
            text={`${Math.round(fatia.share)}%`}
          />
        {/if}
      {/if}
    {/each}

    <!-- notas dentro do plot, na cor de contraste da faixa em que pousam -->
    {#each anotacoes as anotacao (anotacao.ano)}
      {@const i = anos.indexOf(anotacao.ano)}
      {#if i >= 0}
        {@const posX = anotacao.x ?? 50}
        {@const sob = fatias[i].findIndex(
          (f) => f.share > 0 && f.left <= posX && f.right >= posX,
        )}
        {@const cor = sob >= 0 ? getContrastColor(categoriaColor(sob)) : palette.neutral[200]}
        {@const yNota = yScale(anotacao.ano + (anotacao.dy ?? 0))}
        {#if anotacao.titulo}
          <Text
            x={xScale(posX)}
            y={yNota - 7.5 * k}
            textAnchor="middle"
            verticalAnchor="middle"
            fontSize={type.sm}
            fontWeight={700}
            {fontFamily}
            fill={cor}
            text={anotacao.titulo}
          />
        {/if}
        <Text
          x={xScale(posX)}
          y={anotacao.titulo ? yNota + 7.5 * k : yNota}
          textAnchor="middle"
          verticalAnchor="middle"
          fontSize={type.xs}
          fontWeight={500}
          {fontFamily}
          fill={cor}
          opacity={0.92}
          text={anotacao.texto}
        />
      {/if}
    {/each}

    <!-- a régua do tempo: todos os anos, um por linha, como no original; os
         anos que uma anotação destaca saem em negrito na régua e na calha.
         O traço curto liga o rótulo à banda dele — é o par das linhas de
         fronteira riscadas sobre o mapa -->
    {#each anos as ano (ano)}
      {@const destacado = anosDestacados.includes(ano) || anosComBloco.has(ano)}
      {@const yAno = yScale(ano)}
      <line
        x1={-L.tickGap + 2 * k}
        x2={-1.5 * k}
        y1={yAno}
        y2={yAno}
        stroke={palette.neutral[100]}
        stroke-width={k}
      />
      <Text
        x={-L.tickGap - 2 * k}
        y={yAno}
        textAnchor="end"
        verticalAnchor="middle"
        fontSize={type.sm}
        fontWeight={destacado ? 700 : 500}
        {fontFamily}
        fill={destacado ? palette.neutral[300] : palette.neutral[200]}
        text={String(ano)}
      />
    {/each}

    <!-- blocos de leitura por ano, no estilo do bloco de ponta da figura do
         tripé institucional: valor em destaque, título e nota -->
    {#if destaques.length}
      {@const xBloco = innerWidth + L.gutterGap}
      {#each blocosDeAno((ano) => yScale(ano), innerHeight) as bloco (bloco.ano)}
        {#if bloco.valor}
          <Text
            x={xBloco}
            y={bloco.y}
            textAnchor="start"
            verticalAnchor="start"
            fontSize={type.destaque}
            fontWeight={600}
            {fontFamily}
            fill={destaqueValueColor}
            text={bloco.valor}
          />
        {/if}
        <TextLines
          lines={bloco.tituloLines}
          x={xBloco}
          y={bloco.y + (bloco.valor ? L.endValueLine : 0)}
          lineHeight={L.endNameLine}
          fontSize={type.md}
          fontWeight={600}
          {fontFamily}
          fill={palette.neutral[300]}
        />
        <TextLines
          lines={bloco.notaLines}
          x={xBloco}
          y={bloco.y +
            (bloco.valor ? L.endValueLine : 0) +
            bloco.tituloLines.length * L.endNameLine}
          lineHeight={L.endNoteLine}
          fontSize={type.sm}
          fontWeight={400}
          {fontFamily}
          fill={palette.neutral[300]}
        />
      {/each}
    {/if}

    {@const notesTop = innerHeight + L.noteGap}

    <TextLines
      lines={footnoteLines}
      x={cardLeft}
      y={notesTop}
      lineHeight={L.noteLine}
      fontSize={noteStyle.fontSize}
      fontWeight={noteStyle.fontWeight}
      fontFamily={noteStyle.fontFamily}
      fill={noteStyle.fill}
    />

    <TextLines
      lines={sourceLines}
      x={cardLeft}
      y={notesTop + footnoteLines.length * L.noteLine + (footnoteLines.length ? L.noteSpacing : 0)}
      lineHeight={L.noteLine}
      fontSize={noteStyle.fontSize}
      fontWeight={noteStyle.fontWeight}
      fontFamily={noteStyle.fontFamily}
      fill={noteStyle.fill}
    />
  {/snippet}
</Chart>
