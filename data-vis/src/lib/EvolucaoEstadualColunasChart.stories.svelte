<script module lang="ts">
  import type { ComponentProps } from 'svelte';
  import { defineMeta, type StoryContext } from '@storybook/addon-svelte-csf';
  import EvolucaoEstadualColunasChart from './EvolucaoEstadualColunasChart.svelte';
  import StoryFrame from './StoryFrame.svelte';

  const { Story } = defineMeta({
    title: 'Charts/Estadual · Evolução por fonte (colunas)',
    component: EvolucaoEstadualColunasChart,
    tags: ['autodocs'],
    parameters: { layout: 'padded' },
    argTypes: {
      valores: { control: 'inline-radio', options: ['real', 'nominal'] },
    },
  });

  type StoryArgs = ComponentProps<typeof EvolucaoEstadualColunasChart>;
</script>

{#snippet template(args: StoryArgs, ctx: StoryContext<StoryArgs>)}
  <StoryFrame name={ctx.id}>
    <EvolucaoEstadualColunasChart {...args} />
  </StoryFrame>
{/snippet}

<!--
  A mesma tabela de `Estadual · Evolução por fonte (linhas)`, empilhada.

  É a figura em que o total do ano existe como objeto visível — e é ele que
  mostra o investimento estadual saindo de R$ 3,3 bi em 2019 para R$ 7,9 bi em
  2025. Nas linhas, cada fonte é lida contra o eixo e o total não é desenhado em
  lugar nenhum.

  A outra coisa que só a pilha mostra: em 2020 e de 2024 em diante a
  transferência federal *soma-se* ao recurso próprio, em vez de competir com
  ele.

  O que ela esconde, e por isso as duas existem: uma faixa que sobe pode estar
  crescendo ou apenas sendo empurrada pela de baixo. O recurso próprio é a base
  de todas as colunas, então tudo que está acima dele se move quando ele se
  move.

  `template={template as never}`: the addon's `Snippet` brand and Svelte's own
  do not unify under svelte-check, so a correctly typed snippet is still
  rejected. The cast is on the hand-off only — the snippet itself stays typed.
-->

<Story name="Padrão" args={{ valores: 'real' }} template={template as never} />

<!-- Os mesmos dados sem deflator, para conferir contra o empenho publicado. -->
<Story name="Valores nominais" args={{ valores: 'nominal' }} template={template as never} />
