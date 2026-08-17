<script module lang="ts">
  import type { ComponentProps } from 'svelte';
  import { defineMeta, type StoryContext } from '@storybook/addon-svelte-csf';
  import BarrasHorizontaisChart from './BarrasHorizontaisChart.svelte';
  import StoryFrame from './StoryFrame.svelte';
  import { sniic } from './cores';
  import gestao from '../data/gestao-municipal.json';

  const { Story } = defineMeta({
    title: 'Charts/BarrasHorizontaisChart',
    component: BarrasHorizontaisChart,
    tags: ['autodocs'],
    parameters: { layout: 'padded' },
    argTypes: {
      bandHeight: { control: { type: 'range', min: 16, max: 60, step: 2 } },
      width: { control: { type: 'range', min: 600, max: 1900, step: 20 } },
      responsive: { control: 'boolean' },
    },
    /** Sem o fundo do cartão — ver a nota em SerieHistoricaChart.stories. */
    args: { background: null },
  });

  const decimal = new Intl.NumberFormat('pt-BR', {
    minimumFractionDigits: 1,
    maximumFractionDigits: 1,
  });
  const integer = new Intl.NumberFormat('pt-BR');

  /** Barra = percentual; o rótulo carrega também o n, porque as faixas são
      muito desiguais (105 municípios contra 4.988). */
  const escolaridade = gestao.escolaridadeTripe.itens.map((i) => ({
    label: i.label,
    valor: i.pct,
    rotulo: `${decimal.format(i.pct)}%  (${integer.format(i.valor)} de ${integer.format(i.n)})`,
  }));

  /** Barra = contagem; o rótulo traz contagem e participação. */
  const aldirBlanc = gestao.execucaoLab.itens.map((i) => ({
    label: i.label,
    valor: i.valor,
    rotulo: `${integer.format(i.valor)}  (${decimal.format(i.pct)}%)`,
  }));

  // `Args<typeof Story>` collapses to `never` for a meta declared with
  // `component`; the story args are just the component's props.
  type StoryArgs = ComponentProps<typeof BarrasHorizontaisChart>;
</script>

{#snippet template(args: StoryArgs, ctx: StoryContext<StoryArgs>)}
  <StoryFrame name={ctx.id}>
    <BarrasHorizontaisChart {...args} />
  </StoryFrame>
{/snippet}

<!--
  Barras horizontais com o rótulo da categoria à esquerda e o valor na ponta.
  As duas margens laterais são medidas no texto que vai ocupá-las, então nenhum
  nome de categoria e nenhum valor sai cortado, seja qual for o comprimento.

  Não há variante A4: o cartão já é escrito na largura da coluna de texto de um
  A4 retrato e escala o próprio tipo por `a4Scale`.

  `template={template as never}`: ver a nota em RibbonChart.stories.svelte.
-->

<!-- Poucas barras e um nome de categoria longo — "Ensino médio a pós-graduação
     lato sensu" é o que dimensiona a coluna da esquerda. -->
<Story
  name="Rótulos longos"
  args={{
    itens: escolaridade,
    color: sniic.azul,
    title: 'Escolaridade do gestor e institucionalização da cultura',
    subtitle:
      'Percentual de municípios com o tripé completo — plano, fundo e conselho — por escolaridade do titular, em 2021.',
    source: 'Fonte: MUNIC/IBGE 2021.',
  }}
  template={template as never}
/>

<!-- Onze categorias ordenadas, com a faixa mais estreita para o conjunto caber
     numa figura só. -->
<Story
  name="Muitas categorias"
  args={{
    itens: aldirBlanc,
    color: sniic.vermelho,
    bandHeight: 26,
    title: 'Execução do repasse da Lei Aldir Blanc pelos municípios',
    subtitle:
      'Distribuição dos municípios pelo percentual do recurso recebido que chegou a ser executado, em 2021.',
    source: 'Fonte: MUNIC/IBGE 2021.',
  }}
  template={template as never}
/>

<!--
  `xMax` fixo em 100: as barras passam a medir o percentual contra a escala
  inteira, e não contra o maior valor da série. É a leitura certa quando a
  pergunta é "quão longe de todos os municípios", e não "qual faixa é a maior".
-->
<Story
  name="Escala fixa em 100%"
  args={{
    itens: escolaridade,
    color: sniic.azul,
    xMax: 100,
    title: 'Escolaridade do gestor e institucionalização da cultura',
    subtitle: 'As mesmas barras contra a escala inteira: o tripé completo é minoria em toda faixa.',
    source: 'Fonte: MUNIC/IBGE 2021.',
  }}
  template={template as never}
/>
