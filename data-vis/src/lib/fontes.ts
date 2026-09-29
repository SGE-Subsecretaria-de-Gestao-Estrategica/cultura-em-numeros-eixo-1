/**
 * Shared setup for the "fontes de recurso" figures — the Storybook stories and
 * the A4 proof page draw the same charts, so the palettes, the short names and
 * the print sizing live here rather than in any one of them.
 */

import { rampaAzul, rampaRosa, rampaVermelha, sniic } from './cores';
import { colorGradients } from './tokens';

/**
 * As cinco fontes de recurso sub-nacionais, nas cores da implementação
 * anterior das figuras de fita (`RibbonEstadualChart`, `RibbonMunicipalChart`)
 * — um roxo para o recurso próprio e duas matizes verdes, lima e teal,
 * alternando degrau a degrau nas três leis emergenciais e nas emendas.
 *
 * É uma exceção deliberada à rampa de cinco matizes da marca que o resto da
 * coleção usa (ver `cores.ts`): pedido para manter a leitura de cor das duas
 * figuras de fita como ela já foi publicada, e não a paleta categórica do
 * design system nem a rampa da marca. As cores vêm literalmente das escalas
 * `purple`/`teal`/`lime` do `sniic-design-system`, que a implementação
 * anterior importava.
 */
export const fonteColors = [
  '#a44c7f', // Recurso próprio — roxo do design system
  '#c3d992', // Emendas — lima claro
  '#95c0b7', // LAB 1 — teal claro
  '#81a72f', // LPG — lima escuro
  '#255c4f', // PNAB — teal escuro
];

/**
 * As mesmas cinco fontes para as figuras de evolução estadual — as linhas e as
 * colunas empilhadas, que são a mesma tabela e por isso têm de sair na mesma
 * paleta.
 *
 * Difere de `fonteColors` num degrau só: o rosa claro rende 1,8:1 sobre o
 * cartão e não sustenta um traço de 2 px, então as emendas descem para um
 * degrau escuro. A matiz — que é o que identifica a fonte entre as figuras —
 * não muda.
 *
 * Nesta versão nenhum par cai abaixo de ΔE 9,3 em visão normal nem de 6,0 sob
 * qualquer forma de daltonismo, e o pior deles é o par vermelho vizinho.
 */
export const fonteMarcaColors = [
  rampaAzul[2], // Recurso próprio
  rampaRosa[1], // Emendas — o rosa escuro, para aguentar o traço
  rampaVermelha[3], // LAB 1
  rampaVermelha[2], // LPG — o vermelho da marca
  rampaVermelha[0], // PNAB
];

/** Covers both datasets — the own-revenue key differs by sphere. */
export const fonteLabels: Record<string, string> = {
  'Recurso Próprio (Estadual)': 'Recurso próprio',
  'Recurso Próprio (Municipal)': 'Recurso próprio',
  'Emendas Parlamentares (Cultura)': 'Emendas',
  'Lei Aldir Blanc 1 (LAB 1)': 'LAB 1',
  'Lei Paulo Gustavo (LPG)': 'LPG',
  'PNAB (Aldir Blanc 2)': 'PNAB',
};

/**
 * Os três grupos institucionais da série federal, na ordem em que as figuras os
 * desenham: execução direta, renúncia fiscal, transferências a entes.
 *
 * É uma matiz da marca para cada grupo, e é daqui que sai a chave de leitura de
 * todas as outras figuras federais: azul é o orçamento executado pela União,
 * rosa é a renúncia fiscal, vermelho é o dinheiro que desce para estados e
 * municípios. As oito fontes abaixo herdam a matiz do grupo a que pertencem, e
 * as figuras sub-nacionais seguem a mesma chave.
 *
 * Como traço, a renúncia fica no rosa escuro: nenhum par cai abaixo de ΔE 17
 * em visão normal, nem de 15 sob qualquer forma de daltonismo — a maior
 * separação que três séries com dois quentes podem ter nesta paleta.
 *
 * Ficam aqui, e não em cada figura, porque o combo de linhas e colunas e o
 * gráfico de linhas desenham os mesmos três grupos: duas paletas iguais copiadas
 * em dois arquivos só esperam a hora de divergir.
 */
export const grupoFederalColors = [
  rampaAzul[2], // Execução direta
  rampaRosa[1], // Renúncia fiscal
  rampaVermelha[2], // Transferências a estados e municípios
];

/** Só o terceiro encurta — por extenso, ele não cabe ao lado da linha. */
export const grupoFederalLabels: Record<string, string> = {
  'Execução direta': 'Execução direta',
  'Renúncia fiscal': 'Renúncia fiscal',
  'Transferências a estados e municípios': 'Transferências a entes',
};

