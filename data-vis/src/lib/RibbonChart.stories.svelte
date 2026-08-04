<script module lang="ts">
  import type { ComponentProps } from 'svelte';
  import { defineMeta, type StoryContext } from '@storybook/addon-svelte-csf';
  import {
    BRL,
    NUM,
    categorical8,
    colorScales,
    downloadSvg,
    purple,
  } from 'sniic-design-system';
  import RibbonChart from './RibbonChart.svelte';
  import estadual from '../data/estadual-por-fonte.json';
  import federal from '../data/federal-por-fonte.json';
  import municipal from '../data/municipal-por-fonte.json';

  const { Story } = defineMeta({
    title: 'Charts/RibbonChart',
    component: RibbonChart,
    tags: ['autodocs'],
    parameters: { layout: 'padded' },
    argTypes: {
      columnRatio: { control: { type: 'range', min: 0.15, max: 0.8, step: 0.01 } },
      segmentGap: { control: { type: 'range', min: 0, max: 16, step: 1 } },
      ribbonOpacity: { control: { type: 'range', min: 0.1, max: 1, step: 0.05 } },
      cornerRadius: { control: { type: 'range', min: 0, max: 12, step: 1 } },
      rankDirection: { control: { type: 'inline-radio' }, options: ['desc', 'asc'] },
    },
  });

  /**
   * Recurso próprio takes the library's purple; the four transfers share a
   * green family, so the chart reads as own revenue against everything that
   * was transferred in.
   *
   * The greens alternate between the lime and teal scales while stepping
   * steadily darker (L* 84 → 74 → 64 → 35). Alternating is what keeps them
   * apart: the closest pair here is ΔE 31 in Lab, against ΔE 12 for four
   * consecutive steps of a single scale, which would blur under the ribbons'
   * 55% opacity.
   */
  const fonteColors = [
    purple, // Recurso próprio
    colorScales.lime[1], // Emendas
    colorScales.teal[1], // LAB 1
    colorScales.lime[2], // LPG
    colorScales.teal[3], // PNAB
  ];

  // covers both datasets — the own-revenue key differs by sphere
  const fonteLabels: Record<string, string> = {
    'Recurso Próprio (Estadual)': 'Recurso próprio',
    'Recurso Próprio (Municipal)': 'Recurso próprio',
    'Emendas Parlamentares (Cultura)': 'Emendas',
    'Lei Aldir Blanc 1 (LAB 1)': 'LAB 1',
    'Lei Paulo Gustavo (LPG)': 'LPG',
    'PNAB (Aldir Blanc 2)': 'PNAB',
  };

  /**
   * Eight federal sources, so the ramp is the library's `categorical8` — the
   * pillar ramp carries three hues, and the fonte palette above only stretches
   * to five.
   *
   * The order is permuted, not invented: the two renúncia fiscal series take
   * the warm pair (orange, red) so tax expenditure reads apart from money the
   * União actually empenhou, and the residual `Outros órgãos` takes the muted
   * mauve. The rest keep the ramp's own sequence.
   */
  const federalColors = [
    categorical8[0], // MinC — blue, the permanent budget line
    categorical8[1], // Rouanet — renúncia fiscal
    categorical8[6], // ANCINE — renúncia fiscal
    categorical8[2], // FSA
    categorical8[3], // PNAB
    categorical8[5], // LPG
    categorical8[4], // LAB 1
    categorical8[7], // Outros órgãos — residual
  ];

  const federalLabels: Record<string, string> = {
    'Ministério da Cultura (Órgão 42000)': 'MinC',
    'Lei Rouanet': 'Rouanet',
    'Incentivo (ANCINE)': 'ANCINE',
    'FSA (UO 74912)': 'FSA',
    'PNAB (UO 73120)': 'PNAB',
    'Lei Paulo Gustavo': 'LPG',
    'Lei Aldir Blanc 1': 'LAB 1',
    'Outros Órgãos (Cidadania/Turismo)': 'Outros órgãos',
  };

  /** Ranks swap every year — the case the ribbon chart exists for. */
  const linguagens = [
    { label: '2019', Audiovisual: 320, Música: 280, Teatro: 210, Dança: 120, Literatura: 90 },
    { label: '2020', Audiovisual: 180, Música: 340, Teatro: 150, Dança: 100, Literatura: 160 },
    { label: '2021', Audiovisual: 260, Música: 220, Teatro: 320, Dança: 140, Literatura: 130 },
    { label: '2022', Audiovisual: 410, Música: 200, Teatro: 240, Dança: 220, Literatura: 110 },
    { label: '2023', Audiovisual: 300, Música: 380, Teatro: 260, Dança: 190, Literatura: 240 },
    { label: '2024', Audiovisual: 350, Música: 290, Teatro: 400, Dança: 260, Literatura: 180 },
  ];

  // `Args<typeof Story>` collapses to `never` for a meta declared with
  // `component`; the story args are just the component's props.
  type StoryArgs = ComponentProps<typeof RibbonChart>;

  /**
   * Print sizing for a figure running the full text width of A4 portrait.
   *
   * Type in an SVG is absolute, so its printed size is decided by the ratio of
   * font size to chart width, not by either alone. At 170 mm, 9 pt (3.175 mm)
   * needs the value labels to be 1.87% of the chart's width; they are 0.88%
   * on screen, hence the scale below.
   *
   * Widening the columns is not cosmetic: a value label is 3.94 px wide per px
   * of font, and a column is only 5.83% of the chart at `columnRatio` 0.42 —
   * so at 9 pt the labels cannot fit inside a column at any authoring size.
   * 0.6 buys the room back, at the cost of thinner ribbons.
   *
   * It stops at 0.6 on purpose. Fitting the longest labels — `R$ 12,6 bi` and
   * the `mi` values — would take 0.70 and 0.84, and past ~0.68 the ribbons are
   * slivers and the callouts stack over the columns: the chart stops being a
   * ribbon chart. The labels that miss the cut fall back to 7.9 pt, which still
   * prints legibly. Dropping `R$ ` from the in-segment values would fit every
   * one of them at 9 pt without widening anything further.
   */
  const A4_TEXT_WIDTH_MM = 170;
  const A4 = {
    responsive: false,
    width: 1368,
    height: 620,
    fontScale: (3.175 / A4_TEXT_WIDTH_MM) * (1368 / 12),
    columnRatio: 0.6,
    // the legend and axis grow with the type, so the gutter under the plot has to
    margin: { bottom: 132 },
  };

  /**
   * The federal series runs 23 years against the sub-national seven, so it gets
   * the landscape figure: at 170 mm the year ticks alone would need more than a
   * band is wide. Same 9 pt target, measured against the 257 mm text width.
   */
  const A4_LANDSCAPE_TEXT_WIDTH_MM = 257;
  const A4_LANDSCAPE = {
    responsive: false,
    width: 1900,
    height: 760,
    fontScale: (3.175 / A4_LANDSCAPE_TEXT_WIDTH_MM) * (1900 / 12),
    columnRatio: 0.5,
    margin: { bottom: 132 },
  };
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

