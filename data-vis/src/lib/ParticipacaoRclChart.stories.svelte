<script module lang="ts">
  import type { ComponentProps } from 'svelte';
  import { defineMeta, type StoryContext } from '@storybook/addon-svelte-csf';
  import ParticipacaoRclChart from './ParticipacaoRclChart.svelte';
  import StoryFrame from './StoryFrame.svelte';

  const { Story } = defineMeta({
    title: 'Charts/Federal · Participação no orçamento da União',
    component: ParticipacaoRclChart,
    tags: ['autodocs'],
    parameters: { layout: 'padded' },
    argTypes: {
      medida: { control: 'inline-radio', options: ['pleno', 'direto'] },
    },
    /**
     * Sem o fundo do cartão, que é como o PNG é rasterizado (`?bg=0`): o SVG
     * baixado daqui compõe sobre a página em que for colocado.
     */
    args: { background: null },
  });

  type StoryArgs = ComponentProps<typeof ParticipacaoRclChart>;
</script>

{#snippet template(args: StoryArgs, ctx: StoryContext<StoryArgs>)}
  <StoryFrame name={ctx.id}>
    <ParticipacaoRclChart {...args} />
  </StoryFrame>
{/snippet}

<!--
  Quanto da receita da União foi para a cultura, de 2011 a 2025.

  É a série de `Federal · Evolução por fonte (linhas)` dividida pela capacidade
  de gasto do ano. A diferença entre as duas figuras é o que a divisão revela:
  em reais, 2025 é o segundo maior ano da série; contra a receita do ano, ele
  apenas empata com 2011.

  O cartão é o do tripé institucional — faixa grossa, marcador escuro, valor
  final em destaque na ponta —, que é o que a série pede: uma linha só, com
  nível e tendência para ler, e nenhuma outra com que ela possa ser confundida.

  `template={template as never}`: the addon's `Snippet` brand and Svelte's own
  do not unify under svelte-check, so a correctly typed snippet is still
  rejected. The cast is on the hand-off only — the snippet itself stays typed.
-->

<Story name="Padrão" args={{ medida: 'pleno' }} template={template as never} />

<!--
  Só a despesa orçamentária, sem a renúncia fiscal. A distância para a figura
  padrão é o quanto do esforço federal em cultura não passa pelo orçamento: no
  fim da série, quase dois quintos dele.
-->
<Story name="Só execução direta" args={{ medida: 'direto' }} template={template as never} />

<!-- O cartão com o próprio fundo e a própria borda, para páginas não brancas. -->
<Story
  name="Com cartão"
  args={{ medida: 'pleno', background: '#ffffff' }}
  template={template as never}
/>
