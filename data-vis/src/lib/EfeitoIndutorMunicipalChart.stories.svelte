<script module>
  import { defineMeta } from '@storybook/addon-svelte-csf';
  import EfeitoIndutorMunicipalChart from './EfeitoIndutorMunicipalChart.svelte';

  const { Story } = defineMeta({
    title: 'Charts/Efeito Indutor por Região',
    component: EfeitoIndutorMunicipalChart,
    tags: ['autodocs'],
    parameters: {
      layout: 'padded',
    },
  });
</script>

<Story name="Default" />
