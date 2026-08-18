<script lang="ts">
  /**
   * Quanto do orçamento da União foi para a cultura, ano a ano, de 2011 a 2025.
   *
   * A régua é a Receita Corrente Líquida — o que a União arrecada e pode
   * gastar, depois de descontadas as transferências que ela só repassa. É a
   * régua com que a LRF mede pessoal e endividamento e com que a política
   * cultural costuma pedir piso, e é também a que o script de origem já usa
   * (`perc_rcl`, em `gasto federal.R`). A série começa em 2011 porque é onde
   * começa a planilha de RCL do Tesouro; o gasto em cultura vai a 2003.
   *
   * O numerador é o gasto federal pleno: a execução orçamentária direta mais a
   * renúncia fiscal de Rouanet e ANCINE. A renúncia não é despesa — é imposto
   * que o Tesouro deixou de arrecadar — e entra porque a figura mede o esforço
   * federal em cultura por inteiro. Quem quiser só a despesa passa
   * `medida="direto"`, e a distância entre as duas figuras é a renúncia.
   *
   * O cartão é o mesmo do tripé institucional: faixa grossa, marcador escuro
   * sobre ela, valor final em destaque na ponta, e o mesmo traçado suavizado.
   * Do que é próprio daquela figura, fica de fora o colchete de "N anos" entre
   * pontos, que lá mede a distância entre ondas de pesquisa e aqui repetiria
   * "1 ano" catorze vezes.
   *
   * A curva é monotônica, e é isso que a torna utilizável numa série anual:
   * ela nunca ultrapassa os valores medidos, então o pico de 2023 fica em
   * 1,02% e o fundo de 2021, em 0,28% — a suavização arredonda o caminho entre
   * dois anos, não inventa um extremo entre eles. O que ela custa é o
   * contorno: a Aldir Blanc de 2020 e a Paulo Gustavo de 2023 foram executadas
   * num exercício cada uma, e a curva as desenha subindo e descendo em rampa.
   * Os marcadores são o que restitui o instante — é sobre eles, e não sobre o
   * traço, que os valores estão escritos.
   *
   * Três coisas que a figura escolhe:
   *
   * - o eixo vai a zero, e não ao redor da série. Numa participação, a
   *   distância até o zero é o que se está medindo: com o eixo cortado, a
   *   queda de 2021 pareceria o desaparecimento da política, e ela é a queda de
   *   0,50% para 0,28% da receita.
   * - dois dígitos depois da vírgula. A série inteira cabe entre 0,28% e 1,02%,
   *   e com uma casa só os quatro anos do platô 2015–2018 sairiam todos como
   *   "0,5%" — o declínio lento, que é a informação, viraria uma linha reta.
   * - oito dos quinze anos no eixo, e valor escrito só onde a série vira. O
   *   rótulo de um ano é quase tão largo quanto a faixa que um ano ocupa nesta
   *   largura de cartão.
   */
  import SerieHistoricaChart from './SerieHistoricaChart.svelte';
  import { sniic } from './cores';
  import participacao from '../data/participacao-rcl.json';

  let {
    /**
     * `pleno`, execução direta mais renúncia fiscal; `direto`, só a despesa
     * orçamentária.
     */
    medida = 'pleno',
    svgEl = $bindable(null),
    background,
  }: {
    medida?: 'pleno' | 'direto';
    svgEl?: SVGSVGElement | null;
    background?: string | null;
  } = $props();

  const serie = $derived(participacao.series.find((s) => s.key === medida)!);
  const series = $derived([serie]);

  /** Uma cor só: com uma série, quem a nomeia é o bloco de ponta. */
  const colors = [sniic.vermelho];

  const decimal2 = new Intl.NumberFormat('pt-BR', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
  const decimal1 = new Intl.NumberFormat('pt-BR', {
    minimumFractionDigits: 1,
    maximumFractionDigits: 1,
  });

  const pct = (v: number) => `${decimal2.format(v)}%`;

  /** R$ em bilhões ou trilhões, conforme a ordem de grandeza. */
  const reais = (v: number) =>
    v >= 1e12
      ? `R$ ${decimal1.format(v / 1e12)} tri`
      : `R$ ${decimal1.format(v / 1e9)} bi`;

  const ultimo = participacao.totais[participacao.totais.length - 1];

  /**
   * Terceira linha do bloco de ponta: os dois números que a razão esconde.
   * Sem eles o leitor sai sabendo a fatia e não o tamanho do bolo.
   */
  const endNote = () =>
    `${reais(ultimo[medida])} de ${reais(ultimo.rcl)} de RCL em ${ultimo.ano}`;

  /**
   * Teto um pouco acima do pico de 2023, e não o múltiplo de 10 que o cartão
   * usaria: a série não passa de 1,02% e a dezena deixaria 99% do plot vazio.
   *
   * O mesmo teto vale para as duas medidas, e não um ajustado a cada uma: com
   * a mesma régua, a figura da despesa direta pode ser posta sobre a do gasto
   * pleno e a distância entre as duas linhas é a renúncia fiscal. Ajustar o
   * teto por medida faria as duas ocuparem a mesma altura de plot e a
   * comparação desapareceria.
   */
  const yMax = 1.2;

  /**
   * Os anos em que a série decide alguma coisa: as duas pontas do platô que vai
   * até 2018, o degrau de 2019, os dois picos de programa emergencial e o fundo
   * entre eles. 2025 fica de fora porque o bloco de ponta já o escreve em corpo
   * grande.
   *
   * A lista muda com a medida porque as viradas mudam de ano: no gasto pleno o
   * platô culmina em 2012 e o fundo é 2021; só na despesa direta, o platô sobe
   * até 2013 e o fundo desce mais um ano, até 2022.
   */
  const labelYears = $derived(
    medida === 'pleno'
      ? [2011, 2012, 2018, 2019, 2020, 2021, 2023, 2024]
      : [2011, 2013, 2019, 2020, 2022, 2023, 2024],
  );

  /** Oito dos quinze anos, de dois em dois — o passo que não sobrepõe rótulos. */
  const tickYears = [2011, 2013, 2015, 2017, 2019, 2021, 2023, 2025];

  const rotulo = $derived(
    medida === 'pleno'
      ? {
          subtitulo:
            'Gasto federal pleno em cultura — execução direta mais renúncia fiscal — como percentual da Receita Corrente Líquida da União, ano a ano · 2011–2025',
          nota: 'O numerador soma a execução orçamentária direta em cultura e a renúncia fiscal de Rouanet e ANCINE.',
        }
      : {
          subtitulo:
            'Execução orçamentária direta em cultura — sem a renúncia fiscal — como percentual da Receita Corrente Líquida da União, ano a ano · 2011–2025',
          nota: 'O numerador é só a despesa orçamentária: a renúncia fiscal de Rouanet e ANCINE fica de fora, e é ela a distância para a versão do gasto pleno.',
        },
  );
</script>

<SerieHistoricaChart
  {series}
  {colors}
  markerColor={sniic.marcador}
  endValueColor={sniic.azul}
  {yMax}
  {labelYears}
  {tickYears}
  {endNote}
  lineWidth={8.5}
  smooth
  hideYAxis
  xGuides
  endBlocks
  formatValue={pct}
  title="Participação da cultura no orçamento da União"
  subtitle={rotulo.subtitulo}
  footnote={`${rotulo.nota} O denominador é a Receita Corrente Líquida apurada no RREO do Tesouro Nacional, a mesma régua com que a LRF mede pessoal e dívida. Os dois lados estão em valores correntes, e por isso a participação independe do deflator. Em 2020 a fatia sobe pelas duas pontas: a Lei Aldir Blanc levou a execução direta a R$ 4,3 bilhões, e a RCL caiu 28% no ano — a receita corrente recuou 10% na pandemia e as transferências deduzidas subiram 27%, com os repasses de socorro a estados e municípios. O pico de 2023 é a Lei Paulo Gustavo, executada num ano só.`}
  source="Fonte: Elaboração própria com base no SIOP, no SALIC, na ANCINE e no RREO/Tesouro Nacional."
  {background}
  bind:svgEl
/>
