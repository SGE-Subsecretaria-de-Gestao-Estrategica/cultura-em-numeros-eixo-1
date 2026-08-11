<script module>
  import { defineMeta } from '@storybook/addon-svelte-csf';
  import TripeInstitucionalChart from './TripeInstitucionalChart.svelte';

  const { Story } = defineMeta({
    title: 'Charts/Tripé Institucional',
    component: TripeInstitucionalChart,
    tags: ['autodocs'],
    parameters: {
      layout: 'padded',
    },
  });
</script>

<Story name="Default" />
