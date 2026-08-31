<script lang="ts">
  /**
   * A página de navegação: todas as figuras do eixo 1 numa coluna, cada uma com
   * o seu botão de download.
   *
   * O botão fica fora do `<svg>`, e não dentro: tudo o que a figura desenha
   * dentro dele seria serializado no arquivo exportado.
   */
  import { downloadSvg } from 'sniic-design-system';
  import CrescimentoMunicipalChart from './lib/CrescimentoMunicipalChart.svelte';
  import EscolaridadeInstitucionalizacaoChart from './lib/EscolaridadeInstitucionalizacaoChart.svelte';
  import EstadualFontesChart from './lib/EstadualFontesChart.svelte';
  import HistomapFederalChart from './lib/HistomapFederalChart.svelte';
  import MetaRclChart from './lib/MetaRclChart.svelte';
  import MetaRclRegiaoChart from './lib/MetaRclRegiaoChart.svelte';
  import ParticipacaoEstadosChart from './lib/ParticipacaoEstadosChart.svelte';
  import ParticipacaoUniaoChart from './lib/ParticipacaoUniaoChart.svelte';
  import TresEsferasChart from './lib/TresEsferasChart.svelte';
  import TripeUfChart from './lib/TripeUfChart.svelte';

  let tresEsferasSvg = $state<SVGSVGElement | null>(null);
  let histomapSvg = $state<SVGSVGElement | null>(null);
  let participacaoUniaoSvg = $state<SVGSVGElement | null>(null);
  let estadualFontesSvg = $state<SVGSVGElement | null>(null);
  let participacaoEstadosSvg = $state<SVGSVGElement | null>(null);
  let crescimentoMunicipalSvg = $state<SVGSVGElement | null>(null);
  let metaRclSvg = $state<SVGSVGElement | null>(null);
  let metaRclRegiaoSvg = $state<SVGSVGElement | null>(null);
  let tripeUfSvg = $state<SVGSVGElement | null>(null);
  let escolaridadeSvg = $state<SVGSVGElement | null>(null);
</script>

<main>
  <header>
    <p class="eyebrow">Cultura em Números · Eixo 1 · Orçamento</p>
    <h1>O peso da cultura no orçamento público</h1>
  </header>

  <figure>
    <div><TresEsferasChart bind:svgEl={tresEsferasSvg} /></div>
    <button
      class="export"
      onclick={() => tresEsferasSvg && downloadSvg(tresEsferasSvg, 'tres-esferas.svg')}
    >
      Baixar SVG
    </button>
  </figure>

  <figure>
    <div><HistomapFederalChart bind:svgEl={histomapSvg} /></div>
    <button
      class="export"
      onclick={() => histomapSvg && downloadSvg(histomapSvg, 'federal-histomap-por-fonte.svg')}
    >
      Baixar SVG
    </button>
  </figure>

  <figure>
    <div><ParticipacaoUniaoChart bind:svgEl={participacaoUniaoSvg} /></div>
    <button
      class="export"
      onclick={() =>
        participacaoUniaoSvg && downloadSvg(participacaoUniaoSvg, 'participacao-uniao-rcl.svg')}
    >
      Baixar SVG
    </button>
  </figure>

  <figure>
    <div><EstadualFontesChart bind:svgEl={estadualFontesSvg} /></div>
    <button
      class="export"
      onclick={() =>
        estadualFontesSvg && downloadSvg(estadualFontesSvg, 'estadual-proprio-e-repasses.svg')}
    >
      Baixar SVG
    </button>
  </figure>

  <figure>
    <div><ParticipacaoEstadosChart bind:svgEl={participacaoEstadosSvg} /></div>
    <button
      class="export"
      onclick={() =>
        participacaoEstadosSvg &&
        downloadSvg(participacaoEstadosSvg, 'participacao-estados-rcl.svg')}
    >
      Baixar SVG
    </button>
  </figure>

  <figure>
    <div><CrescimentoMunicipalChart bind:svgEl={crescimentoMunicipalSvg} /></div>
    <button
      class="export"
      onclick={() =>
        crescimentoMunicipalSvg &&
        downloadSvg(crescimentoMunicipalSvg, 'crescimento-municipal.svg')}
    >
      Baixar SVG
    </button>
  </figure>

  <figure>
    <div><MetaRclChart bind:svgEl={metaRclSvg} /></div>
    <button
      class="export"
      onclick={() => metaRclSvg && downloadSvg(metaRclSvg, 'meta-rcl-municipios.svg')}
    >
      Baixar SVG
    </button>
  </figure>

  <figure>
    <div><MetaRclRegiaoChart bind:svgEl={metaRclRegiaoSvg} /></div>
    <button
      class="export"
      onclick={() => metaRclRegiaoSvg && downloadSvg(metaRclRegiaoSvg, 'meta-rcl-por-regiao.svg')}
    >
      Baixar SVG
    </button>
  </figure>

  <header>
    <p class="eyebrow">Cultura em Números · Eixo 1 · Gestão e Participação</p>
    <h1>Institucionalização da política cultural nos municípios</h1>
  </header>

  <figure>
    <div><TripeUfChart bind:svgEl={tripeUfSvg} /></div>
    <button
      class="export"
      onclick={() => tripeUfSvg && downloadSvg(tripeUfSvg, 'tripe-institucional-por-uf.svg')}
    >
      Baixar SVG
    </button>
  </figure>

  <figure>
    <div><EscolaridadeInstitucionalizacaoChart bind:svgEl={escolaridadeSvg} /></div>
    <button
      class="export"
      onclick={() =>
        escolaridadeSvg &&
        downloadSvg(escolaridadeSvg, 'escolaridade-institucionalizacao.svg')}
    >
      Baixar SVG
    </button>
  </figure>
</main>
