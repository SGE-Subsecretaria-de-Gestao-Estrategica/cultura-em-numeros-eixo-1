<script lang="ts">
  /**
   * A proporção de mulheres à frente da pasta de cultura municipal, onda a
   * onda — uma linha só, porque a segunda categoria é o complemento exato da
   * primeira: dizer "47,7% mulheres" já diz "52,3% homens", e uma coluna 100%
   * empilhada gastaria duas faixas para uma informação que uma linha e uma
   * nota de rodapé carregam sozinhas.
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
  const inteiro = new Intl.NumberFormat('pt-BR');
  const pct = (v: number) => `${decimal.format(v)}%`;

  const ondas = dados.genero.ondas;
  const anos = ondas.map((o) => Number(o.label));
  const final = ondas[ondas.length - 1];

  const series: Serie[] = [
    {
      key: 'feminino',
      cor: rampaVermelha[2],
      pontos: ondas.map((o) => ({ ano: Number(o.label), valor: o.Feminino })),
      rotulos: anos,
      destaque: {
        valor: pct(final.Feminino),
        cor: rampaVermelha[2],
        texto: `dos titulares da pasta de cultura municipal são mulheres, contra ${pct(final.Masculino)} homens em ${final.label}`,
      },
    },
  ];

  const primeira = ondas[0];

  const footnote =
    `Proporção de mulheres entre os titulares da pasta de cultura que declararam o próprio sexo — o restante são ` +
    `homens, a categoria complementar. Ficaram de fora, por não terem declarado: ` +
    `${ondas.map((o) => `${inteiro.format(o.naoResposta)} em ${o.label}`).join(', ')} — não-resposta não é ` +
    `evidência nem a favor nem contra o que se mede.`;
</script>

<FaixaLinhasChart
  {series}
  title="A proporção de mulheres à frente da cultura municipal recuou entre 2014 e 2021"
  subtitle="Mulheres entre os titulares da pasta de cultura nos municípios · MUNIC {primeira.label}, 2018 e {final.label}"
  formatValue={pct}
  {footnote}
  source="Fonte: Elaboração própria com base na MUNIC/IBGE, ondas de {primeira.label} a {final.label}."
  {background}
  bind:svgEl
/>
