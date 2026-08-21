---
title: "Diagnóstico de Revisão — Eixo 1 / Orçamento"
data_da_revisao: "2026-08-21"
branch_revisada: "main"
---

# Diagnóstico de Revisão — Pipeline de Orçamento (Eixo 1)

Revisão de código e documentação da pasta `eixo1/orcamento/`, com teste funcional real dos scripts R, executado sobre **cópias locais temporárias** do repositório (o repositório remoto não foi alterado). Duas correções foram aplicadas diretamente neste repositório, a pedido: a criação do `renv.lock` e o reposicionamento do `.Rproj` (ver seção 1, item 1 e seção 2).

> **Nota sobre o estado do repositório no momento desta revisão:** durante a sessão de revisão, a branch `main` teve o script `scripts/nacional/nacional.R` e o gráfico `outputs/nacional/grafico_composicao_esferas.png` removidos (o `data/processed/nacional/tres_esferas_consolidado.csv` e o `outputs/nacional/grafico_financiamento_esferas.png` permaneceram). Este diagnóstico reflete o estado atual da `main` — **sem** a etapa de consolidação nacional.

---

## 1. Resumo — Pontos Impeditivos e Sugestões de Correção

| # | Ponto crítico | Impacto | Sugestão / Ação |
|---|---|---|---|
| 1 | **`.Rproj` estava em `scripts/orcamento_cultura.Rproj`, não na raiz de `orcamento/`** | Ao seguir o passo 1 da documentação ("dê duplo clique no `.Rproj`"), o RStudio abriria com working directory em `scripts/`. O pacote `{here}` fixaria a raiz do projeto em `scripts/`, e **todos** os caminhos `here("data", "raw", ...)` apontariam para `scripts/data/raw/...`, que não existe. Confirmado experimentalmente. | ✅ **Corrigido nesta revisão**: o arquivo foi movido para `eixo1/orcamento/orcamento_cultura.Rproj`. Testado após a correção: `here()` agora resolve para a raiz de `orcamento/` corretamente. |
| 2 | **Não existia `renv.lock`** (nem `DESCRIPTION`, `Pipfile` etc.), apesar de a documentação e o cabeçalho de cada script instruírem `renv::restore()`. | Quem clonasse o repositório não tinha como reproduzir as versões de pacotes usadas no desenvolvimento. | ✅ **Corrigido nesta revisão**: gerado `renv.lock` (via `renv::snapshot()`, varrendo os `library()`/`require()` dos 3 scripts ativos e capturando as versões efetivamente usadas), junto com `.Rprofile` e `renv/activate.R` para ativação automática. Ver seção 2 para os detalhes de validação. |
| 3 | **Dados brutos obrigatórios ausentes do repositório**: `data/raw/estadual/msc_orcamentaria_estados_2019_2025_final.parquet` (só existe um `.7z` com nome parecido); `data/raw/municipal/*.parquet`, `data/raw/municipal/MUNIC_FINAL.xlsx` e `data/raw/municipal/LAB1 - MUNIC/cubo_execucao_lab1_municipios_*.xlsx` (nenhum presente). | Os scripts `gasto_estadual.R` e `gasto_municipal.R` **não conseguem rodar do zero** neste repositório clonado; ambos interrompem com `stop()` no primeiro input ausente — comportamento confirmado mesmo depois das correções dos itens 1 e 2. | Documentar explicitamente (como já é feito no `LEIA-ME` da pasta municipal para os parquets grandes) onde obter **cada** arquivo ausente, com link. Hoje só o link do SharePoint dos parquets municipais existe — falta o do MUNIC_FINAL, do cubo LAB1 e do parquet/csv estadual. |
| 4 | **A etapa de consolidação nacional foi removida, mas seus outputs continuam no repositório** | `scripts/nacional/` não existe mais na `main` (o `nacional.R` foi apagado), porém `data/processed/nacional/tres_esferas_consolidado.csv` e `outputs/nacional/grafico_financiamento_esferas.png` continuam versionados — dados/gráficos que hoje ninguém consegue regenerar nem rastrear à sua origem. A documentação (`Projeto_Cultura_Orcamento_v1.md`) ainda descreve essa etapa como "Passo 4" da esteira, citando inclusive um nome de arquivo diferente (`gasto_nacional_consolidado.R`, que nunca existiu — o arquivo real, quando existia, chamava-se `nacional.R`). | Decidir: (a) restaurar o script de consolidação nacional (ele funcionava — ver veredito na seção 2 de uma execução anterior desta mesma revisão, quando o arquivo ainda existia), ou (b) se a remoção foi intencional, remover também os artefatos órfãos e atualizar a documentação para não citar mais essa etapa. |
| 5 | **Incoerência de formato entre documentação e dados reais** | A documentação e os cabeçalhos dos scripts descrevem inputs em `.parquet`; os arquivos de fato entregues em `data/raw/estadual` e `data/raw/municipal` são `.7z`/`.rar`. Os scripts usam `list.files(pattern = "\\.parquet$")` e `pattern = "(?i)^RCL_.*\\.(csv|xlsx|xls)$")` — com os arquivos comprimidos, esses `list.files()` retornariam **zero resultados silenciosamente** (sem erro), gerando bases vazias/incompletas em vez de falhar de forma visível, caso o `stop()` anterior (item 3) não interrompesse antes. | Adicionar checagem explícita (`if (length(arquivos) == 0) stop(...)`) após cada `list.files()` que alimenta uma etapa crítica, e padronizar: ou os scripts leem os arquivos comprimidos diretamente, ou a documentação instrui a descompactar antes de rodar. |
| 6 | **Chamadas de rede em tempo de execução, sem tratamento de falha**: `rbcb::get_series(433, ...)` (BCB) nos scripts, e `jsonlite::fromJSON("https://servicodados.ibge.gov.br/...")` em `gasto_municipal.R`. | Se a API do BCB ou do IBGE estiver fora do ar, mudar de schema, ou o ambiente não tiver acesso à internet, o pipeline falha sem mensagem clara e sem fallback (não há cache local do IPCA nem do dicionário de municípios). | Cachear localmente o resultado dessas chamadas (ex.: salvar `fatores_ipca` e o dicionário do IBGE como `.csv` versionado, com um script separado de atualização), e envolver as chamadas em `tryCatch` com mensagem de erro clara. |
| 7 | **Nenhum arquivo `.xlsx` de ficha de metadados dentro de `orcamento/`** — existe um em `eixo1/Ficha de Metadados - Eixo 1.xlsx`, um nível acima, compartilhado com o outro eixo (`gestao&participacao`). | Não é, em si, impeditivo (o arquivo existe e cobre o eixo), mas não fica claro, sem abrir o arquivo, se ele cobre as variáveis específicas do orçamento (o `Projeto_Cultura_Orcamento_v1.md` já traz uma tabela de dicionário de dados equivalente, seção 3 do `.md`). | Deixar explícito no `.md` de orçamento que a ficha de metadados oficial está em `eixo1/Ficha de Metadados - Eixo 1.xlsx`, ou linkar a partir da documentação da pasta. |
| 8 | **Inconsistências menores entre comentário de cabeçalho e comportamento real do código** em `gasto_municipal.R`: o cabeçalho lista `outputs/municipal/grafico_sankey_interativo.html` como saída, mas nenhum gráfico Sankey é gerado no corpo do script; o script grava `efeito_comportamental_por_porte.csv` em minúsculas enquanto o arquivo já versionado no repositório está como `Efeito_Comportamental_Por_Porte.csv` (case-sensitive em Linux/Mac, não em Windows). | Sem impacto no Windows, mas pode gerar arquivo duplicado / quebra de convenção em CI Linux ou Mac. | Remover a linha do Sankey do cabeçalho (ou implementar o gráfico) e padronizar o nome do CSV. |
| 9 | **O repositório mudou de estado várias vezes durante esta revisão** (troca de branch, exclusão de arquivos) via GitHub Desktop, em paralelo à sessão de revisão. | Isso por si só não é um bug do pipeline, mas indica risco de processo: revisar um repositório enquanto ele está sendo editado em outro lugar pode produzir diagnósticos desatualizados quase imediatamente. | Recomendação de processo: finalizar e commitar edições antes de pedir uma nova revisão, para garantir que o diagnóstico corresponda ao estado que de fato vai para o PR/branch principal. |

