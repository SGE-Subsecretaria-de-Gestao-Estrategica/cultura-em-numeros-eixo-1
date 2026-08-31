/**
 * Prepara a malha das 27 unidades federativas para os mapas coropléticos.
 *
 * A malha do IBGE vem em graus e com detalhe de sobra para uma figura de 170 mm
 * de largura: a costa do Nordeste sozinha traz milhares de vértices que, no
 * papel, cabem em menos de um décimo de milímetro. Este script faz de uma vez o
 * que não vale a pena refazer a cada renderização:
 *
 *  1. baixa a malha por UF (qualidade intermediária) e a guarda em cache, para
 *     que uma segunda execução não dependa da rede nem mude o desenho;
 *  2. projeta em cônica equivalente de Albers com os paralelos do Brasil — a
 *     área do polígono é a área do estado, que é o mínimo que um coroplético
 *     deve ao leitor;
 *  3. simplifica em espaço projetado, com tolerância medida no domínio em que a
 *     figura é desenhada, e não em graus;
 *  4. emite um `d` de SVG por UF, mais a âncora do rótulo.
 *
 * A saída (`src/data/malha-ufs.json`) é o que a figura importa: nenhuma conta de
 * projeção sobra para o navegador, e duas tiragens da mesma figura são idênticas
 * até o último dígito.
 *
 *     node scripts/build_malha_ufs.mjs
 */

import { existsSync } from 'node:fs';
import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { geoConicEqualArea } from 'd3-geo';

const RAIZ = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const CACHE = path.join(RAIZ, 'scripts', 'malha-ufs-cache.json');
const SAIDA = path.join(RAIZ, 'src', 'data', 'malha-ufs.json');

const URL_IBGE =
  'https://servicodados.ibge.gov.br/api/v3/malhas/paises/BR' +
  '?intrarregiao=UF&formato=application/vnd.geo+json&qualidade=intermediaria';

/** Largura do domínio em que a malha é emitida. */
const LARGURA = 1000;

/**
 * Tolerância da simplificação, em unidades do domínio. A 580 unidades de largura
 * autoral, 1 unidade do domínio vale 0,58 unidade da figura e 0,17 mm no papel;
 * 0,5 fica na casa de um décimo de milímetro, abaixo do que a impressão resolve.
 */
const TOLERANCIA = 0.5;

/** Ilhas menores que isto somem — em unidades de área do domínio. */
const AREA_MINIMA = 4;

const SIGLAS = {
  11: 'RO', 12: 'AC', 13: 'AM', 14: 'RR', 15: 'PA', 16: 'AP', 17: 'TO',
  21: 'MA', 22: 'PI', 23: 'CE', 24: 'RN', 25: 'PB', 26: 'PE', 27: 'AL',
  28: 'SE', 29: 'BA', 31: 'MG', 32: 'ES', 33: 'RJ', 35: 'SP',
  41: 'PR', 42: 'SC', 43: 'RS', 50: 'MS', 51: 'MT', 52: 'GO', 53: 'DF',
};

const NOMES = {
  RO: 'Rondônia', AC: 'Acre', AM: 'Amazonas', RR: 'Roraima', PA: 'Pará',
  AP: 'Amapá', TO: 'Tocantins', MA: 'Maranhão', PI: 'Piauí', CE: 'Ceará',
  RN: 'Rio Grande do Norte', PB: 'Paraíba', PE: 'Pernambuco', AL: 'Alagoas',
  SE: 'Sergipe', BA: 'Bahia', MG: 'Minas Gerais', ES: 'Espírito Santo',
  RJ: 'Rio de Janeiro', SP: 'São Paulo', PR: 'Paraná', SC: 'Santa Catarina',
  RS: 'Rio Grande do Sul', MS: 'Mato Grosso do Sul', MT: 'Mato Grosso',
  GO: 'Goiás', DF: 'Distrito Federal',
};

const malhaCrua = async () => {
  if (existsSync(CACHE)) return JSON.parse(await readFile(CACHE, 'utf8'));
  const resposta = await fetch(URL_IBGE);
  if (!resposta.ok) throw new Error(`IBGE respondeu ${resposta.status}`);
  const geojson = await resposta.json();
  await writeFile(CACHE, JSON.stringify(geojson));
  return geojson;
};

/** Douglas-Peucker sobre um anel projetado, preservando o fechamento. */
const simplificaAnel = (anel, tolerancia) => {
  const fechado = anel.length > 1 && anel[0][0] === anel.at(-1)[0] && anel[0][1] === anel.at(-1)[1];
  const pontos = fechado ? anel.slice(0, -1) : anel;
  if (pontos.length <= 4) return anel;

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

  const saida = pontos.filter((_, i) => manter[i]);
  // um anel precisa de três vértices para ainda ser um polígono
  if (saida.length < 3) return anel;
  return fechado ? [...saida, saida[0]] : saida;
};

