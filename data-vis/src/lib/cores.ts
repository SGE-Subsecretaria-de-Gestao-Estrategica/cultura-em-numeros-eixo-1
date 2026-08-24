/**
 * A paleta da marca do SNIIC — as cinco matizes e as variações delas com que
 * todas as figuras são desenhadas.
 *
 * As cinco cores da marca: vermelho `#D5362A`, rosa `#EC6596`, roxo `#4B2F92`,
 * azul `#4F68DA` e verde `#68CF27`. O que este arquivo acrescenta são as
 * variações: cada matiz vira uma rampa de cinco degraus, e é dela que saem as
 * cores das categorias. A escala categórica do design system não é usada em
 * nenhuma figura.
 *
 * Por que rampas, e não só matizes: a separação por luminosidade é o que
 * sobrevive à impressão em escala de cinza e à maior parte das formas de
 * daltonismo. E esta paleta tem um par que o daltonismo derruba de fato:
 * vermelho e verde ficam praticamente iguais sob protanopia e deuteranopia
 * quando têm a mesma luminosidade — é por isso que o verde de preenchimento é
 * claro, o verde de traço é o degrau mais escuro, e nenhum degrau médio do
 * verde aparece ao lado dos vermelhos.
 */

/**
 * Os degraus das cinco rampas são medidos na mesma escala de luminosidade em
 * OKLab — L* 0,32 / 0,44 / 0,555 / 0,67 / 0,79 —, com a matiz mantida e o croma
 * caindo em direção às pontas, onde ele não cabe no sRGB. Duas consequências
 * que as figuras usam o tempo todo:
 *
 * - o mesmo índice em rampas diferentes tem o mesmo peso na página, então a cor
 *   separa por matiz e não por ênfase;
 * - índices diferentes separam por luminosidade, então a ordem se lê sozinha —
 *   é o que faz uma rampa servir de escala sequencial.
 *
 * A cor da marca ocupa o degrau em que ela mesma cai: 2 no vermelho e no azul,
 * 3 no rosa, 1 no roxo — que é escuro por natureza — e 4 no verde, que é claro
 * por natureza.
 */

/** Do mais escuro ao mais claro, com o `#D5362A` da marca no degrau 2. */
export const rampaVermelha = ['#660001', '#9E0102', '#D5362A', '#F65848', '#FF9C8D'] as const;

/**
 * Do mais escuro ao mais claro, com o `#EC6596` da marca no degrau 3.
 *
 * O rosa da marca rende 2,6:1 sobre o cartão — preenche bem, mas não sustenta
 * um traço fino. Quem precisa dele num traço pega um degrau mais escuro da
 * mesma família.
 */
export const rampaRosa = ['#610030', '#960B4F', '#BD3B6F', '#EC6596', '#FF95B7'] as const;

/** Do mais escuro ao mais claro, com o `#4B2F92` da marca no degrau 1. */
export const rampaRoxa = ['#381579', '#4B2F92', '#755EC5', '#9682EB', '#BAAEFF'] as const;

/** Do mais escuro ao mais claro, com o `#4F68DA` da marca no degrau 2. */
export const rampaAzul = ['#191A8A', '#3143B1', '#4F68DA', '#6E8BFF', '#A1B7FF'] as const;

/**
 * Do mais escuro ao mais claro, com o `#68CF27` da marca no degrau 4.
 *
 * O verde da marca é claro demais para carregar traço ou texto: sobre o cartão
 * ele rende 1,7:1. E os degraus médios têm um problema só deles: na mesma
 * luminosidade de um vermelho, um verde some sob protanopia e deuteranopia.
 * Num traço, o verde desce direto ao degrau 0, que se separa dos vermelhos
 * escuros por luminosidade — a matiz, que é o que identifica a série entre as
 * figuras, não muda.
 */
export const rampaVerde = ['#183D00', '#2A6201', '#3D8702', '#51AF03', '#68CF27'] as const;

export const sniic = {
  /** Vermelho da marca — `rampaVermelha[2]`. */
  vermelho: rampaVermelha[2],
  /** Rosa da marca — `rampaRosa[3]`. */
  rosa: rampaRosa[3],
  /** Roxo da marca — `rampaRoxa[1]`. */
  roxo: rampaRoxa[1],
  /** Azul da marca — `rampaAzul[2]`. */
  azul: rampaAzul[2],
  /** Verde da marca — `rampaVerde[4]`. */
  verde: rampaVerde[4],
  /**
   * A cor dos marcadores pousados sobre uma faixa vermelha grossa.
   *
   * Sobre a faixa, um ponto da própria cor dela sumiria dentro dela, e um ponto
   * de outra matiz traria uma segunda cor para dentro do dado. O degrau mais
   * escuro da mesma família resolve os dois: é o máximo de contraste que a
   * família dá contra a faixa, e não acrescenta cor nenhuma à figura.
   */
  marcador: rampaVermelha[0],
} as const;

