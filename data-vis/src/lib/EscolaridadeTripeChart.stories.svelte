<script module>
  import { defineMeta } from '@storybook/addon-svelte-csf';
  import EscolaridadeTripeChart from './EscolaridadeTripeChart.svelte';

  const { Story } = defineMeta({
    title: 'Charts/Escolaridade e Tripé Completo',
    component: EscolaridadeTripeChart,
    tags: ['autodocs'],
    parameters: {
      layout: 'padded',
    },
  });
</script>

<Story name="Default" />
