<script lang="ts">
  import { interpolateLab, scaleLinear } from 'd3';
  import { getPillarTheme } from 'sniic-design-system';
  import TabelaVisualChart from './TabelaVisualChart.svelte';
  import { rampaAzul } from './cores';
  import gestao from '../data/gestao-municipal.json';

  let {
    svgEl = $bindable(null),
    background,
  }: { svgEl?: SVGSVGElement | null; background?: string | null } = $props();

  const palette = getPillarTheme(1).palette;
  const dados = gestao.execucaoLabRegiao;

  const decimal = new Intl.NumberFormat('pt-BR', {
    minimumFractionDigits: 1,
    maximumFractionDigits: 1,
  });
  const integer = new Intl.NumberFormat('pt-BR');

  /**
   * O fundo de cada célula é a própria medida, numa rampa contínua do tom do
   * cartão ao azul da marca, normalizada pelo maior valor da tabela — é o que
   * deixa o padrão saltar antes da leitura número a número: a coluna "Até 10%"
   * escura em todas as regiões, e a cauda "Mais de 90%" mais forte no Sul e no
   * Sudeste. Azul, e não vermelho, pela mesma razão do mapa do tripé: nas
   * figuras de gestão o vermelho é a cor do dado principal.
   */
  const maiorPct = Math.max(...dados.regioes.flatMap((r) => r.faixas.map((f) => f.pct)));
  const cor = scaleLinear<string>()
    .domain([0, maiorPct])
    .range([palette.base[100], rampaAzul[1]])
    .interpolate(interpolateLab);

  const colunas = dados.regioes[0].faixas.map((f) => f.label);

  const secoes = dados.regioes.map((r) => ({
    label: `${r.regiao} · ${integer.format(r.base)} municípios informaram`,
    rows: [
      {
        cells: r.faixas.map((f) => ({
          text: decimal.format(f.pct),
          fill: cor(f.pct),
        })),
      },
    ],
  }));
</script>

<TabelaVisualChart
  {colunas}
  {secoes}
  title="Execução do repasse da Lei Aldir Blanc por região"
  subtitle={`Distribuição dos municípios de cada região pelo percentual executado do recurso recebido, em ${dados.ano}. Valores em % dos municípios que informaram.`}
  footnote="O fundo de cada célula é o próprio valor, do tom do cartão ao azul da marca: quanto mais escuro, maior a concentração de municípios na faixa. Em todas as regiões a moda é executar até 10% — e é no Sul e no Sudeste que a faixa acima de 90% mais pesa."
  source="Fonte: Elaboração própria com base na MUNIC/IBGE 2021."
  {background}
  bind:svgEl
/>
