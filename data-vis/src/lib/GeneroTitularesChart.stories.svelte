<script module>
  import { defineMeta } from '@storybook/addon-svelte-csf';
  import GeneroTitularesChart from './GeneroTitularesChart.svelte';

  const { Story } = defineMeta({
    title: 'Charts/Gênero dos Titulares',
    component: GeneroTitularesChart,
    tags: ['autodocs'],
    parameters: {
      layout: 'padded',
    },
  });
</script>

<Story name="Default" />
