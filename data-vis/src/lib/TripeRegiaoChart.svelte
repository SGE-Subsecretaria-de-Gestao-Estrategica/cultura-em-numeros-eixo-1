<script lang="ts">
  import TabelaVisualChart from './TabelaVisualChart.svelte';
  import { sniic } from './cores';
  import gestao from '../data/gestao-municipal.json';

  let {
    svgEl = $bindable(null),
    background,
  }: { svgEl?: SVGSVGElement | null; background?: string | null } = $props();

  const decimal = new Intl.NumberFormat('pt-BR', {
    minimumFractionDigits: 1,
    maximumFractionDigits: 1,
  });

  const pct = (v: number) => `${decimal.format(v)}%`;

  /**
   * A coluna do tripé completo sai no vermelho da marca e em negrito: é a
   * medida-síntese que a tabela existe para mostrar, e as outras três colunas
   * são a decomposição dela. Nada de fundo — vinte linhas de heatmap em quatro
   * colunas de escalas diferentes virariam ruído.
   */
  const secoes = gestao.tripeRegiao.ondas.map((onda) => ({
    label: String(onda.ano),
    rows: onda.regioes.map((r) => ({
      label: r.regiao,
      cells: [
        { text: pct(r.conselho) },
        { text: pct(r.fundo) },
        { text: pct(r.plano) },
        { text: pct(r.completo), textColor: sniic.vermelho, fontWeight: 600 },
      ],
    })),
  }));
</script>

<TabelaVisualChart
  colunas={['Conselho', 'Fundo', 'Plano', 'Tripé completo']}
  rotuloLinhas="Região"
  {secoes}
  title="Evolução regional do tripé institucional da cultura"
  subtitle="Percentual de municípios de cada região com conselho, fundo e plano de cultura — e com os três ao mesmo tempo — nas quatro ondas da MUNIC."
  footnote="A região sai do código IBGE do município, inclusive em 2006 — onda que outras tabulações mostram sem recorte regional. Denominador: todos os municípios da região em cada onda."
  source="Fonte: Elaboração própria com base na MUNIC/IBGE (2006, 2014, 2018 e 2021)."
  {background}
  bind:svgEl
/>
