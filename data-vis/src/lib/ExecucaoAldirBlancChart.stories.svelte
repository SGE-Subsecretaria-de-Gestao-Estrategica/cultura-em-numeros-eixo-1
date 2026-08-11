<script module>
  import { defineMeta } from '@storybook/addon-svelte-csf';
  import ExecucaoAldirBlancChart from './ExecucaoAldirBlancChart.svelte';

  const { Story } = defineMeta({
    title: 'Charts/Execução da Lei Aldir Blanc',
    component: ExecucaoAldirBlancChart,
    tags: ['autodocs'],
    parameters: {
      layout: 'padded',
    },
  });
</script>

<Story name="Default" />
