<script module lang="ts">
  import type { ComponentProps } from 'svelte';
  import { defineMeta, type StoryContext } from '@storybook/addon-svelte-csf';
  import EvolucaoFederalLinhasChart from './EvolucaoFederalLinhasChart.svelte';
  import StoryFrame from './StoryFrame.svelte';

  const { Story } = defineMeta({
    title: 'Charts/Federal · Evolução por fonte (linhas)',
    component: EvolucaoFederalLinhasChart,
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

  type StoryArgs = ComponentProps<typeof EvolucaoFederalLinhasChart>;
</script>

{#snippet template(args: StoryArgs, ctx: StoryContext<StoryArgs>)}
  <StoryFrame name={ctx.id}>
    <EvolucaoFederalLinhasChart {...args} />
  </StoryFrame>
{/snippet}

<!--
  As oito fontes federais como trajetórias, no cartão do tripé institucional.

  É a mesma tabela de `Federal · Tabela por fonte`, nas mesmas cores, lida como
  forma em vez de como grade — e a forma é o que mostra o desenho institucional:
  o MinC subindo até 2013 e caindo, a Rouanet colada nele, a ANCINE e o FSA
  rentes ao eixo o tempo todo, e as três fontes de emergência entrando como
  ponto ou lasca depois de 2020.

  O combo em `Federal · Evolução por fonte` agrupa as oito em três por natureza
  institucional, e é a figura para quem quer o total por natureza; esta é a
  figura para quem quer saber de que fonte veio o dinheiro.

  Não há variante A4: o cartão já é escrito na largura da coluna de texto de um
  A4 retrato e escala o próprio tipo por `a4Scale`, então o que estas stories
  mostram é o que sai impresso.

  `template={template as never}`: the addon's `Snippet` brand and Svelte's own
  do not unify under svelte-check, so a correctly typed snippet is still
  rejected. The cast is on the hand-off only — the snippet itself stays typed.
-->

<Story name="Padrão" args={{ valores: 'real' }} template={template as never} />

<!--
  Os mesmos dados sem deflator. O MinC perde o pico de 2013 — em reais
  correntes ele sobe até 2023 —, que é justamente o que o deflator existe para
  mostrar.
-->
<Story name="Valores nominais" args={{ valores: 'nominal' }} template={template as never} />

<!-- O cartão com o próprio fundo e a própria borda, para páginas não brancas. -->
<Story
  name="Com cartão"
  args={{ valores: 'real', background: '#ffffff' }}
  template={template as never}
/>
