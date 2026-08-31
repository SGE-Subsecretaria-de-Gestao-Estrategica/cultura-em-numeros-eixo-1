<script module lang="ts">
  import type { ComponentProps } from 'svelte';
  import { defineMeta, type StoryContext } from '@storybook/addon-svelte-csf';
  import ConcentracaoGastoChart from './ConcentracaoGastoChart.svelte';
  import StoryFrame from './StoryFrame.svelte';

  const { Story } = defineMeta({
    title: 'Charts/Municipal · Concentração do gasto',
    component: ConcentracaoGastoChart,
    tags: ['autodocs'],
    parameters: { layout: 'padded' },
    args: { background: null },
  });

  type StoryArgs = ComponentProps<typeof ConcentracaoGastoChart>;
</script>

{#snippet template(args: StoryArgs, ctx: StoryContext<StoryArgs>)}
  <StoryFrame name={ctx.id}>
    <ConcentracaoGastoChart {...args} />
  </StoryFrame>
{/snippet}

<!--
  A única figura da publicação que fala de desigualdade territorial de recurso.
  O rótulo de cada marco é a frase inteira de propósito: o valor de um marco não
  é a altura do ponto em que ele está desenhado — no marco dos 10%, o ponto está
  a 42% e a leitura é 58% — e um número solto ali diria o contrário do que mede.

  `template={template as never}`: the addon's `Snippet` brand and Svelte's own
  do not unify under svelte-check, so a correctly typed snippet is still
  rejected. The cast is on the hand-off only — the snippet itself stays typed.
-->

<Story name="Padrão" args={{}} template={template as never} />

<!-- O cartão com o próprio fundo, para páginas não brancas. -->
<Story name="Com cartão" args={{ background: '#ffffff' }} template={template as never} />
