<script module lang="ts">
  import type { ComponentProps } from 'svelte';
  import { defineMeta, type StoryContext } from '@storybook/addon-svelte-csf';
  import MetaRclChart from './MetaRclChart.svelte';
  import StoryFrame from './StoryFrame.svelte';

  const { Story } = defineMeta({
    title: 'Charts/Municipal · Meta de 2% da RCL',
    component: MetaRclChart,
    tags: ['autodocs'],
    parameters: { layout: 'padded' },
    args: { background: null },
  });

  type StoryArgs = ComponentProps<typeof MetaRclChart>;
</script>

{#snippet template(args: StoryArgs, ctx: StoryContext<StoryArgs>)}
  <StoryFrame name={ctx.id}>
    <MetaRclChart {...args} />
  </StoryFrame>
{/snippet}

<!--
  A figura de dois andares do segundo print: a contagem de municípios acima de
  2% da RCL como faixa grossa e a proporção que eles representam como régua de
  bolinhas. A base declarante menor de 2025 fica na nota de rodapé — o eixo não
  salta nenhum ano, então não há quebra a marcar sobre ele.

  `template={template as never}`: the addon's `Snippet` brand and Svelte's own
  do not unify under svelte-check, so a correctly typed snippet is still
  rejected. The cast is on the hand-off only — the snippet itself stays typed.
-->

<Story name="Padrão" args={{}} template={template as never} />

<!-- O cartão com o próprio fundo, para páginas não brancas. -->
<Story name="Com cartão" args={{ background: '#ffffff' }} template={template as never} />