<!--
  The download button is deliberately outside the chart: everything the
  component draws lives inside the `<svg>` and would be serialized into the
  exported file.
-->
{#snippet template(args: StoryArgs, ctx: StoryContext<StoryArgs>)}
  <div class="story">
    <button class="export" onclick={() => save(ctx)}>Baixar SVG</button>
    <!-- get/set binding: the key does not exist until the chart mounts, and
         `bind:svgEl={undefined}` clashes with the prop's `null` fallback -->
    <RibbonChart
      {...args}
      bind:svgEl={() => svgEls[ctx.id] ?? null, (el) => (svgEls[ctx.id] = el)}
    />
  </div>
{/snippet}

<!--
  Ribbon chart — a stacked column chart that re-ranks its series in every column
  and connects each series across columns with a ribbon, so a series changing
  position is visible as the ribbon crossing.

  `template={template as never}`: the addon's `Snippet` brand and Svelte's own
  do not unify under svelte-check, so a correctly typed snippet is still
  rejected. The cast is on the hand-off only — the snippet itself stays typed.
-->

<Story
  name="Fontes de recurso (estadual)"
  args={{
    data: estadual.real,
    keys: estadual.keys,
    labels: fonteLabels,
    colors: fonteColors,
    valueFormat: (v) => BRL.format(v),
    height: 460,
  }}
  template={template as never}
/>

<Story
  name="Fontes de recurso (municipal)"
  args={{
    data: municipal.real,
    keys: municipal.keys,
    labels: fonteLabels,
    colors: fonteColors,
    valueFormat: (v) => BRL.format(v),
    height: 460,
  }}
  template={template as never}
/>

<!--
  23 columns against the others' 7, so the values come off the segments: at this
  band width every one of them would fall out to a callout, and 8 series × 23
  years of callouts bury the ribbons they point at. Ranks and volume are what
  this chart is for — the numbers live in the table.
-->
<Story
  name="Fontes de recurso (federal)"
  args={{
    data: federal.real,
    keys: federal.keys,
    labels: federalLabels,
    colors: federalColors,
    valueFormat: (v) => BRL.format(v),
    showValues: false,
    width: 1100,
    height: 520,
    columnRatio: 0.5,
    segmentGap: 3,
  }}
  template={template as never}
/>

<Story
  name="Trocas de posição"
  args={{
    data: linguagens,
    labels: {},
    valueFormat: (v) => `${NUM.format(v)}`,
    height: 460,
  }}
  template={template as never}
/>

<Story
  name="Menor no topo"
  args={{
    data: linguagens,
    valueFormat: (v) => `${NUM.format(v)}`,
    rankDirection: 'asc',
    height: 460,
  }}
  template={template as never}
/>

<Story
  name="Colunas largas"
  args={{
    data: linguagens,
    valueFormat: (v) => `${NUM.format(v)}`,
    columnRatio: 0.65,
    ribbonOpacity: 0.35,
    height: 460,
  }}
  template={template as never}
/>

<!-- Print variants. Same data, sized so the labels land at 9 pt when the
     figure runs the full text width of A4 portrait. -->

<Story
  name="A4 · Fontes de recurso (estadual)"
  exportName="A4Estadual"
  args={{
    data: estadual.real,
    keys: estadual.keys,
    labels: fonteLabels,
    colors: fonteColors,
    valueFormat: (v) => BRL.format(v),
    ...A4,
  }}
  template={template as never}
/>

<Story
  name="A4 · Fontes de recurso (municipal)"
  exportName="A4Municipal"
  args={{
    data: municipal.real,
    keys: municipal.keys,
    labels: fonteLabels,
    colors: fonteColors,
    valueFormat: (v) => BRL.format(v),
    ...A4,
  }}
  template={template as never}
/>

<Story
  name="A4 paisagem · Fontes de recurso (federal)"
  exportName="A4Federal"
  args={{
    data: federal.real,
    keys: federal.keys,
    labels: federalLabels,
    colors: federalColors,
    valueFormat: (v) => BRL.format(v),
    showValues: false,
    segmentGap: 3,
    ...A4_LANDSCAPE,
  }}
  template={template as never}
/>

<!--
  Story harness only. The chart components carry no CSS of their own, so that
  every mark they draw survives the SVG export.
-->
<style>
  .story {
    display: flex;
    flex-direction: column;
    gap: 8px;
  }

  .export {
    align-self: flex-end;
    font: 500 12px/1 'General Sans Variable', system-ui, sans-serif;
    color: #4d5148;
    background: transparent;
    border: 1px solid #cec2bb;
    border-radius: 4px;
    padding: 7px 12px;
    cursor: pointer;
  }

  .export:hover {
    color: #33382e;
    border-color: #4d5148;
  }
</style>
