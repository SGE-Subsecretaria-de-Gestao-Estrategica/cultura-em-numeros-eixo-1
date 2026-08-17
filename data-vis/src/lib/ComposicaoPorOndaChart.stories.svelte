<script module lang="ts">
  import type { ComponentProps } from 'svelte';
  import { defineMeta, type StoryContext } from '@storybook/addon-svelte-csf';
  import ComposicaoPorOndaChart from './ComposicaoPorOndaChart.svelte';
  import StoryFrame from './StoryFrame.svelte';
  import { categoricaDe, rampaDe, rampaVermelha } from './cores';
  import gestao from '../data/gestao-municipal.json';

  const { Story } = defineMeta({
    title: 'Charts/ComposicaoPorOndaChart',
    component: ComposicaoPorOndaChart,
    tags: ['autodocs'],
    parameters: { layout: 'padded' },
    argTypes: {
      showBase: { control: 'boolean' },
      width: { control: { type: 'range', min: 600, max: 1900, step: 20 } },
      responsive: { control: 'boolean' },
    },
    /** Sem o fundo do cartão — ver a nota em SerieHistoricaChart.stories. */
    args: { background: null },
  });

  /** Rampa sequencial: as categorias da estrutura estão ordenadas por grau de
      institucionalização, do mais escuro ao mais claro — a mesma rampa da marca
      que o `EstruturaOrgaoGestorChart` desenha sobre os mesmos dados. */
  const estruturaColors = [...rampaVermelha];

  /** Dois degraus da mesma rampa, separados por luminosidade e não por matiz:
      gênero não é uma escala, mas duas matizes aqui sugeririam um contraste que
      o dado não tem. */
  const generoColors = rampaDe(2);

  /** Cinco categorias de novo, mas aqui três delas são fatias muito finas —
      amarela e indígena não passam de 0,8% —, então vale a escala categórica,
      que é onde a marca separa mais. */
  const corRacaColors = categoricaDe(5);

  // `Args<typeof Story>` collapses to `never` for a meta declared with
  // `component`; the story args are just the component's props.
  type StoryArgs = ComponentProps<typeof ComposicaoPorOndaChart>;
</script>

{#snippet template(args: StoryArgs, ctx: StoryContext<StoryArgs>)}
  <StoryFrame name={ctx.id}>
    <ComposicaoPorOndaChart {...args} />
  </StoryFrame>
{/snippet}

<!--
  Composição percentual de uma categórica, uma coluna por onda de pesquisa,
  empilhada até 100%.

  Não há variante A4: o cartão já é escrito na largura da coluna de texto de um
  A4 retrato e escala o próprio tipo por `a4Scale`.

  `template={template as never}`: ver a nota em RibbonChart.stories.svelte.
-->

<!--
  Cinco categorias com nomes longos: a legenda quebra em duas linhas e o cartão
  reserva a altura das duas antes de se diagramar. Os segmentos de 2% ficam
  finos demais para conter o número, que sai para uma guia à direita da coluna.
-->
<Story
  name="Estrutura do órgão gestor"
  args={{
    data: gestao.estrutura.ondas,
    categorias: gestao.estrutura.categorias,
    colors: estruturaColors,
    title: 'A estrutura do órgão gestor da cultura',
    subtitle: 'Como a cultura está alocada na administração municipal, em cada onda da MUNIC.',
    source: 'Fonte: MUNIC/IBGE (2006, 2014, 2018 e 2021).',
  }}
  template={template as never}
/>

<!-- Duas categorias, legenda numa linha, nenhum segmento fino: o caso simples. -->
<Story
  name="Duas categorias"
  args={{
    data: gestao.genero.ondas,
    categorias: gestao.genero.categorias,
    colors: generoColors,
    title: 'Gênero dos titulares dos órgãos gestores de cultura',
    subtitle: 'Participação feminina e masculina no comando da política cultural municipal.',
    source: 'Fonte: MUNIC/IBGE (2014, 2018 e 2021).',
  }}
  template={template as never}
/>

<!--
  Duas ondas e três fatias residuais — preta em 6%, amarela e indígena abaixo de
  1% — que saem todas para a guia e são empurradas para não se sobreporem entre
  si. Os dados já estão em `gestao-municipal.json`; o gráfico ainda não tem
  wrapper próprio (é o A9 do PLANO.md).
-->
<Story
  name="Fatias residuais"
  args={{
    data: gestao.corRaca.ondas,
    categorias: gestao.corRaca.categorias,
    colors: corRacaColors,
    title: 'Cor ou raça dos titulares dos órgãos gestores de cultura',
    subtitle: 'Declaração do titular, nas duas ondas em que a MUNIC coletou a informação.',
    source: 'Fonte: MUNIC/IBGE (2018 e 2021).',
  }}
  template={template as never}
/>

<!-- `showBase` desligado: sem a contagem de municípios sob o rótulo da onda. -->
<Story
  name="Sem a base de respostas"
  args={{
    data: gestao.genero.ondas,
    categorias: gestao.genero.categorias,
    colors: generoColors,
    showBase: false,
    title: 'Gênero dos titulares dos órgãos gestores de cultura',
    subtitle: 'O mesmo gráfico sem a contagem de municípios sob cada onda.',
  }}
  template={template as never}
/>
