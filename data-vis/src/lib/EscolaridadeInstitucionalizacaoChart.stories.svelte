<script module lang="ts">
  import type { ComponentProps } from 'svelte';
  import { defineMeta, type StoryContext } from '@storybook/addon-svelte-csf';
  import EscolaridadeInstitucionalizacaoChart from './EscolaridadeInstitucionalizacaoChart.svelte';
  import StoryFrame from './StoryFrame.svelte';

  const { Story } = defineMeta({
    title: 'Charts/Gestão · Escolaridade e institucionalização',
    component: EscolaridadeInstitucionalizacaoChart,
    tags: ['autodocs'],
    parameters: { layout: 'padded' },
    args: { background: null },
  });

  type StoryArgs = ComponentProps<typeof EscolaridadeInstitucionalizacaoChart>;
</script>

{#snippet template(args: StoryArgs, ctx: StoryContext<StoryArgs>)}
  <StoryFrame name={ctx.id}>
    <EscolaridadeInstitucionalizacaoChart {...args} />
  </StoryFrame>
{/snippet}

<!--
  A matriz existe para desfazer uma leitura anterior, não para confirmá-la: com
  as quatro situações de institucionalização à vista, a relação com a
  escolaridade do gestor aparece só na última coluna. As três primeiras ficam
  praticamente iguais nas quatro escolaridades, e é isso que a figura mostra.

  `template={template as never}`: the addon's `Snippet` brand and Svelte's own
  do not unify under svelte-check, so a correctly typed snippet is still
  rejected. The cast is on the hand-off only — the snippet itself stays typed.
-->

<Story name="Padrão" args={{}} template={template as never} />

<!-- O cartão com o próprio fundo, para páginas não brancas. -->
<Story name="Com cartão" args={{ background: '#ffffff' }} template={template as never} />
