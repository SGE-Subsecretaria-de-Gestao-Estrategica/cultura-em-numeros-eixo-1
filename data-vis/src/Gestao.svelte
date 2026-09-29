<script lang="ts">
  /**
   * Prova de impressão do eixo de gestão e participação: um gráfico por folha
   * A4, na largura em que serão lidos. Abrir `/gestao.html` e imprimir em PDF
   * para conferir uma página de verdade.
   *
   * Folha separada da de orçamento porque são dois recortes do relatório com
   * cabeçalhos próprios — e porque o export de PNG numera as figuras pela ordem
   * em que aparecem na página, então misturar os dois eixos numa folha só
   * amarraria a nomenclatura de um à ordem do outro.
   *
   * A ordem é a do capítulo: primeiro onde o tripé institucional chegou, depois
   * o que explica — e o que não explica — a distância até ele. O script de
   * export numera os PNG pela ordem em que as figuras aparecem aqui, então
   * mexer nesta sequência pede mexer na lista de nomes de
   * `scripts/export-png.mjs`.
   */
  import AgentesPorMunicipioChart from './lib/AgentesPorMunicipioChart.svelte';
  import AgentesTerritoriaisChart from './lib/AgentesTerritoriaisChart.svelte';
  import AutonomiaGestorUfChart from './lib/AutonomiaGestorUfChart.svelte';
  import BibliotecaMunicipalChart from './lib/BibliotecaMunicipalChart.svelte';
  import CompetenciaConselhosEstadualChart from './lib/CompetenciaConselhosEstadualChart.svelte';
  import EquipamentosCulturaisChart from './lib/EquipamentosCulturaisChart.svelte';
  import EscolaridadeEstadualChart from './lib/EscolaridadeEstadualChart.svelte';
  import EscolaridadeInstitucionalizacaoChart from './lib/EscolaridadeInstitucionalizacaoChart.svelte';
  import ExecucaoLabMunicipalChart from './lib/ExecucaoLabMunicipalChart.svelte';
  import GeneroGestoresChart from './lib/GeneroGestoresChart.svelte';
  import IncentivoEstadualChart from './lib/IncentivoEstadualChart.svelte';
  import IncentivoFiscalUfChart from './lib/IncentivoFiscalUfChart.svelte';
  import MaturidadeTripeUfChart from './lib/MaturidadeTripeUfChart.svelte';
  import MosaicoInstitucionalizacaoMunicipalChart from './lib/MosaicoInstitucionalizacaoMunicipalChart.svelte';
  import OrgaoGestorEstadualChart from './lib/OrgaoGestorEstadualChart.svelte';
  import OrgaoGestorMunicipalChart from './lib/OrgaoGestorMunicipalChart.svelte';
  import ParidadeConselhosEstadualChart from './lib/ParidadeConselhosEstadualChart.svelte';
  import PatrimonioEstadualChart from './lib/PatrimonioEstadualChart.svelte';
  import PerfilCncChart from './lib/PerfilCncChart.svelte';
  import RacaGestoresChart from './lib/RacaGestoresChart.svelte';
  import TransversalidadeEstadualChart from './lib/TransversalidadeEstadualChart.svelte';
  import TripeEstadualChart from './lib/TripeEstadualChart.svelte';
  import TripeRegiaoMunicipalChart from './lib/TripeRegiaoMunicipalChart.svelte';
  import TripeUfChart from './lib/TripeUfChart.svelte';

  /**
   * `?bg=0` remove o fundo próprio dos cartões, que é como o export de PNG roda
   * — então a mesma URL mostra exatamente o que é rasterizado. A folha continua
   * branca aqui para o tipo escuro seguir legível durante a conferência.
   */
  const background = new URLSearchParams(location.search).get('bg') === '0' ? null : undefined;

  const eyebrow = 'Cultura em Números · Eixo 1 · Gestão e Participação';
</script>

