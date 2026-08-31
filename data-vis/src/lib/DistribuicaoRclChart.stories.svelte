<script module lang="ts">
  import type { ComponentProps } from 'svelte';
  import { defineMeta, type StoryContext } from '@storybook/addon-svelte-csf';
  import DistribuicaoRclChart from './DistribuicaoRclChart.svelte';
  import StoryFrame from './StoryFrame.svelte';

  const { Story } = defineMeta({
    title: 'Charts/Municipal · Distribuição da RCL',
    component: DistribuicaoRclChart,
    tags: ['autodocs'],
    parameters: { layout: 'padded' },
    args: { background: null },
  });

  type StoryArgs = ComponentProps<typeof DistribuicaoRclChart>;
</script>

{#snippet template(args: StoryArgs, ctx: StoryContext<StoryArgs>)}
  <StoryFrame name={ctx.id}>
    <DistribuicaoRclChart {...args} />
  </StoryFrame>
{/snippet}

<!--
  A contraparte de `MetaRclRegiao`: aquela conta quantos municípios passam da
  meta, esta mostra onde eles estão. A parte vermelha de cada crista é
  exatamente o percentual que a outra figura mostra em 2024, e o número está
  escrito na ponta para as duas leituras se reconhecerem.

  `template={template as never}`: the addon's `Snippet` brand and Svelte's own
  do not unify under svelte-check, so a correctly typed snippet is still
  rejected. The cast is on the hand-off only — the snippet itself stays typed.
-->

<Story name="Padrão" args={{}} template={template as never} />

<!-- O cartão com o próprio fundo, para páginas não brancas. -->
<Story name="Com cartão" args={{ background: '#ffffff' }} template={template as never} />
