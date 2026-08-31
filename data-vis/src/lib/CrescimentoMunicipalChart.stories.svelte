<script module lang="ts">
  import type { ComponentProps } from 'svelte';
  import { defineMeta, type StoryContext } from '@storybook/addon-svelte-csf';
  import CrescimentoMunicipalChart from './CrescimentoMunicipalChart.svelte';
  import StoryFrame from './StoryFrame.svelte';

  const { Story } = defineMeta({
    title: 'Charts/Municipal · Crescimento por origem',
    component: CrescimentoMunicipalChart,
    tags: ['autodocs'],
    parameters: { layout: 'padded' },
    args: { background: null },
  });

  type StoryArgs = ComponentProps<typeof CrescimentoMunicipalChart>;
</script>

{#snippet template(args: StoryArgs, ctx: StoryContext<StoryArgs>)}
  <StoryFrame name={ctx.id}>
    <CrescimentoMunicipalChart {...args} />
  </StoryFrame>
{/snippet}

<!--
  A ponte entre o investimento municipal de 2019 e o de 2024. Os dois estoques
  pousam no chão; as duas parcelas flutuam entre eles. A Lei Aldir Blanc 1
  aparece com valor quase nulo porque a cascata compara dois anos e ela já tinha
  saído em 2024 — a nota de rodapé nomeia os R$ 1,7 bi que ela executou em 2020
  e 2021, que é o que o leitor procura ao não encontrá-la aqui.

  `template={template as never}`: the addon's `Snippet` brand and Svelte's own
  do not unify under svelte-check, so a correctly typed snippet is still
  rejected. The cast is on the hand-off only — the snippet itself stays typed.
-->

<Story name="Padrão" args={{}} template={template as never} />

<!-- O cartão com o próprio fundo, para páginas não brancas. -->
<Story name="Com cartão" args={{ background: '#ffffff' }} template={template as never} />
