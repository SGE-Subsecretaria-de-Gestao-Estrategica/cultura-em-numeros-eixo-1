<script module lang="ts">
  import type { ComponentProps } from 'svelte';
  import { defineMeta, type StoryContext } from '@storybook/addon-svelte-csf';
  import StoryFrame from './StoryFrame.svelte';
  import MunicipalPorFonteChart from './MunicipalPorFonteChart.svelte';

  const { Story } = defineMeta({
    title: 'Charts/Municipal por Fonte',
    component: MunicipalPorFonteChart,
    tags: ['autodocs'],
    parameters: {
      layout: 'padded',
    },
  });

  // `Args<typeof Story>` collapses to `never` for a meta declared with
  // `component`; the story args are just the component's props.
  type StoryArgs = ComponentProps<typeof MunicipalPorFonteChart>;
</script>

<!-- `template={template as never}`: ver a nota em RibbonChart.stories.svelte. -->
{#snippet template(args: StoryArgs, ctx: StoryContext<StoryArgs>)}
  <StoryFrame name={ctx.id}>
    <MunicipalPorFonteChart {...args} />
  </StoryFrame>
{/snippet}

<Story name="Default" template={template as never} />
