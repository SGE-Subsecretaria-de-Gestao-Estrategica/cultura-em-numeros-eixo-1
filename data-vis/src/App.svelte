<script lang="ts">
  import { downloadSvg } from 'sniic-design-system';
  import EstadualPorFonteChart from './lib/EstadualPorFonteChart.svelte';
  import MunicipalPorFonteChart from './lib/MunicipalPorFonteChart.svelte';
  import EfeitoIndutorMunicipalChart from './lib/EfeitoIndutorMunicipalChart.svelte';
  import PerfilMudancaMunicipalChart from './lib/PerfilMudancaMunicipalChart.svelte';

  /**
   * The download control lives in the page, not in the chart: anything drawn
   * inside the `<svg>` would be serialized into the exported file.
   */
  let estadualSvg = $state<SVGSVGElement | null>(null);
  let municipalSvg = $state<SVGSVGElement | null>(null);
  let efeitoIndutorSvg = $state<SVGSVGElement | null>(null);
  let perfilMudancaSvg = $state<SVGSVGElement | null>(null);
</script>

<main>
  <header>
    <p class="eyebrow">Cultura em Números · Eixo 1 · Orçamento</p>
    <h1>Financiamento estadual e municipal da cultura</h1>
  </header>

  <figure>
    <EstadualPorFonteChart bind:svgEl={estadualSvg} />
    <button
      class="export"
      onclick={() =>
        estadualSvg && downloadSvg(estadualSvg, 'investimento-estadual-por-fonte.svg')}
    >
      Baixar SVG
    </button>
  </figure>

  <figure>
    <MunicipalPorFonteChart bind:svgEl={municipalSvg} />
    <button
      class="export"
      onclick={() =>
        municipalSvg && downloadSvg(municipalSvg, 'investimento-municipal-por-fonte.svg')}
    >
      Baixar SVG
    </button>
  </figure>

  <figure>
    <EfeitoIndutorMunicipalChart bind:svgEl={efeitoIndutorSvg} />
    <button
      class="export"
      onclick={() =>
        efeitoIndutorSvg &&
        downloadSvg(efeitoIndutorSvg, 'efeito-indutor-substituicao-por-regiao.svg')}
    >
      Baixar SVG
    </button>
  </figure>

  <figure>
    <PerfilMudancaMunicipalChart bind:svgEl={perfilMudancaSvg} />
    <button
      class="export"
      onclick={() =>
        perfilMudancaSvg &&
        downloadSvg(perfilMudancaSvg, 'perfil-mudanca-municipal-por-porte.svg')}
    >
      Baixar SVG
    </button>
  </figure>
</main>
