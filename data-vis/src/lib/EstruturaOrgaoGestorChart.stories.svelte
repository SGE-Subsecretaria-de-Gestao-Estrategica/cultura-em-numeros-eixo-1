<script module lang="ts">
  import type { ComponentProps } from 'svelte';
  import { defineMeta, type StoryContext } from '@storybook/addon-svelte-csf';
  import StoryFrame from './StoryFrame.svelte';
  import EstruturaOrgaoGestorChart from './EstruturaOrgaoGestorChart.svelte';

  const { Story } = defineMeta({
    title: 'Charts/Estrutura do Órgão Gestor',
    component: EstruturaOrgaoGestorChart,
    tags: ['autodocs'],
    parameters: {
      layout: 'padded',
    },
    /** Sem o fundo do cartão — ver a nota em SerieHistoricaChart.stories. */
    args: { background: null },
  });

  // `Args<typeof Story>` collapses to `never` for a meta declared with
  // `component`; the story args are just the component's props.
  type StoryArgs = ComponentProps<typeof EstruturaOrgaoGestorChart>;
</script>

<!-- `template={template as never}`: ver a nota em RibbonChart.stories.svelte. -->
{#snippet template(args: StoryArgs, ctx: StoryContext<StoryArgs>)}
  <StoryFrame name={ctx.id}>
    <EstruturaOrgaoGestorChart {...args} />
  </StoryFrame>
{/snippet}

<Story name="Default" template={template as never} />
