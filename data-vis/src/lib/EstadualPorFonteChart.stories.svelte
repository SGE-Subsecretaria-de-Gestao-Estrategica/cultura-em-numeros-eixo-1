<script module lang="ts">
  import type { ComponentProps } from 'svelte';
  import { defineMeta, type StoryContext } from '@storybook/addon-svelte-csf';
  import StoryFrame from './StoryFrame.svelte';
  import EstadualPorFonteChart from './EstadualPorFonteChart.svelte';

  const { Story } = defineMeta({
    title: 'Charts/Estadual por Fonte',
    component: EstadualPorFonteChart,
    tags: ['autodocs'],
    parameters: {
      layout: 'padded',
    },
  });

  // `Args<typeof Story>` collapses to `never` for a meta declared with
  // `component`; the story args are just the component's props.
  type StoryArgs = ComponentProps<typeof EstadualPorFonteChart>;
</script>

<!-- `template={template as never}`: ver a nota em RibbonChart.stories.svelte. -->
{#snippet template(args: StoryArgs, ctx: StoryContext<StoryArgs>)}
  <StoryFrame name={ctx.id}>
    <EstadualPorFonteChart {...args} />
  </StoryFrame>
{/snippet}

<Story name="Default" template={template as never} />
