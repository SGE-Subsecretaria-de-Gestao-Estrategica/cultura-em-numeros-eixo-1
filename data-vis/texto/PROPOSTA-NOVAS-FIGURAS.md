# Novas figuras para o Eixo 1

Proposta a partir da leitura do `Texto Publicação Cultura em Números.pdf` (27 páginas)
contra as 8 figuras que existem hoje em `data-vis/src/lib`.

A numeração começa em F9, seguindo as oito existentes. Os números pulam porque três
figuras propostas numa primeira versão saíram do escopo — ficam registradas na
seção 6, com o motivo, para não serem re-propostas do zero se voltarem.

---

## 1. Onde a narrativa está coberta — e onde está vazia

O texto tem três blocos. As 8 figuras cobrem um e meio.

| Bloco do texto | Figuras do texto | O que já temos | Estado |
|---|---|---|---|
| **Cap. 1.1 Investimento federal** | Fig. 1, 2, 3 | `HistomapFederal`, `ParticipacaoUniao` | coberto |
| **Cap. 1.2 Investimento estadual** | Fig. 4, 5, 6 | `EstadualFontes`, `ParticipacaoEstados` | coberto |
| **Cap. 1.3 Investimento municipal** | Fig. 7 | `MetaRcl`, `MetaRclRegiao` | **só a meta de 2%** — não há figura do volume municipal, nem da composição por fonte, nem da distribuição |
| **Cap. 2 Participação social** | 5 tabelas + 2 pedidos de mapa/infográfico | — | **zero figuras** |
| **Gestão pública** (quadro de metas + comentários do Pedro) | 12 gráficos exploratórios, quase todos reprovados | `TripeUf` | **1 figura** |

A figura `TresEsferas` abre o capítulo e não corresponde a nenhuma figura numerada — é
nossa, e é a única leitura consolidada das três esferas.

Dois vazios importam mais que os outros:

- **O capítulo 2 inteiro está sem figura.** O texto marca dois pedidos explícitos
  (`[Mapa ou Infográfico... OSCs por Estado]`, `[Tabela, mapa ou ilustração... agentes
  territoriais]`) e despeja cinco tabelas cruas que ninguém vai ler impressas.
- **O município aparece só como percentual.** É a maior esfera em volume e a única
  que só entra na publicação pela porta do indicador de 2% da RCL.

E há um dado pronto no repo, com script de build e tudo, que nunca virou figura:
`municipal-por-fonte.json`.

---

## 2. Diagnóstico de forma

Cinco das oito figuras são linhas (`FaixaLinhas` ×3 + `PequenosMultiplos` + a régua do
`LinhaProporcao`). Duas são hexmapas. Uma é histomap.

Em vocabulário visual, o que temos e o que falta:

| O que a figura faz | Temos | Falta |
|---|---|---|
| evolução no tempo | ✅ muito | — |
| composição no tempo | ✅ histomap | — |
| comparação territorial | ✅ hexmap ×2 | contagem territorial (o hexmap só lê percentual) |
| **distribuição** | ❌ | tudo é média ou contagem agregada; nunca se vê a forma dos dados |
| **contagem literal** | ❌ | nenhuma figura conta unidades (596 agentes, 1.201 delegados) |
| **relação entre duas variáveis** | ❌ | o cruzamento que o Pedro chamou de "MUITO BOM" não tem forma |
| **decomposição de uma variação** | ❌ | "cresceu R$ 4,4 bi" nunca é aberto em partes |
| **concentração / desigualdade** | ❌ | — |
| **fluxo / transformação** | ❌ | **continua sem cobertura** — ver seção 6 |

As cinco primeiras linhas vazias são a proposta. A última fica em aberto: as duas
figuras que abririam a categoria de fluxo saíram do escopo, então nada na publicação
vai mostrar "de onde vem, para onde vai". É a única lacuna de forma que esta proposta
não fecha, e vale saber que ela é uma escolha e não um esquecimento.

---

## 3. As figuras propostas

Sete figuras, sete tipos que ainda não existem no sistema. Todas mantêm a linguagem de
traço grosso, ponta arredondada e curva — regras na seção 4.

### Capítulo 1 — orçamento

---

#### F9 · De onde saiu o crescimento municipal
**Tipo novo: cascata em blocos arredondados (waterfall).**

De R$ 5,6 bi em 2019 a R$ X bi em 2024: um bloco por fonte que entrou (próprio,
emendas, LAB 1, LPG, PNAB), cada um partindo de onde o anterior parou, ligados por
fitas curvas em vez de degraus. O bloco do recurso próprio é o único que pode ser
negativo — e foi, entre 2019 e 2021.

