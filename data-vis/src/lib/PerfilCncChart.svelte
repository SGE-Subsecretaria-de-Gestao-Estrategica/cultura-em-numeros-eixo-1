<script lang="ts">
  /**
   * Quem esteve na 4ª Conferência Nacional de Cultura, ponto a ponto.
   *
   * A publicação traz esse perfil como cinco tabelinhas empilhadas na mesma
   * página — vinte números soltos que ninguém lê impressos. A grade responde às
   * mesmas perguntas de relance, e faz uma coisa que a tabela não faz: mostra o
   * tamanho de cada grupo na mesma moeda, que é gente.
   *
   * Os quatro recortes são os que descrevem quem a pessoa é. O quinto da
   * tabela — delegação nata, eleita titular, eleita suplente — descreve como
   * ela chegou, que é outra pergunta, e fica de fora.
   *
   * A cor é a escala categórica da marca com o roxo e o rosa trocados de
   * lugar, e a troca não é estética. Numa matriz de pontos as fatias ocupam
   * blocos contíguos, então o que precisa se separar é cada par *vizinho* — e o
   * par vizinho na ordem original seria justamente vermelho e rosa, que rende
   * ΔE 14,6 em visão normal, abaixo do piso de 15. No painel de cor ou raça
   * esse par cairia entre as duas maiores fatias, pardas (425) e brancas (406):
   * a fronteira mais importante da figura ficaria na cor mais fraca da paleta.
   *
   * Com a troca, o primeiro par passa a ser vermelho e roxo — ΔE 32 em visão
   * normal e 26,5 no pior caso de daltonismo, o mesmo par medido para a figura
   * de participação da União — e vermelho e rosa nunca se encostam.
   */
  import MatrizPontosChart, { type Painel } from './MatrizPontosChart.svelte';
  import { rampaAzul, rampaRosa, rampaRoxa, rampaVerde, rampaVermelha } from './cores';
  import dados from '../data/perfil-cnc.json';

  let {
    svgEl = $bindable(null),
    background,
  }: {
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  const inteiro = new Intl.NumberFormat('pt-BR');

  const ESCALA = [
    rampaVermelha[2], // o vermelho da marca
    rampaRoxa[1], // o roxo da marca
    rampaRosa[3], // o rosa da marca
    rampaAzul[2], // o azul da marca
    rampaVerde[4], // o verde da marca
  ];

  const paineis: Painel[] = dados.recortes.map((recorte) => {
    const cores = ESCALA.slice(0, recorte.fatias.length);
    return {
      key: recorte.key,
      titulo: recorte.titulo,
      fatias: recorte.fatias.map((f, i) => ({
        key: f.key,
        label: f.label,
        n: f.n,
        cor: cores[i],
      })),
    };
  });

  const porKey = Object.fromEntries(
    dados.recortes.map((r) => [r.key, Object.fromEntries(r.fatias.map((f) => [f.key, f]))]),
  );

  const sociedadeCivil = porKey.origem['sociedade-civil'];
  const comDeficiencia = porKey.deficiencia.com;
  const pretasEPardas = porKey.raca.pardos.n + porKey.raca.pretos.n;

  const footnote =
    `Cada ponto é uma das ${inteiro.format(dados.total)} pessoas inscritas como delegadas, e a grade é a mesma nos ` +
    `quatro painéis — o que muda de um para outro é só onde caem as fronteiras entre as cores. ` +
    `A sociedade civil respondeu por ${sociedadeCivil.n} das inscrições, contra ${porKey.origem['poder-publico'].n} do ` +
    `poder público; ${pretasEPardas} pessoas se declararam pretas ou pardas, e ${comDeficiencia.n} como pessoas com ` +
    `deficiência. No recorte de gênero, a tabela original traz sete categorias: as pessoas não-binárias (28), mulheres ` +
    `trans (22), travestis (11) e homens trans (4) entram somadas, e "Outro" (77) fica com o nome que a tabela deu. ` +
    `Os quatro recortes fecham em ${inteiro.format(dados.total)} cada um.`;
</script>

<MatrizPontosChart
  {paineis}
  total={dados.total}
  colunasDaGrade={38}
  title="Quem esteve na 4ª Conferência Nacional de Cultura"
  subtitle="As {inteiro.format(dados.total)} pessoas inscritas como delegadas, repartidas de quatro maneiras · {dados.ano}"
  {footnote}
  source="Fonte: Elaboração própria com base nos registros da 4ª Conferência Nacional de Cultura (MinC), reproduzidos na publicação."
  {background}
  bind:svgEl
/>
