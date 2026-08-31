<script lang="ts">
  /**
   * Quanto do gasto cultural municipal do país sai de que fração dos
   * municípios.
   *
   * Nenhuma outra figura da publicação fala de desigualdade territorial de
   * recurso, e ela é o subtexto do capítulo municipal inteiro: as figuras de
   * percentual da RCL tratam cada município como uma unidade — passou ou não
   * passou da meta — e com isso somem com a diferença de escala entre uma
   * capital e um município de cinco mil habitantes.
   *
   * A leitura: metade dos municípios responde por 8% do gasto, e o 1% que mais
   * gasta responde por quase 30%. Parte disso é concentração de população e
   * seria assim em qualquer política pública; o que a curva mede é o resultado,
   * não a sua causa, e a nota diz isso.
   *
   * Os marcos são poucos de propósito. A curva já mostra a forma, e cada marco
   * escrito é uma frase que o leitor leva embora — cinco delas ainda se leem,
   * dez viram um borrão de números sobre a linha.
   */
  import ConcentracaoChart, { type Marco, type PontoLorenz } from './ConcentracaoChart.svelte';
  import { rampaVermelha } from './cores';
  import { colors as marca } from './tokens';
  import dados from '../data/concentracao-gasto-municipal.json';

  let {
    svgEl = $bindable(null),
    background,
  }: {
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  const inteiro = new Intl.NumberFormat('pt-BR');
  const decimal = new Intl.NumberFormat('pt-BR', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
  const pct = new Intl.NumberFormat('pt-BR', {
    minimumFractionDigits: 1,
    maximumFractionDigits: 1,
  });

  const pontos = dados.pontos as PontoLorenz[];

  const um = dados.marcos.find((m) => m.topo === 1)!;
  const dez = dados.marcos.find((m) => m.topo === 10)!;
  const metade = dados.marcos.find((m) => m.topo === 50)!;

  /**
   * Três dos cinco marcos calculados. O de 20% e o de 5% ficam de fora: os
   * cinco se atropelariam no trecho final da curva, que é onde ela sobe quase
   * a pique, e os três escolhidos já dão a escada inteira — 1%, 10% e metade.
   *
   * O rótulo é a frase inteira porque o número de um marco não é a altura do
   * ponto: no marco dos 10%, o ponto está a 42% e a leitura é 58%. Um número
   * solto ali seria lido como a altura, e diria o contrário do que mede.
   */
  const marcos: Marco[] = [metade, dez, um].map((m) => ({
    topo: m.topo,
    rotulo: `os ${m.topo}% que mais gastam concentram ${pct.format(m.share)}%`,
  }));

  const footnote =
    `Gasto com recursos próprios na Função 13 (Cultura) em ${dados.ano}, dos ${inteiro.format(dados.base)} municípios ` +
    `com contas declaradas, ordenados do que menos gasta ao que mais gasta. A metade que menos gasta responde por ` +
    `${decimal.format(100 - metade.share)}% do total; o 1% que mais gasta, por ${pct.format(um.share)}%. ` +
    `O índice de Gini da distribuição é ${decimal.format(dados.gini)}. Parte dessa concentração é concentração de ` +
    `população e de receita, e apareceria em qualquer política pública medida assim: a curva mede o resultado, não ` +
    `a sua causa. É por isso que ela anda junto com a figura de percentual da RCL, que já divide cada gasto pela ` +
    `receita do seu município.`;
</script>

<ConcentracaoChart
  {pontos}
  {marcos}
  cor={rampaVermelha[2]}
  corMarcador={rampaVermelha[0]}
  title="Metade dos municípios responde por 8% do gasto cultural do país"
  subtitle="Gasto cultural próprio acumulado, dos municípios que menos gastam aos que mais gastam · {inteiro.format(dados.base)} municípios em {dados.ano}"
  destaque={{
    valor: `${pct.format(dez.share)}%`,
    cor: marca.primaryVariant,
    texto: `do gasto cultural municipal do país sai dos 10% de municípios que mais gastam`,
  }}
  legendaDiagonal="Linha tracejada: onde a curva estaria se todos os municípios gastassem o mesmo"
  rotuloX="% dos municípios, do que menos gasta ao que mais gasta"
  rotuloY="% do gasto acumulado"
  {footnote}
  source="Fonte: Elaboração própria com base na MSC/SICONFI, Função 13 (Cultura)."
  {background}
  bind:svgEl
/>
