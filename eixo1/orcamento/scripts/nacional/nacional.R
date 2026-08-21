#===============================================================================
# SCRIPT: EIXO 1 - ORÇAMENTO: CONSOLIDAÇÃO TRÊS ESFERAS (NACIONAL)
# 
# INPUTS:
# - data/processed/federal/federal_final.csv 
# - data/processed/estadual/estadual_final.csv 
# - data/processed/municipal/municipal_final.csv 
# 
# OUTPUTS:
# - data/processed/nacional/tres_esferas_consolidado.csv
# - outputs/nacional/grafico_financiamento_esferas.png
# - outputs/nacional/grafico_composicao_esferas.png
#===============================================================================

library(tidyverse)
library(scales)
library(gt)
library(janitor)
library(here)

# 0. CONFIGURAÇÕES E MARCADORES ------------------------------------------------
options(scipen = 999)

path_processed_nacional <- here("data", "processed", "nacional")
path_outputs_nacional   <- here("outputs", "nacional")

dir.create(path_processed_nacional, recursive = TRUE, showWarnings = FALSE)
dir.create(path_outputs_nacional, recursive = TRUE, showWarnings = FALSE)

# 1. CARREGAMENTO EXPLÍCITO DAS DEPENDÊNCIAS ----------------------------------

# 1.1 Base Federal
if (!exists("df_federal_final")) {
  file_fed <- here("data", "processed", "federal", "federal_final.csv")
  
  if (file.exists(file_fed)) {
    df_federal_final <- read_csv2(file_fed, show_col_types = FALSE)
    message("✅ Base Federal carregada do CSV com sucesso.")
  } else if (file.exists(paste0(file_fed, ".csv"))) {
    df_federal_final <- read_csv2(paste0(file_fed, ".csv"), show_col_types = FALSE)
    message("✅ Base Federal carregada (Extensão dupla '.csv.csv' corrigida).")
  } else {
    script_fed <- here("scripts", "federal", "gasto_federal.R")
    if (file.exists(script_fed)) {
      message("⚠️ CSV Federal não encontrado. Rodando o script gasto_federal.R...")
      source(script_fed)
      df_federal_final <- df_anual_ajustado # Herda o objeto do script federal
    } else {
      stop(paste0("\nERRO CRÍTICO: Base Federal não encontrada!\n",
                  "O R tentou procurar exatamente neste caminho:\n", file_fed,
                  "\n\nDICA: Certifique-se de que você abriu o RStudio clicando no arquivo .Rproj!"))
    }
  }
}

# 1.2 Base Estadual
if (!exists("df_estados_final")) {
  file_est <- here("data", "processed", "estadual", "estadual_final.csv")
  
  if (file.exists(file_est)) {
    df_estados_final <- read_csv2(file_est, show_col_types = FALSE)
    message("✅ Base Estadual carregada do CSV com sucesso.")
  } else if (file.exists(paste0(file_est, ".csv"))) {
    df_estados_final <- read_csv2(paste0(file_est, ".csv"), show_col_types = FALSE)
    message("✅ Base Estadual carregada (Extensão dupla '.csv.csv' corrigida).")
  } else {
    script_est <- here("scripts", "estadual", "gasto_estadual.R")
    if (file.exists(script_est)) {
      message("⚠️ CSV Estadual não encontrado. Rodando o script gasto_estadual.R...")
      source(script_est)
    } else {
      stop(paste0("\nERRO CRÍTICO: Base Estadual não encontrada!\n",
                  "O R tentou procurar exatamente neste caminho:\n", file_est))
    }
  }
}

# 1.3 Base Municipal
if (!exists("df_municipios_final")) {
  file_mun <- here("data", "processed", "municipal", "municipal_final.csv")
  
  if (file.exists(file_mun)) {
    df_municipios_final <- read_csv2(file_mun, show_col_types = FALSE)
    message("✅ Base Municipal carregada do CSV com sucesso.")
  } else if (file.exists(paste0(file_mun, ".csv"))) {
    df_municipios_final <- read_csv2(paste0(file_mun, ".csv"), show_col_types = FALSE)
    message("✅ Base Municipal carregada (Extensão dupla '.csv.csv' corrigida).")
  } else {
    script_mun <- here("scripts", "municipal", "gasto_municipal.R")
    if (file.exists(script_mun)) {
      message("⚠️ CSV Municipal não encontrado. Rodando o script gasto_municipal.R...")
      source(script_mun)
    } else {
      stop(paste0("\nERRO CRÍTICO: Base Municipal não encontrada!\n",
                  "O R tentou procurar exatamente neste caminho:\n", file_mun))
    }
  }
}

