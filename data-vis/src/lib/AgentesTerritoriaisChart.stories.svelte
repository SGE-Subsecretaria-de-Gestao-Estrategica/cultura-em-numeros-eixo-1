<script module lang="ts">
  import type { ComponentProps } from 'svelte';
  import { defineMeta, type StoryContext } from '@storybook/addon-svelte-csf';
  import AgentesTerritoriaisChart from './AgentesTerritoriaisChart.svelte';
  import StoryFrame from './StoryFrame.svelte';

  const { Story } = defineMeta({
    title: 'Charts/Participação · Agentes territoriais',
    component: AgentesTerritoriaisChart,
    tags: ['autodocs'],
    parameters: { layout: 'padded' },
    args: { background: null },
  });

  type StoryArgs = ComponentProps<typeof AgentesTerritoriaisChart>;
</script>

{#snippet template(args: StoryArgs, ctx: StoryContext<StoryArgs>)}
  <StoryFrame name={ctx.id}>
    <AgentesTerritoriaisChart {...args} />
  </StoryFrame>
{/snippet}

<!--
  A primeira figura do capítulo de participação social. É a única figura
  territorial desenhada sobre a malha real do IBGE, e não sobre a malha
  hexagonal: aqui o dado é uma contagem por estado, e o contorno de verdade
  identifica cada um sem que o leitor tenha de consultar a legenda de posições.
  A projeção é equivalente, então a área desenhada é a área do estado; a cor é
  a classe de contagem e o número dentro do estado é a contagem exata.

  `template={template as never}`: the addon's `Snippet` brand and Svelte's own
  do not unify under svelte-check, so a correctly typed snippet is still
  rejected. The cast is on the hand-off only — the snippet itself stays typed.
-->

<Story name="Padrão" args={{}} template={template as never} />

<!-- O cartão com o próprio fundo, para páginas não brancas. -->
<Story name="Com cartão" args={{ background: '#ffffff' }} template={template as never} />
