<script lang="ts">
  /**
   * Museu, teatro e cinema nos municípios — os três equipamentos culturais
   * raros da MUNIC, na escala que os três dividem. A biblioteca fica de fora
   * e ganha a própria figura, `BibliotecaMunicipalChart`: ela mora perto de
   * 90%, e numa escala só os outros três — entre 8% e 30% — ficariam
   * espremidos no rodapé do plot, ilegíveis ao lado dela.
   *
   * O museu é o único que cresce de onda a onda; teatro e cinema mal se
   * movem, e o cinema segue abaixo de 11% nas três.
   */
  import FaixaLinhasChart, { type Serie } from './FaixaLinhasChart.svelte';
  import { categoricaTracoDe } from './cores';
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

  const RAROS = ['equip_museu', 'equip_teatro', 'equip_cinema'];
  const seriesRaras = dados.equipamentos.series.filter((s) => RAROS.includes(s.key));
  const cores = categoricaTracoDe(seriesRaras.length);

  const series: Serie[] = seriesRaras.map((s, i) => {
    const anos = s.pontos.map((p) => p.ano);
    const final = s.pontos[s.pontos.length - 1];
    return {
      key: s.key,
      cor: cores[i],
      pontos: s.pontos.map((p) => ({ ano: p.ano, valor: p.pct })),
      rotulos: anos,
      // O cinema fica abaixo das outras duas em todas as ondas, então desce
      // sempre — a mesma separação previsível de `TripeEstadualChart`. O
      // teatro só desce em 2006, o único ponto em que encosta no museu (21,2%
      // contra 21,9%, a menos de um pixel de distância na escala do plot).
      abaixo: s.key === 'equip_cinema' ? anos : s.key === 'equip_teatro' ? [2006] : undefined,
      destaque: {
        valor: pct(final.pct),
        cor: cores[i],
        texto: `dos municípios têm ${s.label.toLowerCase()} em ${final.ano}`,
      },
    };
  });

  const museu = seriesRaras.find((s) => s.key === 'equip_museu')!;
  const inicio = museu.pontos[0];
  const fimMuseu = museu.pontos[museu.pontos.length - 1];

  const footnote =
    `A onda de 2018 fica fora: o questionário daquele ano só perguntou equipamentos a 3.212 dos 5.570 ` +
    `municípios — um degrau da amostra, não do fenômeno. O museu é o único dos três que cresce de onda a onda, ` +
    `de ${pct(inicio.pct)} em ${inicio.ano} para ${pct(fimMuseu.pct)} em ${fimMuseu.ano}.`;
</script>

<FaixaLinhasChart
  {series}
  title="Museu cresce nos municípios; teatro e cinema seguem raros"
  subtitle="Municípios com o equipamento cultural ativo · MUNIC 2006, 2014 e 2021"
  formatValue={pct}
  {footnote}
  source="Fonte: Elaboração própria com base na MUNIC/IBGE, ondas de 2006, 2014 e 2021."
  {background}
  bind:svgEl
/>