---

## 2. Resultado do Teste de Execução

**Ambiente de teste:** cópias locais da pasta `orcamento/` (código + dados versionados, ~408 MB) em diretórios temporários fora do repositório; R 4.6.1, Windows. O repositório remoto/original não foi alterado pelos testes — apenas as duas correções descritas abaixo (`.Rproj` e `renv.lock`) foram aplicadas diretamente neste repositório, por terem sido solicitadas.

### Veredito por etapa (estado atual da `main`, já com as correções de estrutura aplicadas)

| Script | Veredito | Observação |
|---|---|---|
| `scripts/federal/gasto_federal.R` | ✅ **Passou** | Rodou de ponta a ponta, gerou os 10 gráficos e o `federal_final.csv`, com conteúdo idêntico ao já versionado em `data/processed/federal/`. Testado novamente após mover o `.Rproj` e ativar o `renv.lock` — sem regressões. |
| `scripts/estadual/gasto_estadual.R` | ❌ **Falhou** | Interrompido por dado de entrada ausente (arquivo só existe comprimido em `.7z`, não em `.parquet`). Mesmo erro antes e depois das correções de estrutura — confirma que a causa é ausência de dado, não os bugs de caminho/dependência já corrigidos. |
| `scripts/municipal/gasto_municipal.R` | ❌ **Falhou** | Falha por dado de entrada ausente (`MUNIC_FINAL.xlsx`). Diferente da rodada anterior desta revisão: com o `renv.lock` já ativo e a biblioteca do projeto "hidratada", os pacotes (`leaflet`, `writexl`, `plotly`, `ggrepel`) que antes precisavam ser instalados manualmente já estavam disponíveis — o script avançou direto para o próximo bloqueio real. |
| `scripts/nacional/*` | ⚠️ **Não aplicável** | O script foi removido da `main` durante esta sessão de revisão (ver nota no topo do documento). Não há o que testar; os artefatos processados anteriormente (`tres_esferas_consolidado.csv`, `grafico_financiamento_esferas.png`) continuam no repositório, órfãos. |

