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
   */
  import EquipamentosCulturaisChart from './lib/EquipamentosCulturaisChart.svelte';
  import EscolaridadeTripeChart from './lib/EscolaridadeTripeChart.svelte';
  import EstruturaMapaChart from './lib/EstruturaMapaChart.svelte';
  import EstruturaOrgaoGestorChart from './lib/EstruturaOrgaoGestorChart.svelte';
  import ExecucaoAldirBlancChart from './lib/ExecucaoAldirBlancChart.svelte';
  import ExecucaoLabRegiaoChart from './lib/ExecucaoLabRegiaoChart.svelte';
  import GeneroTitularesChart from './lib/GeneroTitularesChart.svelte';
  import TripeInstitucionalChart from './lib/TripeInstitucionalChart.svelte';
  import TripeMapaChart from './lib/TripeMapaChart.svelte';
  import TripeRegiaoChart from './lib/TripeRegiaoChart.svelte';

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
    <TripeInstitucionalChart {background} />
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">{eyebrow}</p>
    <h1>Institucionalização da política cultural nos municípios</h1>
  </header>

  <figure>
    <TripeMapaChart {background} />
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">{eyebrow}</p>
    <h1>Institucionalização da política cultural nos municípios</h1>
  </header>

  <figure>
    <TripeRegiaoChart {background} />
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">{eyebrow}</p>
    <h1>Institucionalização da política cultural nos municípios</h1>
  </header>

  <figure>
    <EstruturaOrgaoGestorChart {background} />
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">{eyebrow}</p>
    <h1>Institucionalização da política cultural nos municípios</h1>
  </header>

  <figure>
    <EstruturaMapaChart {background} />
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">{eyebrow}</p>
    <h1>Quem comanda a política cultural municipal</h1>
  </header>

  <figure>
    <GeneroTitularesChart {background} />
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">{eyebrow}</p>
    <h1>Quem comanda a política cultural municipal</h1>
  </header>

  <figure>
    <EscolaridadeTripeChart {background} />
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">{eyebrow}</p>
    <h1>A resposta municipal à Lei Aldir Blanc</h1>
  </header>

  <figure>
    <ExecucaoAldirBlancChart {background} />
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">{eyebrow}</p>
    <h1>A resposta municipal à Lei Aldir Blanc</h1>
  </header>

  <figure>
    <ExecucaoLabRegiaoChart {background} />
  </figure>
</div>

<div class="sheet">
  <header>
    <p class="eyebrow">{eyebrow}</p>
    <h1>Infraestrutura cultural instalada</h1>
  </header>

  <figure>
    <EquipamentosCulturaisChart {background} />
  </figure>
</div>
