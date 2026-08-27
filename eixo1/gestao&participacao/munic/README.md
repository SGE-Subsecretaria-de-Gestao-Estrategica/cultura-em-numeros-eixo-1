---
title: "Guia de Execução, Fluxo de Dados e Metadados (Eixo 1 - Gestão)"
author: "Projeto Cultura em Números - Ministério da Cultura"
date: "27/08/2026"
output: 
  md_document:
    variant: gfm
    toc: true
---

# Guia de Execução e Metadados (Eixo 1 - Gestão: MUNIC)

Este documento descreve a arquitetura da esteira de dados de gestão e institucionalização cultural do **Eixo 1 (Gestão)**. Ele serve como o guia definitivo para replicação do ambiente, execução dos scripts e consulta de metadados das pesquisas MUNIC e ESTADIC (IBGE), garantindo 100% de transparência e reprodutibilidade metodológica.

---

## 1. Passo a Passo: Como rodar a esteira completa

Para quem acabou de chegar no repositório, a execução do código foi desenhada para ser totalmente reprodutível em qualquer máquina. Siga os passos abaixo:

1. **Abra o Projeto pelo `.Rproj`:** Vá até a raiz do diretório clonado (ex: pasta `MUNIC` ou `ESTADIC`) e dê um duplo clique no arquivo `.Rproj`. Isso garantirá que os caminhos relativos (via pacote `{here}`) funcionem perfeitamente, aposentando a necessidade de configurar `setwd()`.
2. **Restaure o Ambiente Virtual (`renv`):** No console do RStudio, digite `renv::restore()`. O R instalará exatamente as mesmas versões dos pacotes (como `tidyverse`, `arrow`, `sf`) utilizadas durante o desenvolvimento.
3. **Verifique os Inputs (Dados Brutos):** Certifique-se de que os arquivos originais baixados do IBGE (`.xls` e `.xlsx`) estão posicionados "soltos" dentro da pasta `data/raw/` (conforme detalhado na Seção 2).
4. **Execute os Scripts:**
   - **Passo 1:** Rode `scripts/painel_munic.R` para gerar todo o diagnóstico das prefeituras.
   
---

## 2. Detalhamento dos Scripts (Inputs e Outputs)

Abaixo está a ficha técnica de cada esteira. Ela aponta o que o script faz, de onde puxa os microdados do IBGE e onde salva os resultados processados e os gráficos.

### 2.1. Esfera Municipal (`painel_munic.R`)
**Objetivo:** Consolida e harmoniza o Suplemento de Cultura da Pesquisa de Informações Básicas Municipais (MUNIC/IBGE). Mapeia a evolução do Tripé Institucional da Cultura (Conselho, Fundo e Plano), perfil da burocracia (raça, gênero e escolaridade), infraestrutura de equipamentos e lei de patrimônio de 2006 a 2021.

* **📥 INPUTS (Requeridos em `data/raw/`):**
  * `Base_MUNIC_2021_20240425.xlsx` *(Fonte: IBGE)*
  * `Base_MUNIC_2018_xlsx_20201103.xlsx` *(Fonte: IBGE)*
  * `base_cultura_MUNIC_xls_2014.xls` *(Fonte: IBGE)*
  * `Base Suplemento Cultura 2006.xls` *(Fonte: IBGE)*

* **📤 OUTPUTS GERADOS:**
  * **Base Harmonizada:** `data/processed/munic_cultura_painel_historico_06_21.csv`
  * **Visualizações:** Mais de 18 arquivos em `outputs/` (ex: `grafico_1_evolução_tripe.png`, `grafico_6_perfil_etnico_racial.png`, `Tabela_Visual_3_Matriz_Regional_2021.png`, etc.).

---

## 3. Ficha de Metadados e Dicionário de Dados Consolidado

A tabela a seguir é a fonte da verdade sobre as variáveis presentes nas bases finais consolidadas em `data/processed/`. Ela indica não apenas o significado da variável, mas sua trilha de auditoria e origem.

| Variável | Tipo | Base de Dados Original (Fonte) | Esfera | Descrição / Significado Analítico |
| :--- | :--- | :--- | :--- | :--- |
| `cod_municipio` / `cod_uf` | Char | IBGE | Ambas | Código oficial de 7 dígitos para município ou 2 dígitos para estado. |
| `municipio` / `nome_uf` | Char | IBGE | Ambas | Nome por extenso da unidade territorial. |
| `regiao` | Char | Variável Calculada | Ambas | Macro-região geográfica gerada a partir do primeiro dígito do código IBGE. |
| `ano` | Inteiro | IBGE (MUNIC/ESTADIC) | Ambas | Ano de referência da aplicação do questionário da pesquisa. |
| `tipo_orgao_gestor` | Categoria | IBGE | Ambas | Grau de autonomia do ente (Secretaria Exclusiva, Conjunta, ou Setor Subordinado). |
| `tem_plano` | Char (Sim/Não) | IBGE | Ambas | Indica se o ente possui Plano de Cultura ativo. |
| `tem_conselho` | Char (Sim/Não) | IBGE | Ambas | Indica se o ente possui Conselho de Cultura ativo. |
| `tem_fundo` | Char (Sim/Não) | IBGE | Ambas | Indica se o ente possui Fundo de Cultura ativo. |
| `tripe_completo` | Inteiro/Cat | Variável Calculada | Ambas | Indicador binário/categórico: 1 se Conselho, Fundo e Plano = "Sim" (Adesão Plena ao SNC). |
| `gestor_sexo` | Categoria | IBGE | Ambas | Sexo do titular da pasta de cultura. |
| `gestor_cor_raca` | Categoria | IBGE | Ambas | Autodeclaração de raça/cor do titular da pasta (Branca, Preta, Parda, Indígena, Amarela). |
| `gestor_escolaridade_agrupada`| Categoria | Variável Calculada | Ambas | Harmonização dos níveis de ensino em 4 categorias amplas (Fundamental, Médio, Superior, Pós-Graduação). |
| `cons_paritario` | Categoria | IBGE | Ambas | Avalia se a composição do conselho ativo é paritária entre sociedade civil e poder público. |
| `cons_competencia` | Categoria | IBGE / Calculada | Ambas | Natureza do conselho a partir de cruzamento de variáveis (Deliberativo, Consultivo ou Normativo/Fiscalizador). |
| `orcamento_perc_executado` | Categoria | IBGE (MUNIC 2021) | Municipal | Faixa de execução dos recursos emergenciais repassados pela União (Ex: Lei Aldir Blanc 1). |
| `equip_*` | Char (Sim/Não) | IBGE | Municipal | Variáveis binárias indicando presença municipal de Biblioteca, Museu, Teatro e Cinema. |
| `ir_gt_cultura` | Char (Sim/Não) | ESTADIC 2024 | Estadual | (Módulo Transversal) Indica se existe representação da Cultura em instâncias de Igualdade Racial. |
| `pi_arte_cultura` | Char (Sim/Não) | ESTADIC 2023 | Estadual | (Módulo Transversal) Indica existência de política transversal de cultura para a Primeira Infância. |