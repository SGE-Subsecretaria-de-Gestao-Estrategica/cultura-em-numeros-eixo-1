<script lang="ts">
  /**
   * Prova de impressão do eixo de orçamento: um gráfico por folha A4, na
   * largura em que serão lidos. Abrir `/a4.html` e imprimir em PDF para
   * conferir uma página de verdade.
   *
   * As figuras carregam o seu tamanho em unidades de SVG e um `viewBox` que
   * casa com ele, então o cartão inteiro escala junto e os rótulos guardam o
   * tamanho relativo — o que se vê aqui é o que imprime. A folha só precisa
   * fixar uma largura física.
   *
   * A ordem é a do capítulo: o panorama das três esferas, depois a União, os
   * estados e os municípios. O script de export numera os PNG pela ordem em que
   * as figuras aparecem aqui, então mexer nesta sequência pede mexer na lista de
   * nomes de `scripts/export-png.mjs` — ele falha se as duas divergirem, em vez
   * de gravar um gráfico com o nome do vizinho.
   */
  import ConcentracaoGastoChart from './lib/ConcentracaoGastoChart.svelte';
  import CrescimentoMunicipalChart from './lib/CrescimentoMunicipalChart.svelte';
  import DistribuicaoRclChart from './lib/DistribuicaoRclChart.svelte';
  import EstadualFontesChart from './lib/EstadualFontesChart.svelte';
  import HistomapFederalChart from './lib/HistomapFederalChart.svelte';
  import MetaRclChart from './lib/MetaRclChart.svelte';
  import MetaRclRegiaoChart from './lib/MetaRclRegiaoChart.svelte';
  import ParticipacaoEstadosChart from './lib/ParticipacaoEstadosChart.svelte';
  import ParticipacaoUniaoChart from './lib/ParticipacaoUniaoChart.svelte';
  import TresEsferasChart from './lib/TresEsferasChart.svelte';

  /**
   * `?bg=0` remove o fundo próprio dos cartões, que é como o export de PNG roda
   * — então a mesma URL mostra exatamente o que é rasterizado. A folha continua
   * branca aqui para o tipo escuro seguir legível durante a conferência.
   */
  const background = new URLSearchParams(location.search).get('bg') === '0' ? null : undefined;

  const eyebrow = 'Cultura em Números · Eixo 1 · Orçamento';
</script>

<div class="sheet">
  <header>
    <p class="eyebrow">{eyebrow}</p>
    <h1>O peso da cultura no orçamento das três esferas</h1>
  </header>

  <figure>
    <div><TresEsferasChart {background} /></div>
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">{eyebrow}</p>
    <h1>Investimento federal em cultura</h1>
  </header>

  <figure>
    <div><HistomapFederalChart {background} /></div>
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">{eyebrow}</p>
    <h1>Investimento federal em cultura</h1>
  </header>

  <figure>
    <div><ParticipacaoUniaoChart {background} /></div>
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">{eyebrow}</p>
    <h1>Investimento estadual em cultura</h1>
  </header>

  <figure>
    <div><EstadualFontesChart {background} /></div>
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">{eyebrow}</p>
    <h1>Investimento estadual em cultura</h1>
  </header>

  <figure>
    <div><ParticipacaoEstadosChart {background} /></div>
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">{eyebrow}</p>
    <h1>Investimento municipal em cultura</h1>
  </header>

  <figure>
    <div><CrescimentoMunicipalChart {background} /></div>
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">{eyebrow}</p>
    <h1>Investimento municipal em cultura</h1>
  </header>

  <figure>
    <div><MetaRclChart {background} /></div>
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">{eyebrow}</p>
    <h1>Investimento municipal em cultura</h1>
  </header>

  <figure>
    <div><MetaRclRegiaoChart {background} /></div>
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">{eyebrow}</p>
    <h1>Investimento municipal em cultura</h1>
  </header>

  <figure>
    <div><DistribuicaoRclChart {background} /></div>
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">{eyebrow}</p>
    <h1>Investimento municipal em cultura</h1>
  </header>

  <figure>
    <div><ConcentracaoGastoChart {background} /></div>
  </figure>
</div>
