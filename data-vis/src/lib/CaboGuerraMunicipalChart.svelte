<script lang="ts">
  /**
   * O "cabo de guerra" da política cultural municipal: depois das leis
   * emergenciais (LAB 1, LPG, PNAB), quantos municípios aceleraram o próprio
   * investimento em cultura contra quantos o reduziram — por macrorregião.
   *
   * O corte é o Corredor Híbrido: compara o gasto próprio per capita de 2020
   * (pré-crise) com a média de 2023-2024 (pós-repasses), com uma margem de
   * 20% + R$ 5,00 para não confundir ruído orçamentário com mudança de
   * trajetória. Só as duas pontas do corredor entram na figura — Despertados
   * (efeito indutor) e Substituição (efeito substituição) — porque são as que
   * respondem à pergunta do capítulo: o repasse empurrou investimento novo, ou
   * substituiu o que já existia? Os municípios que ficaram Constantes ou
   * Inertes, dentro do corredor, não mudaram de trajetória o bastante para
   * responder isso e ficam de fora do desenho.
   *
   * A escala é uma só para as duas direções, e o desequilíbrio entre elas —
   * dezenas de pontos contra pouco menos de dez — é o achado: em toda região,
   * o efeito indutor supera o de substituição por uma ordem de grandeza.
   */
  import BarraDivergenteChart from './BarraDivergenteChart.svelte';
  import { rampaVermelha, rampaVerde } from './cores';
  import dados from '../data/comportamento-municipal.json';

  let {
    svgEl = $bindable(null),
    background,
  }: {
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  const decimal = new Intl.NumberFormat('pt-BR', {
    minimumFractionDigits: 1,
    maximumFractionDigits: 1,
  });
  const inteiro = new Intl.NumberFormat('pt-BR');

  const linhas = dados.caboGuerra.map((r) => ({
    key: r.label,
    label: r.label,
    positivo: r.indutor,
    negativo: r.substituicao,
  }));

  const footnote =
    'Corredor Híbrido: compara o gasto próprio per capita em cultura de 2020 (pré-crise) com a média de ' +
    '2023-2024 (pós-repasses). "Efeito indutor" é o município cuja média pós ultrapassou o teto do corredor — ' +
    '(gasto de 2020 × 1,20) + R$ 5,00; "efeito substituição" é o que ficou abaixo do piso — (gasto de 2020 × 0,80) ' +
    `− R$ 5,00. As duas parcelas não somam 100%: entre elas ficam os municípios que permaneceram dentro do ` +
    `corredor — Constantes ou Inertes —, sem mudança de trajetória suficiente para entrar nesta leitura. Base: ` +
    `${inteiro.format(dados.universo)} municípios com dados de execução em ambos os períodos.`;
</script>

<BarraDivergenteChart
  {linhas}
  corPositivo={rampaVerde[4]}
  corNegativo={rampaVermelha[0]}
  labelPositivo="Efeito indutor"
  labelNegativo="Efeito substituição"
  title="Depois das leis emergenciais, o efeito indutor domina em todas as regiões"
  subtitle="Municípios por direção da mudança no investimento próprio em cultura, 2020 → média 2023-2024 · macrorregião"
  formatValue={(v) => `${decimal.format(v)}%`}
  destaque={{
    valor: inteiro.format(dados.universo),
    cor: rampaVerde[4],
    texto: 'municípios classificados pelo Corredor Híbrido',
  }}
  {footnote}
  source="Fonte: Elaboração própria com base na MSC/SICONFI e no Cadastro Único (gasto per capita municipal em cultura)."
  {background}
  bind:svgEl
/>
