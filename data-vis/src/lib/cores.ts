/**
 * As cores da marca do SNIIC, para as figuras que são desenhadas nelas em vez
 * de na escala categórica do design system.
 *
 * A escala categórica existe para separar séries por matiz. Quando a figura já
 * separa as séries por outro meio — rótulo em cada ponto e bloco de leitura na
 * ponta de cada linha, como na variante de faixa — a cor deixa de carregar
 * identidade e pode carregar marca.
 */

export const sniic = {
  /** Vermelho da marca. As séries são desenhadas nele. */
  vermelho: '#CB4034',
  /**
   * O mesmo vermelho num tom mais profundo (mesma matiz, luminosidade 15
   * pontos abaixo). É a cor dos marcadores: sobre uma faixa grossa, um ponto
   * da própria cor da linha sumiria dentro dela, e um ponto de outra matiz
   * traria uma segunda cor para dentro do dado.
   */
  vermelhoProfundo: '#8E2A20',
  /**
   * Marrom avermelhado, escuro e dessaturado. A outra cor de marcador: fica na
   * mesma família do vermelho da marca, mas com saturação bem abaixo da faixa
   * em que pousa, então o ponto se destaca sobre o traço grosso sem competir
   * com ele em intensidade.
   */
  marromMarcador: '#77433F',
  /**
   * Azul. Marca os instantes de medição — os pontos sobre a faixa vermelha — e
   * o valor da última onda, o número com que o leitor sai do gráfico.
   */
  azul: '#4271B5',
  /**
   * Ciano da marca. Fora de uso nestas figuras: sobre o fundo claro do cartão
   * ele rende 2,0:1 de contraste, insuficiente para texto.
   */
  ciano: '#10CBD5',
} as const;

/**
 * A escala monocromática do vermelho da marca, do mais escuro ao mais claro,
 * com o `#CB4034` no degrau do meio.
 *
 * É para as figuras cujas categorias são ordenadas — os cinco graus de
 * institucionalização do órgão gestor vão de secretaria própria a nenhuma
 * estrutura — onde uma paleta categórica pediria ao leitor decorar qual matiz
 * é qual, e uma rampa mostra a ordem sozinha.
 *
 * Os degraus são espaçados em luminosidade, não em saturação: é a luminosidade
 * que sobrevive à impressão em escala de cinza e a boa parte das formas de
 * daltonismo.
 */
export const rampaVermelha = [
  '#6E211A',
  '#9B2E23',
  '#CB4034',
  '#E08578',
  '#F3CDC7',
] as const;

/**
 * `n` degraus da rampa, escolhidos com o afastamento máximo possível entre si.
 * Com duas categorias, pega o segundo e o quarto — os extremos deixariam um
 * quase-preto ao lado de um quase-branco.
 */
export const rampaDe = (n: number): string[] => {
  if (n >= rampaVermelha.length) return [...rampaVermelha];
  if (n === 2) return [rampaVermelha[1], rampaVermelha[3]];
  const passo = (rampaVermelha.length - 1) / Math.max(n - 1, 1);
  return Array.from({ length: n }, (_, i) => rampaVermelha[Math.round(i * passo)]);
};