**Veredito consolidado do pipeline como um todo, do zero: falhou.** Das etapas que ainda existem no repositório, só a federal roda sem qualquer ajuste; estadual e municipal são bloqueadas por dados brutos ausentes; e a etapa de consolidação nacional não pode nem ser avaliada, pois o script não existe mais na `main`.

### Correção estrutural aplicada nº 1: `.Rproj` movido para a raiz do projeto

Reproduzi isoladamente o bug antes de corrigir: com o `.Rproj` em `scripts/`, abrir o projeto por ali (como a documentação instrui) faz `{here}` resolver a raiz errada:
```
here() starts at .../scripts
here() resolves to: .../scripts
```
Ação: `eixo1/orcamento/scripts/orcamento_cultura.Rproj` → `eixo1/orcamento/orcamento_cultura.Rproj`. Testado depois da correção, em cópia isolada com o `.Rproj` já na posição nova:
```
here() starts at .../orcamento_full_test
here() resolves to: .../orcamento_full_test
```
Confirmado correto.

### Correção estrutural aplicada nº 2: `renv.lock` criado e validado

1. Gerado com `renv::snapshot()` (tipo *implicit*: varre os `library()`/`require()` dos scripts e resolve as versões a partir da biblioteca de pacotes já instalada nesta máquina, que é a que roda o pipeline hoje). Resultado: **154 pacotes** capturados (dependências diretas + transitivas), com R **4.6.1** e repositório CRAN (`https://cloud.r-project.org`) registrados no lockfile.
2. Adicionados junto ao `renv.lock`: `.Rprofile` (ativa o `renv` automaticamente ao abrir o projeto) e `renv/activate.R` + `renv/settings.json` + `renv/.gitignore` (este último já ignora `library/`, `staging/` etc., para não versionar os pacotes binários).
3. **Validado de ponta a ponta** em cópia isolada:
   - `renv::hydrate()` populou a biblioteca privada do projeto a partir dos pacotes já instalados (sem precisar baixar nada da internet) — 154 pacotes "linkados" em ~10 segundos.
   - `renv::status()` reportou: `No issues found -- the project is in a consistent state.`
   - Os scripts `federal`/`estadual`/`municipal` foram re-executados nessa cópia com o `renv` já ativado — nenhuma mudança de comportamento além dos pacotes antes ausentes (`leaflet`, `writexl`, `plotly`, `ggrepel`) já estarem disponíveis via `renv::restore()`/`renv::hydrate()`, sem precisar de instalação manual.

   > Observação para quem for usar em outra máquina: como o lockfile foi gerado a partir dos pacotes já instalados aqui (e não baixado do zero do CRAN), quem clonar o repositório em outra máquina deve rodar `renv::restore()` — isso *vai* precisar baixar/compilar os pacotes listados (incluindo pacotes pesados com dependências de sistema, como `sf`, `terra`, `arrow`, `geobr`), o que não foi testado neste ambiente (o teste aqui usou `hydrate()`, que reaproveita pacotes já instalados localmente, e não substitui a validação de um `restore()` genuíno a partir do zero).

