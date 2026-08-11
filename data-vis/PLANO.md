# Plano de ação — gráficos do Eixo 1 na lib SNIIC

Levantamento de `eixo1/orcamento/data/` + `eixo1/gestao&participacao/data/`, cruzado com o
que o analista já produziu em `outputs/` e com o que já está implementado em `data-vis/`.

---

## 1. Situação atual

### Já implementado em `data-vis/src/lib/`

| Componente | Equivale a | Dados |
|---|---|---|
| `MunicipalPorFonteChart` / `RibbonChart` | orçamento gráficos 1, 2 e 3 | `src/data/municipal-por-fonte.json` |
| `EstadualPorFonteChart` | (sem equivalente do analista) | `src/data/estadual-por-fonte.json` |
| `EvolucaoFederalChart` | (sem equivalente do analista) | `src/data/federal-por-fonte.json` |
| `FederalFontesTable` | tabela federal | `src/data/federal-por-fonte.json` |
| `CaboGuerraChart` | — | `src/data/comportamento-municipal.json` |
| `PerfilMudancaMunicipalChart`, `PerfilPorPorteChart`, `EfeitoIndutorMunicipalChart` | — | idem |

Pipeline já pronto: `scripts/build_*.py` → `src/data/*.json` → componente Svelte →
`npm run export:png` (A4, 4×/8×).

### Dados disponíveis e ainda não usados

| Arquivo | Conteúdo | Estado |
|---|---|---|
| `orcamento/.../municipal/df_municipios_final.xlsx` | 56.986 linhas: exercício × município × origem, com `regiao_munic`, `porte_populacional`, `populacao`, valores nominal e real | usado só agregado por ano/fonte — **recortes territoriais inexplorados** |
| `orcamento/.../municipal/Grafico_Dispersao_Dados.csv` | 4.448 municípios: gasto 2020 vs média pós-LAB, com perfil e porte | **não usado** |
| `orcamento/.../municipal/MUNIC_FINAL.xlsx` | 5.570 municípios: PIB 2021, PIB per capita, quartil, porte, região | **não usado** (chave de cruzamento) |
| `orcamento/.../estadual/df_estados_final.xlsx` | 332 linhas: exercício × UF × origem | usado só agregado — **ranking por UF inexplorado** |
| `orcamento/.../estadual/PauloGustavo - Estados.csv` | 27 UFs: total recebido vs utilizado (LPG) | **não usado** |
| `orcamento/.../federal/RCL_2011_2025_Uniao_Resumido.xlsx` | RCL da União 2011–2025 | **não usado** |
| `orcamento/raw/federal/salic_minc.xlsx` | 1993–2026: captado, teto, renunciado (Rouanet) | **não usado** |
| `orcamento/raw/federal/funcoes_orgaos_unidades_rp_*.xlsx` | 48.965 linhas, 2003–2026: função × órgão × UO × RP, com dotação/empenhado/liquidado/pago | **não usado** |
| `orcamento/raw/municipal/RCL_*_Municipios.rar` | RCL municipal 2018–2025 (~330 MB/ano descompactado) | **não usado** — necessário para a meta do PNC |
| `gestao&participacao/.../munic_cultura_painel_historico_06_21.csv` | painel MUNIC 2006/2014/2018/2021, 22.274 linhas × 19 variáveis | **não usado** — base dos 5 gráficos + 2 tabelas de gestão |

---

## 2. Catálogo de gráficos a construir

### Bloco A — Gestão & Participação — **Fase 1 concluída** (A1–A5 e A8)

Tudo sai do painel MUNIC único. É o bloco de melhor retorno: uma fonte, um script de build,
sete visualizações.

| # | Gráfico | Componente | Estado |
|---|---|---|---|
| A1 | Tripé institucional 2006–2021 (Plano/Fundo/Conselho, % municípios) | `TripeInstitucionalChart` | ✅ feito |
| A2 | Estrutura do órgão gestor por onda (100% empilhado) | `EstruturaOrgaoGestorChart` | ✅ feito |
| A3 | Gênero dos titulares (100% empilhado) | `GeneroTitularesChart` | ✅ feito |
| A4 | Escolaridade do gestor × tripé completo | `EscolaridadeTripeChart` | ✅ feito |
| A5 | Efeito Aldir Blanc: faixas de execução do repasse | `ExecucaoAldirBlancChart` | ✅ feito |
| A8 | **Novo** — equipamentos culturais (biblioteca/museu/teatro/cinema) | `EquipamentosCulturaisChart` | ✅ feito |
| A6 | Execução da LAB por região (tabela-mapa de calor) | `HeatMap` ou `DataTable` | falta — exige o cruzamento com MUNIC_FINAL |
| A7 | Tripé por região (tabela-mapa de calor) | `HeatMap` ou `DataTable` | falta — idem |
| A9 | **Novo** — perfil de cor/raça dos gestores | `ComposicaoPorOndaChart` | dados já em `gestao-municipal.json`, falta o wrapper |

