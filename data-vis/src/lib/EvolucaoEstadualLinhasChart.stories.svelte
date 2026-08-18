<script module lang="ts">
  import type { ComponentProps } from 'svelte';
  import { defineMeta, type StoryContext } from '@storybook/addon-svelte-csf';
  import EvolucaoEstadualLinhasChart from './EvolucaoEstadualLinhasChart.svelte';
  import StoryFrame from './StoryFrame.svelte';

  const { Story } = defineMeta({
    title: 'Charts/Estadual · Evolução por fonte (linhas)',
    component: EvolucaoEstadualLinhasChart,
    tags: ['autodocs'],
    parameters: { layout: 'padded' },
    argTypes: {
      valores: { control: 'inline-radio', options: ['real', 'nominal'] },
    },
    /**
     * Sem o fundo do cartão, que é como o PNG é rasterizado (`?bg=0`): o SVG
     * baixado daqui compõe sobre a página em que for colocado.
     */
    args: { background: null },
  });

  type StoryArgs = ComponentProps<typeof EvolucaoEstadualLinhasChart>;
</script>

{#snippet template(args: StoryArgs, ctx: StoryContext<StoryArgs>)}
  <StoryFrame name={ctx.id}>
    <EvolucaoEstadualLinhasChart {...args} />
  </StoryFrame>
{/snippet}

<!--
  As cinco fontes do investimento estadual como trajetórias, no cartão do tripé
  institucional.

  É a mesma tabela de `EstadualPorFonteChart`, que a desenha como colunas
  empilhadas, e as duas figuras respondem perguntas diferentes: a pilha diz
  quanto foi o total do ano e como ele se repartiu; as linhas dizem o que cada
  fonte fez ao longo do tempo. Numa pilha, uma faixa que sobe pode estar
  crescendo ou apenas sendo empurrada pela de baixo — aqui cada trajetória é
  lida contra o eixo.

  O que só esta figura mostra: o recurso próprio dos estados dobrando ao longo
  da série e carregando o total sozinho, e as três leis federais se revezando
  por cima dele — LAB 1 em 2020, LPG de 2023 a 2025, PNAB a partir de 2024.

  É o par estadual de `Federal · Evolução por fonte (linhas)`, no mesmo cartão e
  com as mesmas cores das figuras de fonte de recurso.

  `template={template as never}`: the addon's `Snippet` brand and Svelte's own
  do not unify under svelte-check, so a correctly typed snippet is still
  rejected. The cast is on the hand-off only — the snippet itself stays typed.
-->

<Story name="Padrão" args={{ valores: 'real' }} template={template as never} />

<!--
  Os mesmos dados sem deflator. O recurso próprio sobe mais — em reais correntes
  ele parte de R$ 2,5 bi, e não de R$ 3,3 bi —, e é essa diferença que o
  deflator existe para tirar do caminho.
-->
<Story name="Valores nominais" args={{ valores: 'nominal' }} template={template as never} />

<!-- O cartão com o próprio fundo e a própria borda, para páginas não brancas. -->
<Story
  name="Com cartão"
  args={{ valores: 'real', background: '#ffffff' }}
  template={template as never}
/>
