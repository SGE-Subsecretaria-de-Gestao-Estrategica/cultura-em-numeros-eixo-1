<script lang="ts">
  /**
   * A repartição do investimento federal em cultura entre as oito fontes, ano a
   * ano, cada coluna fechando em 100%.
   *
   * É a mesma tabela de `Federal · Tabela por fonte` e o mesmo dado de
   * `Federal · Evolução por fonte (linhas)`, mas respondendo a outra pergunta.
   * A figura de linhas mostra **quanto** cada fonte pôs, e por isso o total
   * também se move nela; esta mostra **de onde veio** cada real, com o total
   * fixo em 100% — o que faz aparecer o que a série de valores esconde, que é a
   * fatia permanente da renúncia fiscal e a substituição do órgão gestor entre
   * 2019 e 2022.
   *
   * Três decisões que a figura toma:
   *
   * - a ordem de empilhamento vem dos grupos institucionais do próprio JSON, e
   *   não da ordem das chaves: execução direta na base, renúncia fiscal no
   *   meio, transferências a estados e municípios no topo. Assim a figura conta
   *   as duas histórias ao mesmo tempo, as oito fontes e as três naturezas, e o
   *   Ministério da Cultura e os Outros Órgãos ficam vizinhos — a extinção do
   *   MinC lê-se como troca de cor dentro de uma faixa contínua, que é o que
   *   ela foi.
   * - a participação é escrita em toda fatia que a comporte, e quem decide é a
   *   altura da fatia. Sobram sem número as que estão abaixo de 4% — a ANCINE
   *   na maior parte da série, o FSA quase sempre — e os três primeiros anos,
   *   onde `100%` é mais largo que a coluna. Nos três casos a ausência do
   *   número não esconde nada: as fatias finas são justamente as que a legenda
   *   e a ordem de grandeza já resolvem, e 2003–2005 é o trecho que o colchete
   *   manda não ler como repartição.
   * - os três primeiros anos levam um colchete. A série de renúncia fiscal
   *   começa em 2006, e num gráfico de participação um buraco na série não fica
   *   em branco: ele empurra todas as outras fatias para cima.
   *
   * Não há variante nominal, e isto não é omissão: o deflator multiplica todas
   * as fontes de um ano pelo mesmo índice, então a repartição do ano é
   * idêntica nas duas medidas (verificado — a maior diferença entre elas é de
   * 1e-10 ponto percentual). A figura de linhas precisa da variante porque lá o
   * que está no eixo é o valor.
   */
  import ComposicaoAnualChart, {
    type AnoRow,
    type Forma,
  } from './ComposicaoAnualChart.svelte';
  import { fonteFederalLabels, fonteFederalStackColors } from './fontes';
  import federal from '../data/federal-por-fonte.json';

  let {
    /** `colunas`, um ano por coluna; `area`, as fontes como faixas contínuas. */
    forma = 'colunas',
    svgEl = $bindable(null),
    background,
  }: {
    forma?: Forma;
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  /**
   * A pilha, da base para o topo, montada a partir dos grupos institucionais
   * declarados no JSON — e não repetida aqui à mão, para que a figura não possa
   * divergir da definição que a tabela e o combo de grupos usam.
   */
  const ordem = federal.grupos.keys.flatMap(
    (grupo) => (federal.grupos.composicao as Record<string, string[]>)[grupo],
  );

  const cores = fonteFederalStackColors(federal.keys);
  const colors = ordem.map((key) => cores[key]);

  /**
   * A curva de fronteira só nas colunas: na forma de área as faixas já são
   * contínuas, e traçar o contorno delas seria desenhar duas vezes a mesma
   * linha.
   */
  const temCurvas = $derived(forma === 'colunas');

  /** A participação é a mesma nas duas medidas; `real` é só a que já existe. */
  const data = federal.real as unknown as AnoRow[];

  /**
   * Os mesmos oito anos marcados na figura de linhas, para as duas poderem ser
   * lidas uma sobre a outra. De dois em dois não caberia: o rótulo de um ano é
   * mais largo do que a faixa que um ano ocupa nesta largura de cartão.
   */
  const tickYears = [2003, 2006, 2010, 2013, 2016, 2019, 2023, 2025];
</script>

<ComposicaoAnualChart
  {data}
  keys={ordem}
  labels={fonteFederalLabels}
  {colors}
  {forma}
  curvas={temCurvas}
  {tickYears}
  spans={[{ de: 2003, ate: 2005, texto: 'sem série de renúncia fiscal' }]}
  title="Composição do investimento federal em cultura por fonte de recurso"
  subtitle="Participação de cada fonte no gasto federal pleno em cultura, ano a ano · 2003–2025"
  footnote={'As fontes estão empilhadas por natureza: execução direta na base, renúncia fiscal no meio, transferências a estados e municípios no topo. A série de renúncia começa em 2006, então nos três primeiros anos a fatia do Ministério da Cultura está superestimada — a renúncia não era nula, não foi medida. De 2019 a 2022 o MinC não aparece porque foi extinto, e a despesa da pasta corre por Cidadania e Turismo: as duas faixas são o mesmo dinheiro trocando de casa. A Lei Aldir Blanc 1 (2020) e a Lei Paulo Gustavo (2023) foram executadas num ano só cada uma. As participações não dependem do deflator, e por isso a figura vale igual a preços de 2024 e em valores correntes.'}
  source="Fonte: Elaboração própria com base no SIOP, no SALIC e na ANCINE."
  {background}
  bind:svgEl
/>