**Cuidados de dados — todos já tratados em `scripts/build_gestao_data.py`:**
- `tipo_orgao_gestor` tem **17 rótulos** para ~5 categorias reais, com grafias diferentes por
  onda (`"Setor subordinado diretamente à chefia do Executivo"` vs `"… do executivo"` vs
  `"…  à chefia"` com espaço duplo). Precisa de tabela de-para explícita.
- `gestor_sexo` tem `-`, `(**)Sem gestor`, `(**) Sem gestor`, `Não informado`, `Não informou`,
  `Recusa` → tratar como não-resposta, não como categoria.
- 2006 não tem dados de gestor (5.564 nulos) — A3/A9 começam em 2014.
- 2006 tem 5.564 municípios; 2014+ têm 5.570 — usar percentuais, nunca contagens comparadas.
- `orcamento_perc_executado` só existe em 2021 e é **categórico** (faixas), não numérico.
- A coluna `gestor_escolaridade_agrupada` do painel **está furada** e não foi usada: em 2021
  ela joga os 105 municípios de ensino fundamental dentro da faixa "Ensino Médio a
  Pós-graduação lato sensu" e deixa a categoria zerada, enquanto a coluna bruta mostra 55
  completos e 50 incompletos. O agrupamento foi refeito de `gestor_escolaridade`, e assim
  reproduz exatamente os números publicados (15,2 / 10,3 / 3,8).
- **Divergência conhecida com o gráfico 4 do analista.** O agrupamento dele não é consistente
  entre ondas: em 2006 "Fundação pública" entra em "Secretaria Exclusiva / Fundação"
  (7% = 236 + 145), mas em 2014+ o equivalente "Órgão da administração indireta" fica de fora
  (19,3% = só exclusiva); e o denominador de 2021 exclui "Não possui estrutura" enquanto o de
  2006 não. Reproduzir isso propagaria a inconsistência, então `EstruturaOrgaoGestorChart` usa
  uma regra única para as quatro ondas — 5 categorias, denominador = respostas válidas — e os
  percentuais diferem em 1–2 p.p. dos publicados. **Vale confirmar com o analista** qual das
  duas versões vai para o relatório.

### Bloco B — Orçamento: completar o que o analista já fez

| # | Gráfico | Componente DS | Dado | Esforço |
|---|---|---|---|---|
| B1 | Tabela: total municipal por fonte 2019–2025 (acumulado + %) | `DataTable` | `municipal-por-fonte.json` (já existe) | baixo |
| B2 | Cumprimento da meta do PNC (≥2% da RCL) por região, 2019–2024 | `LineChart` | despesa municipal ÷ **RCL municipal** | **alto** (ver §3) |

### Bloco C — Orçamento: gráficos novos, dados já na mão

| # | Gráfico | Componente DS | Dado |
|---|---|---|---|
| C1 | Consolidado federativo: União × Estados × Municípios (empilhado + 100%) | `RibbonChart` (reuso) | os três JSON já gerados; lógica em `despesa_cultura_final.R` |
| C2 | Gasto federal direto como % da RCL da União, 2011–2025 | `LineChart` | `RCL_2011_2025_Uniao_Resumido.xlsx` + `federal_final.csv` |
| C3 | Renúncia fiscal Rouanet: captado × teto × renunciado, 1993–2026 | `LineChart` / `AreaPath` | `salic_minc.xlsx` |
| C4 | Função 13-Cultura: dotação × empenhado × pago e taxa de execução | `GroupedColumnChart` + linha | `funcoes_orgaos_unidades_rp_*.xlsx` |
| C5 | Investimento municipal por região e por porte populacional | `RibbonChart` / `HorizontalStackedBarChart` | `df_municipios_final.xlsx` (recortes já na base) |
| C6 | Investimento cultural per capita por região/porte | `HorizontalBarChart` | idem + `populacao` |
| C7 | Dispersão pré-LAB × pós-LAB por município | `BubbleChart` / `ContourPlot` | `Grafico_Dispersao_Dados.csv` |
| C8 | Ranking estadual: investimento próprio per capita por UF | `HorizontalBarChart` + `StateFlag` | `df_estados_final.xlsx` |
| C9 | LPG estadual: recebido × utilizado por UF | `DivergingBarChart` / `SlopeGraph` | `PauloGustavo - Estados.csv` |
| C10 | Investimento cultural × PIB per capita (quartis) | `BubbleChart` | `MUNIC_FINAL.xlsx` + `df_municipios_final.xlsx` |

