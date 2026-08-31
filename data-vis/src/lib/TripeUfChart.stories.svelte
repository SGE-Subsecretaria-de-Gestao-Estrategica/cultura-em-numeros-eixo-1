<script module lang="ts">
  import type { ComponentProps } from 'svelte';
  import { defineMeta, type StoryContext } from '@storybook/addon-svelte-csf';
  import TripeUfChart from './TripeUfChart.svelte';
  import StoryFrame from './StoryFrame.svelte';

  const { Story } = defineMeta({
    title: 'Charts/Gestão · Tripé por UF',
    component: TripeUfChart,
    tags: ['autodocs'],
    parameters: { layout: 'padded' },
    args: { background: null },
  });

  type StoryArgs = ComponentProps<typeof TripeUfChart>;
</script>

{#snippet template(args: StoryArgs, ctx: StoryContext<StoryArgs>)}
  <StoryFrame name={ctx.id}>
    <TripeUfChart {...args} />
  </StoryFrame>
{/snippet}

<!--
  O mapa hexagonal do terceiro print aplicado ao tripé institucional: 2014 à
  esquerda, 2021 à direita, a linha preta na média nacional de 2021 e o verde
  marcando quem passa dela.

  `template={template as never}`: the addon's `Snippet` brand and Svelte's own
  do not unify under svelte-check, so a correctly typed snippet is still
  rejected. The cast is on the hand-off only — the snippet itself stays typed.
-->

<Story name="Padrão" args={{}} template={template as never} />

<!-- O cartão com o próprio fundo, para páginas não brancas. -->
<Story name="Com cartão" args={{ background: '#ffffff' }} template={template as never} />
