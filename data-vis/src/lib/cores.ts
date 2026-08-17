/**
 * A paleta da marca do SNIIC — as três matizes e as variações delas com que
 * todas as figuras são desenhadas.
 *
 * As três cores são as mesmas que o tema do pilar 1 do design system carrega
 * como `primary`, `secondary` e `accent`. O que este arquivo acrescenta são as
 * variações: cada matiz vira uma rampa de cinco degraus, e é dela que saem as
 * cores das categorias. A escala categórica do design system não é mais usada
 * em nenhuma figura.
 *
 * Por que rampas, e não mais matizes: com três matizes só, a separação entre
 * séries tem de vir da luminosidade. É ela, e não a saturação, que sobrevive à
 * impressão em escala de cinza e à maior parte das formas de daltonismo — e é
 * o que permite oito séries saírem de três cores sem virarem uma mancha só.
 */

/**
 * Os degraus das três rampas são medidos na mesma escala de luminosidade em
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
 * 4 no ciano, que é claro por natureza.
 */

/** Do mais escuro ao mais claro, com o `#CB3328` da marca no degrau 2. */
export const rampaVermelha = ['#620A07', '#961E16', '#CB3328', '#E46B5C', '#FA9F91'] as const;

/** Do mais escuro ao mais claro, com o `#2062C2` da marca no degrau 2. */
export const rampaAzul = ['#06306A', '#144EA1', '#2062C2', '#6696DF', '#98BCF3'] as const;

/**
 * Do mais escuro ao mais claro, com o `#12C9D2` da marca no degrau 4.
 *
 * O ciano da marca é claro demais para carregar traço ou texto: sobre o cartão
 * ele rende 1,8:1. Quem precisa dele num traço fino pega um degrau mais escuro
 * da mesma família — a matiz, que é o que identifica a série entre as figuras,
 * não muda.
 */
export const rampaCiana = ['#13393C', '#185D61', '#1E8288', '#29A8AF', '#12C9D2'] as const;

export const sniic = {
  /** Vermelho da marca — `rampaVermelha[2]`. */
  vermelho: rampaVermelha[2],
  /** Azul da marca — `rampaAzul[2]`. */
  azul: rampaAzul[2],
  /** Ciano da marca — `rampaCiana[4]`. */
  ciano: rampaCiana[4],
  /**
   * A cor dos marcadores pousados sobre uma faixa vermelha grossa.
   *
   * Sobre a faixa, um ponto da própria cor dela sumiria dentro dela, e um ponto
   * de outra matiz traria uma segunda cor para dentro do dado. O degrau mais
   * escuro da mesma família resolve os dois: rende 2,6:1 contra a faixa, que é
   * o máximo que a família dá, e não acrescenta cor nenhuma à figura.
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
 * A ordem é gulosa, não arbitrária — cada degrau é o que fica mais longe de
 * todos os já escolhidos. Isso torna todo prefixo utilizável: um gráfico de
 * três séries pega as três primeiras e recebe as três cores da marca; um de
 * cinco pega as cinco primeiras e recebe o melhor conjunto de cinco que a
 * paleta dá. Nenhuma figura precisa escolher índices na mão.
 *
 * O que cada tamanho garante, como distância mínima entre duas séries quaisquer
 * (ΔE em OKLab ×100, visão normal / pior forma de daltonismo):
 *
 * | séries | 3     | 4     | 5     | 6     | 7     | 8     |
 * |--------|-------|-------|-------|-------|-------|-------|
 * | ΔE     | 29/24 | 25/21 | 20/17 | 15/12 | 12/11 | 12/10 |
 *
 * O piso confortável para preenchimentos é ΔE 15. Até seis séries a paleta o
 * sustenta; de sete em diante ela desce a ~12, e a figura tem de carregar a
 * identidade por outro meio — rótulo dentro do segmento, nome na ponta da
 * linha — com a cor fazendo o reforço, não o trabalho. Vale para preenchimento;
 * para traço fino, `categoricaTracoDe`.
 */
export const categoricaMarca = [
  rampaVermelha[2], // o vermelho da marca
  rampaAzul[2], // o azul da marca
  rampaCiana[4], // o ciano da marca
  rampaVermelha[0],
  rampaAzul[0],
  rampaAzul[3],
  rampaVermelha[3],
  rampaVermelha[1],
] as const;

/**
 * A mesma escala para as figuras que desenham as séries como traço fino, ou que
 * escrevem o nome da série na cor dela.
 *
 * A diferença é o piso de contraste contra o cartão: um preenchimento se
 * sustenta em 1,6:1, um traço de 2 px não. Os degraus claros saem, e a série
 * que ficaria com o ciano da marca fica com o degrau imediatamente abaixo.
 *
 * Sai melhor que a escala categórica do design system que estas figuras usavam:
 * nas oito séries federais, o pior par vai de ΔE 9,0 para 11,8 em visão normal,
 * de 3,8 para 8,5 em protanopia e de 0,4 — duas cores praticamente iguais — para
 * 11,5 em deuteranopia.
 *
 * Até cinco séries a distância mínima é ΔE 20 e nenhuma forma de daltonismo cai
 * abaixo de 16. Da sexta em diante o ciano precisa de um segundo degrau e o par
 * azul-ciano escuro colapsa sob tritanopia (ΔE 4,7) — que é a forma rara, e
 * mesmo assim o gráfico só deve chegar lá se rotular as séries diretamente.
 */
export const categoricaMarcaTraco = [
  rampaVermelha[2], // o vermelho da marca
  rampaAzul[2], // o azul da marca
  rampaCiana[3], // o ciano um degrau abaixo, para aguentar o traço
  rampaVermelha[0],
  rampaAzul[0],
  rampaCiana[2],
  rampaVermelha[1],
  rampaCiana[1],
] as const;

/** As `n` primeiras da escala categórica. Ver `categoricaMarca`. */
export const categoricaDe = (n: number): string[] =>
  Array.from({ length: n }, (_, i) => categoricaMarca[i % categoricaMarca.length]);

/** As `n` primeiras da escala de traço. Ver `categoricaMarcaTraco`. */
export const categoricaTracoDe = (n: number): string[] =>
  Array.from({ length: n }, (_, i) => categoricaMarcaTraco[i % categoricaMarcaTraco.length]);
