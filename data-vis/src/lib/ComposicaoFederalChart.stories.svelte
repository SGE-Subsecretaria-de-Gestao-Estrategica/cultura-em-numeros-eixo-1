<script module lang="ts">
  import type { ComponentProps } from 'svelte';
  import { defineMeta, type StoryContext } from '@storybook/addon-svelte-csf';
  import ComposicaoFederalChart from './ComposicaoFederalChart.svelte';
  import StoryFrame from './StoryFrame.svelte';

  const { Story } = defineMeta({
    title: 'Charts/Federal · Composição por fonte',
    component: ComposicaoFederalChart,
    tags: ['autodocs'],
    parameters: { layout: 'padded' },
    argTypes: {
      forma: { control: 'inline-radio', options: ['colunas', 'area'] },
    },
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
  De onde veio cada real do investimento federal em cultura, ano a ano, em vez
  de quanto foi.

  É o par de `Federal · Evolução por fonte (linhas)`: mesmos dados, mesmas
  cores, total fixo em 100%. O que só esta figura mostra é a fatia permanente da
  renúncia fiscal — entre um terço e dois terços do gasto federal pleno em todos
  os anos medidos — e a substituição do órgão gestor de 2019 a 2022, que na
  série de valores parece o desaparecimento de uma linha e o aparecimento de
  outra.

  As duas formas mostram o mesmo empilhamento e diferem no vão entre os anos.
  Nenhuma interpola a altura da fatia: a fonte vale para o exercício inteiro e
  muda em degrau na virada do ano, o que importa porque três das oito fontes
  existiram em três anos ou menos e uma rampa desenharia entradas e saídas
  graduais que não houve.

  Na forma de colunas, a fronteira de cima de cada fonte é repetida como curva
  por sobre a pilha, dentro do vão de superfície que já separava os segmentos.
  É o que devolve à figura a trajetória de cada fonte sem tirar dela a
  composição: a coluna continua dizendo a repartição do ano, e o vão entre duas
  curvas vizinhas continua sendo a participação da fonte entre elas. Onde a
  fonte não foi executada a curva atravessa tracejada — o MinC de 2019 a 2022,
  o FSA em 2014 —, porque ali não há medida ligando as duas pontas. E onde a
  fonte fecha a pilha não há curva: a fronteira dela é o teto de 100%, que o
  eixo já marca.

  Não há variante nominal: a participação de cada fonte é a mesma nas duas
  medidas, porque o deflator multiplica todas as fontes de um ano pelo mesmo
  índice.

  `template={template as never}`: the addon's `Snippet` brand and Svelte's own
  do not unify under svelte-check, so a correctly typed snippet is still
  rejected. The cast is on the hand-off only — the snippet itself stays typed.
-->

<Story name="Padrão" args={{ forma: 'colunas' }} template={template as never} />

<!--
  A mesma pilha com os anos encostados, e sem as curvas de fronteira: aqui as
  faixas já são contínuas, e o contorno delas é a própria curva.

  O que esta forma ainda tem de seu é a área — a renúncia fiscal aparece como
  uma massa, e não como uma distância entre duas linhas. O que ela perde é o
  ano como objeto contável.
-->
<Story name="Faixas" args={{ forma: 'area' }} template={template as never} />

<!-- O cartão com o próprio fundo e a própria borda, para páginas não brancas. -->
<Story
  name="Com cartão"
  args={{ forma: 'colunas', background: '#ffffff' }}
  template={template as never}
/>