# 2. CONSOLIDAÇÃO DOS DADOS NACIONAIS POR ESFERA --------------------------------

# 2.1 Esfera Municipal (Agregado Nacional por Ano e Fonte)
df_nacional_municipal <- df_municipios_final %>%
  group_by(exercicio, origem) %>%
  summarise(valor_real = sum(valor_real_final, na.rm = TRUE), .groups = "drop") %>%
  mutate(esfera = "Municipal",
         fonte_padronizada = case_when(
           str_detect(origem, "Próprio") ~ "Recursos Próprios",
           str_detect(origem, "Emendas") ~ "Emendas Parlamentares",
           TRUE ~ "Transferências Especiais (LAB/LPG/PNAB)"))

# 2.2 Esfera Estadual (Agregado Nacional por Ano e Fonte)
df_nacional_estadual <- df_estados_final %>%
  group_by(exercicio, origem) %>%
  summarise(valor_real = sum(valor_real_final, na.rm = TRUE), .groups = "drop") %>%
  mutate(esfera = "Estadual",
         fonte_padronizada = case_when(
           str_detect(origem, "Próprio") ~ "Recursos Próprios",
           str_detect(origem, "Emendas") ~ "Emendas Parlamentares",
           TRUE ~ "Transferências Especiais (LAB/LPG/PNAB)"))

# 2.3 Esfera Federal (Agregado Nacional por Ano)
df_nacional_federal <- df_federal_final %>%
  mutate(exercicio = as.numeric(ano),
         esfera = "Federal",
         fonte_padronizada = case_when(
           str_detect(fonte, "Rouanet|ANCINE") ~ "Incentivo Fiscal (Renúncia)",
           str_detect(fonte, "Ministério|FSA|Outros") ~ "Orçamento Direto / Fundos",
           TRUE ~ "Transferências / Fomento Descentralizado")) %>%
  group_by(exercicio, esfera, fonte_padronizada) %>%
  summarise(valor_real = sum(valor_real, na.rm = TRUE), .groups = "drop")

# 3. EMPILHAMENTO DA MATRIZ TRICOLOR (FEDERATIVA) ------------------------------
df_tres_esferas_consolidado <- bind_rows(
  df_nacional_municipal %>% select(exercicio, esfera, fonte_padronizada, valor_real),
  df_nacional_estadual %>% select(exercicio, esfera, fonte_padronizada, valor_real),
  df_nacional_federal %>% select(exercicio, esfera, fonte_padronizada, valor_real)) %>%
  filter(exercicio >= 2019 & exercicio <= 2024)

# Salva a base unificada consolidada
write_excel_csv2(df_tres_esferas_consolidado, file.path(path_processed_nacional, "tres_esferas_consolidado.csv"))

# 4. GRÁFICO 1: EVOLUÇÃO ABSOLUTA DO GASTO CULTURAL POR ESFERA DE GOVERNO -----
df_resumo_esferas <- df_tres_esferas_consolidado %>%
  group_by(exercicio, esfera) %>%
  summarise(valor_total = sum(valor_real, na.rm = TRUE), .groups = "drop")

g1 <- ggplot(df_resumo_esferas, aes(x = factor(exercicio), y = valor_total, fill = esfera)) +
  geom_col(position = position_stack(), width = 0.7, alpha = 0.9) +
  geom_text(aes(label = ifelse(valor_total > 1e9, label_number(scale = 1e-9, suffix = "b", accuracy = 0.1, decimal.mark = ",")(valor_total), "")), 
            position = position_stack(vjust = 0.5), color = "white", fontface = "bold", size = 3.2) +
  stat_summary(fun = sum, aes(label = label_number(scale = 1e-9, suffix = " bi", accuracy = 0.1, decimal.mark = ",")(after_stat(y)), group = exercicio), 
               geom = "text", vjust = -1.2, size = 4, fontface = "bold") +
  scale_y_continuous(labels = label_number(prefix = "R$ ", scale = 1e-9, suffix = " bi", decimal.mark = ","), 
                     expand = expansion(mult = c(0, 0.4))) +
  scale_fill_manual(values = c("Municipal" = "#1b2631", "Estadual" = "#2980b9", "Federal" = "#e67e22")) +
  labs(title = "Financiamento Público da Cultura no Brasil por Esfera Federativa",
       subtitle = "Investimento Real Consolidado (Preços de 2024) | União, Estados e Municípios (2019-2024)",
       x = "Ano de Execução", y = "Valor Empenhado Real (R$ Bilhões)", fill = "Esfera de Governo",
       caption = "Fonte: SICONFI, SIOP, SALIC e ANCINE. Deflação: IPCA/SGS-BCB. Elaboração: Cultura em Números (2026).") +
  theme_minimal() + 
  theme(legend.position = "bottom", 
        plot.title = element_text(face = "bold", size = 14), 
        axis.text.x = element_text(face = "bold"))

