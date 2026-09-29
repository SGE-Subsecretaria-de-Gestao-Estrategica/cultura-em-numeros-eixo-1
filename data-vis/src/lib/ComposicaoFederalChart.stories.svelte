<script module lang="ts">
  import type { ComponentProps } from 'svelte';
  import { defineMeta, type StoryContext } from '@storybook/addon-svelte-csf';
  import ComposicaoFederalChart from './ComposicaoFederalChart.svelte';
  import StoryFrame from './StoryFrame.svelte';

  const { Story } = defineMeta({
    title: 'Orçamento/Federal/Composição por fonte',
    component: ComposicaoFederalChart,
    tags: ['autodocs'],
    parameters: { layout: 'padded' },
    /**
     * Sem o fundo do cartão, que é como o PNG é rasterizado (`?bg=0`): o SVG
     * baixado daqui compõe sobre a página em que for colocado.
     */
    args: { background: null },
  });

  type StoryArgs = ComponentProps<typeof ComposicaoFederalChart>;
</script>

{#snippet template(args: StoryArgs, ctx: StoryContext<StoryArgs>)}
  <StoryFrame name={ctx.id}>
    <ComposicaoFederalChart {...args} />
  </StoryFrame>
{/snippet}

<!--
  A versão em colunas da composição federal por fonte: cada ano fecha em
  100%, empilhado de baixo para cima, e a fatia que a geometria comportar
  recebe o próprio número.

  É a mesma tabela de `Federal · Histomap por fonte`, e as duas figuras
  divergem de propósito. Lá o tempo desce e as transições são suavizadas,
  porque o fluxo é o assunto; aqui a fatia muda em degrau na virada do ano,
  fiel à medida anual, e é essa fidelidade que sustenta escrever o percentual
  dentro do segmento.

  `template={template as never}`: the addon's `Snippet` brand and Svelte's own
  do not unify under svelte-check, so a correctly typed snippet is still
  rejected. The cast is on the hand-off only — the snippet itself stays typed.
-->

<Story name="Padrão" args={{}} template={template as never} />

<!--
  Os 23 anos corridos em vez dos sete anos-marco — a comparação direta com o
  histomap, na mesma unidade de tempo. O preço é o número: numa coluna fina a
  geometria não escreve o percentual, e só a cor e a legenda identificam a
  fatia.
-->
<Story name="Todos os anos" args={{ variante: 'todos' }} template={template as never} />

<!-- O cartão com o próprio fundo e a própria borda, para páginas não brancas. -->
<Story name="Com cartão" args={{ background: '#ffffff' }} template={template as never} />
