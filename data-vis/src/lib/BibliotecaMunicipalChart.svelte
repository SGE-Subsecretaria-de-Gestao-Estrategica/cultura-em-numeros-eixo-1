<script lang="ts">
  /**
   * A biblioteca pública municipal — o mais comum dos quatro equipamentos
   * culturais que a MUNIC pergunta, e o único que recua depois do pico.
   *
   * Fica sozinha, e não junto com museu, teatro e cinema: os quatro numa
   * escala só espremeria os três raros — 8% a 30% — no rodapé do plot,
   * ilegíveis ao lado de uma linha que mora perto de 90%. `EquipamentosCulturaisChart`
   * é o par desta figura, os três equipamentos que cabem juntos na mesma escala.
   */
  import FaixaLinhasChart, { type Serie } from './FaixaLinhasChart.svelte';
  import { rampaVermelha } from './cores';
  import dados from '../data/gestao-municipal.json';

  let {
    svgEl = $bindable(null),
    background,
  }: {
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  const decimal = new Intl.NumberFormat('pt-BR', { maximumFractionDigits: 1 });
  const pct = (v: number) => `${decimal.format(v)}%`;

  const bibliotecas = dados.equipamentos.series.find((s) => s.key === 'equip_biblioteca')!;
  const anos = bibliotecas.pontos.map((p) => p.ano);
  const pico = bibliotecas.pontos.find((p) => p.ano === 2014)!;
  const ultima = bibliotecas.pontos[bibliotecas.pontos.length - 1];

  const series: Serie[] = [
    {
      key: bibliotecas.key,
      cor: rampaVermelha[2],
      pontos: bibliotecas.pontos.map((p) => ({ ano: p.ano, valor: p.pct })),
      rotulos: anos,
      destaque: {
        valor: pct(ultima.pct),
        cor: rampaVermelha[2],
        texto: `dos municípios têm biblioteca pública em ${ultima.ano}`,
      },
    },
  ];

  const footnote =
    `A onda de 2018 fica fora: o questionário daquele ano só perguntou equipamentos a 3.212 dos 5.570 municípios, ` +
    `e a taxa de biblioteca cai para 63,9% ali — um degrau da amostra, não do fenômeno. É o único dos quatro ` +
    `equipamentos culturais que a MUNIC pergunta a recuar depois do pico: de ${pct(pico.pct)} em 2014 para ` +
    `${pct(ultima.pct)} em ${ultima.ano}.`;
</script>

<FaixaLinhasChart
  {series}
  title="Biblioteca pública é quase universal nos municípios — mas recuou desde 2014"
  subtitle="Municípios com biblioteca pública ativa · MUNIC 2006, 2014 e 2021"
  formatValue={pct}
  {footnote}
  source="Fonte: Elaboração própria com base na MUNIC/IBGE, ondas de 2006, 2014 e 2021."
  {background}
  bind:svgEl
/>
