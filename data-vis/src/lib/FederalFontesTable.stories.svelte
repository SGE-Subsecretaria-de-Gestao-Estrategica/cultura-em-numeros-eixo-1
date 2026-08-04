<script module lang="ts">
  import { defineMeta } from '@storybook/addon-svelte-csf';
  import { categorical8 } from 'sniic-design-system';
  import FederalFontesTable from './FederalFontesTable.svelte';
  import federal from '../data/federal-por-fonte.json';

  const { Story } = defineMeta({
    title: 'Charts/Federal · Tabela por fonte',
    component: FederalFontesTable,
    tags: ['autodocs'],
    parameters: { layout: 'padded' },
  });

  const labels: Record<string, string> = {
    'Ministério da Cultura (órgão 42000)': 'MinC',
    'Lei Rouanet': 'Rouanet',
    'Incentivo (ANCINE)': 'ANCINE',
    'FSA (UO 74912)': 'FSA',
    'PNAB (UO 73120)': 'PNAB',
    'Lei Paulo Gustavo': 'LPG',
    'Lei Aldir Blanc 1': 'LAB 1',
    'Outros órgãos (Cidadania/Turismo)': 'Outros órgãos',
  };

  /** Mesmas cores do ribbon chart, para quem lê os dois lado a lado. */
  const ordem = [0, 1, 6, 2, 3, 5, 4, 7];
  const colors = Object.fromEntries(
    federal.keys.map((k, i) => [k, categorical8[ordem[i]]]),
  );
</script>

<Story
  name="Valores reais"
  args={{
    data: federal.real,
    keys: federal.keys,
    labels,
    colors,
    caption:
      'Gasto federal pleno em cultura por fonte de recurso, em R$ correntes de 2024 (IPCA). ' +
      'Fonte: SIOP, SALIC e ANCINE. Um traço indica ausência de execução no ano — a fonte ' +
      'não existia, ou o empenho líquido foi nulo (caso do FSA em 2014).',
  }}
/>

<Story
  name="Valores nominais"
  args={{
    data: federal.nominal,
    keys: federal.keys,
    labels,
    colors,
    caption:
      'Gasto federal pleno em cultura por fonte de recurso, valores nominais. ' +
      'Fonte: SIOP, SALIC e ANCINE.',
  }}
/>
