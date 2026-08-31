<script lang="ts">
  /**
   * O outro lado da contagem de agentes territoriais: quantos municípios cabem
   * a cada um.
   *
   * O mapa por UF responde "onde há mais agentes" e diz, na própria nota, o que
   * não responde — cobertura. Esta figura responde isso, com o único
   * denominador que o registro permite: o número de municípios do estado. São
   * Paulo tem os 93 agentes, a maior contagem do país, e 645 municípios; o Rio
   * Grande do Norte tem 11 agentes e 167 municípios. A leitura se inverte entre
   * as duas figuras, e é esse o ponto de haver as duas.
   *
   * Por que a malha municipal, se o dado é por UF: porque o denominador é
   * contado em municípios, e desenhá-los é mostrá-lo. Um estado com 645
   * unidades e um com 15 viram duas texturas diferentes antes de virarem duas
   * cores, e a razão que a cor carrega deixa de ser um número abstrato. A cor é
   * constante dentro de cada estado — não há, e a nota diz isso, registro de
   * agentes município a município.
   *
   * A rampa é a vermelha, a sequencial padrão da paleta, e não a roxa do mapa
   * de contagem: são duas medidas opostas sobre o mesmo fato, e cores iguais
   * convidariam a ler a segunda como continuação da primeira. Aqui o escuro é o
   * encargo — mais municípios por agente —, e o claro é a folga.
   */
  import CoropletoUfChart, { type ValorUf } from './CoropletoUfChart.svelte';
  import { rampaVermelha } from './cores';
  import { colors as marca } from './tokens';
  import agentes from '../data/agentes-territoriais.json';
  import malha from '../data/malha-municipios-projetada.json';

  let {
    svgEl = $bindable(null),
    background,
  }: {
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  const inteiro = new Intl.NumberFormat('pt-BR');
  const decimal = new Intl.NumberFormat('pt-BR', {
    minimumFractionDigits: 1,
    maximumFractionDigits: 1,
  });

  const municipiosPorUf: Record<string, number> = malha.municipiosPorUf;
  const totalMunicipios = malha.municipios.length;

  const valores: ValorUf[] = agentes.ufs.map(({ uf, valor }) => ({
    uf,
    valor: municipiosPorUf[uf] / valor,
  }));

  const ordenados = [...valores].sort((a, b) => b.valor - a.valor);
  const [maisPesado, segundo] = ordenados;
  const maisLeve = ordenados[ordenados.length - 1];
  const media = totalMunicipios / agentes.total;

  const agentesDe = (uf: string) => agentes.ufs.find((u) => u.uf === uf)!.valor;
  const sp = valores.find((v) => v.uf === 'SP')!.valor;

  const footnote =
    `Os agentes territoriais são registrados por unidade federativa, e não por município: a cor é a mesma em todos ` +
    `os municípios de um estado e vale a razão entre os municípios que ele tem e os agentes que atuam nele. Desenhar ` +
    `a malha municipal é pôr esse denominador à vista — o encargo de um agente é o pedaço de território que a cor ` +
    `dele cobre. No ${maisPesado.uf} cada agente responde por ${decimal.format(maisPesado.valor)} municípios e no ` +
    `${segundo.uf}, por ${decimal.format(segundo.valor)}, contra ${decimal.format(maisLeve.valor)} no ` +
    `${maisLeve.uf} — que é um caso à parte, com um município só e ${agentesDe(maisLeve.uf)} agentes. São Paulo, ` +
    `que tem a maior contagem de agentes do país, fica em ${decimal.format(sp)} municípios por agente, ` +
    `${sp > media ? 'acima' : 'abaixo'} da média nacional de ${decimal.format(media)} — a figura anterior o põe no ` +
    `extremo escuro da escala, e esta o devolve ao meio dela. Malha municipal do IBGE em projeção cônica ` +
    `equivalente de Albers, no mesmo enquadramento da figura anterior.`;
</script>

<CoropletoUfChart
  {valores}
  mosaico={malha.municipios}
  rampa={[rampaVermelha[4], rampaVermelha[3], rampaVermelha[2], rampaVermelha[1], rampaVermelha[0]]}
  quebras={[4, 7, 10, 13]}
  rotulosClasses={['menos de 4', '4 a 7', '7 a 10', '10 a 13', '13 ou mais']}
  title="Quantos municípios cabem a cada agente territorial"
  subtitle="Municípios por agente territorial em atuação · {inteiro.format(totalMunicipios)} municípios e {inteiro.format(agentes.total)} agentes"
  legendaTitulo="Municípios por agente"
  formatValue={(v) => decimal.format(v)}
  destaque={{
    valor: decimal.format(media),
    cor: marca.primary,
    texto: 'municípios para cada agente territorial, na média do país',
  }}
  {footnote}
  source="Fonte: Elaboração própria com base nos registros da Secretaria dos Comitês de Cultura (MinC), reproduzidos na publicação, e na malha municipal do IBGE."
  {background}
  bind:svgEl
/>
