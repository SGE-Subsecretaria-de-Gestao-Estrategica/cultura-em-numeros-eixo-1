<script lang="ts">
  /**
   * Quanto da receita de cada estado foi para a cultura, no mapa hexagonal — a
   * leitura territorial do painel de esforço fiscal estadual da publicação.
   *
   * A linha preta não é uma média: é a meta de 1,5% da RCL do Plano Nacional de
   * Cultura. Ela muda o que a figura responde — de "quem está acima do
   * conjunto" para "quem cumpre a meta" — e a resposta é quase ninguém, que é
   * justamente o achado. Só o Amazonas passa dela, e o verde aparece em um
   * hexágono de vinte e sete.
   *
   * A barra da esquerda é 2019 e a da direita, 2024, os extremos da série com
   * RCL disponível para todas as UFs.
   */
  import HexMapaUfChart from './HexMapaUfChart.svelte';
  import dados from '../data/participacao-rcl-uf.json';

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
  const pct = (v: number) => `${decimal.format(v)}%`;

  const [inicio, fim] = dados.anos;

  const valores = dados.ufs.map((u) => ({
    uf: u.uf,
    a: u.pctInicio ?? 0,
    b: u.pctFim ?? 0,
  }));
</script>

<HexMapaUfChart
  {valores}
  referencia={dados.metaPnc}
  formatPct={pct}
  title="Participação da cultura no orçamento dos estados"
  subtitle="Gasto estadual com recursos próprios em cultura como percentual da Receita Corrente Líquida · {inicio} e {fim}"
  legendas={{
    excedente: `Parte em verde: quanto o estado supera a meta de ${decimal.format(dados.metaPnc)}%`,
    referencia: `Linha preta: ${decimal.format(dados.metaPnc)}% da RCL, a meta do Plano Nacional de Cultura`,
    a: `À esquerda: participação em ${inicio}`,
    b: `À direita: participação em ${fim}`,
  }}
  footnote="Valores a preços correntes: o denominador é a RCL nominal do mesmo ano, então corrigir só o numerador inflaria a razão. Um estado sem despesa própria em cultura no ano aparece com 0,0% — é o caso do Ceará em 2019, e a publicação nomeia os demais. O Distrito Federal entra como unidade federativa, com receita e despesa próprias."
  source="Fonte: Elaboração própria com base na MSC/SICONFI, Função 13 (Cultura), e nos demonstrativos de RCL do SICONFI."
  {background}
  bind:svgEl
/>
