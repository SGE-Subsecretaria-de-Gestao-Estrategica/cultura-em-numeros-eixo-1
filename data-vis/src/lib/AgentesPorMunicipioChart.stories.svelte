<script module lang="ts">
  import type { ComponentProps } from 'svelte';
  import { defineMeta, type StoryContext } from '@storybook/addon-svelte-csf';
  import AgentesPorMunicipioChart from './AgentesPorMunicipioChart.svelte';
  import StoryFrame from './StoryFrame.svelte';

  const { Story } = defineMeta({
    title: 'Charts/Participação · Municípios por agente',
    component: AgentesPorMunicipioChart,
    tags: ['autodocs'],
    parameters: { layout: 'padded' },
    args: { background: null },
  });

  type StoryArgs = ComponentProps<typeof AgentesPorMunicipioChart>;
</script>

{#snippet template(args: StoryArgs, ctx: StoryContext<StoryArgs>)}
  <StoryFrame name={ctx.id}>
    <AgentesPorMunicipioChart {...args} />
  </StoryFrame>
{/snippet}

<!--
  O par da figura de contagem: a mesma malha, o mesmo enquadramento e a leitura
  invertida. Lá a cor é quantos agentes o estado tem; aqui é quantos municípios
  cabem a cada um deles, e São Paulo sai do extremo escuro para o meio da
  escala. Os 5 570 municípios são desenhados um a um porque são o denominador
  da razão — o registro de agentes é por UF, e a nota da figura o diz.

  `template={template as never}`: the addon's `Snippet` brand and Svelte's own
  do not unify under svelte-check, so a correctly typed snippet is still
  rejected. The cast is on the hand-off only — the snippet itself stays typed.
-->

<Story name="Padrão" args={{}} template={template as never} />

<!-- O cartão com o próprio fundo, para páginas não brancas. -->
<Story name="Com cartão" args={{ background: '#ffffff' }} template={template as never} />