/**
 * `n` degraus de uma rampa, escolhidos com o afastamento máximo possível entre
 * si. Com duas categorias, pega o segundo e o quarto — os extremos deixariam um
 * quase-preto ao lado de um quase-branco.
 *
 * É para as figuras cujas categorias são ordenadas — os cinco graus de
 * institucionalização do órgão gestor vão de secretaria própria a nenhuma
 * estrutura — onde uma paleta categórica pediria ao leitor decorar qual matiz é
 * qual, e uma rampa mostra a ordem sozinha.
 */
export const degrausDe = (rampa: readonly string[], n: number): string[] => {
  if (n >= rampa.length) return [...rampa];
  if (n === 2) return [rampa[1], rampa[3]];
  const passo = (rampa.length - 1) / Math.max(n - 1, 1);
  return Array.from({ length: n }, (_, i) => rampa[Math.round(i * passo)]);
};

/** `degrausDe` na rampa vermelha, que é a sequencial padrão. */
export const rampaDe = (n: number): string[] => degrausDe(rampaVermelha, n);

/**
 * A escala categórica da marca: a cor de cada série quando as séries não estão
 * ordenadas entre si.
 *
 * As cinco primeiras são as cinco cores da marca, na ordem da marca — um
 * gráfico de até cinco séries recebe só cores oficiais. Da sexta em diante a
 * ordem é gulosa: cada degrau é o que fica mais longe de todos os já
 * escolhidos, então todo prefixo continua utilizável e nenhuma figura precisa
 * escolher índices na mão.
 *
 * O que cada tamanho garante, como distância mínima entre duas séries quaisquer
 * (ΔE em OKLab ×100, visão normal / pior forma de daltonismo):
 *
 * | séries | 3     | 4     | 5     | 6     | 7     | 8     |
 * |--------|-------|-------|-------|-------|-------|-------|
 * | ΔE     | 15/11 | 15/11 | 15/11 | 15/11 | 15/11 | 11/10 |
 *
 * O piso confortável para preenchimentos é ΔE 15 — a paleta o sustenta até sete
 * séries em visão normal, mas o piso sob daltonismo é 11 desde a quarta série
 * (o rosa e o azul claros sob tritanopia, o verde e o vermelho sob
 * deuteranopia). De seis em diante convém a figura carregar a identidade por
 * outro meio — rótulo dentro do segmento, nome na ponta da linha — com a cor
 * fazendo o reforço, não o trabalho. Vale para preenchimento; para traço fino,
 * `categoricaTracoDe`.
 */
export const categoricaMarca = [
  rampaVermelha[2], // o vermelho da marca
  rampaRosa[3], // o rosa da marca
  rampaRoxa[1], // o roxo da marca
  rampaAzul[2], // o azul da marca
  rampaVerde[4], // o verde da marca
  rampaVermelha[0],
  rampaRosa[1],
  rampaAzul[3],
] as const;

/**
 * A mesma escala para as figuras que desenham as séries como traço fino, ou que
 * escrevem o nome da série na cor dela.
 *
 * A diferença é o piso de contraste contra o cartão: um preenchimento se
 * sustenta em 1,7:1, um traço de 2 px não. O rosa desce um degrau que ainda é
 * rosa; o verde desce até o degrau mais escuro, porque é o único que não some
 * ao lado de um vermelho sob protanopia ou deuteranopia — os degraus médios
 * rendem ΔE 2,5 a 3,6 contra o vermelho da marca, que é uma cor só.
 *
 * Até quatro séries a distância mínima é ΔE 17 em visão normal e 12 sob
 * qualquer forma de daltonismo. A quinta série traz o verde e o piso sob
 * tritanopia desce a 9; da sexta em diante os degraus repetidos derrubam o piso
 * a ΔE 6-7 — daí em diante o gráfico só deve chegar se rotular as séries
 * diretamente, com a cor fazendo o reforço.
 */
export const categoricaMarcaTraco = [
  rampaVermelha[2], // o vermelho da marca
  rampaRosa[1], // o rosa dois degraus abaixo, para aguentar o traço
  rampaRoxa[1], // o roxo da marca
  rampaAzul[2], // o azul da marca
  rampaVerde[0], // o verde no degrau mais escuro — ver o comentário da rampa
  rampaRosa[2],
  rampaRoxa[0],
  rampaAzul[1],
] as const;

/** As `n` primeiras da escala categórica. Ver `categoricaMarca`. */
export const categoricaDe = (n: number): string[] =>
  Array.from({ length: n }, (_, i) => categoricaMarca[i % categoricaMarca.length]);

/** As `n` primeiras da escala de traço. Ver `categoricaMarcaTraco`. */
export const categoricaTracoDe = (n: number): string[] =>
  Array.from({ length: n }, (_, i) => categoricaMarcaTraco[i % categoricaMarcaTraco.length]);