### Erros encontrados e não corrigidos (dados ausentes, fora do escopo de uma correção simples)

**`gasto_estadual.R`:**
```
here() starts at .../orcamento_full_test
Erro: ERRO: O arquivo 'msc_orcamentaria_estados_2019_2025_final.parquet' não foi
encontrado em data/raw/estadual/.
Execução interrompida
```
O arquivo existente na pasta é `msc_orcamentaria_estados_2019_2025_final.7z` (compressão 7z). Não há ferramenta de descompactação 7z disponível no ambiente de teste (nem `7z`, nem `p7zip`, nem o pacote R `archive`), então não foi possível confirmar se, uma vez extraído, o `.parquet` resultante teria o schema esperado pelo script.

**`gasto_municipal.R`:**
```
here() starts at .../orcamento_full_test
Erro: ERRO: O arquivo 'MUNIC_FINAL.xlsx' não foi encontrado em data/raw/municipal/.
Execução interrompida
```
Além do `MUNIC_FINAL.xlsx`, também estão ausentes: a subpasta `LAB1 - MUNIC/` com o `cubo_execucao_lab1_municipios_*.xlsx`, e os `.parquet` municipais do SICONFI (só existem como `.rar` por ano, ex. `2018 - Municipal.rar`, mencionados no `LEIA-ME` como grandes demais para o GitHub e disponibilizados via link do SharePoint — mas o link cobre apenas os parquets, não o `MUNIC_FINAL.xlsx` nem o cubo LAB1). Mesmo obtendo os parquets pelo link do SharePoint, os `RCL_*_Municipios.rar` também estão comprimidos e não seriam lidos pelo script (que só reconhece `.csv/.xlsx/.xls`), então essa etapa produziria uma base de RCL vazia sem aviso.

---

## 3. Checklist de Itens Imprescindíveis para Execução

- [ ] Repositório é executável (roda sem erros críticos, mesmo que com ajustes simples) — *federal passa; estadual e municipal falham por dados ausentes; a etapa nacional não existe mais para ser testada*
- [x] Documentação explica a estrutura do código
- [ ] Documentação explica como executar o código (sequência dos scripts) — *cita um "Passo 4" (`gasto_nacional_consolidado.R`) que nunca existiu com esse nome e cujo script real (`nacional.R`) foi removido da `main`*
- [x] Cada script documenta input/output esperado — *no cabeçalho de cada `.R` e na seção 2 do `.md`; com pequenas divergências (ex. `.parquet` vs. `.7z`/`.rar` reais, gráfico Sankey citado e não gerado)*
- [x] Existe tutorial de como rodar na máquina de quem clonar
- [x] Existe arquivo `.xlsx` com a ficha de metadados do projeto — *presente em `eixo1/Ficha de Metadados - Eixo 1.xlsx` (um nível acima de `orcamento/`, compartilhado com o eixo)*
- [x] Existe arquivo de dependências adequado à linguagem (`renv.lock` para R) — *criado e validado nesta revisão (`eixo1/orcamento/renv.lock`, com `.Rprofile`/`renv/` de ativação); ver seção 2*
- [ ] Ausência de erros críticos que impeçam a execução — *o bug do `.Rproj` fora da raiz foi corrigido nesta revisão; permanecem os dados brutos ausentes de `estadual`/`municipal` e a lacuna documental/de artefatos órfãos da etapa `nacional`*
