<script module>
  import { defineMeta } from '@storybook/addon-svelte-csf';
  import MunicipalPorFonteChart from './MunicipalPorFonteChart.svelte';

  const { Story } = defineMeta({
    title: 'Charts/Municipal por Fonte',
    component: MunicipalPorFonteChart,
    tags: ['autodocs'],
    parameters: {
      layout: 'padded',
    },
  });
</script>

<Story name="Default" />
