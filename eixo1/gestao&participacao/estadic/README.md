---
title: "Guia de Execução, Fluxo de Dados e Metadados (Eixo 1 - Gestão) - Estadic"
author: "Projeto Cultura em Números - Ministério da Cultura"
date: "27/08/2026"
output: 
  md_document:
    variant: gfm
    toc: true
---

# Guia de Execução e Metadados (Eixo 1 - Gestão: ESTADIC)

Este documento descreve a arquitetura da esteira de dados de gestão e institucionalização cultural estadual do **Eixo 1 (Gestão)**. Ele serve como o guia definitivo para replicação do ambiente, execução do script e consulta de metadados da pesquisa ESTADIC (IBGE), garantindo 100% de transparência e reprodutibilidade metodológica.

---

## 1. Passo a Passo: Como rodar a esteira completa

Para quem acabou de chegar no repositório, a execução do código foi desenhada para ser totalmente reprodutível em qualquer máquina. Siga os passos abaixo:

1. **Abra o Projeto pelo `.Rproj`:** Vá até a raiz do diretório clonado (ex: pasta `ESTADIC`) e dê um duplo clique no arquivo `.Rproj`. Isso garantirá que os caminhos relativos (via pacote `{here}`) funcionem perfeitamente, aposentando a necessidade de configurar `setwd()`.
2. **Restaure o Ambiente Virtual (`renv`):** No console do RStudio, digite `renv::restore()`. O R instalará exatamente as mesmas versões dos pacotes (como `tidyverse`, `rnaturalearth`, `sf`) utilizadas durante o desenvolvimento.
3. **Verifique os Inputs (Dados Brutos):** Certifique-se de que os arquivos originais baixados do IBGE (`.xls` e `.xlsx`) estão posicionados "soltos" dentro da pasta `data/raw/` (conforme detalhado na Seção 2).
4. **Execute o Script:**
   - Rode o arquivo `scripts/ESTADIC.R` para gerar o diagnóstico de todos os estados, a evolução histórica do painel e as análises cartográficas (mapas).

---

## 2. Detalhamento do Script (Inputs e Outputs)

Abaixo está a ficha técnica da esteira estadual. Ela aponta o que o script faz, de onde puxa os microdados do IBGE e onde salva os resultados processados e os gráficos.

### Esfera Estadual (`ESTADIC.R`)
**Objetivo:** Harmoniza e processa os dados da Pesquisa de Informações Básicas Estaduais (ESTADIC/IBGE) de 2012 a 2024. O script mapeia a evolução do núcleo duro de gestão (Tripé, Autonomia e Escolaridade), os mecanismos de fomento (Patrimônio e Leis de Incentivo) e a presença de ações culturais transversais (Igualdade Racial, Primeira Infância e Mulheres). Inclui renderização cartográfica via `rnaturalearth`.

* **📥 INPUTS (Requeridos em `data/raw/`):**
  * `ESTADIC 2024.xlsx` *(Módulo Transversal: Igualdade Racial)*
  * `ESTADIC 2023.xlsx` *(Módulos Transversais: Infância e Mulheres)*
  * `ESTADIC 2021.xlsx` *(Módulo Direto de Cultura)*
  * `ESTADIC 2018.xlsx` *(Módulo Direto de Cultura)*
  * `ESTADIC 2014.xls` *(Módulo Direto de Cultura + Patrimônio)*
  * `ESTADIC 2012.xls` *(Módulo Transversal: Conselhos e Fundos)*

* **📤 OUTPUTS GERADOS:**
  * **Base Harmonizada:** `data/processed/estadic_cultura_painel_transversal_12_24.csv`
  * **Visualizações Gráficas:** 8 gráficos salvos em `outputs/` (Evolução do Tripé, Transversalidade, Fomento e Patrimônio, Escolaridade).
  * **Visualizações Cartográficas (Mapas):** 3 mapas temáticos salvos em `outputs/` avaliando territorialmente a Maturidade do SNC, a Autonomia do Gestor e os Marcos Legais.

---

## 3. Ficha de Metadados e Dicionário de Dados Consolidado

A tabela a seguir é a fonte da verdade sobre as variáveis presentes na base final consolidada em `data/processed/`. Ela indica não apenas o significado da variável, mas sua trilha de auditoria e origem.

| Variável | Tipo | Base de Dados Original (Fonte) | Esfera | Descrição / Significado Analítico |
| :--- | :--- | :--- | :--- | :--- |
| `cod_uf` | Char | IBGE | Estadual | Código oficial de 2 dígitos para estado. |
| `nome_uf` | Char | IBGE | Estadual | Nome por extenso da unidade territorial (Estado/UF). |
| `regiao` | Char | Variável Calculada | Estadual | Macro-região geográfica gerada a partir do primeiro dígito do código IBGE. |
| `ano` | Inteiro | IBGE (ESTADIC) | Estadual | Ano de referência da aplicação do questionário da pesquisa. |
| `tipo_orgao_gestor` | Categoria | IBGE | Estadual | Grau de autonomia do ente (Secretaria Exclusiva, Conjunta, ou Setor Subordinado). |
| `tem_plano` | Char (Sim/Não) | IBGE | Estadual | Indica se o estado possui Plano de Cultura ativo. |
| `tem_conselho` | Char (Sim/Não) | IBGE | Estadual | Indica se o estado possui Conselho de Cultura ativo. |
| `tem_fundo` | Char (Sim/Não) | IBGE | Estadual | Indica se o estado possui Fundo de Cultura ativo. |
| `tripe_completo` | Inteiro/Cat | Variável Calculada | Estadual | Indicador binário/categórico: 1 se Conselho, Fundo e Plano = "Sim" (Adesão Plena ao SNC). |
| `gestor_sexo` | Categoria | IBGE | Estadual | Sexo do titular da pasta de cultura estadual. |
| `gestor_cor_raca` | Categoria | IBGE | Estadual | Autodeclaração de raça/cor do titular da pasta (Branca, Preta, Parda, Indígena, Amarela). |
| `gestor_escolaridade_agrupada`| Categoria | Variável Calculada | Estadual | Harmonização dos níveis de ensino em 4 categorias amplas (Fundamental, Médio, Superior, Pós-Graduação). |
| `cons_paritario` | Categoria | IBGE | Estadual | Avalia se a composição do conselho ativo é paritária entre sociedade civil e poder público. |
| `cons_competencia` | Categoria | IBGE / Calculada | Estadual | Natureza do conselho a partir de cruzamento de variáveis (Deliberativo, Consultivo ou Normativo/Fiscalizador). |
| `tem_lei_patrimonio` | Char (Sim/Não) | IBGE | Estadual | Indica se o estado possui legislação específica de tombamento e acautelamento de patrimônio cultural. |
| `tem_lei_incentivo` | Char (Sim/Não) | IBGE | Estadual | Indica se o estado possui mecanismo próprio de mecenato/renúncia fiscal para a cultura. |
| `ir_gt_cultura` | Char (Sim/Não) | ESTADIC 2024 | Estadual | (Módulo Transversal) Indica se existe representação da Cultura em instâncias de Igualdade Racial. |
| `pi_arte_cultura` | Char (Sim/Não) | ESTADIC 2023 | Estadual | (Módulo Transversal) Indica existência de política transversal de cultura para a Primeira Infância. |