const areaAnel = (anel) => {
  let soma = 0;
  for (let i = 0, j = anel.length - 1; i < anel.length; j = i++) {
    soma += anel[j][0] * anel[i][1] - anel[i][0] * anel[j][1];
  }
  return Math.abs(soma) / 2;
};

const dentro = (anel, [px, py]) => {
  let bate = false;
  for (let i = 0, j = anel.length - 1; i < anel.length; j = i++) {
    const [xi, yi] = anel[i];
    const [xj, yj] = anel[j];
    if (yi > py !== yj > py && px < ((xj - xi) * (py - yi)) / (yj - yi) + xi) bate = !bate;
  }
  return bate;
};

/**
 * A âncora do rótulo: o ponto do maior anel mais distante da borda dele — o
 * polo de inacessibilidade, aproximado por refinamento sucessivo de uma grade.
 *
 * O centroide serviria na maioria dos estados e falharia justamente nos de
 * contorno recortado, onde ele cai fora do próprio polígono ou encosta numa
 * reentrância. O que interessa aqui não é o centro de massa, é o lugar em que
 * cabe texto.
 */
const poloDeInacessibilidade = (anel) => {
  const xs = anel.map((p) => p[0]);
  const ys = anel.map((p) => p[1]);
  let [x0, x1] = [Math.min(...xs), Math.max(...xs)];
  let [y0, y1] = [Math.min(...ys), Math.max(...ys)];

  const distancia = ([px, py]) => {
    if (!dentro(anel, [px, py])) return -1;
    let minima = Infinity;
    for (let i = 0, j = anel.length - 1; i < anel.length; j = i++) {
      const [ax, ay] = anel[j];
      const [bx, by] = anel[i];
      const dx = bx - ax;
      const dy = by - ay;
      const t = dx || dy ? Math.max(0, Math.min(1, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy))) : 0;
      minima = Math.min(minima, Math.hypot(px - (ax + t * dx), py - (ay + t * dy)));
    }
    return minima;
  };

  let melhor = [(x0 + x1) / 2, (y0 + y1) / 2];
  let melhorD = -1;
  for (let rodada = 0; rodada < 6; rodada++) {
    const passos = 16;
    for (let i = 0; i <= passos; i++) {
      for (let j = 0; j <= passos; j++) {
        const p = [x0 + ((x1 - x0) * i) / passos, y0 + ((y1 - y0) * j) / passos];
        const d = distancia(p);
        if (d > melhorD) {
          melhorD = d;
          melhor = p;
        }
      }
    }
    // aperta a janela em torno do melhor ponto e refina
    const lx = (x1 - x0) / passos;
    const ly = (y1 - y0) / passos;
    [x0, x1] = [melhor[0] - lx, melhor[0] + lx];
    [y0, y1] = [melhor[1] - ly, melhor[1] + ly];
  }
  return { ponto: melhor.map((v) => Math.round(v * 10) / 10), folga: Math.round(melhorD * 10) / 10 };
};

const numero = (v) => Math.round(v * 10) / 10;

const caminho = (poligonos) =>
  poligonos
    .flatMap((aneis) =>
      aneis.map((anel) => `M${anel.map(([x, y]) => `${numero(x)},${numero(y)}`).join('L')}Z`),
    )
    .join('');

const geojson = await malhaCrua();

/**
 * Cônica equivalente de Albers com os paralelos-padrão do Brasil. Equivalente
 * porque num coroplético a área pintada é o peso visual de cada estado: numa
 * Mercator, Roraima ganharia área que não tem e o Sul perderia a sua.
 */
const projecao = geoConicEqualArea().parallels([-2, -32]).rotate([54, 0]);

const projetaAnel = (anel) => {
  const saida = [];
  for (const coordenada of anel) {
    const p = projecao(coordenada);
    if (!p || Number.isNaN(p[0])) continue;
    saida.push(p);
  }
  return saida;
};

/**
 * Projetado primeiro, escalado depois.
 *
 * `fitWidth` mediria a caixa com o `geoPath` da própria projeção, que numa
 * cônica leva junto o recorte do lado de trás do cone e devolve uma caixa muito
 * maior do que o Brasil. A caixa aqui sai dos vértices que de fato serão
 * desenhados, e a simplificação só vem depois da escala — a tolerância está em
 * unidades do domínio, e aplicá-la antes apagaria o Distrito Federal.
 */
