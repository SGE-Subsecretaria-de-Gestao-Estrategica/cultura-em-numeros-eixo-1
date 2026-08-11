<script lang="ts">
  import { downloadSvg } from 'sniic-design-system';
  import EstadualPorFonteChart from './lib/EstadualPorFonteChart.svelte';
  import MunicipalPorFonteChart from './lib/MunicipalPorFonteChart.svelte';
  import EfeitoIndutorMunicipalChart from './lib/EfeitoIndutorMunicipalChart.svelte';
  import PerfilMudancaMunicipalChart from './lib/PerfilMudancaMunicipalChart.svelte';
  import TripeInstitucionalChart from './lib/TripeInstitucionalChart.svelte';
  import EstruturaOrgaoGestorChart from './lib/EstruturaOrgaoGestorChart.svelte';
  import GeneroTitularesChart from './lib/GeneroTitularesChart.svelte';
  import EscolaridadeTripeChart from './lib/EscolaridadeTripeChart.svelte';
  import ExecucaoAldirBlancChart from './lib/ExecucaoAldirBlancChart.svelte';
  import EquipamentosCulturaisChart from './lib/EquipamentosCulturaisChart.svelte';

  /**
   * The download control lives in the page, not in the chart: anything drawn
   * inside the `<svg>` would be serialized into the exported file.
   */
  let estadualSvg = $state<SVGSVGElement | null>(null);
  let municipalSvg = $state<SVGSVGElement | null>(null);
  let efeitoIndutorSvg = $state<SVGSVGElement | null>(null);
  let perfilMudancaSvg = $state<SVGSVGElement | null>(null);
  let tripeSvg = $state<SVGSVGElement | null>(null);
  let estruturaSvg = $state<SVGSVGElement | null>(null);
  let generoSvg = $state<SVGSVGElement | null>(null);
  let escolaridadeSvg = $state<SVGSVGElement | null>(null);
  let aldirBlancSvg = $state<SVGSVGElement | null>(null);
  let equipamentosSvg = $state<SVGSVGElement | null>(null);
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

  <header>
    <p class="eyebrow">Cultura em Números · Eixo 1 · Gestão e Participação</p>
    <h1>Institucionalização da política cultural nos municípios</h1>
  </header>

  <figure>
    <TripeInstitucionalChart bind:svgEl={tripeSvg} />
    <button
      class="export"
      onclick={() => tripeSvg && downloadSvg(tripeSvg, 'tripe-institucional.svg')}
    >
      Baixar SVG
    </button>
  </figure>

  <figure>
    <EstruturaOrgaoGestorChart bind:svgEl={estruturaSvg} />
    <button
      class="export"
      onclick={() => estruturaSvg && downloadSvg(estruturaSvg, 'estrutura-orgao-gestor.svg')}
    >
      Baixar SVG
    </button>
  </figure>

  <figure>
    <GeneroTitularesChart bind:svgEl={generoSvg} />
    <button
      class="export"
      onclick={() => generoSvg && downloadSvg(generoSvg, 'genero-titulares.svg')}
    >
      Baixar SVG
    </button>
  </figure>

  <figure>
    <EscolaridadeTripeChart bind:svgEl={escolaridadeSvg} />
    <button
      class="export"
      onclick={() => escolaridadeSvg && downloadSvg(escolaridadeSvg, 'escolaridade-tripe.svg')}
    >
      Baixar SVG
    </button>
  </figure>

  <figure>
    <ExecucaoAldirBlancChart bind:svgEl={aldirBlancSvg} />
    <button
      class="export"
      onclick={() => aldirBlancSvg && downloadSvg(aldirBlancSvg, 'execucao-aldir-blanc.svg')}
    >
      Baixar SVG
    </button>
  </figure>

  <figure>
    <EquipamentosCulturaisChart bind:svgEl={equipamentosSvg} />
    <button
      class="export"
      onclick={() => equipamentosSvg && downloadSvg(equipamentosSvg, 'equipamentos-culturais.svg')}
    >
      Baixar SVG
    </button>
  </figure>
</main>
