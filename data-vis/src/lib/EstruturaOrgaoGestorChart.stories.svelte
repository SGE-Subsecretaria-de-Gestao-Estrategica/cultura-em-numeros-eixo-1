<script module>
  import { defineMeta } from '@storybook/addon-svelte-csf';
  import EstruturaOrgaoGestorChart from './EstruturaOrgaoGestorChart.svelte';

  const { Story } = defineMeta({
    title: 'Charts/Estrutura do Órgão Gestor',
    component: EstruturaOrgaoGestorChart,
    tags: ['autodocs'],
    parameters: {
      layout: 'padded',
    },
  });
</script>

<Story name="Default" />
