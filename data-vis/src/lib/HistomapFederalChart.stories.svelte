<script module lang="ts">
  import type { ComponentProps } from 'svelte';
  import { defineMeta, type StoryContext } from '@storybook/addon-svelte-csf';
  import HistomapFederalChart from './HistomapFederalChart.svelte';
  import StoryFrame from './StoryFrame.svelte';

  const { Story } = defineMeta({
    title: 'Charts/Federal · Histomap por fonte',
    component: HistomapFederalChart,
    tags: ['autodocs'],
    parameters: { layout: 'padded' },
    /**
     * Sem o fundo do cartão, que é como o PNG é rasterizado (`?bg=0`): o SVG
     * baixado daqui compõe sobre a página em que for colocado.
     */
    args: { background: null },
  });

  type StoryArgs = ComponentProps<typeof HistomapFederalChart>;
</script>

{#snippet template(args: StoryArgs, ctx: StoryContext<StoryArgs>)}
  <StoryFrame name={ctx.id}>
    <HistomapFederalChart {...args} />
  </StoryFrame>
{/snippet}

<!--
  A versão histomap da evolução federal por fonte: o tempo desce pelo eixo Y e
  cada fonte é uma faixa tão larga quanto a sua participação no total do ano,
  com a soma fechando em 100% — a régua do Histomap de 1931, o "poder relativo"
  ano a ano.

  É a mesma tabela de `Federal · Composição por fonte`, e as duas figuras
  divergem de propósito: lá a fatia muda em degrau na virada do ano, fiel à
  medida anual; aqui as transições são suavizadas porque o fluxo é o assunto.
  O total do ano, que o fechamento em 100% esconde, volta pela calha direita.

  `template={template as never}`: the addon's `Snippet` brand and Svelte's own
  do not unify under svelte-check, so a correctly typed snippet is still
  rejected. The cast is on the hand-off only — the snippet itself stays typed.
-->

<Story name="Padrão" args={{}} template={template as never} />

<!-- O cartão com o próprio fundo e a própria borda, para páginas não brancas. -->
<Story name="Com cartão" args={{ background: '#ffffff' }} template={template as never} />
