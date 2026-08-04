<script lang="ts">
  /**
   * Evolução do investimento federal em cultura, 2003–2025.
   *
   * Combo de linhas e colunas num único eixo. A forma vem do formato da série,
   * não de gosto: das oito fontes originais, quatro existem em quatro anos ou
   * menos e duas em um único ano, então metade delas não é série temporal e não
   * pode virar linha. Agrupadas pelo que são institucionalmente sobram três —
   * duas contínuas, que viram linhas, e uma episódica, que vira coluna.
   *
   * As três leis de transferência (LAB 1, LPG, PNAB) nunca coexistem num mesmo
   * ano, então a coluna é uma série só e o rótulo acima diz qual lei a originou.
   */
  import { curveLinear, max, scaleBand, scaleLinear, type ScaleLinear } from 'd3';
  import {
    Axis,
    Bar,
    Chart,
    Circle,
    DefaultTheme,
    GridRows,
    LinePath,
    Text,
    getContrastColor,
    getPillarTheme,
    resolveThemeStyle,
    type ChartDimensions,
    type ChartTheme,
  } from 'sniic-design-system';
  import LegendChips from './LegendChips.svelte';
  import { fontFamily, fontSize, measureLabel, tickLabelProps } from './tokens';

  export type GrupoDatum = {
    label: string;
    origemTransferencia?: string;
    [serie: string]: string | number | undefined;
  };

  interface Props {
    data: GrupoDatum[];
    /** As duas séries contínuas, desenhadas como linhas. */
    linhas: string[];
    /** A série episódica, desenhada como colunas. */
    colunas: string[];
    labels?: Record<string, string>;
    /** Cores na ordem `[...linhas, ...colunas]`. */
    colors?: readonly string[];
    /** Faixa de anos sombreada ao fundo, com sua legenda. */
    destaque?: { de: string; ate: string; texto: string };
    width?: number;
    height?: number;
    responsive?: boolean;
    theme?: ChartTheme;
    pillar?: number;
    margin?: Partial<ChartDimensions['margin']>;
    valueFormat?: (v: number) => string;
    /** Rótulo do eixo y, escrito acima do primeiro tick. */
    unidade?: string;
    /** Colunas abaixo disto ficam sem rótulo — o número não caberia. */
    minRotuloColuna?: number;
    /** Largura da coluna como fração da banda do ano. */
    columnRatio?: number;
    /** Multiplica todo o texto, e as folgas medidas contra ele. Ver A4 nas stories. */
    fontScale?: number;
    /** Bindable — o `<svg>` renderizado, para `downloadSvg`. */
    svgEl?: SVGSVGElement | null;
  }

  let {
    data,
    linhas,
    colunas,
    labels = {},
    colors = ['#4271b5', '#ea662f', '#a44c7f'],
    destaque,
    width = 1000,
    height = 520,
    responsive = true,
    theme,
    pillar = 1,
    margin,
    valueFormat = (v: number) => String(v),
    unidade,
    minRotuloColuna = 0,
    columnRatio = 0.34,
    fontScale = 1,
    svgEl = $bindable(null),
  }: Props = $props();

  /** À direita cabem os rótulos diretos das linhas, que substituem a leitura pela legenda. */
  const MARGIN = $derived({
    top: 28 * fontScale,
    right: 132 * fontScale,
    bottom: 76 * fontScale,
    left: 52 * fontScale,
    ...margin,
  });

  const activeTheme = $derived(theme ?? getPillarTheme(pillar));
  const palette = $derived({
    ...DefaultTheme.palette,
    ...activeTheme.palette,
    base: { ...DefaultTheme.palette.base, ...activeTheme.palette?.base },
    neutral: { ...DefaultTheme.palette.neutral, ...activeTheme.palette?.neutral },
  });

  const labelStyle = $derived(
    resolveThemeStyle<ChartTheme, 'dataLabel'>(
      { fontSize: fontSize.md * fontScale, fontWeight: 600, fontFamily },
      activeTheme.dataLabel,
      DefaultTheme.dataLabel,
    )!,
  );

  const series = $derived([...linhas, ...colunas]);
  const cor = (serie: string) => colors[series.indexOf(serie) % colors.length];
  const nome = (serie: string) => labels[serie] ?? serie;

  const categories = $derived(data.map((d) => d.label));
  const valor = (row: GrupoDatum, serie: string) => Number(row[serie]) || 0;

  const yMax = $derived(
    max(data, (d) => max(series, (s) => valor(d, s)) ?? 0) ?? 1,
  );

  const legendItems = $derived(
    series.map((s) => ({ label: nome(s), color: cor(s) })),
  );

  /**
   * Uma série só entra na linha nos anos em que existe: a renúncia fiscal
   * começa em 2006, quando o SALIC passa a registrar o teto. Ligar o zero de
   * 2003 ao valor de 2006 desenharia uma rampa que não aconteceu.
   */
  const definido = (row: GrupoDatum, serie: string) => valor(row, serie) > 0;

  /** Último ano em que a série existe — onde vai o rótulo direto. */
  function ultimoPonto(serie: string) {
    for (let i = data.length - 1; i >= 0; i--) {
      if (definido(data[i], serie)) return { row: data[i], index: i };
    }
    return null;
  }

  /** Um ponto da linha, guardando o índice da banda em que ele cai. */
  type Ponto = { row: GrupoDatum; i: number };

  /** Ano de pico da série, anotado como o extremo da trajetória. */
  function pico(serie: string) {
    let melhor = 0;
    data.forEach((row, i) => {
      if (valor(row, serie) > valor(data[melhor], serie)) melhor = i;
    });
    return { row: data[melhor], index: melhor };
  }

  /**
   * A partir de onde escrever o rótulo de uma coluna.
   *
   * O natural é logo acima do topo dela, e em 2020 e 2022 é onde ele fica — a
   * coluna é a maior coisa do ano. Mas em 2023 a execução direta volta acima do
   * PNAB, e um rótulo colado no topo da coluna cairia em cima da linha. Quando
   * alguma linha invade a faixa que o rótulo ocuparia, ele sobe para acima dela.
   */
  function topoRotuloColuna(
    row: GrupoDatum,
    v: number,
    yScale: ScaleLinear<number, number>,
  ) {
    const topo = yScale(v);
    const alturaRotulo = 26 * fontScale;

    const invasoras = linhas
      .map((serie) => valor(row, serie))
      .filter((lv) => lv > 0)
      .map((lv) => yScale(lv))
      .filter((ly) => ly < topo && ly > topo - alturaRotulo);

    // subindo por causa de uma linha, o rótulo ainda precisa de folga sobre ela:
    // encostado, o traço da linha passaria dentro do texto
    return invasoras.length ? Math.min(...invasoras) - 7 * fontScale : topo;
  }

  /**
   * As duas linhas terminam a menos de R$ 0,1 bi uma da outra em 2025, então os
   * rótulos de ponta escritos na altura real da linha se sobrepõem. Cada um
   * ocupa duas linhas de texto, e aqui eles são empurrados para baixo até caber
   * — a ordem vertical das séries é preservada, que é o que o rótulo precisa
   * comunicar.
   */
  function rotulosFinais(yScale: ScaleLinear<number, number>) {
    const alturaRotulo = 30 * fontScale;

    const itens = linhas
      .map((serie) => {
        const fim = ultimoPonto(serie);
        return fim
          ? { serie, index: fim.index, y: yScale(valor(fim.row, serie)), valor: valor(fim.row, serie) }
          : null;
      })
      .filter((d) => d !== null)
      .sort((a, b) => a.y - b.y);

    for (let i = 1; i < itens.length; i++) {
      const minimo = itens[i - 1].y + alturaRotulo;
      if (itens[i].y < minimo) itens[i].y = minimo;
    }

    return itens;
  }
