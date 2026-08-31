<script lang="ts" module>
  export type ValorUf = { uf: string; valor: number };
</script>

<script lang="ts">
  /**
   * Um cartograma de círculos — Dorling — sobre a mesma malha do mapa
   * hexagonal: um disco por UF, com área proporcional à contagem.
   *
   * Existe porque o hexmap não sabe contar. Lá, cada UF tem uma célula do mesmo
   * tamanho e o dado é a altura de uma coluna contra uma linha de referência —
   * uma leitura de percentual, que responde "quem está acima de quanto". Aqui a
   * pergunta é outra: quantos, e onde. A área é o dado, e uma UF com 93 agentes
   * ocupa mesmo vinte e três vezes a área de uma com 4.
   *
   * A malha é a de `mapaUf.ts`, a mesma das outras figuras territoriais: quem
   * aprendeu onde fica cada UF numa não reaprende na outra. Os discos partem do
   * centro da célula e são afastados até não se sobreporem, com uma mola
   * puxando cada um de volta ao seu lugar — é o que faz São Paulo caber sem
   * empurrar o Sudeste para fora do país.
   *
   * A relaxação é determinística: mesma entrada, mesmo desenho. Um cartograma
   * com semente aleatória mudaria a cada exportação, e duas tiragens da mesma
   * figura não bateriam.
   *
   * Os valores não são escritos disco a disco. A escala de área é explicada uma
   * vez, na legenda de círculos de referência, e o que a figura tem a dizer é o
   * padrão territorial — a tabela é que guarda os 27 números.
   */
  import { CONTORNOS, LARGURA_PRINT, REGIOES, centro, regiaoDe } from './mapaUf';
  import { a4Scale, fontFamily, fontSize as scale, measureLabel, wrapText } from './tokens';

  let {
    valores,
    cor,
    title,
    subtitle,
    formatValue = (v: number) => String(v),
    legendaTitulo = 'Área do círculo',
    legendaValores,
    destaque,
    footnote,
    source,
    width = 580,
    svgEl = $bindable(null),
    background = null,
  }: {
    valores: ValorUf[];
    cor: string;
    title: string;
    subtitle?: string;
    formatValue?: (v: number) => string;
    legendaTitulo?: string;
    /** Os valores dos círculos de referência, do menor para o maior. */
    legendaValores: number[];
    destaque?: { valor: string; cor: string; texto: string };
    footnote?: string;
    source?: string;
    width?: number;
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  // svelte-ignore state_referenced_locally -- a largura autoral é fixada na criação
  const k = a4Scale(width);
  const km = $derived(width / LARGURA_PRINT);

  const type = {
    title: 14 * k,
    subtitle: scale.md * k,
    destaqueValor: 19 * k,
    destaqueTexto: scale.md * k,
    nota: scale.sm * k,
  };

  const cinza = {
    titulo: '#2F2F2B',
    subtitulo: '#6E6E68',
    dado: '#3F3F3B',
    regiao: '#3F3F3B',
    contorno: '#DCDCD7',
    legenda: '#8A8A84',
    nota: '#8A8A84',
  };

  const pad = 16 * k;

  /**
   * Raio do maior disco, no domínio da malha. O hexágono tem lado 76,7, então
   * um disco de 96 transborda a célula — é o que se quer: a área é o dado, e o
   * disco de São Paulo tem de poder ser maior do que o lugar em que São Paulo
   * cabe. Quem resolve o transbordo é a relaxação.
   */
  const R_MAX = 96;
  const GAP = 5;

  const vMax = $derived(Math.max(...valores.map((v) => v.valor)));
  const raio = $derived((v: number) => (v <= 0 ? 0 : R_MAX * Math.sqrt(v / vMax)));

  type Disco = { uf: string; valor: number; r: number; x: number; y: number; ax: number; ay: number };

  /**
   * Dorling: mola para a âncora e repulsão entre pares, iteradas até assentar.
   *
   * A ordem dos pares é a da lista e o passo é fixo, então não há nada a
   * sortear — duas execuções dão o mesmo resultado até o último dígito.
   */
  const discos = $derived.by((): Disco[] => {
    const nos: Disco[] = valores.map((v) => {
      const [ax, ay] = centro(regiaoDe(v.uf), v.uf);
      return { uf: v.uf, valor: v.valor, r: raio(v.valor), x: ax, y: ay, ax, ay };
    });

    for (let passo = 0; passo < 400; passo++) {
      for (const n of nos) {
        n.x += (n.ax - n.x) * 0.08;
        n.y += (n.ay - n.y) * 0.08;
      }
      for (let i = 0; i < nos.length; i++) {
        for (let j = i + 1; j < nos.length; j++) {
          const a = nos[i];
          const b = nos[j];
          const dx = b.x - a.x;
          const dy = b.y - a.y;
          const d = Math.hypot(dx, dy);
          const minimo = a.r + b.r + GAP;
          if (d >= minimo) continue;
          // dois centros exatamente coincidentes não têm direção; a malha não
          // produz isso, mas um empurrão fixo evita divisão por zero
          const [ux, uy] = d === 0 ? [1, 0] : [dx / d, dy / d];
          const empurra = (minimo - d) / 2;
          a.x -= ux * empurra;
          a.y -= uy * empurra;
          b.x += ux * empurra;
          b.y += uy * empurra;
        }
      }
    }
    return nos;
  });

  /** Sigla dentro do disco só quando ela cabe; a menor da malha decide o corpo. */
  const corpoDaSigla = $derived((r: number) => Math.min(r * 0.62, 26));
  const siglaCabe = $derived(
    (uf: string, r: number) =>
      measureLabel(uf, corpoDaSigla(r) * km, 700) < (2 * r - 6) * km,
  );

  const textWidth = $derived(width - pad * 2);
  const titleLines = $derived(wrapText(title, type.title, textWidth, 600));
  const subtitleLines = $derived(wrapText(subtitle ?? '', type.subtitle, textWidth));
  const footnoteLines = $derived(wrapText(footnote ?? '', type.nota, textWidth));
  const sourceLines = $derived(wrapText(source ?? '', type.nota, textWidth));

  const titleLine = 19 * k;
  const subtitleLine = 15 * k;
  const notaLine = 13.5 * k;

  const mapaTop = $derived(
    12 * k + titleLines.length * titleLine + subtitleLines.length * subtitleLine + 14 * k,
  );

  /** A mesma altura de domínio do mapa hexagonal, para as duas figuras casarem. */
  const MAPA_ALTURA_PX = 1105;
  const notasTop = $derived(mapaTop + MAPA_ALTURA_PX * km + 6 * k);
  const height = $derived(
    notasTop + (footnoteLines.length + sourceLines.length) * notaLine + pad,
  );

  /**
   * Os rótulos de região do mapa hexagonal encostam na célula do seu
   * aglomerado, que é o lugar certo quando cada UF ocupa exatamente uma célula.
   * Aqui não ocupa: um disco grande transborda a sua e a relaxação empurra os
   * vizinhos para o vão que o rótulo usava. São Paulo e Rio Grande do Sul, os
   * dois maiores do país nesta contagem, cobrem justamente onde estavam
   * "Centro-Oeste" e "Sul".
   *
   * Estes dois voltam para fora do aglomerado, do lado que ficou livre. Os
   * outros três não se mexem — o Norte, o Nordeste e o Sudeste não têm disco
   * grande o bastante para alcançá-los.
   */
  const ROTULOS_REGIAO: Record<string, [number, number]> = {
    ...Object.fromEntries(Object.entries(REGIOES).map(([r, { rotulo }]) => [r, rotulo])),
    'Centro-Oeste': [430, 640],
    Sul: [545, 1010],
  };

  /** A legenda de área ocupa o vão vazio à esquerda do Sudeste. */
  const LEGENDA = { x: 120, y: 700, base: 900 };
  const legendaR = $derived(legendaValores.map((v) => raio(v)));
  const legendaCx = $derived(LEGENDA.x + Math.max(...legendaR));

  const destaqueLinhas = $derived(
    destaque ? wrapText(destaque.texto, type.destaqueTexto, 150 * k, 500) : [],
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

  <g transform="translate(0 {mapaTop}) scale({km})">
    <!-- o contorno de cada região, atrás dos discos: a geografia de referência -->
    {#each CONTORNOS as { arestas }}
      {#each arestas as [x1, y1, x2, y2]}
        <line {x1} {y1} {x2} {y2} stroke={cinza.contorno} stroke-width="4" stroke-linecap="round" />
      {/each}
    {/each}

    {#each Object.entries(ROTULOS_REGIAO) as [regiao, rotulo]}
      <text
        x={rotulo[0]}
        y={rotulo[1]}
        text-anchor="middle"
        font-size="21"
        font-weight="700"
        fill={cinza.regiao}
        font-family={fontFamily}>{regiao}</text
      >
    {/each}

    <!-- os discos -->
    {#each discos as d (d.uf)}
      <circle cx={d.x} cy={d.y} r={d.r} fill={cor} />
      {#if siglaCabe(d.uf, d.r)}
        <text
          x={d.x}
          y={d.y + corpoDaSigla(d.r) * 0.35}
          text-anchor="middle"
          font-size={corpoDaSigla(d.r)}
          font-weight="700"
          fill="#FFFFFF"
          font-family={fontFamily}>{d.uf}</text
        >
      {:else}
        <text
          x={d.x}
          y={d.y + d.r + 20}
          text-anchor="middle"
          font-size="19"
          font-weight="600"
          fill={cinza.dado}
          font-family={fontFamily}>{d.uf}</text
        >
      {/if}
    {/each}

    <!-- legenda de área: círculos de referência concêntricos pela base -->
    <text
      x={LEGENDA.x}
      y={LEGENDA.y}
      font-size="22"
      font-weight="600"
      fill={cinza.titulo}
      font-family={fontFamily}>{legendaTitulo}</text
    >
    {#each legendaValores as v, i}
      {@const r = legendaR[i]}
      <circle
        cx={legendaCx}
        cy={LEGENDA.base - r}
        {r}
        fill="none"
        stroke={cinza.legenda}
        stroke-width="2.5"
      />
      <line
        x1={legendaCx}
        y1={LEGENDA.base - 2 * r}
        x2={legendaCx + Math.max(...legendaR) + 26}
        y2={LEGENDA.base - 2 * r}
        stroke={cinza.legenda}
        stroke-width="1.5"
        stroke-dasharray="4 4"
      />
      <text
        x={legendaCx + Math.max(...legendaR) + 32}
        y={LEGENDA.base - 2 * r + 7}
        font-size="19"
        font-weight="500"
        fill={cinza.legenda}
        font-family={fontFamily}>{formatValue(v)}</text
      >
    {/each}
  </g>

  {#if destaque}
    <text
      x={pad}
      y={mapaTop + 250 * km + type.destaqueValor}
      font-size={type.destaqueValor}
      font-weight="700"
      fill={destaque.cor}
      font-family={fontFamily}>{destaque.valor}</text
    >
    {#each destaqueLinhas as linha, i}
      <text
        x={pad}
        y={mapaTop + 250 * km + 21 * k + (i + 0.85) * 14.5 * k}
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
