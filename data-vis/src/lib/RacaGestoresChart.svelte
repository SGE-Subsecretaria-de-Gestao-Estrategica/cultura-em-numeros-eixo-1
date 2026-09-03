<script lang="ts">
  /**
   * A cor/raça autodeclarada do titular da pasta de cultura, coluna por onda
   * da MUNIC — o par de `GeneroGestoresChart` na mesma leitura de composição.
   *
   * Cinco categorias, as cinco cores da marca: é o caso em que a escala
   * categórica cabe inteira, sem precisar de rampa nem de pequenos múltiplos.
   * Amarela e Indígena somam menos de 1% e ficam sem número dentro da própria
   * fatia — a cor e a legenda ainda as identificam; é a mesma troca que
   * `ComposicaoFederalChart` faz numa série densa.
   */
  import ComposicaoChart, { type AnoRow } from './ComposicaoChart.svelte';
  import { categoricaDe } from './cores';
  import dados from '../data/gestao-municipal.json';

  let {
    svgEl = $bindable(null),
    background,
  }: {
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  const inteiro = new Intl.NumberFormat('pt-BR');

  const data = dados.corRaca.ondas as unknown as AnoRow[];
  const colors = categoricaDe(dados.corRaca.categorias.length);

  const primeira = dados.corRaca.ondas[0];
  const ultima = dados.corRaca.ondas[dados.corRaca.ondas.length - 1];
  const pretosEPardos = (o: (typeof dados.corRaca.ondas)[number]) => o.Preta + o.Parda;

  const footnote =
    `Cada coluna soma 100% sobre os titulares que declararam a própria cor/raça. Ficaram de fora, por não ` +
    `terem declarado: ${dados.corRaca.ondas.map((o) => `${inteiro.format(o.naoResposta)} em ${o.label}`).join(', ')} ` +
    `— não-resposta não é evidência nem a favor nem contra o que se mede.`;
</script>

<ComposicaoChart
  {data}
  keys={dados.corRaca.categorias}
  {colors}
  columnRatio={0.5}
  title="Pretos e pardos já respondem por quatro em cada dez titulares da pasta de cultura"
  subtitle="Cor/raça autodeclarada do titular da pasta de cultura nos municípios · MUNIC {primeira.label} e {ultima.label}"
  {footnote}
  source="Fonte: Elaboração própria com base na MUNIC/IBGE, ondas de {primeira.label} e {ultima.label}."
  {background}
  bind:svgEl
/>
