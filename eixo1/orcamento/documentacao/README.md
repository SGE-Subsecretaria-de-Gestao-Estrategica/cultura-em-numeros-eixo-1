---
title: "Guia de Execução dos Scripts e Dicionário de Dados (Eixo 1 - Orçamento)"
author: "Projeto Cultura em Números - Ministério da Cultura - Pedro Buril S. Lins"
date: "13/08/2026"
output:
  md_document:
    variant: gfm
    toc: yes
---

# Resumo da Esteira e Estrutura de Dados

1. A esteira de processamento orçamentário do Eixo 1 é composta por quatro scripts em R que devem ser executados estritamente em ordem sequencial: Federal, Estadual, Municipal e Consolidação Macro.
2. A esfera Federal integra dados do SIOP, SALIC/Lei Rouanet e descentralizações (LPG, LAB 1 e PNAB).
3. A esfera Estadual avalia o gasto contábil via SICONFI Estadual e o percentual da Receita Corrente Líquida (RCL).
4. A esfera Municipal processa dados do SICONFI Municipal e do BB Ágil, aplicando o Corredor de Tolerância Híbrido (20% + R$ 5,00 per capita) para classificar o comportamento fiscal dos municípios.
5. A esfera Macro (Total) consolida os fluxos orçamentários das três esferas federativas em valores nominais e reais.

---

# 1. Esteira e Ordem de Execução dos Scripts

A esteira de processamento de dados do Eixo 1 segue uma dependência lógica entre as esferas de governo. Os scripts das esferas individuais (Federal, Estadual e Municipal) devem ser executados previamente para que o script final de consolidação macro possa agregar os resultados.


Table: Tabela 1: Sequência Obrigatória de Execução dos Scripts do Eixo 1

| Passo|Esfera de Governo               |Nome do Documento (.R)                     |Descrição da Função                                                                                                                                                                          |
|-----:|:-------------------------------|:------------------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|     1|1. Federal                      |SIOP.R                                     |Consolida o gasto direto do MinC (Órgão 42000), FSA, Leis de Incentivo (SALIC/Rouanet, ANCINE) e descentralizações (LPG, LAB 1, PNAB) com deflação pelo IPCA.                                |
|     2|2. Estadual                     |fonte_recurso_siconfi_participacao_gasto.R |Mapeia a execução contábil dos Governos Estaduais/DF via SICONFI e calcula o gasto próprio sobre a Receita Corrente Líquida (RCL) para avaliar a Meta do PNC (1,5%).                         |
|     3|3. Municipal                    |fonte de recurso_municipal.R               |Processa os arquivos contábeis do SICONFI Municipal (.parquet) e do BB Ágil. Aplica o Corredor Híbrido (20% + R$ 5,00 per capita) para classificar o comportamento fiscal dos municípios. |
|     4|4. Consolidação Macro (Total) |despesa_cultura_final.R                    |Cruza e consolida os fluxos financeiros finais das esferas Federal, Estadual e Municipal em valores nominais e reais (Ano-base 2024).                                                        |

---

# 2. Dicionário de Dados Consolidado

O dicionário de dados a seguir descreve as variáveis padronizadas utilizadas nas bases de dados e nos modelos analíticos desenvolvidos ao longo dos scripts:


Table: Tabela 2: Dicionário de Dados Consolidado das Variáveis (Eixo 1 - Orçamento)

|Nome da Variável    |Tipo de Dado           |Descrição / Significado Analítico                                                              |
|:-------------------|:----------------------|:----------------------------------------------------------------------------------------------|
|codigo_ibge         |Caractere (7 dígitos) |Código oficial do município segundo a divisão territorial do IBGE.                             |
|municipio           |Caractere              |Nome oficial do município padronizado sem acentuação.                                          |
|uf_sigla            |Caractere (2 letras)   |Sigla da Unidade da Federação (UF).                                                            |
|regiao_munic        |Caractere              |Macro-região geográfica do município (Norte, Nordeste, Centro-Oeste, Sudeste, Sul).            |
|exercicio           |Numérico (Ano)         |Ano do exercício financeiro da execução orçamentária.                                          |
|fonte_recursos      |Caractere              |Código contábil da fonte/destinação de recursos no SICONFI.                                    |
|valor_nominal_final |Numérico (Decimal)     |Montante financeiro empenhado em valores correntes da época da execução (R$).                  |
|fator_deflacao      |Numérico (Decimal)     |Fator multiplicador baseado no IPCA acumulado (série 433/BCB) com ano-base em 2024.            |
|valor_real_final    |Numérico (Decimal)     |Montante financeiro corrigido pela inflação (Valores constantes de 2024).                      |
|populacao           |Numérico (Inteiro)     |População residente obtida via estimativas oficiais do IBGE.                                   |
|porte_populacional  |Categoria (Fator)      |Faixa populacional do município (Até 5.000 a Mais de 500.000 hab.).                            |
|origem              |Categoria (Fator)      |Origem analítica da fonte de financiamento (Recurso Próprio, Emendas, LAB 1, LPG, PNAB).       |
|ano_2020            |Numérico (Decimal)     |Investimento próprio per capita no ano-base pré-repasses (2020).                               |
|media_pos           |Numérico (Decimal)     |Média do investimento próprio per capita no período pós-repasses (2023-2024).                  |
|limite_superior     |Numérico (Decimal)     |Teto do Corredor Híbrido calculado como (ano_2020 * 1.20) + 5.00.                              |
|limite_inferior     |Numérico (Decimal)     |Piso do Corredor Híbrido calculado como (ano_2020 * 0.80) - 5.00.                              |
|perfil_mudanca      |Categoria              |Perfil comportamental do município (Inertes, Constantes, Despertados, Efeito Substituição). |
|percentual_rcl      |Numérico (Percentual) |Percentual do investimento próprio em relação à Receita Corrente Líquida do ente.              |
