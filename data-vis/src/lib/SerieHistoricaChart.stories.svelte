<script module lang="ts">
  import type { ComponentProps } from 'svelte';
  import { defineMeta, type StoryContext } from '@storybook/addon-svelte-csf';
  import { categorical8, colorScales, downloadSvg } from 'sniic-design-system';
  import SerieHistoricaChart from './SerieHistoricaChart.svelte';
  import gestao from '../data/gestao-municipal.json';

  const { Story } = defineMeta({
    title: 'Charts/SerieHistoricaChart',
    component: SerieHistoricaChart,
    tags: ['autodocs'],
    parameters: { layout: 'padded' },
    argTypes: {
      yMax: { control: { type: 'range', min: 20, max: 100, step: 5 } },
      width: { control: { type: 'range', min: 600, max: 1900, step: 20 } },
      responsive: { control: 'boolean' },
    },
  });

  const tripeColors = [categorical8[0], categorical8[2], categorical8[1]];
  const equipColors = [categorical8[0], categorical8[1], categorical8[2], categorical8[4]];

  /**
   * Duas séries a menos de um ponto de distância na primeira e na última onda,
   * e cruzando no meio. É o caso que a colocação dos rótulos existe para
   * resolver: sem ela, o valor da série de baixo aterrissa sobre a linha da de
   * cima. Sintético — os dados reais mais apertados são museu e teatro, que já
   * aparecem na story de equipamentos.
   */
  const coladas = [
    {
      key: 'a',
      label: 'Série A',
      pontos: [
        { ano: 2006, pct: 22.4 },
        { ano: 2014, pct: 30.1 },
        { ano: 2021, pct: 25.2 },
      ],
    },
    {
      key: 'b',
      label: 'Série B',
      pontos: [
        { ano: 2006, pct: 21.9 },
        { ano: 2014, pct: 30.6 },
        { ano: 2021, pct: 25.9 },
      ],
    },
  ];

  // `Args<typeof Story>` collapses to `never` for a meta declared with
  // `component`; the story args are just the component's props.
  type StoryArgs = ComponentProps<typeof SerieHistoricaChart>;
</script>

<script lang="ts">
  /**
   * Autodocs renders every story on one page, so the SVGs are keyed by story
   * id — one shared reference would have the charts overwrite each other and
   * every button would export whichever rendered last.
   */
  const svgEls: Record<string, SVGSVGElement | null> = $state({});

  function save(ctx: StoryContext<StoryArgs>) {
    const el = svgEls[ctx.id];
    if (el) downloadSvg(el, `${ctx.id}.svg`);
  }
</script>

{#snippet template(args: StoryArgs, ctx: StoryContext<StoryArgs>)}
  <div class="story">
    <button class="export" onclick={() => save(ctx)}>Baixar SVG</button>
    <!-- get/set binding: the key does not exist until the chart mounts, and
         `bind:svgEl={undefined}` clashes with the prop's `null` fallback -->
    <SerieHistoricaChart
      {...args}
      bind:svgEl={() => svgEls[ctx.id] ?? null, (el) => (svgEls[ctx.id] = el)}
    />
  </div>
{/snippet}

<!--
  Séries percentuais medidas em ondas de pesquisa, uma linha por indicador, com
  o nome de cada série na ponta da linha em vez de numa legenda.

  Não há variante A4 aqui: o cartão já é escrito na largura da coluna de texto
  de um A4 retrato e escala o próprio tipo por `a4Scale`, então o que estas
  stories mostram é o que sai impresso.

  `template={template as never}`: the addon's `Snippet` brand and Svelte's own
  do not unify under svelte-check, so a correctly typed snippet is still
  rejected. The cast is on the hand-off only — the snippet itself stays typed.
-->

<Story
  name="Tripé institucional"
  args={{
    series: gestao.tripe.series,
    colors: tripeColors,
    title: 'Evolução do tripé institucional da cultura',
    subtitle:
      'Proporção dos municípios brasileiros com cada instrumento do Sistema Nacional de Cultura criado.',
    source: 'Fonte: MUNIC/IBGE (2006, 2014, 2018 e 2021).',
  }}
  template={template as never}
/>

<!--
  Quatro séries, e duas delas — museu e teatro — separadas por 0,7 ponto em
  2006. Os rótulos da série de baixo caem para debaixo do próprio marcador,
  que é o espaço que sobra entre as duas linhas.
-->
<Story
  name="Séries próximas"
  args={{
    series: gestao.equipamentos.series,
    colors: equipColors,
    yMax: 100,
    title: 'Equipamentos culturais nos municípios',
    subtitle: 'Proporção dos municípios que declaram ter cada equipamento em funcionamento.',
    source: 'Fonte: MUNIC/IBGE (2006, 2014 e 2021).',
  }}
  template={template as never}
/>

<!-- Duas séries que se cruzam coladas: o caso-limite do posicionamento. -->
<Story
  name="Séries que se cruzam"
  args={{
    series: coladas,
    colors: [colorScales.purple[2], colorScales.teal[2]],
    yMax: 40,
    title: 'Duas séries a menos de um ponto de distância',
    subtitle: 'Caso sintético, para exercitar a resolução de colisão dos rótulos.',
  }}
  template={template as never}
/>

<!--
  Sem cartão: é assim que o PNG é rasterizado (`/gestao.html?bg=0`), para o
  gráfico compor sobre a página em que for colocado. O fundo desta página é o
  do Storybook, não do gráfico.
-->
<Story
  name="Sem cartão"
  args={{
    series: gestao.tripe.series,
    colors: tripeColors,
    background: null,
    title: 'Evolução do tripé institucional da cultura',
    subtitle: 'O mesmo gráfico sem o fundo e a borda do cartão.',
  }}
  template={template as never}
/>

<!-- Story harness only. The chart components carry no CSS of their own, so
     that every mark they draw survives the SVG export. -->
<style>
  .story {
    display: flex;
    flex-direction: column;
    gap: 8px;
  }
</style>
