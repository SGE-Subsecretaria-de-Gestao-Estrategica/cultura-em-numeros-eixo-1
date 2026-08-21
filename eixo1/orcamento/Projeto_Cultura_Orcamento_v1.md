---
title: "Guia de Execução, Fluxo de Dados e Metadados (Eixo 1 - Orçamento)"
author: "Projeto Cultura em Números - Ministério da Cultura"
date: "13/08/2026"
output:
  md_document:
    variant: gfm
    toc: true
---

# Guia de Execução e Metadados (Eixo 1 - Orçamento)

Este documento descreve a arquitetura da esteira de dados orçamentários do **Eixo 1 (Financiamento da Cultura)**. Ele serve como o guia definitivo para replicação do ambiente, execução dos scripts e consulta de metadados, garantindo 100% de transparência e reprodutibilidade.

---

## 1. Passo a Passo: Como rodar a esteira completa

Siga os passos abaixo:

1. **Abra o Projeto pelo `.Rproj`:** Vá até a raiz do repositório clonado e dê um duplo clique no arquivo `.Rproj` (ex: `orcamento.Rproj`). Isso garantirá que os caminhos relativos (via pacote `{here}`) funcionem perfeitamente.
2. **Restaure o Ambiente Virtual (`renv`):** No console do RStudio, digite `renv::restore()`. O R instalará exatamente as mesmas versões dos pacotes utilizadas no desenvolvimento.
3. **Verifique os Inputs (Dados Brutos):** Certifique-se de que todos os arquivos `.xlsx`, `.csv` e `.parquet` originais estão posicionados dentro de suas respectivas pastas em `data/raw/` (conforme detalhado na Seção 2).
4. **Execute os Scripts na Ordem:**
   - **Passo 1:** Rode `scripts/federal/gasto_federal.R`
   - **Passo 2:** Rode `scripts/estadual/gasto_estadual.R`
   - **Passo 3:** Rode `scripts/municipal/gasto_municipal.R`
   - **Passo 4:** Rode `scripts/nacional/gasto_nacional_consolidado.R`

---

## 2. Detalhamento dos Scripts (Inputs e Outputs)

Abaixo está a ficha técnica de cada etapa da esteira. Nela consta o que o script faz, de onde puxa os dados e onde salva os resultados processados.

### 2.1. Esfera Federal (`gasto_federal.R`)
**Objetivo:** Consolida o gasto direto do MinC (Órgão 42000), Fundo Setorial do Audiovisual (FSA), Leis de Incentivo (SALIC/Rouanet, ANCINE) e as transferências da União (LPG, LAB 1, PNAB). Aplica deflação (IPCA 2024).

* **📥 INPUTS (Requeridos em `data/raw/federal/`):**
  * `salic_minc.xlsx` *(Fonte: SALIC/MinC)*
  * `ANCINE - 2005 a 2026.xlsx` *(Fonte: ANCINE)*
  * `funcoes_orgaos_unidades_rp_..._v2.xlsx` *(Fonte: SIOP)*
  * `RCL_2011_2025_Uniao_Resumido.xlsx` *(Fonte: Tesouro Nacional)*

* **📤 OUTPUTS GERADOS:**
  * **Base:** `data/processed/federal/federal_final.csv`
  * **Gráficos:** `outputs/federal/grafico_origem_direto.png`, `grafico_indireto.png`, `grafico_pleno_composicao.png`, `grafico_pleno_mandato.png`, `grafico_evolucao_real.png`, entre outros.

### 2.2. Esfera Estadual (`gasto_estadual.R`)
**Objetivo:** Mapeia a execução orçamentária dos Estados e do DF na Função 13 via SICONFI. Calcula o Esforço Fiscal comparando o gasto de Recursos Próprios contra a Receita Corrente Líquida (RCL) estadual, monitorando a Meta do PNC (1,5%).

* **📥 INPUTS (Requeridos em `data/raw/estadual/`):**
  * `msc_orcamentaria_estados_2019_2025_final.parquet` *(Fonte: SICONFI/Tesouro)*
  * `RCL_*_Estados.csv` (Múltiplos arquivos por ano) *(Fonte: SICONFI/Tesouro)*

* **📤 OUTPUTS GERADOS:**
  * **Base:** `data/processed/estadual/estadual_final.csv`
  * **Gráficos:** `outputs/estadual/grafico_evolucao_nominal.png`, `grafico_evolucao_real.png`, `painel_esforco_fiscal.png`.

### 2.3. Esfera Municipal (`gasto_municipal.R`)
**Objetivo:** Processa a execução contábil dos 5.570 municípios via SICONFI e BB Ágil. É responsável por aplicar a lógica do **Corredor Híbrido** (Variação de 20% + R$ 5,00 per capita) para classificar as prefeituras em Perfis Comportamentais (Inertes, Constantes, Despertados, Substituição) pós-repasse de leis emergenciais.

* **📥 INPUTS (Requeridos em `data/raw/municipal/`):**
  * `*.parquet` (Arquivos anuais SICONFI Função 13) *(Fonte: SICONFI/Tesouro)*
  * `LAB1 - MUNIC/cubo_execucao_lab1_municipios_*.xlsx` *(Fonte: BB Ágil)*
  * `RCL_*_Municipios.csv` (Múltiplos arquivos) *(Fonte: SICONFI/Tesouro)*
  * `MUNIC_FINAL.xlsx` *(Fonte: IBGE / Perfil dos Municípios)*