const projetados = geojson.features.map((feature) => {
  const bruto =
    feature.geometry.type === 'Polygon'
      ? [feature.geometry.coordinates]
      : feature.geometry.coordinates;
  return {
    sigla: SIGLAS[Number(feature.properties.codarea)],
    poligonos: bruto.map((aneis) => aneis.map(projetaAnel)),
  };
});

const todosOsPontos = projetados.flatMap((f) => f.poligonos.flat(2));
const minX = Math.min(...todosOsPontos.map((p) => p[0]));
const maxX = Math.max(...todosOsPontos.map((p) => p[0]));
const minY = Math.min(...todosOsPontos.map((p) => p[1]));
const escala = LARGURA / (maxX - minX);
const paraDominio = ([x, y]) => [(x - minX) * escala, (y - minY) * escala];

const ufs = projetados.map(({ sigla, poligonos: brutos }) => {
  const poligonos = brutos
    .map((aneis) =>
      aneis
        .map((anel) => {
          const escalado = [];
          for (const p of anel.map(paraDominio)) {
            // vértices que caem no mesmo décimo de unidade não desenham nada
            const anterior = escalado.at(-1);
            if (anterior && Math.abs(anterior[0] - p[0]) < 0.05 && Math.abs(anterior[1] - p[1]) < 0.05)
              continue;
            escalado.push(p);
          }
          return simplificaAnel(escalado, TOLERANCIA);
        })
        .filter((anel) => anel.length >= 4 && areaAnel(anel) >= AREA_MINIMA),
    )
    .filter((aneis) => aneis.length > 0);

  return { sigla, poligonos };
});

/**
 * O enquadramento final sai do que sobrou, e não do que veio.
 *
 * A caixa da primeira passagem inclui as ilhas oceânicas — Trindade sozinha
 * empurra a borda leste 65 unidades para fora do continente. Descartadas elas,
 * o desenho é reescalado para ocupar a largura cheia do domínio: assim o mapa
 * impresso é o continente, sem uma faixa vazia de mar à direita.
 */
const desenhados = ufs.flatMap((u) => u.poligonos.flat(2));
const caixaX = [Math.min(...desenhados.map((p) => p[0])), Math.max(...desenhados.map((p) => p[0]))];
const caixaY = [Math.min(...desenhados.map((p) => p[1])), Math.max(...desenhados.map((p) => p[1]))];
const ajuste = LARGURA / (caixaX[1] - caixaX[0]);
const enquadra = ([x, y]) => [(x - caixaX[0]) * ajuste, (y - caixaY[0]) * ajuste];

/**
 * O enquadramento em números, para quem mais precisar dele.
 *
 * A malha municipal é desenhada no mesmo domínio, e ela não tem como recalcular
 * este quadro: a caixa saiu das 27 UFs com as ilhas já descartadas. Publicado
 * aqui, o mapa municipal aplica `(p − [x0, y0]) × escala` ao seu próprio
 * resultado de projeção e cai exatamente sobre este — divisa com divisa.
 */
const quadro = {
  x0: minX + caixaX[0] / escala,
  y0: minY + caixaY[0] / escala,
  escala: escala * ajuste,
};

const saida = {
  fonte: 'IBGE · malha das unidades federativas, qualidade intermediária',
  projecao: 'Cônica equivalente de Albers, paralelos -2 e -32, meridiano central -54',
  largura: LARGURA,
  altura: Math.ceil((caixaY[1] - caixaY[0]) * ajuste),
  quadro,
  ufs: ufs
    .map(({ sigla, poligonos }) => {
      const enquadrados = poligonos.map((aneis) => aneis.map((anel) => anel.map(enquadra)));
      const maiorAnel = enquadrados.flat().reduce((a, b) => (areaAnel(a) >= areaAnel(b) ? a : b));
      const { ponto, folga } = poloDeInacessibilidade(maiorAnel);
      return {
        uf: sigla,
        nome: NOMES[sigla],
        d: caminho(enquadrados),
        rotulo: ponto,
        /** Raio do maior círculo que cabe no estado: quanto texto cabe dentro. */
        folga,
      };
    })
    .sort((a, b) => a.uf.localeCompare(b.uf)),
};

await writeFile(SAIDA, `${JSON.stringify(saida)}\n`);

const bytes = (await readFile(SAIDA)).length;
console.log(
  `${saida.ufs.length} UFs · ${(bytes / 1024).toFixed(0)} kB · domínio ${saida.largura}×${saida.altura}`,
);
console.log(saida.ufs.map((u) => `${u.uf} folga ${u.folga}`).join('  '));
