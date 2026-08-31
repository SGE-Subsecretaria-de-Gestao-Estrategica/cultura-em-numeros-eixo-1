<script lang="ts">
  /**
   * Quanto da capacidade de investimento da União foi para a cultura, ano a ano
   * — a Figura 3 da publicação, no estilo do primeiro print.
   *
   * As duas séries são encaixadas, não concorrentes: a execução direta é uma
   * parte do gasto pleno, então o vão vertical entre as faixas é a renúncia
   * fiscal — a Lei Rouanet e a ANCINE, que não passam pelo orçamento executado.
   * É por isso que valem duas linhas e não uma: a distância entre elas é o
   * terceiro dado da figura, e ela se estreita quando o financiamento deixa de
   * depender de incentivo e passa a correr por repasse direto.
   *
   * As duas cores foram medidas, não escolhidas a olho: vermelho e roxo rendem
   * ΔE 32 em visão normal e 26,5 no pior caso de daltonismo, bem acima do piso
   * de 8. O par vermelho e rosa da paleta da marca não passaria.
   */
  import FaixaLinhasChart, { type Serie } from './FaixaLinhasChart.svelte';
  import { colors as marca } from './tokens';
  import participacao from '../data/participacao-rcl.json';

  let {
    svgEl = $bindable(null),
    background,
  }: {
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  const decimal = new Intl.NumberFormat('pt-BR', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
  const pct = (v: number) => `${decimal.format(v)}%`;

  const porKey = Object.fromEntries(
    participacao.series.map((s) => [s.key, s.pontos.map((p) => ({ ano: p.ano, valor: p.pct }))]),
  );

  const ultimo = (key: string) => porKey[key][porKey[key].length - 1];
  const ultimoAno = ultimo('pleno').ano;

  /**
   * Os anos rotulados são os que a figura precisa nomear: as duas pontas, os
   * dois picos de emergência e o fundo de 2022. Rotular os quinze faria uma
   * fileira de números que ninguém lê.
   */
  const series: Serie[] = [
    {
      key: 'pleno',
      cor: marca.primary,
      pontos: porKey.pleno,
      rotulos: [2011, 2020, 2023],
      destaque: {
        valor: pct(ultimo('pleno').valor),
        cor: marca.primaryVariant,
        texto: `da receita da União foi para a cultura em ${ultimoAno}, somada a renúncia fiscal`,
      },
    },
    {
      key: 'direto',
      cor: marca.secondary,
      pontos: porKey.direto,
      /**
       * Nos dois picos a faixa roxa sobe em V, e um rótulo abaixo do marcador
       * cairia dentro da própria curva. Os anos que ela rotula são as pontas do
       * patamar e o fundo de 2022 — o resto da sua história é a distância até a
       * faixa vermelha, que não precisa de número para ser vista.
       */
      rotulos: [2011, 2022],
      abaixo: [2011, 2022],
      destaque: {
        valor: pct(ultimo('direto').valor),
        cor: marca.secondaryVariant,
        texto: 'saiu da execução orçamentária direta',
      },
    },
  ];
</script>

<FaixaLinhasChart
  {series}
  title="Participação da cultura no orçamento da União"
  subtitle="Gasto federal em cultura como percentual da Receita Corrente Líquida · de 2011 a {ultimoAno}"
  formatValue={pct}
  plotHeight={250}
  footnote="A Receita Corrente Líquida é o que resta ao ente para políticas públicas depois das deduções legais, e é o denominador que torna anos de receita diferente comparáveis. A faixa vermelha soma execução direta e renúncia fiscal (Lei Rouanet e ANCINE); a roxa traz só a execução direta, então o vão entre as duas é a renúncia. Os picos de 2020 e 2023 são a Lei Aldir Blanc e, depois, a Lei Paulo Gustavo com a PNAB."
  source="Fonte: Elaboração própria com base no SIOP, no SALIC, na ANCINE e no Tesouro Nacional."
  {background}
  bind:svgEl
/>
