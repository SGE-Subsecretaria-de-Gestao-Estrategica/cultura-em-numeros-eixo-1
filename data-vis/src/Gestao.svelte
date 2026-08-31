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
  import EscolaridadeInstitucionalizacaoChart from './lib/EscolaridadeInstitucionalizacaoChart.svelte';
  import PerfilCncChart from './lib/PerfilCncChart.svelte';
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
    <div><EscolaridadeInstitucionalizacaoChart {background} /></div>
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
