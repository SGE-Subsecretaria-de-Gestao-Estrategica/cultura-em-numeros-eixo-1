/**
 * Prepara a malha dos 5 570 municípios para o mapa coroplético municipal.
 *
 * Faz o mesmo que `build_malha_ufs.mjs` — projeta, simplifica e emite um `d` de
 * SVG por unidade —, com duas diferenças que a escala municipal impõe:
 *
 *  - a simplificação é feita **nos arcos**, e não nos polígonos. A malha vem em
 *    TopoJSON, onde a divisa entre dois municípios é um arco só, referenciado
 *    pelos dois. Simplificar polígono a polígono cortaria a mesma divisa duas
 *    vezes, cada uma para o seu lado, e o mapa impresso ganharia frestas
 *    brancas e sobreposições em toda divisa comum. Simplificado o arco, os dois
 *    vizinhos continuam encaixados por construção;
 *  - o enquadramento não é recalculado: ele vem pronto de `malha-ufs.json`, e é
 *    o que faz os dois mapas caírem um sobre o outro, divisa com divisa.
 *
 * A tolerância é medida no domínio de 1 000 unidades, que impresso vale 150 mm:
 * uma unidade é 0,15 mm no papel, e meia unidade é 0,075 mm — abaixo do ponto
 * de uma impressão a 300 dpi, e ainda assim corta um terço dos vértices e meio
 * megabyte do arquivo.
 *
 *     node scripts/build_malha_municipios.mjs
 */

import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { geoConicEqualArea } from 'd3-geo';

const RAIZ = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const ENTRADA = path.join(RAIZ, 'src', 'data', 'malha-municipios.json');
const MALHA_UFS = path.join(RAIZ, 'src', 'data', 'malha-ufs.json');
const SAIDA = path.join(RAIZ, 'src', 'data', 'malha-municipios-projetada.json');

const TOLERANCIA = 0.5;

const SIGLAS = {
  11: 'RO', 12: 'AC', 13: 'AM', 14: 'RR', 15: 'PA', 16: 'AP', 17: 'TO',
  21: 'MA', 22: 'PI', 23: 'CE', 24: 'RN', 25: 'PB', 26: 'PE', 27: 'AL',
  28: 'SE', 29: 'BA', 31: 'MG', 32: 'ES', 33: 'RJ', 35: 'SP',
  41: 'PR', 42: 'SC', 43: 'RS', 50: 'MS', 51: 'MT', 52: 'GO', 53: 'DF',
};

/** Douglas-Peucker sobre uma linha aberta — um arco não se fecha. */
const simplifica = (pontos, tolerancia) => {
  if (pontos.length <= 2) return pontos;

  const manter = new Uint8Array(pontos.length);
  manter[0] = 1;
  manter[pontos.length - 1] = 1;

  const pilha = [[0, pontos.length - 1]];
  while (pilha.length) {
    const [inicio, fim] = pilha.pop();
    const [x1, y1] = pontos[inicio];
    const [x2, y2] = pontos[fim];
    const dx = x2 - x1;
    const dy = y2 - y1;
    const norma = Math.hypot(dx, dy);

    let pior = -1;
    let maior = tolerancia;
    for (let i = inicio + 1; i < fim; i++) {
      const [x, y] = pontos[i];
      const d =
        norma === 0
          ? Math.hypot(x - x1, y - y1)
          : Math.abs(dy * x - dx * y + x2 * y1 - y2 * x1) / norma;
      if (d > maior) {
        maior = d;
        pior = i;
      }
    }
    if (pior === -1) continue;
    manter[pior] = 1;
    pilha.push([inicio, pior], [pior, fim]);
  }

  return pontos.filter((_, i) => manter[i]);
};

const topologia = JSON.parse(await readFile(ENTRADA, 'utf8'));
const { quadro, largura, altura } = JSON.parse(await readFile(MALHA_UFS, 'utf8'));

const projecao = geoConicEqualArea().parallels([-2, -32]).rotate([54, 0]);
const { scale: [kx, ky], translate: [tx, ty] } = topologia.transform;

/**
 * Cada arco, uma vez: dequantizado, projetado, posto no quadro da malha das UFs
 * e simplificado. É aqui que mora quase todo o custo do script — e é por isso
 * que ele roda uma vez e não a cada renderização.
 */
const arcos = topologia.arcs.map((arco) => {
  let x = 0;
  let y = 0;
  const pontos = [];
  for (const [dx, dy] of arco) {
    x += dx;
    y += dy;
    const p = projecao([x * kx + tx, y * ky + ty]);
    if (!p || Number.isNaN(p[0])) continue;
    pontos.push([(p[0] - quadro.x0) * quadro.escala, (p[1] - quadro.y0) * quadro.escala]);
  }
  return simplifica(pontos, TOLERANCIA);
});

const numero = (v) => Math.round(v * 10) / 10;

/** Os pontos de um anel, costurados dos seus arcos; negativo é arco invertido. */
const anel = (indices) => {
  const pontos = [];
  for (const i of indices) {
    const arco = i < 0 ? [...arcos[~i]].reverse() : arcos[i];
    // o primeiro ponto de cada arco repete o último do anterior
    for (const p of pontos.length ? arco.slice(1) : arco) pontos.push(p);
  }
  return pontos;
};

const caminho = (geometria) => {
  const poligonos =
    geometria.type === 'Polygon' ? [geometria.arcs] : geometria.arcs;
  return poligonos
    .flatMap((aneis) =>
      aneis
        .map(anel)
        .filter((pontos) => pontos.length >= 3)
        .map((pontos) => `M${pontos.map(([x, y]) => `${numero(x)},${numero(y)}`).join('L')}Z`),
    )
    .join('');
};

const municipios = topologia.objects.BRMU.geometries
  .map((g) => {
    const codigo = String(g.properties.codarea);
    return { c: codigo, uf: SIGLAS[Number(codigo.slice(0, 2))], d: caminho(g) };
  })
  .sort((a, b) => a.c.localeCompare(b.c));

const vazios = municipios.filter((m) => !m.d);
if (vazios.length) throw new Error(`${vazios.length} municípios sem desenho`);

const porUf = municipios.reduce((acc, m) => ({ ...acc, [m.uf]: (acc[m.uf] ?? 0) + 1 }), {});
if (Object.keys(porUf).length !== 27) throw new Error(`esperava 27 UFs, tenho ${Object.keys(porUf).length}`);

await writeFile(
  SAIDA,
  `${JSON.stringify({
    fonte: 'IBGE · malha municipal digital',
    projecao: 'Cônica equivalente de Albers, paralelos -2 e -32, meridiano central -54',
    largura,
    altura,
    /** Quantos municípios tem cada UF — o denominador dos mapas de cobertura. */
    municipiosPorUf: porUf,
    municipios,
  })}\n`,
);

const bytes = (await readFile(SAIDA)).length;
const vertices = arcos.reduce((n, a) => n + a.length, 0);
const originais = topologia.arcs.reduce((n, a) => n + a.length, 0);
console.log(
  `${municipios.length} municípios · ${(bytes / 1024 / 1024).toFixed(2)} MB · ` +
    `${vertices} de ${originais} vértices (${Math.round((100 * vertices) / originais)}%)`,
);
