<script lang="ts">
  /**
   * Os 596 agentes territoriais de cultura no território, como coroplético.
   *
   * É a primeira figura do capítulo de participação social, que até aqui não
   * tinha nenhuma — o texto pede o mapa explicitamente ("[Tabela, mapa ou
   * ilustração, com a quantidade de agentes territoriais atuantes em cada
   * Estado]") e entrega uma tabela de 27 linhas no lugar dele.
   *
   * O que o mapa mostra e a tabela não: a concentração. São Paulo e Minas
   * Gerais sozinhos têm 166 dos 596 agentes — mais que o Norte e o Centro-Oeste
   * somados, que ficam com 118. A leitura é de contagem, não de cobertura: uma
   * cor escura diz que há muitos agentes ali, não que o estado esteja bem
   * servido em relação ao seu tamanho ou à sua população.
   *
   * As classes são as que a distribuição pede, e não decis nem quantis: os
   * valores vão de 4 a 93 com uma cauda de dois estados, e uma quebra por
   * quantis juntaria São Paulo e Santa Catarina na mesma cor. Cinco faixas de
   * dez em dez até trinta, uma de trinta a cinquenta e a última aberta deixam
   * 7, 8, 7, 3 e 2 estados em cada — nenhuma classe vazia, nenhuma com metade
   * do país.
   *
   * As 66 OSCs do Programa Nacional dos Comitês de Cultura entrariam como
   * segunda marca sobre este mesmo mapa, quando vier a quebra por UF — o texto
   * traz o total (23 celebrantes e 43 parceiras) mas não a distribuição.
   */
  import CoropletoUfChart, { type ValorUf } from './CoropletoUfChart.svelte';
  import { rampaRoxa } from './cores';
  import { colors as marca } from './tokens';
  import { regiaoDe } from './mapaUf';
  import dados from '../data/agentes-territoriais.json';

  let {
    svgEl = $bindable(null),
    background,
  }: {
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  const inteiro = new Intl.NumberFormat('pt-BR');

  const valores: ValorUf[] = dados.ufs;

  const porRegiao = valores.reduce<Record<string, number>>((acc, { uf, valor }) => {
    const regiao = regiaoDe(uf);
    acc[regiao] = (acc[regiao] ?? 0) + valor;
    return acc;
  }, {});

  const ordenados = [...valores].sort((a, b) => b.valor - a.valor);
  const [maior, segundo] = ordenados;
  const duasMaiores = maior.valor + segundo.valor;
  const norteECentroOeste = porRegiao['Norte'] + porRegiao['Centro-Oeste'];

  const menor = ordenados[ordenados.length - 1];

  const footnote =
    `A cor é a contagem de agentes do estado, em cinco classes; o número dentro de cada estado é a contagem exata, ` +
    `e os estados pequenos demais para comportá-lo trazem o rótulo à direita, ligado por uma linha. Malha das ` +
    `unidades federativas do IBGE em projeção cônica equivalente de Albers, em que a área desenhada é a área do ` +
    `estado. A leitura é de ` +
    `quantidade, e não de cobertura: ${maior.uf} e ${segundo.uf} concentram ${duasMaiores} dos ${dados.total} ` +
    `agentes — mais do que o Norte e o Centro-Oeste somados, que têm ${norteECentroOeste} —, o que diz onde há mais ` +
    `gente e não onde há gente suficiente, já que um estado grande e claro chama mais atenção que um pequeno e ` +
    `escuro. Todas as 27 unidades federativas têm ao menos um agente; a menor contagem é a do ${menor.uf}, com ` +
    `${menor.valor}.`;
</script>

<CoropletoUfChart
  {valores}
  rampa={[rampaRoxa[4], rampaRoxa[3], rampaRoxa[2], rampaRoxa[1], rampaRoxa[0]]}
  quebras={[10, 20, 30, 50]}
  title="Os agentes territoriais de cultura no território"
  subtitle="Agentes territoriais em atuação, por unidade federativa · {inteiro.format(dados.total)} agentes no país"
  legendaTitulo="Agentes por estado"
  formatValue={(v) => inteiro.format(v)}
  destaque={{
    valor: inteiro.format(dados.total),
    cor: marca.primaryVariant,
    texto: 'agentes territoriais de cultura, em todas as unidades federativas',
  }}
  {footnote}
  source="Fonte: Elaboração própria com base nos registros da Secretaria dos Comitês de Cultura (MinC), reproduzidos na publicação."
  {background}
  bind:svgEl
/>
