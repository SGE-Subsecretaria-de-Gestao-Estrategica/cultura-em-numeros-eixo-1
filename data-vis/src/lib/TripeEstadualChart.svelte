<script lang="ts">
  /**
   * A evolução do tripé institucional do SNC nos estados — conselho, fundo e
   * plano de cultura — o par estadual de `TripeUfChart` (que mede a mesma
   * coisa nos municípios).
   *
   * O salto do conselho entre 2014 e 2018 não é gradual: de 3 para 27 UFs, o
   * instrumento praticamente universaliza em uma onda só, o oposto do fundo e
   * do plano, que sobem devagar. É por isso que a leitura do capítulo separa
   * "que instrumento" de "que ritmo" — a mesma pergunta tem respostas bem
   * diferentes conforme o instrumento.
   */
  import FaixaLinhasChart, { type Serie } from './FaixaLinhasChart.svelte';
  import { rampaAzul, rampaVerde, rampaVermelha } from './cores';
  import dados from '../data/estadic-governanca.json';

  let {
    svgEl = $bindable(null),
    background,
  }: {
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  const decimal = new Intl.NumberFormat('pt-BR', { maximumFractionDigits: 0 });
  const pct = (v: number) => `${decimal.format(v)}%`;

  const [conselho, fundo, plano] = dados.tripe.instrumentos;
  const anos = dados.tripe.anos;

  const cores: Record<string, { cor: string; corPontoFinal?: string }> = {
    conselho: { cor: rampaAzul[2] },
    fundo: { cor: rampaVerde[0] },
    plano: { cor: rampaVermelha[2] },
  };

  const series: Serie[] = dados.tripe.instrumentos.map((inst) => ({
    key: inst.key,
    cor: cores[inst.key].cor,
    pontos: inst.pontos.map((p) => ({ ano: p.ano, valor: p.taxa })),
    rotulos: anos,
    abaixo: inst.key === 'plano' ? [2014] : undefined,
    destaque: {
      valor: pct(inst.pontos[inst.pontos.length - 1].taxa),
      cor: cores[inst.key].cor,
      texto: `das UFs têm ${inst.label.toLowerCase()} ativo em ${anos[anos.length - 1]}`,
    },
  }));

  const footnote =
    'Cada ponto é a proporção das 27 UFs com o instrumento ativo naquela onda da ESTADIC. O conselho salta de ' +
    `${decimal.format(conselho.pontos[0].taxa)}% em 2014 para 100% em 2018 porque a onda de 2014 tem a base ` +
    `declarante mais restrita do painel — só 3 UFs confirmaram o instrumento; nas ondas seguintes, todas as ` +
    '27 o fazem.';
</script>

<FaixaLinhasChart
  {series}
  title="O conselho estadual universaliza; fundo e plano avançam mais devagar"
  subtitle="Estados com conselho, fundo e plano de cultura ativos · ESTADIC 2014, 2018 e 2021"
  formatValue={pct}
  {footnote}
  source="Fonte: Elaboração própria com base na ESTADIC/IBGE, ondas de 2014 a 2021."
  {background}
  bind:svgEl
/>