print(g1)
ggsave(file.path(path_outputs_nacional, "grafico_financiamento_esferas.png"), plot = g1, width = 10, height = 6)

# 5. GRÁFICO 2: PERCENTUAL ANUAL (MUNICÍPIOS E ESTADOS USANDO APENAS RECURSO PRÓPRIO) ----
df_perc_municipal <- df_municipios_final %>%
  filter(exercicio >= 2019 & exercicio <= 2024, str_detect(origem, "Próprio")) %>%
  group_by(exercicio) %>%
  summarise(valor_esfera = sum(valor_real_final, na.rm = TRUE), .groups = "drop") %>%
  mutate(esfera = "Municípios (Próprio)")

df_perc_estadual <- df_estados_final %>%
  filter(exercicio >= 2019 & exercicio <= 2024, str_detect(origem, "Próprio")) %>%
  group_by(exercicio) %>%
  summarise(valor_esfera = sum(valor_real_final, na.rm = TRUE), .groups = "drop") %>%
  mutate(esfera = "Estados (Próprio)")

df_perc_federal <- df_federal_final %>%
  mutate(exercicio = as.numeric(ano)) %>%
  filter(exercicio >= 2019 & exercicio <= 2024) %>%
  group_by(exercicio) %>%
  summarise(valor_esfera = sum(valor_real, na.rm = TRUE), .groups = "drop") %>%
  mutate(esfera = "União (Pleno)")

df_tres_esferas_proprio <- bind_rows(df_perc_municipal, df_perc_estadual, df_perc_federal) %>%
  group_by(exercicio) %>%
  mutate(total_geral = sum(valor_esfera, na.rm = TRUE),
         participacao = ifelse(total_geral > 0, valor_esfera / total_geral, 0)) %>%
  ungroup() %>%
  mutate(esfera = factor(esfera, levels = c("União (Pleno)", "Estados (Próprio)", "Municípios (Próprio)")))

g2 <- ggplot(df_tres_esferas_proprio, aes(x = factor(exercicio), y = participacao, fill = esfera)) +
  geom_col(position = "fill", width = 0.7, alpha = 0.9) +
  geom_text(aes(label = ifelse(participacao > 0.05, label_percent(accuracy = 0.1, decimal.mark = ",")(participacao), "")), 
            position = position_fill(vjust = 0.5), color = "white", fontface = "bold", size = 3.2) +
  scale_y_continuous(labels = label_percent(decimal.mark = ","), expand = expansion(mult = c(0, 0.05))) +
  scale_fill_manual(values = c("União (Pleno)"       = "#2980b9", 
                               "Estados (Próprio)"    = "#27ae60", 
                               "Municípios (Próprio)" = "#1b2631")) +
  labs(title = "Composição Percentual do Financiamento Cultural por Esfera de Governo",
       subtitle = "Participação relativa anual (Subnacionais restritas a Recursos Próprios vs. União Completa)",
       x = "Ano de Execução", 
       y = "Participação Percentual (%)", 
       fill = "Esfera / Categoria",
       caption = "Fonte: SICONFI, SIOP, SALIC e ANCINE. Deflação: IPCA/SGS-BCB (2024). Elaboração: Cultura em Números (2026).") +
  theme_minimal() + 
  theme(legend.position = "bottom", 
        plot.title = element_text(face = "bold", size = 13), 
        axis.text.x = element_text(face = "bold"),
        panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank())

print(g2)
ggsave(file.path(path_outputs_nacional, "grafico_composicao_esferas.png"), plot = g2, width = 10, height = 6)
