---
title: "Diagnóstico de Revisão — Eixo 1 / Orçamento"
data_da_revisao: "2026-08-21"
branch_revisada: "main"
escopo: "eixo1/orcamento (gestão&participação não foi revisada, por solicitação)"
---

# Diagnóstico de Revisão — Pipeline de Orçamento (Eixo 1)

Revisão de código e documentação de `eixo1/orcamento/`, com teste funcional real dos 4 scripts R, executado sobre uma **cópia local temporária** do repositório (clone local em `C:\tmp_orc_test`, sem qualquer alteração no repositório original). Ambiente: R 4.6.1, Windows, pacotes já instalados no sistema (hidratados via `renv::hydrate()`).

Não existem testes automatizados (`testthat` ou equivalente) no repositório — a única forma de "rodar os testes" é executar os próprios scripts de produção, o que foi feito de ponta a ponta.

---

## 1. Resumo — Pontos Impeditivos e Sugestões

| # | Ponto crítico | Impacto | Sugestão |
|---|---|---|---|
| 1 | **Dado obrigatório da esfera estadual só existe comprimido**: `data/raw/estadual/msc_orcamentaria_estados_2019_2025_final.7z`, mas o script espera o `.parquet` já extraído. Não há ferramenta de descompactação 7z disponível no ambiente de execução (nem `7z.exe`, nem o pacote R `archive`). | `scripts/estadual/gasto_estadual.R` **não roda do zero** neste repositório clonado — interrompe com `stop()` no primeiro input. | (a) Versionar/disponibilizar o `.parquet` já extraído (ou via link externo, como já é feito para os municipais), **ou** (b) ajustar o script para descompactar o `.7z` em tempo de execução (ex.: pacote `archive::archive_extract()`), documentando a dependência. |
| 2 | **Dados obrigatórios da esfera municipal ausentes**: falta `MUNIC_FINAL.xlsx`, falta a subpasta `LAB1 - MUNIC/cubo_execucao_lab1_municipios_*.xlsx`, e os `.parquet` do SICONFI só existem como `.rar` por ano (`2018 - Municipal.rar` etc.). | `scripts/municipal/gasto_municipal.R` **não roda do zero** — interrompe com `stop()` no primeiro input ausente. | Disponibilizar os 3 conjuntos de arquivos faltantes (mesmo esquema já usado no `LEIA-ME` para os parquets — link de SharePoint/Drive), atualizando o `LEIA-ME` da pasta `data/raw/municipal/` para cobrir também `MUNIC_FINAL.xlsx` e o cubo LAB1. |
| 3 | **Chamadas de rede em tempo de execução sem cache nem tratamento de falha**: `rbcb::get_series(433, ...)` (IPCA/BCB) em `gasto_federal.R`, `gasto_estadual.R` e `gasto_municipal.R`; `jsonlite::fromJSON("https://servicodados.ibge.gov.br/...")` em `gasto_municipal.R`. | Nesta revisão as APIs responderam normalmente, mas se o BCB/IBGE estiverem fora do ar, mudarem de schema, ou o ambiente não tiver acesso à internet, o pipeline falha sem mensagem clara e sem fallback (não há cache local do IPCA nem do dicionário de municípios). | Cachear localmente o resultado dessas chamadas (`.csv` versionado, atualizado por um script separado) e envolver as chamadas em `tryCatch` com mensagem de erro explícita. Não é bloqueante hoje, mas é um ponto único de falha externo ao controle do projeto. |
| 4 | **`renv::restore()` (o passo 2 da documentação) não foi validado do zero** — o teste desta revisão usou `renv::hydrate()`, que reaproveita pacotes já instalados na máquina, não um `restore()` real que baixa/compila tudo do lockfile. O projeto depende de pacotes com dependências de sistema pesadas (`sf`, `terra`, `arrow`, `geobr`, `gt`), que podem exigir bibliotecas nativas (GDAL/GEOS/PROJ) e tempo de compilação relevantes em uma máquina "limpa". | Risco de reprodutibilidade: alguém clonando o repo pela primeira vez pode travar no passo 2, sem que isso apareça em uma revisão que reutiliza pacotes já instalados. | Registrar essa limitação, ou (idealmente) validar `renv::restore()` uma vez em um ambiente realmente limpo (container Docker `rocker/geospatial`, por exemplo) e documentar pré-requisitos de sistema (GDAL/GEOS/PROJ) no `.md`. |

