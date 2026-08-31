/**
 * A malha hexagonal do Brasil — a geografia esquemática que as figuras
 * territoriais compartilham.
 *
 * Ela nasceu dentro da `HexMapaUfChart` e saiu para cá quando uma segunda
 * figura passou a precisar dela. O motivo de haver uma só: um leitor que
 * aprendeu onde fica cada UF numa figura não deve ter de reaprender na
 * seguinte. As duas figuras territoriais da publicação põem a mesma UF no mesmo
 * lugar, e o que muda entre elas é a marca desenhada ali — colunas contra uma
 * referência num caso, um disco proporcional no outro.
 *
 * As medidas são as do print de referência, num domínio de 1307 unidades de
 * largura; quem desenha escala para a sua largura autoral.
 */

/** Lado do hexágono; largura 2s, altura √3·s, colunas a 1,5s. */
export const S = 76.7;
export const COL = 1.5 * S;
export const MEIA_LINHA = (Math.sqrt(3) / 2) * S;

/** Largura do domínio em que a malha está desenhada. */
export const LARGURA_PRINT = 1307;

export type Regiao = {
  offset: [number, number];
  rotulo: [number, number];
  celulas: Record<string, [number, number]>;
};

/**
 * Cada região com as suas células locais (coluna, meia-linha) e o deslocamento
 * do aglomerado na página. A paridade de coluna e meia-linha andam juntas — é o
 * que mantém as células na malha.
 */
export const REGIOES: Record<string, Regiao> = {
  Norte: {
    offset: [160, 70],
    rotulo: [235, 178],
    celulas: { RR: [2, 0], AP: [4, 0], PA: [3, 1], AM: [2, 2], AC: [1, 3], TO: [3, 3], RO: [2, 4] },
  },
  Nordeste: {
    offset: [700, 225],
    rotulo: [940, 122],
    celulas: {
      MA: [0, 0], RN: [2, 0], CE: [1, 1], PB: [3, 1], PE: [2, 2],
      AL: [4, 2], PI: [1, 3], SE: [3, 3], BA: [2, 4],
    },
  },
  'Centro-Oeste': {
    offset: [505, 334],
    rotulo: [645, 775],
    celulas: { DF: [1, 1], MT: [0, 2], GO: [1, 3], MS: [1, 5] },
  },
  Sudeste: {
    offset: [815, 635],
    rotulo: [1090, 745],
    celulas: { MG: [0, 0], ES: [2, 0], RJ: [1, 1], SP: [0, 2] },
  },
  Sul: {
    offset: [700, 880],
    rotulo: [742, 930],
    celulas: { PR: [2, 0], SC: [1, 1], RS: [0, 2] },
  },
};

/** O centro da célula de uma UF, no domínio da malha. */
export const centro = (regiao: string, uf: string): [number, number] => {
  const { offset, celulas } = REGIOES[regiao];
  const [col, meia] = celulas[uf];
  return [offset[0] + col * COL, offset[1] + meia * MEIA_LINHA];
};

/** A região a que uma UF pertence, procurada na própria malha. */
export const regiaoDe = (uf: string): string =>
  Object.keys(REGIOES).find((regiao) => uf in REGIOES[regiao].celulas)!;

/** Todas as UFs da malha, na ordem em que as regiões estão declaradas. */
export const UFS = Object.values(REGIOES).flatMap((r) => Object.keys(r.celulas));

/** Vértices de um hexágono de topo plano: pontas à esquerda e à direita. */
export const vertices = (cx: number, cy: number): [number, number][] =>
  [0, 60, 120, 180, 240, 300].map((g) => {
    const rad = (g * Math.PI) / 180;
    return [cx + S * Math.cos(rad), cy + S * Math.sin(rad)];
  });

export const caminhoHex = (cx: number, cy: number) =>
  `M${vertices(cx, cy)
    .map(([x, y]) => `${x.toFixed(1)},${y.toFixed(1)}`)
    .join('L')}Z`;

/**
 * O contorno externo de cada aglomerado: de todas as arestas dos hexágonos da
 * região, as que aparecem uma vez só — as internas aparecem duas.
 *
 * A malha não muda, então isto se calcula uma vez por módulo e não por figura.
 */
export const CONTORNOS: { regiao: string; arestas: [number, number, number, number][] }[] =
  Object.entries(REGIOES).map(([regiao, { celulas }]) => {
    const arestas = new Map<string, [number, number, number, number]>();
    for (const uf of Object.keys(celulas)) {
      const v = vertices(...centro(regiao, uf));
      for (let i = 0; i < 6; i++) {
        const [x1, y1] = v[i];
        const [x2, y2] = v[(i + 1) % 6];
        const chave = `${Math.round((x1 + x2) / 2)},${Math.round((y1 + y2) / 2)}`;
        if (arestas.has(chave)) arestas.delete(chave);
        else arestas.set(chave, [x1, y1, x2, y2]);
      }
    }
    return { regiao, arestas: [...arestas.values()] };
  });
