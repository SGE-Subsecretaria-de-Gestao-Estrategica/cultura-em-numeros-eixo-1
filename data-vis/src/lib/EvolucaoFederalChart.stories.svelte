<script module lang="ts">
  import type { ComponentProps } from 'svelte';
  import { defineMeta, type StoryContext } from '@storybook/addon-svelte-csf';
  import EvolucaoFederalChart from './EvolucaoFederalChart.svelte';
  import StoryFrame from './StoryFrame.svelte';
  import { grupoFederalColors, grupoFederalLabels } from './fontes';
  import federal from '../data/federal-por-fonte.json';

  const { Story } = defineMeta({
    title: 'Charts/Federal · Evolução por fonte',
    component: EvolucaoFederalChart,
    tags: ['autodocs'],
    parameters: { layout: 'padded' },
    argTypes: {
      columnRatio: { control: { type: 'range', min: 0.15, max: 0.8, step: 0.01 } },
    },
  });

  const grupos = federal.grupos;

  /** Bilhões com uma casa: a escala do gráfico não sustenta mais precisão. */
  const bi = (v: number) =>
    `R$ ${(v / 1e9).toLocaleString('pt-BR', {
      minimumFractionDigits: 1,
      maximumFractionDigits: 1,
    })} bi`;

  /**
   * Os quatro anos sem Ministério da Cultura — e, não por acaso, os quatro em
   * que a renúncia fiscal fica acima da execução direta.
   */
  const destaque = {
    de: '2019',
    ate: '2022',
    texto: 'MinC extinto · a renúncia passa à frente',
  };

  const base = {
    data: grupos.real,
    linhas: grupos.linhas,
    colunas: grupos.colunas,
    labels: grupoFederalLabels,
    colors: grupoFederalColors,
    destaque,
    valueFormat: bi,
    unidade: 'R$ bilhões · preços médios de 2024',
    // 2024 tem R$ 11 mi de PNAB: uma coluna de meio pixel, cujo rótulo pairaria
    // sobre o nada
    minRotuloColuna: 5e8,
  };

  type StoryArgs = ComponentProps<typeof EvolucaoFederalChart>;

  /**
   * Impressão a 9 pt numa figura que ocupa a largura de texto do A4 paisagem.
   * O tipo em SVG é absoluto, então o tamanho impresso sai da razão entre corpo
   * e largura do gráfico — daí a escala, e não um gráfico menor.
   */
  const A4_PAISAGEM_MM = 257;
  const A4 = {
    responsive: false,
    width: 1800,
    height: 900,
    fontScale: (3.175 / A4_PAISAGEM_MM) * (1800 / 12),
  };
</script>

{#snippet template(args: StoryArgs, ctx: StoryContext<StoryArgs>)}
  <StoryFrame name={ctx.id}>
    <EvolucaoFederalChart {...args} />
  </StoryFrame>
{/snippet}

<!--
  Combo de linhas e colunas num eixo só.

  A forma sai do formato da série: das oito fontes originais, quatro existem em
  quatro anos ou menos e duas em um único ano — LAB 1 só em 2020, LPG só em
  2022. Metade delas não é série temporal, e uma linha precisa de dois pontos.
  Agrupadas pelo que são institucionalmente, sobram três: duas contínuas, que
  viram linhas, e uma episódica, que vira coluna.
-->

<Story name="Padrão" args={base} template={template as never} />

<Story
  name="Valores nominais"
  args={{
    ...base,
    data: grupos.nominal,
    unidade: 'R$ bilhões · valores nominais',
  }}
  template={template as never}
/>

<Story
  name="A4 paisagem"
  exportName="A4"
  args={{ ...base, ...A4 }}
  template={template as never}
/>
