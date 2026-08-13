<script module lang="ts">
  import type { ComponentProps } from 'svelte';
  import { defineMeta, type StoryContext } from '@storybook/addon-svelte-csf';
  import { categorical8, colorScales } from 'sniic-design-system';
  import SerieHistoricaChart from './SerieHistoricaChart.svelte';
  import StoryFrame from './StoryFrame.svelte';
  import { sniic } from './cores';
  import gestao from '../data/gestao-municipal.json';

  const { Story } = defineMeta({
    title: 'Charts/SerieHistoricaChart',
    component: SerieHistoricaChart,
    tags: ['autodocs'],
    parameters: { layout: 'padded' },
    argTypes: {
      variant: { control: 'inline-radio', options: ['linha', 'faixa'] },
      yMax: { control: { type: 'range', min: 20, max: 100, step: 5 } },
      width: { control: { type: 'range', min: 600, max: 1900, step: 20 } },
      responsive: { control: 'boolean' },
    },
    /**
     * Sem o fundo do cartão, que é como o PNG é rasterizado (`?bg=0`): o SVG
     * baixado daqui compõe sobre a página em que for colocado. O branco atrás
     * das marcas é a tela do Storybook, não do gráfico.
     */
    args: { background: null },
  });

  const tripeColors = [categorical8[0], categorical8[2], categorical8[1]];
  const equipColors = [categorical8[0], categorical8[1], categorical8[2], categorical8[4]];

  /**
   * Duas séries a menos de um ponto de distância na primeira e na última onda,
   * e cruzando no meio. É o caso que a colocação dos rótulos existe para
   * resolver: sem ela, o valor da série de baixo aterrissa sobre a linha da de
   * cima. Sintético — os dados reais mais apertados são museu e teatro, que já
   * aparecem na story de equipamentos.
   */
  const coladas = [
    {
      key: 'a',
      label: 'Série A',
      pontos: [
        { ano: 2006, pct: 22.4 },
        { ano: 2014, pct: 30.1 },
        { ano: 2021, pct: 25.2 },
      ],
    },
    {
      key: 'b',
      label: 'Série B',
      pontos: [
        { ano: 2006, pct: 21.9 },
        { ano: 2014, pct: 30.6 },
        { ano: 2021, pct: 25.9 },
      ],
    },
  ];

  // `Args<typeof Story>` collapses to `never` for a meta declared with
  // `component`; the story args are just the component's props.
  type StoryArgs = ComponentProps<typeof SerieHistoricaChart>;
</script>

{#snippet template(args: StoryArgs, ctx: StoryContext<StoryArgs>)}
  <StoryFrame name={ctx.id}>
    <SerieHistoricaChart {...args} />
  </StoryFrame>
{/snippet}

<!--
  Séries percentuais medidas em ondas de pesquisa, uma linha por indicador, com
  o nome de cada série na ponta da linha em vez de numa legenda.

  Não há variante A4 aqui: o cartão já é escrito na largura da coluna de texto
  de um A4 retrato e escala o próprio tipo por `a4Scale`, então o que estas
  stories mostram é o que sai impresso.

  `template={template as never}`: the addon's `Snippet` brand and Svelte's own
  do not unify under svelte-check, so a correctly typed snippet is still
  rejected. The cast is on the hand-off only — the snippet itself stays typed.
-->

<!--
  A variante de faixa como o relatório a usa: uma cor de marca para todas as
  séries, marcadores azuis, o eixo Y trocado por rótulo em todo ponto, o
  intervalo entre as ondas anotado no topo, o bloco de leitura na ponta de cada
  linha e a régua de bolinhas embaixo. O plot conta em municípios; a régua, em
  proporção — e o valor de 2021 é o único em azul, nos dois.
-->
<Story
  name="Tripé institucional"
  args={{
    series: gestao.tripe.series,
    colors: [sniic.vermelho],
    markerColor: sniic.azul,
    endValueColor: sniic.azul,
    valueFormat: 'abs',
    dotStrip: true,
    dotStripLead: 'Do total de 5.570 municípios brasileiros, isso representa…',
    variant: 'faixa',
    title: 'Evolução do tripé institucional da cultura',
    subtitle:
      'Proporção dos municípios brasileiros com cada instrumento do Sistema Nacional de Cultura criado.',
    source: 'Fonte: MUNIC/IBGE (2006, 2014, 2018 e 2021).',
  }}
  template={template as never}
/>

<!-- As mesmas séries na variante fina, para comparar as duas lado a lado. -->
<Story
  name="Tripé institucional · linha"
  args={{
    series: gestao.tripe.series,
    colors: tripeColors,
    title: 'Evolução do tripé institucional da cultura',
    subtitle: 'A mesma série na variante fina, com eixo Y e grade horizontal.',
    source: 'Fonte: MUNIC/IBGE (2006, 2014, 2018 e 2021).',
  }}
  template={template as never}
/>

<!--
  Quatro séries, três delas amontoadas entre 9% e 30% de um eixo que vai a 100%
  — o caso apertado da variante de faixa. Os blocos de ponta não cabem na altura
  que separa as linhas, então são puxados para cima até caberem, na ordem das
  séries. Em 2006, museu e teatro estão a 0,7 ponto de distância: nessa escala,
  as duas faixas se sobrepõem.
-->
<Story
  name="Séries próximas"
  args={{
    series: gestao.equipamentos.series,
    colors: equipColors,
    variant: 'faixa',
    yMax: 100,
    title: 'Equipamentos culturais nos municípios',
    subtitle: 'Proporção dos municípios que declaram ter cada equipamento em funcionamento.',
    source: 'Fonte: MUNIC/IBGE (2006, 2014 e 2021).',
  }}
  template={template as never}
/>

<!-- Duas séries que se cruzam coladas: o caso-limite do posicionamento. -->
<Story
  name="Séries que se cruzam"
  args={{
    series: coladas,
    colors: [colorScales.purple[2], colorScales.teal[2]],
    yMax: 40,
    title: 'Duas séries a menos de um ponto de distância',
    subtitle: 'Caso sintético, para exercitar a resolução de colisão dos rótulos.',
  }}
  template={template as never}
/>

<!--
  A única story com cartão: o gráfico desenha o próprio fundo e a própria
  borda, para quem for colocá-lo sobre uma página que não seja branca. Todas as
  outras seguem o padrão do export, sem fundo.
-->
<Story
  name="Com cartão"
  args={{
    series: gestao.tripe.series,
    colors: tripeColors,
    variant: 'faixa',
    background: '#ffffff',
    title: 'Evolução do tripé institucional da cultura',
    subtitle: 'O mesmo gráfico com o fundo e a borda do cartão.',
  }}
  template={template as never}
/>
