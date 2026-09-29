<script lang="ts">
  /**
   * Um coroplético município a município — a malha inteira, cada uma das 5.570
   * unidades na cor do seu próprio valor, e não na cor agregada da sua UF como
   * em `CoropletoUfChart` com `mosaico`.
   *
   * É a granularidade mais fina da coleção. As demais figuras territoriais
   * respondem por estado porque o registro que elas desenham só existe por
   * estado — `AgentesPorMunicipioChart` é explícito sobre isso, a cor ali é
   * constante dentro da UF porque o dado é. Aqui o dado é mesmo municipal: a
   * MUNIC pergunta a cada prefeitura, e a malha pode mostrar o município, não
   * o estado que ele integra.
   *
   * Sem sigla nem número dentro da unidade — não há espaço para texto em
   * 5.570 formas, e a cor sozinha é o que a figura tem para contar a história.
   * A divisa estadual, por cima em traço mais grosso que a divisa municipal,
   * é a única referência de localização.
   */
  import malhaMunicipios from '../data/malha-municipios-projetada.json';
  import malhaUf from '../data/malha-ufs.json';
  import { fontFamily, fontSize as scale, a4Scale, measureLabel, wrapText } from './tokens';

  let {
    valores,
    rampa,
    quebras,
    rotulosClasses,
    legendaTitulo,
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
    /** Valor por código IBGE de 7 dígitos. Município sem entrada fica cinza. */
    valores: Record<string, number>;
    /** Do mais claro ao mais escuro; precisa de `quebras.length + 1` degraus. */
    rampa: readonly string[];
    quebras: number[];
    rotulosClasses?: string[];
    legendaTitulo?: string;
    title: string;
    subtitle?: string;
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
    chamada: scale.sm * k,
    destaqueValor: 19 * k,
    destaqueTexto: scale.md * k,
    nota: scale.sm * k,
  };

  const cinza = {
    titulo: '#2F2F2B',
    subtitulo: '#6E6E68',
    legenda: '#8A8A84',
    nota: '#8A8A84',
    semDado: '#EDEDE8',
    divisaMunicipio: '#FFFFFF',
    divisaUf: '#FFFFFF',
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

  const classeDe = (v: number) => quebras.filter((q) => v >= q).length;
  const corDe = (v: number | undefined) => (v === undefined ? cinza.semDado : rampa[classeDe(v)]);

  const mapaLargura = $derived(width - pad * 2);
  const km = $derived(mapaLargura / malhaMunicipios.largura);

  const legendaTop = $derived(
    12 * k + titleLines.length * titleLine + subtitleLines.length * subtitleLine + (legendaTitulo ? 19 * k : 6 * k),
  );
  const faixaAltura = 9 * k;
  const rotulos = $derived(
    rotulosClasses ??
      quebras.map((q, i) =>
        i === 0 ? `menos de ${formatValue(q)}` : `${formatValue(quebras[i - 1])} a ${formatValue(q - 1)}`,
      ).concat(`${formatValue(quebras.at(-1)!)} ou mais`),
  );
  const passo = $derived(
    Math.max(...rotulos.map((r) => measureLabel(r, type.legenda, 500))) + 12 * k,
  );

  const mapaTop = $derived(legendaTop + faixaAltura + 20 * k);
  const mapaAltura = $derived(malhaMunicipios.altura * km);

  /** O destaque ocupa o vazio a sudoeste do mapa — Pacífico, Bolívia, Argentina — como em `CoropletoUfChart`. */
  const DESTAQUE = { x: 14, y: 812, largura: 258 };
  const destaqueLinhas = $derived(
    destaque ? wrapText(destaque.texto, type.destaqueTexto, DESTAQUE.largura * km, 500) : [],
  );

  const notasTop = $derived(mapaTop + mapaAltura + 10 * k);
  const height = $derived(notasTop + (footnoteLines.length + sourceLines.length) * notaLine + pad);
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
      {#each malhaMunicipios.municipios as m (m.c)}
        <path
          d={m.d}
          fill={corDe(valores[m.c])}
          stroke={cinza.divisaMunicipio}
          stroke-opacity="0.35"
          stroke-width={(0.25 * k) / km}
          stroke-linejoin="round"
        />
      {/each}
      {#each malhaUf.ufs as e (e.uf)}
        <path
          d={e.d}
          fill="none"
          stroke={cinza.divisaUf}
          stroke-width={(1.1 * k) / km}
          stroke-linejoin="round"
        />
      {/each}
    </g>

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
          fill={cinza.titulo}
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
