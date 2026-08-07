<script module>
  import { defineMeta } from '@storybook/addon-svelte-csf';
  import PerfilMudancaMunicipalChart from './PerfilMudancaMunicipalChart.svelte';

  const { Story } = defineMeta({
    title: 'Charts/Perfil de Mudança por Porte',
    component: PerfilMudancaMunicipalChart,
    tags: ['autodocs'],
    parameters: {
      layout: 'padded',
    },
  });
</script>

<Story name="Default" />
