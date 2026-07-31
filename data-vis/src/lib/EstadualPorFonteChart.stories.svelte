<script module>
  import { defineMeta } from '@storybook/addon-svelte-csf';
  import EstadualPorFonteChart from './EstadualPorFonteChart.svelte';

  const { Story } = defineMeta({
    title: 'Charts/Estadual por Fonte',
    component: EstadualPorFonteChart,
    tags: ['autodocs'],
    parameters: {
      layout: 'padded',
    },
  });
</script>

<Story name="Default" />
