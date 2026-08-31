<script lang="ts">
  /**
   * A ponte entre o investimento municipal de 2019 e o de 2024: quanto do
   * crescimento saiu do próprio orçamento do município e quanto veio de
   * repasse federal.
   *
   * É a figura que faltava ao capítulo municipal. As duas que existem —
   * `MetaRcl` e `MetaRclRegiao` — medem o município em percentual da receita, e
   * nenhuma diz que ele é, em volume, a maior das três esferas. Esta diz, e
   * responde à pergunta do lead do capítulo: os novos mecanismos de repasse
   * mudaram o cenário, mas o crescimento é sobretudo dinheiro local.
   *
   * A ponte termina em 2024, e não em 2025, porque 2025 sai de uma base
   * declarante menor — 4.788 municípios contra 5.191. Numa figura de
   * percentual isso se absorve no denominador; numa de volume, não: o total
   * de 2025 seria comparado com o de 2019 como se fossem o mesmo universo.
   *
   * A cor segue a chave de `fontes.ts`, que vale para toda a coleção: azul é o
   * orçamento do próprio ente, vermelho são as leis de emergência. O roxo do
   * total não colide com nenhuma fonte — é a cor de "o consolidado", e só.
   */
  import CascataChart, { type Bloco } from './CascataChart.svelte';
  import { rampaAzul, rampaRoxa, rampaVermelha } from './cores';
  import { colors as marca } from './tokens';
  import municipal from '../data/municipal-por-fonte.json';

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
  const bi = (v: number) => `R$ ${decimal.format(v)} bi`;
  const maisBi = (v: number) => `+${bi(v)}`;

  const PROPRIO = 'Recurso Próprio (Municipal)';
  const ANO_INICIAL = 2019;
  const ANO_FINAL = 2024;

  type Linha = Record<string, number> & { label: string };

  const linhaDe = (ano: number) =>
    (municipal.real as unknown as Linha[]).find((r) => Number(r.label) === ano)!;

  const inicial = linhaDe(ANO_INICIAL);
  const final = linhaDe(ANO_FINAL);

  const totalDe = (linha: Linha) =>
    municipal.keys.reduce((soma, key) => soma + linha[key], 0) / 1e9;

  const proprioDe = (linha: Linha) => linha[PROPRIO] / 1e9;
  const repassesDe = (linha: Linha) => totalDe(linha) - proprioDe(linha);

  const totalInicial = totalDe(inicial);
  const totalFinal = totalDe(final);
  const deltaProprio = proprioDe(final) - proprioDe(inicial);
  const deltaRepasses = repassesDe(final) - repassesDe(inicial);
  const crescimento = totalFinal - totalInicial;

  const parcelaPropria = Math.round((deltaProprio / crescimento) * 100);

  /**
   * As quatro fontes de repasse abertas sob o bloco agregado, da maior para a
   * menor. Elas entram somadas porque, na escala da figura, as emendas valem
   * dois pontos e meio de altura e a LAB 1 nem isso — e a cascata não infla
   * bloco pequeno para deixá-lo visível. Somadas, valem 22 unidades e se leem.
   */
  const aberturaDosRepasses = municipal.keys
    .filter((key) => key !== PROPRIO)
    .map((key) => ({ key, valor: final[key] / 1e9 }))
    .sort((a, b) => b.valor - a.valor);

  const curto: Record<string, string> = {
    'Emendas Parlamentares (Cultura)': 'emendas',
    'Lei Aldir Blanc 1 (LAB 1)': 'LAB 1',
    'Lei Paulo Gustavo (LPG)': 'LPG',
    'PNAB (Aldir Blanc 2)': 'PNAB',
  };

  /**
   * Duas por linha, para o texto miúdo caber na banda do bloco.
   *
   * A LAB 1 executou R$ 3 milhões em 2024 e arredondaria para "0,0", que se lê
   * como dado faltando e não como valor. `<0,1` diz a mesma coisa sem parecer
   * defeito, e a nota de rodapé conta para onde a lei foi.
   */
  const detalheDosRepasses = [
    aberturaDosRepasses.slice(0, 2),
    aberturaDosRepasses.slice(2),
  ].map((par) =>
    par
      .map(({ key, valor }) => `${curto[key]} ${valor < 0.05 ? '<0,1' : decimal.format(valor)}`)
      .join(' · '),
  );

  const blocos: Bloco[] = [
    {
      key: 'base',
      label: `Investimento em ${ANO_INICIAL}`,
      valor: totalInicial,
      tipo: 'base',
      cor: rampaAzul[2],
      detalhe: ['tudo de recurso próprio'],
    },
    {
      key: 'proprio',
      label: 'Recursos próprios do município',
      valor: deltaProprio,
      tipo: 'delta',
      cor: rampaAzul[3],
    },
    {
      key: 'repasses',
      label: 'Repasses federais',
      valor: deltaRepasses,
      tipo: 'delta',
      cor: rampaVermelha[2],
      detalhe: detalheDosRepasses,
    },
    {
      key: 'total',
      label: `Investimento em ${ANO_FINAL}`,
      valor: totalFinal,
      tipo: 'total',
      cor: rampaRoxa[1],
    },
  ];

  const footnote =
    `Gasto na Função 13 (Cultura) executado pelos municípios, somando recursos próprios e os repasses federais que ` +
    `eles executam. A cascata compara dois anos, não soma o período: cada repasse entra pelo que foi executado em ` +
    `${ANO_FINAL}, e é por isso que a Lei Aldir Blanc 1 quase não aparece — ela correu em 2020 e 2021, com ` +
    `R$ 1,2 bi e R$ 0,5 bi, e já tinha saído em ${ANO_FINAL}. A ponte termina em ${ANO_FINAL} porque 2025 sai de uma ` +
    `base declarante menor, de 4.788 municípios contra 5.191, e um total de volume não absorve essa diferença como ` +
    `um percentual absorveria.`;
</script>

<CascataChart
  {blocos}
  title="De onde saiu o crescimento do investimento municipal em cultura"
  subtitle="Do investimento de {ANO_INICIAL} ao de {ANO_FINAL}, por origem do recurso · R$ bilhões, a preços médios de 2024 (IPCA)"
  formatValue={bi}
  formatDelta={maisBi}
  destaque={{
    valor: `${parcelaPropria}%`,
    cor: marca.primaryVariant,
    texto: `do crescimento saiu do orçamento do próprio município`,
  }}
  {footnote}
  source="Fonte: Elaboração própria com base na MSC/SICONFI, Função 13 (Cultura)."
  {background}
  bind:svgEl
/>
