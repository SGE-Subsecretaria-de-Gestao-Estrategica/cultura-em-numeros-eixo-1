<script lang="ts">
  /**
   * O investimento federal em cultura como histomap: as oito fontes descendo
   * por 23 anos, cada uma tão larga quanto a sua participação no total do ano.
   *
   * É a mesma tabela do `ComposicaoFederalChart` — mesma normalização, mesma
   * ordem de empilhamento, mesmas cores — com o tempo no eixo Y e as
   * transições suavizadas, que é o que a forma histomap pede. O que só esta
   * leitura dá é o fluxo: a renúncia fiscal engordando até ocupar o meio da
   * figura, a extinção do MinC como um estrangulamento da faixa azul, e as três
   * leis de emergência entrando pela direita como bolsões vermelhos.
   *
   * A ordem de empilhamento vem dos grupos institucionais do próprio JSON, e
   * não da ordem das chaves: execução direta à esquerda, renúncia fiscal ao
   * centro, transferências a estados e municípios à direita. Assim a figura
   * conta as duas histórias ao mesmo tempo — as oito fontes e as três
   * naturezas — e o MinC e os Outros Órgãos ficam vizinhos: a extinção lê-se
   * como troca de cor dentro de uma massa contínua, que é o que ela foi.
   *
   * Não há variante nominal: a participação de cada fonte é a mesma nas duas
   * medidas, porque o deflator multiplica todas as fontes de um ano pelo mesmo
   * índice. Os valores dos blocos de destaque, esses sim, estão a preços
   * de 2024.
   */
  import HistomapChart, { type AnoRow } from './HistomapChart.svelte';
  import { fonteFederalLabels, fonteFederalStackColors } from './fontes';
  import federal from '../data/federal-por-fonte.json';

  let {
    svgEl = $bindable(null),
    background,
  }: {
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  /**
   * A pilha, da esquerda para a direita, montada a partir dos grupos
   * institucionais declarados no JSON — e não repetida aqui à mão, para que a
   * figura não possa divergir da definição que a tabela e as demais figuras
   * federais usam.
   */
  const ordem = federal.grupos.keys.flatMap(
    (grupo) => (federal.grupos.composicao as Record<string, string[]>)[grupo],
  );

  const cores = fonteFederalStackColors(federal.keys);
  const colors = ordem.map((key) => cores[key]);

  /** A participação é a mesma nas duas medidas; `real` é só a que já existe. */
  const data = federal.real as unknown as AnoRow[];

  /**
   * Até 2005 o MinC divide o ano só consigo mesmo — a renúncia não era nula,
   * não era medida — então a faixa mais larga do trecho é justamente a que a
   * anotação manda não ler ao pé da letra. O nome ancora de 2006 em diante,
   * onde a participação já é uma medida, e os percentuais anuais seguem a
   * mesma regra: escrever "100%" três vezes sob a ressalva seria afirmar em
   * número o que a nota acabou de negar.
   */
  const anosComRenunciaMedida = {
    'Ministério da Cultura (Órgão 42000)': federal.real
      .map((row) => Number(row.label))
      .filter((ano) => ano >= 2006),
  };
</script>

<HistomapChart
  {data}
  keys={ordem}
  labels={fonteFederalLabels}
  {colors}
  labelYears={anosComRenunciaMedida}
  shareYears={anosComRenunciaMedida}
  title="Evolução do investimento federal em cultura por fonte de recurso"
  subtitle="Participação de cada fonte no gasto federal pleno, ano a ano, de cima para baixo · 2003–2025"
  anotacoes={[{ ano: 2004, texto: 'até 2005, só a execução direta é medida' }]}
  destaques={[
    {
      ano: 2006,
      valor: 'R$ 3,2 bi',
      titulo: 'a renúncia fiscal entra na série',
      nota: 'o teto da Rouanet e da ANCINE passa a ser medido',
    },
    {
      ano: 2012,
      valor: 'R$ 7,6 bi',
      titulo: 'o pico do ciclo do MinC',
      nota: 'só superado em 2023',
    },
    {
      ano: 2020,
      valor: 'R$ 7,4 bi',
      titulo: 'a emergência da pandemia',
      nota: 'a LAB 1 transfere R$ 3,9 bi a estados e municípios num ano só',
    },
    {
      ano: 2023,
      valor: 'R$ 13,1 bi',
      titulo: 'o maior ano da série',
      nota: 'a Lei Paulo Gustavo e a PNAB somam R$ 7,2 bi',
    },
  ]}
  footnote={'As fontes correm de cima para baixo, empilhadas por natureza: execução direta à esquerda, renúncia fiscal ao centro, transferências a estados e municípios à direita. A largura de cada faixa é a participação da fonte no total do ano; as transições entre os anos são suavizadas para dar a leitura de fluxo, mas a medida é anual — uma fonte executada num ano só, como a Lei Aldir Blanc 1, entra e sai em rampa que não houve. A série de renúncia fiscal começa em 2006, então até 2005 a fatia do MinC está superestimada. De 2019 a 2022 o MinC não aparece porque foi extinto, e a despesa da pasta corre por Cidadania e Turismo: as duas faixas azuis são o mesmo dinheiro trocando de casa. As participações não dependem do deflator; os valores em destaque estão a preços médios de 2024 (IPCA).'}
  source="Fonte: Elaboração própria com base no SIOP, no SALIC e na ANCINE."
  {background}
  bind:svgEl
/>