* **📤 OUTPUTS GERADOS:**
  * **Bases:** `data/processed/municipal/municipal_final.csv`, além dos 4 CSVs de Indicadores de Metas da RCL.
  * **Gráficos:** `outputs/municipal/grafico_cabo_guerra.png`, `grafico_porte_comportamental.png`.
  * **Interativos:** `grafico_dispersao_interativo.html`

### 2.4. Consolidação Macro Nacional (`nacional.R`)
**Objetivo:** Lê as três bases "finais" processadas nos passos anteriores e as consolida em uma visão macroeconômica tricolor (Municípios, Estados, União).

* **📥 INPUTS (Requeridos em `data/processed/`):**
  * `federal/federal_final.csv`
  * `estadual/estadual_final.csv`
  * `municipal/municipal_final.csv`
  *(Nota: Se estes arquivos não existirem, o script tentará executar os 3 scripts .R anteriores via `source()` automaticamente).*

* **📤 OUTPUTS GERADOS:**
  * **Base:** `data/processed/nacional/tres_esferas_consolidado.csv`
  * **Gráficos:** `outputs/nacional/grafico_financiamento_esferas.png`, `grafico_composicao_esferas.png`.

---

## 3. Ficha de Metadados e Dicionário de Dados Consolidado

A tabela a seguir é a fonte da verdade sobre as variáveis presentes nas bases finais de `processed/`. Ela indica não apenas o significado técnico da variável, mas sua trilha de auditoria: **De qual base primária a variável foi extraída** e **qual script a processou**.

| Variável | Tipo | Base de Dados Original (Fonte) | Script de Origem | Descrição / Significado Analítico |
| :--- | :--- | :--- | :--- | :--- |
| `codigo_ibge` | Char (7) | IBGE (Malha Territorial / MUNIC) | `municipal` / `estadual` | Código oficial do município ou estado segundo a divisão do IBGE. |
| `municipio` | Char | IBGE (API Localidades) | `municipal` | Nome do município padronizado, em caixa alta e sem acentuação. |
| `uf_sigla` | Char (2) | IBGE / SICONFI | `municipal` / `estadual` | Sigla da Unidade da Federação. |
| `regiao_munic` | Char | IBGE (MUNIC_FINAL.xlsx) | `municipal` | Macro-região geográfica (Norte, Nordeste, Centro-Oeste, Sudeste, Sul). |
| `porte_populacional` | Categoria | IBGE (Estimativas populacionais) | `municipal` | Classificação do tamanho da cidade (Ex: "Até 5.000", "Mais de 500.000"). |
| `exercicio` | Inteiro | SICONFI / SIOP / SALIC | `Todos` | Ano do exercício financeiro em que ocorreu o empenho/arrecadação. |
| `fonte_recursos` | Char | SICONFI (Matriz Saldos Contábeis) | `municipal` / `estadual` | Código contábil da fonte de destinação de recursos informada pelo ente. |
| `origem` | Categoria | SICONFI / BB Ágil / SIOP | `Todos` | Rótulo analítico criado via regra de negócio (Recurso Próprio, LAB 1, LPG, PNAB, Emendas). |
| `valor_nominal_final` | Numérico | SICONFI / SIOP / BB Ágil | `Todos` | Montante financeiro empenhado/arrecadado em valores correntes da época (R$). |
| `fator_deflacao` | Numérico | SGS-BCB (Série 433 - IPCA) | `Todos` | Fator multiplicador acumulado para trazer valores correntes a preços de 2024. |
| `valor_real_final` | Numérico | Variável Calculada (No Script R) | `Todos` | Montante financeiro atualizado pela inflação (`valor_nominal * fator_deflacao`). |
| `ano_2020` | Numérico | SICONFI (Processado) | `municipal` | Investimento de *Recurso Próprio per capita* no ano base pré-crise (2020). |
| `media_pos` | Numérico | SICONFI (Processado) | `municipal` | Média anual de *Recurso Próprio per capita* nos anos pós-repasses (2023 e 2024). |
| `limite_superior` | Numérico | Variável Calculada (No Script R) | `municipal` | Teto do Corredor Híbrido: `(ano_2020 * 1.20) + 5.00`. Usado para atestar Efeito Indutor. |
| `limite_inferior` | Numérico | Variável Calculada (No Script R) | `municipal` | Piso do Corredor Híbrido: `(ano_2020 * 0.80) - 5.00`. Usado para atestar Efeito Substituição. |
| `perfil_mudanca` | Categoria | Variável Calculada (Modelo) | `municipal` | Perfil comportamental do município frente aos repasses (Inertes, Constantes, Despertados, Retração). |
| `valor_rcl` | Numérico | SICONFI (Anexo de RCL) | `federal` / `est` / `mun` | Receita Corrente Líquida consolidada do ente no exercício em questão. |
| `percentual_rcl` | Numérico | Variável Calculada (No Script R) | `est` / `mun` | Proporção do investimento próprio na RCL (`valor_nominal / valor_rcl`). Base para acompanhamento da Meta do PNC. |
