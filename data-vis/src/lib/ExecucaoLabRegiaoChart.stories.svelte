<script module lang="ts">
  import type { ComponentProps } from 'svelte';
  import { defineMeta, type StoryContext } from '@storybook/addon-svelte-csf';
  import StoryFrame from './StoryFrame.svelte';
  import ExecucaoLabRegiaoChart from './ExecucaoLabRegiaoChart.svelte';

  const { Story } = defineMeta({
    title: 'Charts/Execução da Aldir Blanc por Região',
    component: ExecucaoLabRegiaoChart,
    tags: ['autodocs'],
    parameters: {
      layout: 'padded',
    },
    /** Sem o fundo do cartão — ver a nota em SerieHistoricaChart.stories. */
    args: { background: null },
  });

  type StoryArgs = ComponentProps<typeof ExecucaoLabRegiaoChart>;
</script>

<!-- `template={template as never}`: ver a nota em RibbonChart.stories.svelte. -->
{#snippet template(args: StoryArgs, ctx: StoryContext<StoryArgs>)}
  <StoryFrame name={ctx.id}>
    <ExecucaoLabRegiaoChart {...args} />
  </StoryFrame>
{/snippet}

<Story name="Default" template={template as never} />
