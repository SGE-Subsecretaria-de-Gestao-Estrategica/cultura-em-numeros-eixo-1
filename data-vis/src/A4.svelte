<script lang="ts">
  /**
   * Print proof: both charts on one A4 portrait sheet, at the width they will
   * be read at. Open `/a4.html` and print to PDF to check a real page.
   *
   * The charts are sized in SVG units and scale as a whole, so this page only
   * has to set a physical width — everything inside keeps its proportion.
   */
  import { BRL } from 'sniic-design-system';
  import EfeitoIndutorMunicipalChart from './lib/EfeitoIndutorMunicipalChart.svelte';
  import PerfilMudancaMunicipalChart from './lib/PerfilMudancaMunicipalChart.svelte';
  import RibbonChart from './lib/RibbonChart.svelte';
  import { A4_RIBBON, fonteColors, fonteLabels } from './lib/fontes';
  import municipal from './data/municipal-por-fonte.json';

  /**
   * `?bg=0` drops the cards' own background, which is how the PNG export runs —
   * so the same URL shows exactly what gets rasterized. The sheet stays white
   * here so the dark type is still readable while checking it.
   */
  const background = new URLSearchParams(location.search).get('bg') === '0' ? null : undefined;
</script>

<!-- One chart per sheet: at the 170 mm text column the two cards are too tall to
     share a page with each other and a heading. -->
<div class="sheet">
  <header>
    <p class="eyebrow">Cultura em Números · Eixo 1 · Orçamento</p>
    <h1>Resposta orçamentária dos municípios às transferências federais</h1>
  </header>

  <figure>
    <EfeitoIndutorMunicipalChart {background} />
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">Cultura em Números · Eixo 1 · Orçamento</p>
    <h1>Resposta orçamentária dos municípios às transferências federais</h1>
  </header>

  <figure>
    <PerfilMudancaMunicipalChart {background} />
  </figure>
</div>

<!-- The ribbon chart carries no card of its own — it draws only the plot, so it
     is transparent already and the sheet header supplies the title. -->
<div class="sheet">
  <header>
    <p class="eyebrow">Cultura em Números · Eixo 1 · Orçamento</p>
    <h1>Evolução do investimento cultural municipal por fonte de recurso</h1>
    <p class="subtitle">
      Valores empenhados, corrigidos pela inflação (IPCA, preços médios de
      {municipal.anoBaseDeflator}) · 2019–2025
    </p>
  </header>

  <figure>
    <RibbonChart
      data={municipal.real}
      keys={municipal.keys}
      labels={fonteLabels}
      colors={fonteColors}
      valueFormat={(v) => BRL.format(v)}
      {...A4_RIBBON}
    />
  </figure>
</div>