Não há nada bloqueante no **código** em si (fora os itens acima): os quatro scripts estão sintaticamente corretos, os caminhos relativos via `{here}` funcionam (o `.Rproj` já está na raiz de `orcamento/`, corrigido em revisão anterior), e o `renv.lock` existe e é válido. O que impede a execução completa **hoje** é exclusivamente a ausência de parte dos dados brutos de entrada (itens 1 e 2).

---

## 2. Resultado do Teste de Execução

**Ambiente:** clone local (`git clone --local`) da íntegra do repositório para `C:\tmp_orc_test\repo`, fora do diretório do projeto original — nenhuma alteração foi feita no repositório real. R 4.6.1, pacotes hidratados via `renv::hydrate()` (154 pacotes, 0 downloads, reaproveitando a biblioteca já instalada na máquina).

### Veredito por etapa

| Script | Veredito | Observação |
|---|---|---|
| `scripts/federal/gasto_federal.R` | ✅ **Passou** | Rodou de ponta a ponta sem erros (apenas *warnings* esperados de parsing de planilha). Gerou os 10 gráficos e `federal_final.csv` com conteúdo **idêntico** ao já versionado no repositório (única diferença: terminador de linha LF vs. CRLF, sem relevância). |
| `scripts/estadual/gasto_estadual.R` | ❌ **Falhou** | `Erro: ERRO: O arquivo 'msc_orcamentaria_estados_2019_2025_final.parquet' não foi encontrado em data/raw/estadual/.` — arquivo só existe como `.7z`. Ver item 1. |
| `scripts/municipal/gasto_municipal.R` | ❌ **Falhou** | `Erro: ERRO: O arquivo 'MUNIC_FINAL.xlsx' não foi encontrado em data/raw/municipal/.` — arquivo ausente. Ver item 2. |
| `scripts/nacional/nacional.R` | ✅ **Passou** | Diferente de revisões anteriores, o script voltou a existir na `main` e **rodou sem erros**, consumindo as bases `federal_final.csv` (recém-gerada), `estadual_final.csv` e `municipal_final.csv` (as versões já processadas e versionadas, já que os scripts de origem falharam por falta de dado bruto). Gerou `tres_esferas_consolidado.csv`, `grafico_composicao_esferas.png` e `grafico_financiamento_esferas.png` corretamente. |

**Veredito consolidado, do zero: passou com ajustes parciais.** Federal e Nacional rodam sem qualquer intervenção. Estadual e Municipal são bloqueados unicamente por dados brutos ausentes/comprimidos em formato não lido pelo script — não foi possível corrigir isso na cópia local porque não há ferramenta de extração `.7z`/`.rar` disponível no ambiente de teste, e a extração de dados de terceiros está fora do escopo de uma "correção simples" (não é um bug de código, é ausência/formato do dado de entrada).

Nenhuma correção de código foi necessária ou aplicada nesta rodada — a estrutura (`.Rproj` na raiz, `renv.lock`) já estava correta de uma revisão anterior.

---

## 3. Checklist de Itens Imprescindíveis para Execução

- [ ] Repositório é executável (roda sem erros críticos, mesmo que com ajustes simples) — *federal e nacional passam; estadual e municipal falham por dados brutos ausentes/comprimidos (itens 1 e 2)*
- [x] Documentação explica a estrutura do código
- [x] Documentação explica como executar o código (sequência dos scripts)
- [x] Cada script documenta input/output esperado — *cabeçalho de cada `.R` + seção 2 do `Projeto_Cultura_Orcamento_v1.md`*
- [x] Existe tutorial de como rodar na máquina de quem clonar — *seção 1 do `.md`*
- [x] Existe arquivo `.xlsx` com a ficha de metadados do projeto — *`eixo1/Ficha de Metadados - Eixo 1.xlsx` (um nível acima de `orcamento/`, compartilhada com o outro eixo)*
- [x] Existe arquivo de dependências adequado à linguagem (`renv.lock`) — *presente e funcional via `hydrate()`; `restore()` genuíno em máquina limpa não foi validado (item 4)*
- [ ] Ausência de erros críticos que impeçam a execução — *bloqueado pelos dados brutos ausentes de estadual/municipal (itens 1 e 2)*
