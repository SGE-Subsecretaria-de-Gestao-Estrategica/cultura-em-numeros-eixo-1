<script module lang="ts">
  import type { ComponentProps } from 'svelte';
  import { defineMeta, type StoryContext } from '@storybook/addon-svelte-csf';
  import RibbonMunicipalChart from './RibbonMunicipalChart.svelte';
  import StoryFrame from './StoryFrame.svelte';

  const { Story } = defineMeta({
    title: 'Orçamento/Municipal/Fontes de recurso (fita)',
    component: RibbonMunicipalChart,
    tags: ['autodocs'],
    parameters: { layout: 'padded' },
    args: { background: null },
  });

  type StoryArgs = ComponentProps<typeof RibbonMunicipalChart>;
</script>

{#snippet template(args: StoryArgs, ctx: StoryContext<StoryArgs>)}
  <StoryFrame name={ctx.id}>
    <RibbonMunicipalChart {...args} />
  </StoryFrame>
{/snippet}

<!--
  As quatro fontes municipais que pesam de fato — recurso próprio e as três
  leis emergenciais — empilhadas por valor absoluto e ligadas de ano a ano; a
  fita cruza quando uma lei emergencial ultrapassa a outra. Emendas ficam de
  fora por serem pequenas demais na escala do recurso próprio.

  `template={template as never}`: the addon's `Snippet` brand and Svelte's own
  do not unify under svelte-check, so a correctly typed snippet is still
  rejected. The cast is on the hand-off only — the snippet itself stays typed.
-->

<Story name="Padrão" args={{}} template={template as never} />

<!-- O cartão com o próprio fundo, para páginas não brancas. -->
<Story name="Com cartão" args={{ background: '#ffffff' }} template={template as never} />