<div class="sheet">
  <header>
    <p class="eyebrow">{eyebrow}</p>
    <h1>Institucionalização da política cultural nos municípios</h1>
  </header>

  <figure>
    <div><TripeUfChart {background} /></div>
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">{eyebrow}</p>
    <h1>Institucionalização da política cultural nos municípios</h1>
  </header>

  <figure>
    <div><TripeRegiaoMunicipalChart {background} /></div>
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">{eyebrow}</p>
    <h1>Institucionalização da política cultural nos municípios</h1>
  </header>

  <figure>
    <div><MosaicoInstitucionalizacaoMunicipalChart {background} /></div>
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">{eyebrow}</p>
    <h1>Institucionalização da política cultural nos municípios</h1>
  </header>

  <figure>
    <div><OrgaoGestorMunicipalChart {background} /></div>
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">{eyebrow}</p>
    <h1>Institucionalização da política cultural nos municípios</h1>
  </header>

  <figure>
    <div><BibliotecaMunicipalChart {background} /></div>
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">{eyebrow}</p>
    <h1>Institucionalização da política cultural nos municípios</h1>
  </header>

  <figure>
    <div><EquipamentosCulturaisChart {background} /></div>
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">{eyebrow}</p>
    <h1>Institucionalização da política cultural nos municípios</h1>
  </header>

  <figure>
    <div><ExecucaoLabMunicipalChart {background} /></div>
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">{eyebrow}</p>
    <h1>Institucionalização da política cultural nos municípios</h1>
  </header>

  <figure>
    <div><EscolaridadeInstitucionalizacaoChart {background} /></div>
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">{eyebrow}</p>
    <h1>Quem gere a cultura nos municípios</h1>
  </header>

  <figure>
    <div><GeneroGestoresChart {background} /></div>
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">{eyebrow}</p>
    <h1>Quem gere a cultura nos municípios</h1>
  </header>

  <figure>
    <div><RacaGestoresChart {background} /></div>
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">Cultura em Números · Eixo 1 · Gestão estadual</p>
    <h1>A governança da cultura nos estados</h1>
  </header>

  <figure>
    <div><TripeEstadualChart {background} /></div>
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">Cultura em Números · Eixo 1 · Gestão estadual</p>
    <h1>A governança da cultura nos estados</h1>
  </header>

  <figure>
    <div><MaturidadeTripeUfChart {background} /></div>
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">Cultura em Números · Eixo 1 · Gestão estadual</p>
    <h1>A governança da cultura nos estados</h1>
  </header>

  <figure>
    <div><OrgaoGestorEstadualChart {background} /></div>
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">Cultura em Números · Eixo 1 · Gestão estadual</p>
    <h1>A governança da cultura nos estados</h1>
  </header>

  <figure>
    <div><AutonomiaGestorUfChart {background} /></div>
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">Cultura em Números · Eixo 1 · Gestão estadual</p>
    <h1>A governança da cultura nos estados</h1>
  </header>

  <figure>
    <div><EscolaridadeEstadualChart {background} /></div>
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">Cultura em Números · Eixo 1 · Gestão estadual</p>
    <h1>Os conselhos estaduais de cultura</h1>
  </header>

  <figure>
    <div><ParidadeConselhosEstadualChart {background} /></div>
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">Cultura em Números · Eixo 1 · Gestão estadual</p>
    <h1>Os conselhos estaduais de cultura</h1>
  </header>

  <figure>
    <div><CompetenciaConselhosEstadualChart {background} /></div>
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">Cultura em Números · Eixo 1 · Gestão estadual</p>
    <h1>Marcos legais e mecenato estadual</h1>
  </header>

  <figure>
    <div><PatrimonioEstadualChart {background} /></div>
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">Cultura em Números · Eixo 1 · Gestão estadual</p>
    <h1>Marcos legais e mecenato estadual</h1>
  </header>

  <figure>
    <div><IncentivoEstadualChart {background} /></div>
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">Cultura em Números · Eixo 1 · Gestão estadual</p>
    <h1>Marcos legais e mecenato estadual</h1>
  </header>

  <figure>
    <div><IncentivoFiscalUfChart {background} /></div>
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">Cultura em Números · Eixo 1 · Gestão estadual</p>
    <h1>Cultura transversal a outras políticas estaduais</h1>
  </header>

  <figure>
    <div><TransversalidadeEstadualChart {background} /></div>
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">Cultura em Números · Eixo 1 · Participação social</p>
    <h1>A sociedade civil nas decisões sobre cultura</h1>
  </header>

  <figure>
    <div><AgentesTerritoriaisChart {background} /></div>
  </figure>
</div>

<!-- a contagem e a cobertura, uma folha depois da outra: as duas leituras do
     mesmo registro, na mesma malha e no mesmo enquadramento -->
<div class="sheet">
  <header>
    <p class="eyebrow">Cultura em Números · Eixo 1 · Participação social</p>
    <h1>A sociedade civil nas decisões sobre cultura</h1>
  </header>

  <figure>
    <div><AgentesPorMunicipioChart {background} /></div>
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">Cultura em Números · Eixo 1 · Participação social</p>
    <h1>A sociedade civil nas decisões sobre cultura</h1>
  </header>

  <figure>
    <div><PerfilCncChart {background} /></div>
  </figure>
</div>