### Bloco D — Mapas (bloqueado, ver §3)

| # | Mapa | Situação |
|---|---|---|
| D1 | Tripé institucional no território (2021) | precisa de malha municipal |
| D2 | Estrutura do órgão gestor no território | precisa de malha municipal |
| D3 | **Alternativa viável agora** — versão estadual dos mesmos indicadores | `ChoroplethMap` + `geo/brazil-states.geojson` (já no pacote) |

---

## 3. Lacunas e bloqueios

1. **RCL municipal (B2).** Os arquivos existem em `.rar` mas descompactam para ~330 MB/ano
   × 8 anos ≈ 2,6 GB. `7z` e `unar` estão instalados, então é factível, mas exige:
   extração fora do repo → filtro das contas de RCL → agregação por município/ano → join com
   a despesa cultural própria → cálculo do % ≥ 2%. Não há script R no repo reproduzindo isso;
   a lógica terá de ser escrita do zero. **Confirmar a definição exata de RCL usada pelo
   analista** (RCL total vs RCL ajustada, `<MR-11>` vs exercício fechado).
2. **Malha municipal (D1, D2).** A lib traz só `geo/brazil-states.geojson` e as UFs
   individuais. Municípios exigiriam baixar a malha do IBGE (~50 MB simplificada) e decidir
   onde versioná-la. Opções: (a) adicionar a malha ao repo `data-vis/public/`; (b) propor a
   inclusão na `sniic-design-system`; (c) entregar a versão estadual (D3) primeiro.
3. **Agrupamentos do analista.** Vários gráficos usam agrupamentos não documentados
   (categorias de órgão gestor, recorte institucional do MinC por fase). Reproduzi-los ao pé
   da letra exige confirmação; caso contrário os números divergem em 1–2 p.p.
4. **`estadual/*.csv` por ano em latin-1 com separador `;`** — não são fonte primária dos
   gráficos (o `df_estados_final.xlsx` já é o processado), mas se forem necessários, o
   encoding precisa ser tratado.

---

## 4. Execução sugerida

**Fase 1 — Gestão & Participação (A1–A5, A8). ✅ Concluída.** `scripts/build_gestao_data.py` lê
o painel MUNIC com o de-para de rótulos explícito e gera `src/data/gestao-municipal.json`; três
componentes genéricos (`SerieHistoricaChart`, `ComposicaoPorOndaChart`,
`BarrasHorizontaisChart`) servem os seis wrappers. Prova de impressão em `/gestao.html`,
exports em `exports/a4-*.png` via `npm run export:png`.

**Fase 2 — orçamento com dado pronto (B1, C1, C2, C3, C4).** Fecha a paridade com os outputs
do analista e aproveita o `RibbonChart` já existente para o consolidado federativo (C1), que
é o gráfico-síntese do eixo e ainda não existe em lugar nenhum.

**Fase 3 — recortes territoriais (C5, C6, C8, C9, C10, A6, A7).** Exige juntar
`df_municipios_final` + `MUNIC_FINAL` numa base analítica única; depois disso, cada gráfico é
barato.

**Fase 4 — bloqueados (B2, C7, D1–D3).** Começar por D3 (mapa estadual, já viável) e C7
(dispersão, dado pronto mas escolha de componente em aberto); B2 e os mapas municipais
dependem das decisões do §3.

**Convenções a manter em todas as fases** (já valem no repo): compor primitivas do core com
`getPillarTheme(1)`/`resolveThemeStyle`, estilo todo dentro do SVG, largura intrínseca de 580
para A4, `colors` explícito com `categorical5`/`categorical8` quando houver 4+ séries, e um
script `build_*.py` versionado por conjunto de dados.
