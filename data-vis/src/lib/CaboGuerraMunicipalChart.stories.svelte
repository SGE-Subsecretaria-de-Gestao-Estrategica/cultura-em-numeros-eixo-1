<script module lang="ts">
  import type { ComponentProps } from 'svelte';
  import { defineMeta, type StoryContext } from '@storybook/addon-svelte-csf';
  import CaboGuerraMunicipalChart from './CaboGuerraMunicipalChart.svelte';
  import StoryFrame from './StoryFrame.svelte';

  const { Story } = defineMeta({
    title: 'Charts/Municipal · Cabo de guerra (indutor vs. substituição)',
    component: CaboGuerraMunicipalChart,
    tags: ['autodocs'],
    parameters: { layout: 'padded' },
    args: { background: null },
  });

  type StoryArgs = ComponentProps<typeof CaboGuerraMunicipalChart>;
</script>

{#snippet template(args: StoryArgs, ctx: StoryContext<StoryArgs>)}
  <StoryFrame name={ctx.id}>
    <CaboGuerraMunicipalChart {...args} />
  </StoryFrame>
{/snippet}

<!--
  Barras divergentes por macrorregião: o efeito indutor (verde claro, à
  direita do zero) contra o efeito substituição (vermelho escuro, à esquerda)
  do Corredor Híbrido. A escala é uma só para as duas direções — o
  desequilíbrio de escala entre elas é o próprio achado.

  `template={template as never}`: the addon's `Snippet` brand and Svelte's own
  do not unify under svelte-check, so a correctly typed snippet is still
  rejected. The cast is on the hand-off only — the snippet itself stays typed.
-->

<Story name="Padrão" args={{}} template={template as never} />

<!-- O cartão com o próprio fundo, para páginas não brancas. -->
<Story name="Com cartão" args={{ background: '#ffffff' }} template={template as never} />
