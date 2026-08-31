<script lang="ts" module>
  export type ValorUf = { uf: string; valor: number };
  /** Um município da malha projetada: código, sigla da UF e o caminho. */
  export type Municipio = { c: string; uf: string; d: string };
</script>

<script lang="ts">
  /**
   * Um coroplético por unidade federativa, sobre a malha do IBGE.
   *
   * A geografia é a de verdade, e não a malha hexagonal das outras figuras
   * territoriais: quando o dado é uma contagem por estado e o leitor precisa
   * reconhecer o país, o contorno faz mais trabalho que o esquema. A projeção é
   * cônica equivalente de Albers com os paralelos do Brasil — num coroplético a
   * área pintada é o peso visual de cada estado, então ela tem de ser a área do
   * estado.
   *
   * O valor entra por classes, não por escala contínua: cinco degraus da mesma
   * rampa, do mais claro ao mais escuro. Uma rampa contínua pediria ao leitor
   * distinguir tons vizinhos a olho e ainda assim daria as classes de volta na
   * legenda; com cinco, cada estado tem uma resposta que se lê sem consulta, e a
   * ordem se enxerga mesmo impressa em escala de cinza.
   *
   * Cada estado carrega a sigla e o número dentro de si quando cabem — a medida
   * é o raio do maior círculo inscrito, que vem da malha pronta. Os oito que não
   * comportam texto (os do litoral do Nordeste, o Rio, o Espírito Santo e o
   * Distrito Federal) recebem o rótulo na calha à direita, ligado por uma linha
   * fina, empilhados na ordem em que aparecem de norte a sul para que as linhas
   * não se cruzem.
   *
   * O que a figura não diz, e nenhum coroplético de contagem diz: cobertura. Uma
   * cor escura significa muitos agentes, não muitos agentes por habitante nem
   * por município — e o estado grande e claro chama mais atenção que o pequeno e
   * escuro só por ser grande. É o custo do formato, e a nota de rodapé o assume.
   */
  import malha from '../data/malha-ufs.json';
  import { a4Scale, fontFamily, fontSize as scale, measureLabel, wrapText } from './tokens';

  let {
    valores,
    mosaico,
    rampa,
    quebras,
    rotulosClasses,
    title,
    subtitle,
    legendaTitulo,
    formatValue = (v: number) => String(v),
    destaque,
    footnote,
    source,
    width = 580,
    svgEl = $bindable(null),
    background = null,
  }: {
    valores: ValorUf[];
    /**
     * A malha municipal projetada, quando a figura quer desenhar os 5 570
     * municípios em vez das 27 UFs. O valor continua sendo o da UF — o que o
     * mosaico acrescenta é o denominador à vista: quantas unidades cabem em cada
     * estado. Sem ela, cada UF é uma mancha só.
     */
    mosaico?: Municipio[];
    /** Do mais claro ao mais escuro; precisa de `quebras.length + 1` degraus. */
    rampa: readonly string[];
    /** Os limites inferiores das classes acima da primeira: `[10, 20, 30, 50]`. */
    quebras: number[];
    /** Um rótulo por classe. Sem eles, a legenda escreve as faixas dos números. */
    rotulosClasses?: string[];
    title: string;
    subtitle?: string;
    legendaTitulo?: string;
    formatValue?: (v: number) => string;
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
    legendaTitulo: scale.sm * k,
    legenda: scale.sm * k,
    sigla: scale.sm * k,
    valor: 13 * k,
    chamada: scale.sm * k,
    destaqueValor: 19 * k,
    destaqueTexto: scale.md * k,
    nota: scale.sm * k,
  };

  const cinza = {
    titulo: '#2F2F2B',
    subtitulo: '#6E6E68',
    dado: '#3F3F3B',
    legenda: '#8A8A84',
    nota: '#8A8A84',
    /** O traço entre estados, por cima dos preenchimentos. */
    divisa: '#FFFFFF',
    chamada: '#9A9A94',
  };

  const pad = 16 * k;

  /** A calha à direita do mapa, onde ficam os rótulos que não couberam dentro. */
  const calha = 84 * k;

  const mapaLargura = $derived(width - pad * 2 - calha);
  /** Domínio da malha → unidades do cartão. */
  const km = $derived(mapaLargura / malha.largura);
  /** Unidades do cartão → domínio da malha, para o texto desenhado dentro dele. */
  const dom = $derived((v: number) => v / km);

  const porUf = $derived(new Map(valores.map((v) => [v.uf, v.valor])));

  const classeDe = (v: number) => quebras.filter((q) => v >= q).length;
  const corDe = (v: number | undefined) => (v === undefined ? '#EDEDE8' : rampa[classeDe(v)]);

  /**
   * Preto ou branco sobre o preenchimento, pelo contraste de fato.
   *
   * A rampa vai do claro ao escuro e o ponto de virada muda com a matiz, então
   * fixar "os dois últimos degraus levam branco" quebraria na primeira figura
   * que trocasse de família.
   */
  const luminancia = (hex: string) => {
    const canal = (i: number) => {
      const v = parseInt(hex.slice(1 + i * 2, 3 + i * 2), 16) / 255;
      return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4;
    };
    return 0.2126 * canal(0) + 0.7152 * canal(1) + 0.0722 * canal(2);
  };
  const contraste = (a: number, b: number) =>
    (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05);
  const corDoTexto = (fundo: string) => {
    const l = luminancia(fundo);
    return contraste(l, 1) >= contraste(l, luminancia(cinza.titulo)) ? '#FFFFFF' : cinza.titulo;
  };

  /**
   * O bloco de duas linhas — sigla e número — cabe no estado se couber no maior
   * círculo que cabe nele. `folga` é o raio desse círculo, calculado uma vez na
   * preparação da malha.
   *
   * O `0,85` desconta o que o círculo inscrito tem de pessimista: ele é o que
   * cabe no pior sentido, e o texto é largo e baixo. Sem ele o Acre e Santa
   * Catarina — que comportam o rótulo com sobra visível — iriam para a calha
   * por dois décimos de unidade, e as linhas de chamada deles atravessariam o
   * mapa inteiro.
   */
  const blocoInterno = $derived.by(() => {
    const alturaBloco = dom(type.sigla + type.valor + 2 * k);
    return (uf: string, valor: number) => {
      const larguraBloco = Math.max(
        dom(measureLabel(uf, type.sigla, 600)),
        dom(measureLabel(formatValue(valor), type.valor, 700)),
      );
      return 0.85 * Math.hypot(larguraBloco / 2, alturaBloco / 2);
    };
  });

  type Estado = {
    uf: string;
    d: string;
    valor: number | undefined;
    cor: string;
    ancora: [number, number];
    dentro: boolean;
  };

  const estados: Estado[] = $derived(
    malha.ufs.map((u) => {
      const valor = porUf.get(u.uf);
      return {
        uf: u.uf,
        d: u.d,
        valor,
        cor: corDe(valor),
        ancora: u.rotulo as [number, number],
        dentro: valor !== undefined && u.folga >= blocoInterno(u.uf, valor),
      };
    }),
  );

  const textWidth = $derived(width - pad * 2);
  const titleLines = $derived(wrapText(title, type.title, textWidth, 600));
  const subtitleLines = $derived(wrapText(subtitle ?? '', type.subtitle, textWidth));
  const footnoteLines = $derived(wrapText(footnote ?? '', type.nota, textWidth));
  const sourceLines = $derived(wrapText(source ?? '', type.nota, textWidth));

  const titleLine = 19 * k;
  const subtitleLine = 15 * k;
  const notaLine = 13.5 * k;

  /** A legenda é uma faixa contínua de degraus, entre o subtítulo e o mapa. */
  const legendaTitle = $derived(legendaTitulo ? 19 * k : 6 * k);
  const legendaTop = $derived(
    12 * k + titleLines.length * titleLine + subtitleLines.length * subtitleLine + legendaTitle,
  );
  const faixaAltura = 9 * k;
  const rotulos = $derived(
    rotulosClasses ??
      quebras.map((q, i) =>
        i === 0
          ? `menos de ${formatValue(q)}`
          : `${formatValue(quebras[i - 1])} a ${formatValue(q - 1)}`,
      ).concat(`${formatValue(quebras.at(-1)!)} ou mais`),
  );
  const passo = $derived(
    Math.max(...rotulos.map((r) => measureLabel(r, type.legenda, 500))) + 12 * k,
  );

  const mapaTop = $derived(legendaTop + faixaAltura + 20 * k);
  const mapaAltura = $derived(malha.altura * km);

  /**
   * Os rótulos que não couberam dentro do estado, na calha: cada um na altura da
   * sua âncora, empurrados para baixo só o suficiente para não se encostarem. A
   * ordem é a do norte para o sul, então as linhas de chamada não se cruzam.
   */
  const chamadaLinha = $derived(type.chamada * 1.5);
  const chamadas = $derived.by(() => {
    const fora = estados
      .filter((e) => !e.dentro && e.valor !== undefined)
      .sort((a, b) => a.ancora[1] - b.ancora[1]);

    let ultimo = -Infinity;
    return fora.map((e) => {
      const y = Math.max(e.ancora[1] * km, ultimo + chamadaLinha);
      ultimo = y;
      return { uf: e.uf, valor: e.valor!, y, ax: e.ancora[0] * km, ay: e.ancora[1] * km };
    });
  });

  const calhaX = $derived(pad + mapaLargura + 9 * k);

  /** O destaque ocupa o vazio a sudoeste do mapa — Pacífico, Bolívia, Argentina. */
  const DESTAQUE = { x: 14, y: 812, largura: 258 };
  const destaqueLinhas = $derived(
    destaque ? wrapText(destaque.texto, type.destaqueTexto, DESTAQUE.largura * km, 500) : [],
  );

  const notasTop = $derived(mapaTop + mapaAltura + 10 * k);
  const height = $derived(
    notasTop + (footnoteLines.length + sourceLines.length) * notaLine + pad,
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

  <!-- legenda: os degraus encostados, na ordem, com a faixa de cada um embaixo -->
  <g transform="translate({pad} {legendaTop})">
    {#if legendaTitulo}
      <text
        x="0"
        y={-6 * k}
        font-size={type.legendaTitulo}
        font-weight="600"
        fill={cinza.subtitulo}
        font-family={fontFamily}>{legendaTitulo}</text
      >
    {/if}
    {#each rampa as cor, i}
      <rect x={i * passo} y="0" width={passo} height={faixaAltura} fill={cor} />
      <text
        x={i * passo}
        y={faixaAltura + type.legenda + 3 * k}
        font-size={type.legenda}
        font-weight="500"
        fill={cinza.nota}
        font-family={fontFamily}>{rotulos[i]}</text
      >
    {/each}
  </g>

  <g transform="translate({pad} {mapaTop})">
    <g transform="scale({km})">
      {#if mosaico}
        <!--
          A malha municipal por baixo: cada município na cor da sua UF, com a
          divisa desenhada em branco esmaecido. É a mesma informação de cor do
          mapa por UF — o que muda é que o leitor passa a ver as unidades sobre
          as quais o número foi calculado.
        -->
        {#each mosaico as m (m.c)}
          <path
            d={m.d}
            fill={corDe(porUf.get(m.uf))}
            stroke="#FFFFFF"
            stroke-opacity="0.45"
            stroke-width={dom(0.35 * k)}
            stroke-linejoin="round"
          />
        {/each}
        {#each estados as e (e.uf)}
          <path
            d={e.d}
            fill="none"
            stroke={cinza.divisa}
            stroke-width={dom(1.2 * k)}
            stroke-linejoin="round"
          />
        {/each}
      {:else}
        {#each estados as e (e.uf)}
          <path d={e.d} fill={e.cor} stroke={cinza.divisa} stroke-width={dom(0.9 * k)} stroke-linejoin="round" />
        {/each}
      {/if}

      <!-- sigla e número dentro do estado, quando o círculo inscrito os comporta -->
      {#each estados as e (e.uf)}
        {#if e.dentro}
          {@const cor = corDoTexto(e.cor)}
          <!--
            As duas linhas montadas em torno da âncora, e não a partir dela: sem
            o recuo, o bloco desce para baixo do centro do círculo inscrito e a
            sigla de Santa Catarina encosta na divisa com o Paraná.
          -->
          <text
            x={e.ancora[0]}
            y={e.ancora[1] - dom(3.2 * k)}
            text-anchor="middle"
            font-size={dom(type.sigla)}
            font-weight="600"
            fill={cor}
            font-family={fontFamily}>{e.uf}</text
          >
          <text
            x={e.ancora[0]}
            y={e.ancora[1] + dom(type.valor - 2.2 * k)}
            text-anchor="middle"
            font-size={dom(type.valor)}
            font-weight="700"
            fill={cor}
            font-family={fontFamily}>{formatValue(e.valor!)}</text
          >
        {/if}
      {/each}
    </g>

    <!-- os oito estados pequenos: ponto na âncora, linha fina e rótulo na calha -->
    {#each chamadas as c (c.uf)}
      {@const traco = `M${c.ax} ${c.ay}L${calhaX - pad - 4 * k} ${c.y - type.chamada * 0.3}`}
      <!-- o halo branco carrega a linha por cima dos estados escuros -->
      <path d={traco} fill="none" stroke="#FFFFFF" stroke-width={2 * k} stroke-opacity="0.85" />
      <path d={traco} fill="none" stroke={cinza.chamada} stroke-width={0.6 * k} />
      <circle cx={c.ax} cy={c.ay} r={1.6 * k} fill="#FFFFFF" />
      <circle cx={c.ax} cy={c.ay} r={1.1 * k} fill={cinza.chamada} />
      <text
        x={calhaX - pad}
        y={c.y}
        font-size={type.chamada}
        font-weight="600"
        fill={cinza.dado}
        font-family={fontFamily}
        >{c.uf} <tspan font-weight="700">{formatValue(c.valor)}</tspan></text
      >
    {/each}

    {#if destaque}
      <text
        x={DESTAQUE.x * km}
        y={DESTAQUE.y * km + type.destaqueValor}
        font-size={type.destaqueValor}
        font-weight="700"
        fill={destaque.cor}
        font-family={fontFamily}>{destaque.valor}</text
      >
      {#each destaqueLinhas as linha, i}
        <text
          x={DESTAQUE.x * km}
          y={DESTAQUE.y * km + 21 * k + (i + 0.85) * 14.5 * k}
          font-size={type.destaqueTexto}
          font-weight="500"
          fill={cinza.dado}
          font-family={fontFamily}>{linha}</text
        >
      {/each}
    {/if}
  </g>

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
