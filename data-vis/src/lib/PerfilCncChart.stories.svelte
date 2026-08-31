<script module lang="ts">
  import type { ComponentProps } from 'svelte';
  import { defineMeta, type StoryContext } from '@storybook/addon-svelte-csf';
  import PerfilCncChart from './PerfilCncChart.svelte';
  import StoryFrame from './StoryFrame.svelte';

  const { Story } = defineMeta({
    title: 'Charts/Participação · Perfil da 4ª CNC',
    component: PerfilCncChart,
    tags: ['autodocs'],
    parameters: { layout: 'padded' },
    args: { background: null },
  });

  type StoryArgs = ComponentProps<typeof PerfilCncChart>;
</script>

{#snippet template(args: StoryArgs, ctx: StoryContext<StoryArgs>)}
  <StoryFrame name={ctx.id}>
    <PerfilCncChart {...args} />
  </StoryFrame>
{/snippet}

<!--
  Um ponto por pessoa: a única figura da coleção em que a unidade do dado é a
  unidade do desenho. As cores são a escala da marca com o roxo e o rosa
  trocados, para que vermelho e rosa — o par mais fraco da paleta — nunca caiam
  em blocos vizinhos.

  `template={template as never}`: the addon's `Snippet` brand and Svelte's own
  do not unify under svelte-check, so a correctly typed snippet is still
  rejected. The cast is on the hand-off only — the snippet itself stays typed.
-->

<Story name="Padrão" args={{}} template={template as never} />

<!-- O cartão com o próprio fundo, para páginas não brancas. -->
<Story name="Com cartão" args={{ background: '#ffffff' }} template={template as never} />