</script>

<Chart
  {width}
  {height}
  {responsive}
  theme={activeTheme}
  margin={MARGIN}
  ariaLabel="Evolução do investimento federal em cultura por fonte de recurso"
  role="img"
  bind:innerRef={svgEl}
>
  {#snippet children({ innerWidth, innerHeight }: ChartDimensions)}
    {@const xScale = scaleBand<string>()
      .domain(categories)
      .range([0, innerWidth])
      .paddingInner(0)
      .paddingOuter(0)}
    {@const yScale = scaleLinear()
      .domain([0, yMax * 1.12])
      .range([innerHeight, 0])
      .nice()}
    {@const banda = xScale.bandwidth()}
    {@const centro = (i: number) => (xScale(categories[i]) ?? 0) + banda / 2}
    {@const larguraColuna = banda * columnRatio}

    <GridRows
      scale={yScale}
      width={innerWidth}
      numTicks={5}
      stroke={palette.neutral[100]}
      strokeOpacity={0.5}
    />

    {#if destaque}
      {@const x1 = xScale(destaque.de) ?? 0}
      {@const x2 = (xScale(destaque.ate) ?? 0) + banda}
      <rect
        x={x1}
        y={0}
        width={x2 - x1}
        height={innerHeight}
        fill={palette.neutral[100]}
        fill-opacity={0.28}
      />
      <Text
        x={(x1 + x2) / 2}
        y={10 * fontScale}
        width={x2 - x1 - 8 * fontScale}
        textAnchor="middle"
        verticalAnchor="start"
        fontSize={fontSize.sm * fontScale}
        fontWeight={600}
        {fontFamily}
        fill={palette.neutral[200]}
        text={destaque.texto}
      />
    {/if}

    <!-- colunas primeiro: são o fundo contra o qual as linhas se leem -->
    {#each colunas as serie (serie)}
      {#each data as row, i (row.label)}
        {@const v = valor(row, serie)}
        {#if v > 0}
          <Bar
            x={centro(i) - larguraColuna / 2}
            y={yScale(v)}
            width={larguraColuna}
            height={innerHeight - yScale(v)}
            fill={cor(serie)}
            fillOpacity={0.9}
            rx={3}
          />
          {#if v >= minRotuloColuna}
            {@const topo = topoRotuloColuna(row, v, yScale)}
            {@const nomeColuna = row.origemTransferencia ?? nome(serie)}
            <!-- centrado sobre a coluna, exceto junto à borda direita: lá o
                 rótulo centrado entraria na calha dos rótulos de ponta, então
                 ele encosta na esquerda da coluna e cresce para dentro -->
            {@const larguraRotulo = Math.max(
              measureLabel(nomeColuna, fontSize.sm * fontScale, 700),
              measureLabel(valueFormat(v), fontSize.sm * fontScale, 500),
            )}
            {@const naBorda = centro(i) + larguraRotulo / 2 > innerWidth}
            {@const xRotulo = naBorda
              ? centro(i) - larguraColuna / 2 - 4 * fontScale
              : centro(i)}
            {@const ancora = naBorda ? 'end' : 'middle'}
            <!-- as folgas são medidas contra o corpo do texto, não fixas: o
                 rótulo é centrado verticalmente e desce metade da altura da
                 linha, então -3 encostava no topo da coluna em escala de
                 impressão -->
            <Text
              x={xRotulo}
              y={topo - 26 * fontScale}
              textAnchor={ancora}
              verticalAnchor="middle"
              fontSize={fontSize.sm * fontScale}
              fontWeight={700}
              {fontFamily}
              fill={cor(serie)}
              text={nomeColuna}
            />
            <Text
              x={xRotulo}
              y={topo - 12 * fontScale}
              textAnchor={ancora}
              verticalAnchor="middle"
              fontSize={fontSize.sm * fontScale}
              fontWeight={500}
              {fontFamily}
              fill={palette.neutral[200]}
              text={valueFormat(v)}
            />
          {/if}
        {/if}
      {/each}
    {/each}

    {#each linhas as serie (serie)}
      {@const pontos = data
        .map((row, i) => ({ row, i }))
        .filter(({ row }) => definido(row, serie))}
      <!-- linear, não suavizada: a observação é anual e discreta, e uma curva
           desenharia valores intermediários que não existem -->
      <LinePath
        data={pontos}
        x={(p: Ponto) => centro(p.i)}
        y={(p: Ponto) => yScale(valor(p.row, serie))}
        curve={curveLinear}
        stroke={cor(serie)}
        strokeWidth={2.5 * fontScale}
        fill="none"
      />
      {#each pontos as p (p.row.label)}
        <Circle
          x={centro(p.i)}
          y={yScale(valor(p.row, serie))}
          size={3.2 * fontScale}
          fill={cor(serie)}
        />
      {/each}
    {/each}

    <!-- rótulos diretos: cada linha se identifica na própria ponta, e a legenda
         abaixo fica como reforço, não como única chave de leitura -->
    {#each rotulosFinais(yScale) as rotulo (rotulo.serie)}
      {@const x = centro(rotulo.index) + 10 * fontScale}
      {@const yLinha = yScale(rotulo.valor)}
      <!-- deslocado da linha para não colidir com a outra ponta: o traço
           reconecta o rótulo ao ponto de onde ele saiu -->
      {#if Math.abs(rotulo.y - yLinha) > 2}
        <path
          d={`M${centro(rotulo.index) + 4 * fontScale},${yLinha} L${x - 2 * fontScale},${rotulo.y}`}
          stroke={cor(rotulo.serie)}
          stroke-width={1}
          stroke-opacity={0.6}
          fill="none"
        />
      {/if}
      <Text
        {x}
        y={rotulo.y - 7 * fontScale}
        textAnchor="start"
        verticalAnchor="middle"
        fontSize={fontSize.sm * fontScale}
        fontWeight={700}
        {fontFamily}
        fill={cor(rotulo.serie)}
        text={nome(rotulo.serie)}
      />
      <Text
        {x}
        y={rotulo.y + 7 * fontScale}
        textAnchor="start"
        verticalAnchor="middle"
        fontSize={fontSize.sm * fontScale}
        fontWeight={500}
        {fontFamily}
        fill={palette.neutral[200]}
        text={valueFormat(rotulo.valor)}
      />
    {/each}

    <!-- o pico da primeira linha: o extremo da série, que os rótulos de ponta
         não alcançam -->
    {#each linhas.slice(0, 1) as serie (serie)}
      {@const p = pico(serie)}
      {@const rotulo = `${valueFormat(valor(p.row, serie))} · ${p.row.label}`}
      <Text
        x={centro(p.index) - measureLabel(rotulo, fontSize.sm * fontScale, 600) / 2}
        y={yScale(valor(p.row, serie)) - 14 * fontScale}
        textAnchor="start"
        verticalAnchor="middle"
        fontSize={fontSize.sm * fontScale}
        fontWeight={600}
        {fontFamily}
        fill={cor(serie)}
        text={rotulo}
      />
    {/each}

    <Axis
      orientation="left"
      scale={yScale}
      numTicks={5}
      hideAxisLine
      hideTicks
      tickFormat={(v: number) => valueFormat(Number(v))}
      tickLabelProps={tickLabelProps(palette.neutral[200], fontSize.sm * fontScale)}
    />

    {#if unidade}
      <Text
        x={-MARGIN.left}
        y={-12 * fontScale}
        textAnchor="start"
        verticalAnchor="middle"
        fontSize={fontSize.sm * fontScale}
        fontWeight={500}
        {fontFamily}
        fill={palette.neutral[200]}
        text={unidade}
      />
    {/if}

    <Axis
      orientation="bottom"
      scale={xScale}
      top={innerHeight}
      hideTicks
      stroke={palette.neutral[100]}
      tickLabelProps={tickLabelProps(palette.neutral[200], fontSize.sm * fontScale)}
    />

    <LegendChips
      items={legendItems}
      left={0}
      top={innerHeight + 44 * fontScale}
      padX={10 * fontScale}
      fontSize={fontSize.sm * fontScale}
      fontFamily={labelStyle.fontFamily}
      fontWeight={600}
      radius={4}
    />
  {/snippet}
</Chart>