*Por que:* é a resposta direta ao lead do capítulo ("de que maneira os novos mecanismos
de repasse mudaram o cenário"), e o município é hoje o buraco da publicação.
*Dado:* `src/data/municipal-por-fonte.json` — **pronto, já no repo, sem figura.**
*Cor:* rosa para as emendas (regra da paleta), rampa vermelha para as três leis,
roxo para o próprio.

---

#### F10 · A distribuição por trás da média
**Tipo novo: enxame (beeswarm) por região, com a linha dos 2% atravessando.**

Cinco faixas horizontais, uma por região; cada município é uma bolinha translúcida
posicionada pelo seu gasto próprio como % da RCL. A linha preta dos 2% corta as cinco.

*Por que:* hoje `MetaRcl` diz "N municípios acima de 2%" e `MetaRclRegiao` diz "X% em
cada região" — nenhuma das duas mostra que a distribuição é uma massa colada no zero
com uma cauda longa. É o argumento mais forte que o dado tem e ele está invisível.
*Variante ainda mais curva:* cristas de densidade (ridgeline) empilhadas por região —
cinco curvas suaves sobrepostas. Perde os outliers individuais, ganha em elegância.
Sugiro fazer o enxame e guardar a crista como alternativa se ficar denso demais no A4.
*Dado:* `eixo1/orcamento/data/processed/municipal/municipal_final.csv` cruzado com
`data-vis/.cache/rcl-municipal/*.csv` — **precisa de script**, mas é o mesmo join que
`build_participacao_rcl.py` já faz para os estados.

---

#### F11 · Quem concentra o gasto cultural
**Tipo novo: curva de concentração (Lorenz).**

Uma curva grossa só, com marcadores nos decis: "os 10% que mais gastam concentram
X% do gasto cultural municipal do país". Diagonal pontilhada como referência da
igualdade perfeita.

*Por que:* nenhuma figura da publicação fala de desigualdade territorial de recurso,
e ela é o subtexto do capítulo inteiro. É também a curva mais literal possível —
casa perfeitamente com a linguagem.
*Dado:* `municipal_final.csv` — **precisa de script** (curto).

---

### Capítulo 2 — participação social (hoje, zero figuras)

---

#### F14 · Quem esteve na 4ª Conferência Nacional
**Tipo novo: matriz de pontos (dot matrix), em pequenos múltiplos.**

1.201 bolinhas — uma por delegado — repetidas em quatro painéis, cada painel
recolorindo o mesmo enxame por um recorte: sociedade civil × poder público (67%/33%),
raça, gênero, pessoa com deficiência (6,2%). A posição de cada ponto não muda entre
painéis, só a cor.

*Por que:* abre a categoria "contagem literal", que o sistema não tem. E resolve o
problema real da p. 15: cinco tabelinhas empilhadas que ninguém lê. Os 6,2% de PcD
como 75 bolinhas destacadas dizem mais que "6,24%".
*Dado:* tabela de perfil da p. 15 — **transcrever**, são 20 números, e todos os
recortes fecham em 1.201. Não depende da tabela por UF das pp. 17–18.
*Cor:* categórica da marca, no máximo 5 categorias por painel — o recorte de gênero
tem 7, então agrupar em "homem cis / mulher cis / demais" com o detalhamento na nota.

---

#### F15 · Os agentes territoriais no território
**Tipo novo: cartograma de círculos (Dorling).**

Um círculo por UF, área proporcional ao número de agentes territoriais (596 no total),
empurrados até não se sobreporem mas mantendo a geografia aproximada.

*Por que:* o texto pede o mapa explicitamente. E o hexmap que já temos não serve: ele
lê percentual (barra contra referência), não contagem. O Dorling lê contagem, e é o
par curvo do hexmap — mesma leitura territorial, gramática oposta.
*Dado:* tabela da p. 13 (agentes por UF) — **transcrever**, 27 linhas, fecha em 596.
*Depois:* as 66 OSCs (23 celebrantes + 43 parceiras) entram como segunda marca sobre
o mesmo círculo, quando vier a quebra por UF — que **não está no PDF** e precisa da
Secretaria dos Comitês. A figura fica de pé só com os agentes, então não espera por
isso.

---

### Gestão pública municipal (hoje, uma figura)

---

#### F17 · Escolaridade do gestor × institucionalização
**Tipo novo: matriz de bolhas.**

Quatro linhas (fundamental, médio, superior, pós) × quatro colunas (nenhum
instrumento, um, dois, tripé completo). Área da bolha = número de municípios,
cor = rampa vermelha pela proporção da linha.

*Por que:* é literalmente o pedido do Pedro no PDF (p. 21) — *"Esse dado é MUITO BOM.
Mas o gráfico não deixa clara a relação direta entre as duas variáveis. Precisa de
outro tipo de visualização, incorporando as outras situações de institucionalização
(ex.: municípios que não tem o tripé)"*. O gráfico atual é uma barra com quatro
percentuais soltos; a matriz mostra a relação e o peso de cada célula ao mesmo tempo.
*Dado:* `eixo1/gestao&participacao/data/processed/munic_painel_historico.csv`
(`gestor_escolaridade_agrupada` + `tem_plano`/`tem_conselho`/`tem_fundo`, ano 2021) —
**pronto, precisa de script curto.**

---

#### F18 · Com quem a cultura divide a secretaria — **não foi feita: o dado não sustenta**

A figura seria um diagrama de arcos ligando a cultura às pastas com que divide
estrutura. Ao abrir o painel para construí-la, a resposta apareceu — e ela é que
**a MUNIC não sabe com quem a cultura divide a secretaria na maioria dos casos.**

| ano | secretarias compartilhadas | com pasta parceira identificada |
|---|---|---|
| 2018 | 3.665 | 289 (7,9%) |
| 2021 | 4.012 | 432 (10,8%) |

Em 2021, 4.012 dos 5.570 municípios têm a cultura numa secretaria compartilhada,
e alguma das três pastas que o questionário identifica aparece em apenas 432
deles. Nos outros 3.580 o parceiro não é nomeado.

Um arco desenhado sobre esses 432 descreveria um décimo dos casos com a aparência
de descrever todos. A pergunta do Pedro na p. 20 — *"A cultura compartilha a
estrutura com quais pastas?"* — tem resposta, só que ela é "os dados da MUNIC não
dizem, em 89% dos casos", e essa é uma frase do texto, não uma figura.

O que os 432 casos identificados dizem, se ainda assim for útil: quando há
parceiro nomeado é quase sempre o esporte (339 dos 432 o envolvem), seguido de
educação (163) e turismo (146).

Duas saídas, se a figura for mesmo necessária:

- **Assumir o buraco como o assunto** — uma figura cujo elemento dominante são os
  89% sem identificação, com os 432 abertos ao lado. Honesta, mas é uma figura
  sobre o limite do dado, não sobre a gestão cultural.
- **Ir aos microdados brutos da MUNIC**, se o questionário original trouxer a
  pasta parceira em campo aberto. O painel consolidado do repositório não traz.

---

### Resumo — o que ficou construído

Seis das sete estão no repositório, exportando a 347 dpi pelo `npm run export:png`.

| # | Figura | Tipo novo | Componente | Estado |
|---|---|---|---|---|
| F9 | Crescimento municipal | cascata arredondada | `CascataChart` + `CrescimentoMunicipalChart` | ✅ |
| F10 | Distribuição por região | cristas de densidade | `CristasChart` + `DistribuicaoRclChart` | ✅ |
| F11 | Concentração do gasto | curva de Lorenz | `ConcentracaoChart` + `ConcentracaoGastoChart` | ✅ |
| F14 | Perfil da 4ª CNC | matriz de pontos | `MatrizPontosChart` + `PerfilCncChart` | ✅ |
| F15 | Agentes territoriais | cartograma Dorling | `CartogramaUfChart` + `AgentesTerritoriaisChart` | ✅ |
| F17 | Escolaridade × tripé | matriz de bolhas | `MatrizBolhasChart` + `EscolaridadeInstitucionalizacaoChart` | ✅ |
| F18 | Secretarias compartilhadas | arcos | — | ⛔ dado não sustenta |

Cada motor é genérico e cada embrulho é específico, como os que já existiam. A
malha hexagonal saiu de dentro da `HexMapaUfChart` para `mapaUf.ts`, porque agora
duas figuras territoriais dividem a mesma geografia.

Com as seis, a distribuição de formas fica: 5 linhas, 2 hexmaps, 1 histomap, 3 de
círculo/contagem, 1 de matriz/relação, 2 de curva analítica, 1 de decomposição.
Nenhum tipo com mais de cinco figuras, e a categoria de linha deixa de ser maioria.

### Scripts de dados novos

| script | saída |
|---|---|
| `build_escolaridade_institucionalizacao.py` | `escolaridade-institucionalizacao.json` |
| `build_agentes_territoriais.py` | `agentes-territoriais.json` |
| `build_perfil_cnc.py` | `perfil-cnc.json` |
| `build_distribuicao_municipal.py` | `distribuicao-rcl-regiao.json`, `concentracao-gasto-municipal.json` |

Os três primeiros conferem os totais publicados por asserção e param se a
transcrição não fechar. O quarto confere o join município × RCL contra
`meta-rcl-municipios.json`, que já passou pelos indicadores publicados: um join
que perde municípios em silêncio ainda produz curvas plausíveis.

---

## 4. Regras de forma, para as sete continuarem a mesma publicação

O que faz os prints serem uma família não é a paleta — é o traço. Para os tipos novos:

1. **Ponta arredondada em tudo.** `stroke-linecap="round"`, `stroke-linejoin="round"`.
   Um bloco de cascata é um retângulo com raio igual a metade da altura.
2. **Conector é sempre Bézier cúbica, nunca cotovelo.** Vale para a cascata (F9) e
   para os arcos (F18). Se aparecer um ângulo reto no meio de um dado, a figura saiu
   da família.
3. **O círculo é a marca padrão de contagem.** F14, F15 e F17 usam o mesmo vocabulário
   de bolha; quem ler as três deve sentir que são o mesmo instrumento apontado para
   coisas diferentes.
4. **Sem caixa, sem grade horizontal.** A grade é linha vertical clara atrás do dado,
   como nos prints. Eixo vertical fechado só onde a leitura exigir escala (F10).
5. **Rótulo direto, nunca legenda solta.** Vale inclusive para as bolhas do Dorling:
   sigla dentro do círculo quando couber, na ponta de um fio curto quando não.
6. **`QUEBRA`** quando a base muda — a mesma convenção do print 1. Vai fazer falta em
   F10, onde a base declarante de 2025 é menor.
7. **Paleta:** `cores.ts` como está. Máximo cinco séries por painel — acima disso,
   pequenos múltiplos. Rosa continua sendo emendas e renúncia. Verde só no degrau
   escuro quando estiver ao lado de vermelho.
8. **A4:** largura intrínseca 580, altura auto, `a4Scale` no tipo e em toda medida
   fixa. Vale para os tipos novos exatamente como para os antigos.

---

## 5. O que mudou nos achados ao construir

Duas figuras responderam diferente do que a proposta previa. Vale o registro,
porque as duas mexem no texto e não só na figura.

**F17 desfaz a leitura anterior em vez de confirmá-la.** O gráfico exploratório
media só o topo da escada — municípios com o tripé completo — e ali a
escolaridade parece decisiva: 3,8% no ensino fundamental contra 12,0% na
pós-graduação. Com as quatro situações à vista, a coluna do "nenhum dos três"
fica praticamente parada em torno de 42% nas três escolaridades mais altas.
**Mesmo entre gestores pós-graduados, quatro em cada dez municípios não têm
nenhum dos três instrumentos.** A escolaridade mexe em quem chega ao topo, não em
quem sai do zero — é uma conclusão mais fraca que a anterior, e é a que o dado
sustenta.

**F9 mostra que o crescimento municipal é sobretudo dinheiro local.** Dos R$ 9,0
bilhões a mais que os municípios investiram em 2024 contra 2019, **83% saíram do
orçamento próprio**. Os repasses federais somaram R$ 1,55 bi no ano. Isso não
diminui a política federal — combina com o achado de "efeito indutor" do
`comportamento-municipal.json` —, mas contraria a leitura de que os repasses
explicam o salto, e o capítulo hoje sugere essa leitura.

Duas ressalvas metodológicas que entraram nas notas de rodapé e valem para o
texto:

- **A ponte da F9 termina em 2024, não em 2025.** 2025 sai de uma base declarante
  de 4.788 municípios contra 5.191 — uma figura de percentual absorve isso no
  denominador, uma de volume não.
- **A LAB 1 quase não aparece na F9** porque a cascata compara dois anos e ela
  correu em 2020 e 2021, com R$ 1,2 bi e R$ 0,5 bi. Quem procurar a lei na figura
  precisa achar a explicação, e ela está na nota.

---

## 6. Fora do escopo, por enquanto

Três figuras saíram, e com elas a categoria de **fluxo** inteira (ver seção 2).
Registradas aqui com o que teriam sido e o que trava cada uma:

- **F12 · Indução × substituição** — aluvial de fitas curvas, porte populacional →
  perfil comportamental (Despertados / Constantes / Inertes / Substituição). O dado
  está pronto em `src/data/comportamento-municipal.json`, e o mesmo dado já teve
  figura (`CaboGuerraChart`), removida.
- **F13 · Funil territorial das conferências** — fluxo em fitas: 5.570 municípios →
  os que realizaram conferência municipal → os que chegaram à etapa estadual → os
  1.201 delegados. Depende da tabela por UF das pp. 17–18, que tem **"não informado"
  em MA, PA e SP** e uma Bahia com mais municípios na etapa estadual (400) do que
  realizaram conferência (378). Um funil não fecha com isso.
- **F16 · Ações de mobilização por grupo populacional** — bolhas empacotadas, 1.573
  ações em sete grupos. Trava numa inconsistência do texto: a p. 12 afirma **1.573
  ações e 119 mil pessoas**, e a tabela logo abaixo fecha em **1.124 ações e 71.245
  participantes** (só os 374 municípios batem). A tabela por grupo populacional fecha
  em 1.573. Provavelmente são recortes de período diferentes — se a figura voltar, é
  isso que precisa ser resolvido primeiro, senão ela contradiz o parágrafo que a
  apresenta.