/**
 * As oito fontes federais nos gradientes da marca — a paleta que o histomap
 * desenha.
 *
 * Oito séries passam do que três matizes sustentam sozinhas, então a paleta usa
 * as duas dimensões que tem: a **matiz diz a que grupo institucional a fonte
 * pertence** e a **luminosidade separa as fontes dentro do grupo**. Quem lê a
 * legenda no topo da figura, que sai na ordem de empilhamento, já chega ao plot
 * com os três grupos na cabeça.
 *
 * - **Azuis e roxo, a execução direta.** O MinC no degrau mais escuro do azul,
 *   por ser a maior faixa; os Outros Órgãos num azul claro — a extinção do MinC
 *   lê-se como clareamento dentro da mesma massa, que é o que ela foi; e o FSA
 *   no roxo escuro, a única troca de matiz do grupo. Ela existe porque o
 *   gradiente azul não separa três faixas: com o FSA em azul, o MinC e os
 *   Outros Órgãos ficariam a ΔE 5 um do outro na legenda, encostados e quase
 *   iguais, e são justamente os dois que o leitor precisa distinguir.
 * - **Rosas, a renúncia fiscal.** A Lei Rouanet no degrau escuro e a ANCINE no
 *   mais claro — as duas ficam sempre encostadas na pilha, e essa distância é o
 *   que impede que se fundam numa faixa só, que é exatamente a leitura errada:
 *   metade do investimento federal é renúncia, e a figura precisa mostrar de
 *   qual das duas.
 * - **Vermelhos, o que desce para estados e municípios.** A LPG no degrau mais
 *   escuro e a PNAB no mais claro, que é o par que de fato se toca (2023), com
 *   a LAB 1 no meio — ela vive sozinha em 2020 e só encosta na ANCINE.
 *
 * O que a paleta garante é a adjacência, que é o que uma figura empilhada pede:
 * nenhum par que chegue a se tocar na pilha cai abaixo de ΔE 15,1 em visão
 * normal nem de 14,5 sob qualquer forma de daltonismo. O que ela não garante é
 * o par distante: os gradientes desta marca são estreitos em luminosidade, e
 * sob protanopia ou deuteranopia um rosa claro e um vermelho claro que nunca se
 * encostam ficam a ΔE 3,7. Daí a legenda no topo e o nome escrito dentro da
 * faixa: aqui a cor reforça a identidade, não a carrega sozinha.
 */
export const fonteFederalPalette: Record<string, string> = {
  'Ministério da Cultura (Órgão 42000)': colorGradients.secondaryVariant[0],
  'Outros Órgãos (Cidadania/Turismo)': colorGradients.secondaryVariant[3],
  'FSA (UO 74912)': colorGradients.secondary[0],
  'Lei Rouanet': colorGradients.primaryVariant[0],
  'Incentivo (ANCINE)': colorGradients.primaryVariant[4],
  'Lei Aldir Blanc 1': colorGradients.primary[2],
  'Lei Paulo Gustavo': colorGradients.primary[0],
  'PNAB (UO 73120)': colorGradients.primary[4],
};

/**
 * As cores na ordem em que as chaves forem pedidas.
 *
 * A paleta é indexada pelo nome da fonte, e não pela posição no JSON, porque a
 * figura empilha na ordem dos grupos institucionais e não na ordem das chaves:
 * indexar por posição faria a cor seguir a tabela em vez de seguir a fonte.
 */
export const fonteFederalColors = (keys: readonly string[]): Record<string, string> =>
  Object.fromEntries(keys.map((k) => [k, fonteFederalPalette[k] ?? sniic.vermelho]));

/**
 * Fica como função, e não como sinônimo, porque é a assinatura que as figuras
 * empilhadas chamam — e porque é aqui que uma correção entraria, se algum ano
 * futuro puser duas fontes de matizes vizinhas encostadas.
 */
export const fonteFederalStackColors = fonteFederalColors;

/**
 * Nomes curtos das fontes federais.
 *
 * As leis vêm por extenso e o resto por sigla, e não é inconsistência: numa
 * figura sobre fonte de recurso, "Lei Paulo Gustavo" e "Lei Aldir Blanc 1" são
 * o assunto, e são justamente as que acabam dentro do plot, onde o nome longo
 * cabe. As que chegam a 2025 põem o nome na margem direita, que toda série
 * paga em largura de plot — lá a sigla é o que evita a calha larga.
 */
export const fonteFederalLabels: Record<string, string> = {
  'Ministério da Cultura (Órgão 42000)': 'MinC',
  'Lei Rouanet': 'Lei Rouanet',
  'Incentivo (ANCINE)': 'ANCINE',
  'FSA (UO 74912)': 'FSA',
  'PNAB (UO 73120)': 'PNAB',
  'Lei Paulo Gustavo': 'Lei Paulo Gustavo',
  'Lei Aldir Blanc 1': 'Lei Aldir Blanc 1',
  'Outros Órgãos (Cidadania/Turismo)': 'Outros órgãos',
};
