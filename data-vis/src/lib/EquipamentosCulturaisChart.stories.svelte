<script module>
  import { defineMeta } from '@storybook/addon-svelte-csf';
  import EquipamentosCulturaisChart from './EquipamentosCulturaisChart.svelte';

  const { Story } = defineMeta({
    title: 'Charts/Equipamentos Culturais',
    component: EquipamentosCulturaisChart,
    tags: ['autodocs'],
    parameters: {
      layout: 'padded',
    },
  });
</script>

<Story name="Default" />
