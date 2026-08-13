<script module lang="ts">
  import type { ComponentProps } from 'svelte';
  import { defineMeta, type StoryContext } from '@storybook/addon-svelte-csf';
  import StoryFrame from './StoryFrame.svelte';
  import GeneroTitularesChart from './GeneroTitularesChart.svelte';

  const { Story } = defineMeta({
    title: 'Charts/Gênero dos Titulares',
    component: GeneroTitularesChart,
    tags: ['autodocs'],
    parameters: {
      layout: 'padded',
    },
    /** Sem o fundo do cartão — ver a nota em SerieHistoricaChart.stories. */
    args: { background: null },
  });

  // `Args<typeof Story>` collapses to `never` for a meta declared with
  // `component`; the story args are just the component's props.
  type StoryArgs = ComponentProps<typeof GeneroTitularesChart>;
</script>

<!-- `template={template as never}`: ver a nota em RibbonChart.stories.svelte. -->
{#snippet template(args: StoryArgs, ctx: StoryContext<StoryArgs>)}
  <StoryFrame name={ctx.id}>
    <GeneroTitularesChart {...args} />
  </StoryFrame>
{/snippet}

<Story name="Default" template={template as never} />
