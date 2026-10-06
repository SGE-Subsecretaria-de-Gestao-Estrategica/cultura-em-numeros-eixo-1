# ==============================================================================
# PAINEL SNC - SISTEMA NACIONAL DE CULTURA (MUNICÍPIOS CADASTRADOS)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. PACOTES E CONFIGURAÇÕES
# ------------------------------------------------------------------------------
library(tidyverse)
library(janitor)
library(readxl)
library(here)
library(ggplot2)
library(scales)
library(stringr)
library(lubridate)
library(gt)

dir.create(here("data", "raw"), recursive = TRUE, showWarnings = FALSE)
dir.create(here("data", "processed"), recursive = TRUE, showWarnings = FALSE)
dir.create(here("outputs"), recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------------------------
# 2. IMPORTAÇÃO E LIMPEZA DE NOMES
# ------------------------------------------------------------------------------
path_snc <- here("data", "raw", "SNC - painel dados_04-09-26-11h30.xlsx")

df_snc_bruto <- read_excel(path_snc) %>% 
  clean_names()

# ------------------------------------------------------------------------------
# 3. HARMONIZAÇÃO E SELEÇÃO DAS VARIÁVEIS ESTRATÉGICAS
# ------------------------------------------------------------------------------
df_snc_painel <- df_snc_bruto %>%
  mutate(cod_ibge = as.character(as.integer(cod_ibge))) %>%
  select(ente_federado, 
    uf, 
    regiao, 
    cod_ibge, 
    populacao_2022, 
    faixa_populacional,
    situacao_adesao = situacao, 
    data_adesao,
    perfil_orgao_gestor = perfil_do_orgao_gestor,
    situacao_lei_snc = situacao_da_lei_do_sistema_de_cultura,
    situacao_conselho = situacao_da_lei_do_conselho_de_politica_cultural,
    conselho_paritario,
    natureza_conselho = natureza_do_conselho,
    situacao_fundo = situacao_da_lei_do_fundo_de_cultura,
    situacao_plano = situacao_do_plano_de_cultura)

# ------------------------------------------------------------------------------
# 4. DIAGNÓSTICO BÁSICO
# ------------------------------------------------------------------------------

cat("\n--- Status geral de adesão ao SNC ---\n")
df_snc_painel %>%
  count(situacao_adesao, sort = TRUE) %>%
  mutate(perc = round(n / sum(n) * 100, 1)) %>%
  print(n = 20)

cat("\n--- Situações do Conselho na plataforma ---\n")
df_snc_painel %>%
  count(situacao_conselho, sort = TRUE) %>%
  mutate(perc = round(n / sum(n) * 100, 1)) %>%
  print(n = 20)

cat("\n--- Perfil do Órgão Gestor por Região ---\n")
df_snc_painel %>%
  filter(!is.na(perfil_orgao_gestor)) %>%
  count(regiao, perfil_orgao_gestor) %>%
  pivot_wider(names_from = perfil_orgao_gestor, values_from = n, values_fill = 0) %>%
  print()

# ==============================================================================
# 5. ANÁLISE EXPLORATÓRIA VISUAL
# ==============================================================================

# --- GRÁFICO 5.1: STATUS DE ADESÃO AO SNC POR REGIÃO ---
eda_adesao <- df_snc_painel %>%
  filter(!is.na(regiao), !is.na(situacao_adesao)) %>%
  count(regiao, situacao_adesao) %>%
  group_by(regiao) %>%
  mutate(taxa = n / sum(n))

p_adesao <- ggplot(eda_adesao, aes(x = regiao, y = taxa, fill = situacao_adesao)) +
  geom_col(position = "stack", color = "white", width = 0.7) +
  geom_text(aes(label = ifelse(taxa > 0.05, percent(taxa, accuracy = 1), "")), 
            position = position_stack(vjust = 0.5), size = 3.5, color = "white", fontface = "bold") +
  scale_y_continuous(labels = percent_format()) +
  scale_fill_brewer(palette = "Set1") +
  theme_minimal(base_size = 14) +
  theme(legend.position = "bottom", 
        plot.title = element_text(face = "bold"),
        plot.margin = margin(15, 15, 15, 15)) +
  guides(fill = guide_legend(nrow = 2, byrow = TRUE)) + 
  labs(title = "Situação de Adesão ao SNC por Região",
       subtitle = "Proporção do status cadastral dos municípios na Plataforma SNC",
       x = "Região", y = "Proporção de Municípios", fill = "Status de Adesão:")

ggsave(here("outputs", "eda_1_adesao_regiao.png"), plot = p_adesao, width = 11, height = 7, dpi = 300, bg = "white")


# --- GRÁFICO 5.2: STATUS CADASTRAL DO TRIPÉ INSTITUCIONAL ---
eda_tripe <- df_snc_painel %>%
  select(situacao_conselho, situacao_fundo, situacao_plano) %>%
  pivot_longer(cols = everything(), names_to = "instrumento", values_to = "status") %>%
  mutate(status = replace_na(status, "Não Informado/Em Branco"),
         instrumento = case_match(
           instrumento,
           "situacao_conselho" ~ "Conselho de Cultura",
           "situacao_fundo" ~ "Fundo de Cultura",
           "situacao_plano" ~ "Plano de Cultura")) %>%
  count(instrumento, status) %>%
  group_by(instrumento) %>%
  mutate(taxa = n / sum(n))

p_tripe <- ggplot(eda_tripe, aes(x = taxa, y = fct_reorder(status, taxa), fill = instrumento)) +
  geom_col(show.legend = FALSE) +
  geom_text(aes(label = percent(taxa, accuracy = 0.1)), hjust = -0.1, size = 3.5, fontface = "bold") +
  scale_x_continuous(labels = percent_format(), limits = c(0, 1.15)) +
  scale_fill_manual(values = c("Conselho de Cultura" = "#2980B9", "Fundo de Cultura" = "#27AE60", "Plano de Cultura" = "#E74C3C")) +
  facet_wrap(~ instrumento, ncol = 1, scales = "free_y") +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"), 
        strip.text = element_text(face = "bold", size = 12),
        plot.margin = margin(15, 15, 15, 15)) +
  labs(title = "Situação Declarada dos Instrumentos do Tripé",
       subtitle = "Como os entes registraram a situação de suas leis no sistema",
       x = "Proporção", y = "")

ggsave(here("outputs", "eda_2_status_tripe.png"), plot = p_tripe, width = 11, height = 9, dpi = 300, bg = "white")


# --- GRÁFICO 5.3: NATUREZA VS PARIDADE DOS CONSELHOS ---
eda_conselhos <- df_snc_painel %>%
  filter(!is.na(natureza_conselho), !is.na(conselho_paritario), conselho_paritario != "Não informado") %>%
  count(natureza_conselho, conselho_paritario)

p_conselhos <- ggplot(eda_conselhos, aes(x = conselho_paritario, y = n, fill = natureza_conselho)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7, color = "white") +
  geom_text(aes(label = n), position = position_dodge(width = 0.8), vjust = -0.5, fontface = "bold") +
  scale_fill_brewer(palette = "Dark2") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "bottom", 
        legend.direction = "vertical", 
        plot.title = element_text(face = "bold"),
        plot.margin = margin(15, 15, 15, 15)) +
  labs(title = "Perfil dos Conselhos Municipais na Plataforma SNC",
       subtitle = "Cruzamento entre a paridade de assentos e o poder decisório (Natureza)",
       x = "O Conselho é Paritário?", y = "Quantidade de Municípios", fill = "Natureza do Conselho:")

ggsave(here("outputs", "eda_3_natureza_paridade_conselhos.png"), plot = p_conselhos, width = 11, height = 7, dpi = 300, bg = "white")


# --- GRÁFICO 5.4: AUTONOMIA DO ÓRGÃO GESTOR POR PORTE POPULACIONAL ---
eda_orgao_porte <- df_snc_painel %>%
  filter(!is.na(faixa_populacional), !is.na(perfil_orgao_gestor)) %>%
  count(faixa_populacional, perfil_orgao_gestor) %>%
  group_by(faixa_populacional) %>%
  mutate(taxa = n / sum(n)) %>%
  mutate(faixa_populacional = factor(faixa_populacional, levels = sort(unique(faixa_populacional))))

p_orgao <- ggplot(eda_orgao_porte, aes(x = faixa_populacional, y = taxa, fill = perfil_orgao_gestor)) +
  geom_col(color = "white") +
  coord_flip() +
  scale_y_continuous(labels = percent_format(), expand = expansion(mult = c(0, 0.05))) +
  scale_fill_viridis_d(option = "magma", begin = 0.2, end = 0.8) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "bottom", 
        plot.title = element_text(face = "bold"),
        plot.margin = margin(15, 15, 15, 15)) +
  guides(fill = guide_legend(ncol = 1)) + 
  labs(title = "Estrutura do Órgão Gestor vs Porte do Município",
       subtitle = "Proporção de secretarias exclusivas e setores subordinados por tamanho da cidade",
       x = "Faixa Populacional", y = "Proporção", fill = "Perfil do Órgão:")

ggsave(here("outputs", "eda_4_orgao_gestor_porte.png"), plot = p_orgao, width = 12, height = 8, dpi = 300, bg = "white")

# --- GRÁFICO 5.5: TOTAL DE ADESÕES POR REGIÃO (NÚMEROS ABSOLUTOS E COBERTURA) ---
df_adesao_regiao <- df_snc_painel %>%
  filter(str_length(str_trim(cod_ibge)) > 2, !is.na(regiao)) %>%
  group_by(regiao) %>%
  summarise(
    total_mun = n(), 
    adesoes = sum(situacao_adesao == "Publicado no DOU", na.rm = TRUE), 
    taxa_cobertura = adesoes / total_mun 
  ) %>%
  ungroup()

p_adesao_regiao <- ggplot(df_adesao_regiao, aes(x = adesoes, y = fct_reorder(regiao, adesoes))) +
  geom_col(fill = "#2980B9", color = "white", width = 0.7) +
  geom_text(aes(label = paste0(format(adesoes, big.mark = ".", decimal.mark = ","), 
                               " (", percent(taxa_cobertura, accuracy = 0.1, decimal.mark = ","), ")")), 
            hjust = -0.1, fontface = "bold", size = 4) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.20))) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold"),
    plot.margin = margin(15, 15, 15, 15),
    panel.grid.major.y = element_blank(),
    axis.text.x = element_blank(), 
    axis.title.x = element_blank() 
  ) +
  labs(title = "Total de Adesões ao SNC por Região", y = "")

ggsave(here("outputs", "eda_5_adesao_regiao_absoluto.png"), plot = p_adesao_regiao, width = 11, height = 7, dpi = 300, bg = "white")

# --- GRÁFICO 5.6: TOTAL DE ADESÕES POR PORTE POPULACIONAL (EXCLUINDO ESTADOS) ---
df_adesao_porte <- df_snc_painel %>%
  filter(str_length(str_trim(cod_ibge)) > 2, !is.na(faixa_populacional)) %>%
  mutate(faixa_populacional = case_when(str_detect(faixa_populacional, "Grande") ~ "Porte 4 (Grande): acima de 100 mil habitantes",
    TRUE ~ as.character(faixa_populacional))) %>%
  group_by(faixa_populacional) %>%
  summarise(total_mun = n(),
            adesoes = sum(situacao_adesao == "Publicado no DOU", na.rm = TRUE),
            taxa_cobertura = adesoes / total_mun) %>%
  ungroup() %>%
  mutate(faixa_populacional = factor(faixa_populacional, levels = sort(unique(faixa_populacional))))

# 2. Plotagem alterando o eixo X para a taxa e os rótulos de dados
p_adesao_porte <- ggplot(df_adesao_porte, aes(x = taxa_cobertura, y = fct_rev(faixa_populacional))) +
  geom_col(fill = "#27AE60", color = "white", width = 0.7) +
  geom_text(aes(label = paste0(percent(taxa_cobertura, accuracy = 0.1, decimal.mark = ","), 
                               " (n=", format(adesoes, big.mark = ".", decimal.mark = ","), ")")), 
            hjust = -0.1, fontface = "bold", size = 4) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.25))) +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(face = "bold"),
        plot.margin = margin(15, 15, 15, 15),
        panel.grid.major.y = element_blank(),
        axis.text.x = element_blank(), 
        axis.title.x = element_blank() ) +
  labs(title = "Taxa de Adesão ao SNC por Porte Populacional",
       subtitle = "Proporção de municípios aderentes em relação ao total de cada faixa",
       y = "")

ggsave(here("outputs", "eda_6_adesao_porte_percentual.png"), plot = p_adesao_porte, width = 11, height = 7, dpi = 300, bg = "white")

# EXPORTAÇÃO DO DATASET (GRÁFICO 5.6: TAXA DE ADESÃO POR PORTE)
df_tidy_exportacao_adesao_porte <- df_adesao_porte %>%
  select(porte_populacional = faixa_populacional, 
    total_municipios = total_mun, 
    adesoes_validadas = adesoes, 
    taxa_cobertura) %>%
  mutate(porte_populacional = as.character(porte_populacional)) %>%
  arrange(porte_populacional)

write.table(df_tidy_exportacao_adesao_porte, 
  file = here("data", "processed", "Figura 8 – Adesões municipais ao SNC por porte populacional.csv"), 
  sep = ";", dec = ".", row.names = FALSE, fileEncoding = "Latin1", quote = FALSE)

# ==============================================================================
# 6. ANÁLISE BIVARIADA: QUALIDADE INSTITUCIONAL X CAPACIDADE ESTATAL
# ==============================================================================
df_snc_bivariada <- df_snc_painel %>%
  mutate(cod_ibge = as.character(as.integer(cod_ibge)),
    idh_2021 = df_snc_bruto$idh_2021,
    possui_metas = df_snc_bruto$possui_metas,
    categoria_idh = case_when(
      idh_2021 < 0.600 ~ "Baixo (< 0,600)",
      idh_2021 >= 0.600 & idh_2021 < 0.700 ~ "Médio (0,600 a 0,699)",
      idh_2021 >= 0.700 & idh_2021 < 0.800 ~ "Alto (0,700 a 0,799)",
      idh_2021 >= 0.800 ~ "Muito Alto (>= 0,800)",
      TRUE ~ "Sem Informação"),
    categoria_idh = factor(categoria_idh, levels = c("Baixo (< 0,600)", "Médio (0,600 a 0,699)", "Alto (0,700 a 0,799)", "Muito Alto (>= 0,800)", "Sem Informação")),
    faixa_populacional = factor(faixa_populacional, levels = sort(unique(faixa_populacional))),
    tripe_completo = case_when(situacao_conselho == "Concluída" & 
        situacao_fundo == "Concluída" & 
        situacao_plano == "Concluída" ~ "Sim",
      TRUE ~ "Não"))

# --- GRÁFICO 6.1: ADESÃO VS IDH (COM OCLUSÃO DE TEXTO EM BARRAS < 5%) ---
eda_adesao_idh <- df_snc_bivariada %>%
  filter(!is.na(situacao_adesao), categoria_idh != "Sem Informação") %>%
  count(categoria_idh, situacao_adesao) %>%
  group_by(categoria_idh) %>%
  mutate(taxa = n / sum(n))

p_adesao_idh <- ggplot(eda_adesao_idh, aes(x = categoria_idh, y = taxa, fill = situacao_adesao)) +
  geom_col(position = "fill", color = "white", width = 0.7) +
  geom_text(aes(label = ifelse(taxa < 0.05, "", paste0(n, "\n(", percent(taxa, accuracy = 1), ")"))), 
            position = position_stack(vjust = 0.5), fontface = "bold", color = "white", size = 3.5) +
  scale_y_continuous(labels = percent_format()) +
  scale_fill_brewer(palette = "Set1") +
  theme_minimal(base_size = 14) +
  theme(legend.position = "bottom", plot.title = element_text(face = "bold"), plot.margin = margin(15, 15, 15, 15)) +
  guides(fill = guide_legend(nrow = 2, byrow = TRUE)) +
  labs(title = "Situação de Adesão ao SNC por Faixa de IDH",
       subtitle = "O nível de desenvolvimento socioeconômico influencia o trâmite de adesão?",
       x = "Faixa de IDH (2021)", y = "Proporção de Municípios", fill = "Status de Adesão:")

ggsave(here("outputs", "eda_7_adesao_vs_idh.png"), plot = p_adesao_idh, width = 11, height = 7, dpi = 300, bg = "white")


# --- GRÁFICO 6.2: TRIPÉ COMPLETO VS PORTE POPULACIONAL ---
eda_tripe_porte <- df_snc_bivariada %>%
  filter(!is.na(faixa_populacional)) %>%
  count(faixa_populacional, tripe_completo) %>%
  group_by(faixa_populacional) %>%
  mutate(taxa = n / sum(n))

p_tripe_porte <- ggplot(eda_tripe_porte, aes(x = faixa_populacional, y = taxa, fill = tripe_completo)) +
  geom_col(color = "white") +
  geom_text(aes(label = paste0(n, " (", percent(taxa, accuracy = 1), ")")), 
            position = position_stack(vjust = 0.5), fontface = "bold", color = "white", size = 4) +
  coord_flip() +
  scale_y_continuous(labels = percent_format(), expand = expansion(mult = c(0, 0.05))) +
  scale_fill_manual(values = c("Sim" = "#27AE60", "Não" = "#E74C3C")) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "bottom", plot.title = element_text(face = "bold"), plot.margin = margin(15, 15, 15, 15)) +
  labs(title = "Consolidação do Tripé Institucional por Porte do Município",
       subtitle = "Proporção de entes que possuem Conselho, Fundo e Plano 'Concluídos' simultaneamente",
       x = "Porte Populacional", y = "Proporção", fill = "Possui Tripé Completo?")

ggsave(here("outputs", "eda_8_tripe_completo_vs_porte.png"), plot = p_tripe_porte, width = 12, height = 7, dpi = 300, bg = "white")


# --- GRÁFICO 6.3: PLANO COM METAS VS REGIÃO (COM REGRA DE QUEBRA DE LINHA < 15%) ---
eda_metas_regiao <- df_snc_bivariada %>%
  filter(situacao_plano == "Concluída", possui_metas %in% c("Sim", "Não")) %>%
  count(regiao, possui_metas) %>%
  group_by(regiao) %>%
  mutate(taxa = n / sum(n))

p_metas_regiao <- ggplot(eda_metas_regiao, aes(x = regiao, y = taxa, fill = possui_metas)) +
  geom_col(position = "fill", color = "white", width = 0.7) +
  geom_text(aes(label = ifelse(taxa < 0.15, 
                               paste0(n, " (", percent(taxa, accuracy = 1), ")"), 
                               paste0(n, "\n(", percent(taxa, accuracy = 1), ")"))), 
            position = position_stack(vjust = 0.5), fontface = "bold", color = "white", size = 3.5) +
  scale_y_continuous(labels = percent_format()) +
  scale_fill_manual(values = c("Sim" = "#2980B9", "Não" = "#7F8C8D")) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "bottom", plot.title = element_text(face = "bold"), plot.margin = margin(15, 15, 15, 15)) +
  labs(title = "Qualidade do Planejamento Cultural por Região",
       subtitle = "Dentre os municípios com Plano 'Concluído', quantos definiram metas claras na lei?",
       x = "Região", y = "Proporção de Planos Concluídos", fill = "O Plano possui metas definidas?")

ggsave(here("outputs", "eda_9_metas_plano_vs_regiao.png"), plot = p_metas_regiao, width = 11, height = 7, dpi = 300, bg = "white")


# ==============================================================================
# 7. SÉRIE HISTÓRICA: EVOLUÇÃO DAS ADESÕES VALIDADAS DO TRIPÉ (2012 - 2026)
# ==============================================================================

# --- 7.1 PREPARAÇÃO DOS DADOS TEMPORAIS---
df_evolucao_base <- df_snc_bruto %>%
  select(cod_ibge,
    data_Conselho = data_da_lei_do_conselho_de_politica_cultural,
    sit_Conselho = situacao_da_lei_do_conselho_de_politica_cultural,
    data_Fundo = data_da_lei_do_fundo_de_cultura,
    sit_Fundo = situacao_da_lei_do_fundo_de_cultura,
    data_Plano = data_do_plano_de_cultura,
    sit_Plano = situacao_do_plano_de_cultura) %>%
  pivot_longer(cols = -cod_ibge,
    names_to = c(".value", "instrumento"),
    names_pattern = "(data|sit)_(.*)") %>%
  filter(sit == "Concluída") %>%
  mutate(data_num = suppressWarnings(as.numeric(data)),
    data_formatada = as.Date(data_num, origin = "1899-12-30"),
    ano = year(data_formatada),
    instrumento = paste(instrumento, "de Cultura"))

# --- 7.2 AGREGAÇÃO ---
df_serie_historica <- df_evolucao_base %>%
  filter(!is.na(ano)) %>%
  count(instrumento, ano, name = "novas_adesoes") %>%
  arrange(instrumento, ano) %>%
  group_by(instrumento) %>%
  mutate(adesoes_acumuladas = cumsum(novas_adesoes)) %>%
  ungroup() %>%
  filter(ano >= 2012, ano <= 2026) %>%
  pivot_longer(cols = c(novas_adesoes, adesoes_acumuladas), 
               names_to = "tipo", values_to = "quantidade") %>%
  mutate(tipo = factor(tipo, 
                  levels = c("adesoes_acumuladas", "novas_adesoes"), 
                  labels = c("Adesões acumuladas", "Novas adesões no ano")))

# --- 7.3 FUNÇÃO DE PLOTAGEM E GERAÇÃO AUTOMÁTICA DOS 3 GRÁFICOS ---
instrumentos_tripe <- unique(df_serie_historica$instrumento)

purrr::walk(instrumentos_tripe, function(inst) {
  
  df_plot <- df_serie_historica %>% filter(instrumento == inst)
  limite_y_superior <- max(df_plot$quantidade) * 1.20 
  limite_y_inferior <- -max(df_plot$quantidade) * 0.08 
  
  p_evolucao <- ggplot(df_plot, aes(x = ano, y = quantidade, color = tipo, linetype = tipo)) +
    annotate("rect", xmin = -Inf, xmax = 2020, ymin = -Inf, ymax = Inf, fill = "#FFF9E6", alpha = 0.7) +
    annotate("rect", xmin = 2020, xmax = 2023, ymin = -Inf, ymax = Inf, fill = "#E9F2FA", alpha = 0.9) +
    annotate("rect", xmin = 2023, xmax = 2024, ymin = -Inf, ymax = Inf, fill = "#FFF9E6", alpha = 0.7) +
    annotate("rect", xmin = 2024, xmax = Inf,  ymin = -Inf, ymax = Inf, fill = "#E9F2FA", alpha = 0.9) +
    geom_vline(xintercept = c(2020, 2023, 2024), color = "#B0BEC5", linetype = "solid", linewidth = 0.6) +
    annotate("text", x = 2012.2,  y = limite_y_superior * 0.98, label = "Sem\nRepasses", hjust = 0, vjust = 1, fontface = "bold", color = "#78909C", size = 3.5, lineheight = 0.9) +
    annotate("text", x = 2020.15, y = limite_y_superior * 0.98, label = "LAB 1\n(2020)", hjust = 0, vjust = 1, fontface = "bold", color = "#546E7A", size = 3.5, lineheight = 0.9) +
    annotate("text", x = 2023.1,  y = limite_y_superior * 0.98, label = "LPG\n(2023)", hjust = 0, vjust = 1, fontface = "bold", color = "#546E7A", size = 3.5, lineheight = 0.9) +
    annotate("text", x = 2024.15, y = limite_y_superior * 0.98, label = "PNAB\n(2024-2028)", hjust = 0, vjust = 1, fontface = "bold", color = "#546E7A", size = 3.5, lineheight = 0.9) +
    geom_line(linewidth = 1.2) +
    geom_point(size = 3) +
    geom_text(aes(label = quantidade, 
                  vjust = ifelse(tipo == "Adesões acumuladas", -1.2, 1.8)), 
              fontface = "bold", size = 3.5, show.legend = FALSE) +
    scale_color_manual(values = c("Adesões acumuladas" = "#2D68C4", "Novas adesões no ano" = "#29B6F6")) +
    scale_linetype_manual(values = c("Adesões acumuladas" = "solid", "Novas adesões no ano" = "dashed")) +
    scale_x_continuous(breaks = seq(2012, 2026, by = 1)) +
    scale_y_continuous(limits = c(limite_y_inferior, limite_y_superior), expand = c(0, 0)) +
    theme_minimal(base_size = 14) +
    theme(legend.position = "bottom",
      legend.title = element_blank(),
      plot.title = element_text(face = "bold", size = 16),
      panel.grid.major.x = element_blank(),
      panel.grid.minor = element_blank(),
      axis.text.y = element_blank(), 
      axis.title.y = element_blank(),
      plot.margin = margin(15, 15, 15, 15)) +
    labs(title = paste("Evolução das adesões validadas ao SNC:", inst),
      subtitle = "Impacto das Leis Federais de Fomento na aprovação de instrumentos institucionais locais",
      x = "")
  
  nome_arquivo <- paste0("eda_10_evolucao_validada_", str_replace_all(inst, " ", "_"), ".png")
  
  ggsave(here("outputs", nome_arquivo), plot = p_evolucao, width = 12, height = 6.5, dpi = 300, bg = "white")
})

# --- 7.4 SÉRIE HISTÓRICA: EVOLUÇÃO GERAL DAS ADESÕES AO SNC ---
df_evolucao_geral <- df_snc_painel %>%
  filter(situacao_adesao == "Publicado no DOU", !is.na(data_adesao)) %>%
  mutate(data_num = suppressWarnings(as.numeric(data_adesao)),
    data_formatada = case_when(!is.na(data_num) ~ as.Date(data_num, origin = "1899-12-30"),
      TRUE ~ as.Date(parse_date_time(str_replace(as.character(data_adesao), " às ", " "), 
                                     orders = c("dmy_HMS", "dmy", "ymd_HMS", "ymd"), quiet = TRUE))),
    ano = year(data_formatada)) %>%
  filter(!is.na(ano)) %>%
  count(ano, name = "novas_adesoes") %>%
  arrange(ano) %>%
  mutate(adesoes_acumuladas = cumsum(novas_adesoes)) %>%
  filter(ano >= 2012, ano <= 2026) %>%
  pivot_longer(cols = c(novas_adesoes, adesoes_acumuladas), 
               names_to = "tipo", values_to = "quantidade") %>%
  mutate(tipo = factor(tipo, 
                       levels = c("adesoes_acumuladas", "novas_adesoes"), 
                       labels = c("Adesões acumuladas", "Novas adesões no ano")))

p_evolucao_geral <- ggplot(df_evolucao_geral, aes(x = ano, y = quantidade, color = tipo, linetype = tipo)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  geom_text(aes(label = format(quantidade, big.mark = ".", decimal.mark = ","),
                vjust = ifelse(tipo == "Adesões acumuladas", -1.2, 1.8)),
            fontface = "bold", size = 3.5, show.legend = FALSE) +
  scale_color_manual(values = c("Adesões acumuladas" = "#2D68C4", "Novas adesões no ano" = "#009BFF")) +
  scale_linetype_manual(values = c("Adesões acumuladas" = "solid", "Novas adesões no ano" = "dashed")) +
  scale_x_continuous(breaks = seq(2012, 2026, by = 1)) +
  scale_y_continuous(limits = c(-250, 4300), 
                     breaks = seq(0, 4000, by = 1000), 
                     expand = c(0, 0), 
                     labels = function(x) format(x, big.mark = ".", scientific = FALSE)) +
  coord_cartesian(clip = "off") +
  theme_minimal(base_size = 14) +
  theme(legend.position = "bottom",
        legend.title = element_blank(),
        plot.title = element_text(face = "bold", size = 16),
        plot.subtitle = element_text(color = "gray50", size = 12),
        panel.grid.major.x = element_blank(),
        panel.grid.minor = element_blank(),
        axis.text.y = element_text(color = "gray50"),
        axis.title.y = element_blank(),
        plot.margin = margin(15, 15, 15, 15)) +
  labs(title = "Evolução das adesões ao SNC",
       subtitle = "Por ano de adesão",
       x = "",
       caption = "Fonte: Elaboração própria a partir da Plataforma do Sistema Nacional de Cultura.")

ggsave(here("outputs", "eda_11_evolucao_geral_snc.png"), plot = p_evolucao_geral, width = 12, height = 6.5, dpi = 300, bg = "white")

# EXPORTAÇÃO DO DATASET (GRÁFICO 7.4: EVOLUÇÃO GERAL DAS ADESÕES)
df_tidy_exportacao_evolucao_geral <- df_evolucao_geral %>%
  select(ano_adesao = ano, 
    tipo_metrica = tipo, 
    quantidade) %>%
  mutate(tipo_metrica = as.character(tipo_metrica)) %>%
  arrange(ano_adesao, tipo_metrica)

# Exporta preservando os números crus
write.table(df_tidy_exportacao_evolucao_geral, 
  file = here("data", "processed", "Figura 9 – Evolução das adesões municipais ao SNC.csv"), 
  sep = ";", dec = ".", row.names = FALSE, fileEncoding = "Latin1", quote = FALSE)

# ==============================================================================
# 8. TABELA DE TRIPÉ
# ==============================================================================

# --- 8.1 PREPARAÇÃO DOS DADOS DA TABELA ---
tabela_tripe_dados_2026 <- df_snc_bivariada %>%
  filter(!is.na(regiao)) %>%
  group_by(regiao) %>%
  summarise(total_mun = n(),
    n_conselho = sum(situacao_conselho == "Concluída", na.rm = TRUE),
    n_fundo = sum(situacao_fundo == "Concluída", na.rm = TRUE),
    n_plano = sum(situacao_plano == "Concluída", na.rm = TRUE),
    n_tripe = sum(tripe_completo == "Sim", na.rm = TRUE),
    perc_conselho = n_conselho / total_mun,
    perc_fundo = n_fundo / total_mun,
    perc_plano = n_plano / total_mun,
    perc_tripe = n_tripe / total_mun) %>%
  mutate(ano = "2026",
    col_conselho = paste0(n_conselho, " (", percent(perc_conselho, accuracy = 0.1, decimal.mark = ","), ")"),
    col_fundo = paste0(n_fundo, " (", percent(perc_fundo, accuracy = 0.1, decimal.mark = ","), ")"),
    col_plano = paste0(n_plano, " (", percent(perc_plano, accuracy = 0.1, decimal.mark = ","), ")"),
    col_tripe = paste0(n_tripe, " (", percent(perc_tripe, accuracy = 0.1, decimal.mark = ","), ")")) %>%
  select(ano, regiao, col_conselho, col_fundo, col_plano, col_tripe)

# --- 8.2 GERAÇÃO E FORMATAÇÃO DA TABELA ---
gt_tabela_snc <- tabela_tripe_dados_2026 %>%
  gt(groupname_col = "ano") %>%
  tab_header(title = md("**Consolidação Regional do Tripé Institucional da Cultura**"),
    subtitle = "Número absoluto e proporção de municípios com Conselhos, Fundos, Planos e Tripé Completo") %>%
  cols_label(regiao = "Região",
    col_conselho = "Conselho",
    col_fundo = "Fundo",
    col_plano = "Plano",
    col_tripe = "Tripé Completo") %>%
  tab_style(style = cell_text(weight = "bold", color = "#C0392B"),
    locations = cells_body(columns = col_tripe)) %>%
  tab_options(row_group.background.color = "#ECF0F1",
    row_group.font.weight = "bold",
    heading.background.color = "#2C3E50",
    heading.title.font.size = px(18),
    heading.subtitle.font.size = px(14),
    column_labels.background.color = "#34495E",
    column_labels.font.weight = "bold") %>%
  tab_source_note(source_note = md("*Fonte: Elaboração própria com base na Plataforma SNC/MinC (2026).*"))

gtsave(gt_tabela_snc, here("outputs", "Tabela_SNC_Tripe_Regiao_2026.html"))

# ==============================================================================
# 9. VALIDAÇÃO DAS AFIRMAÇÕES DO RELATÓRIO EXECUTIVO
# ==============================================================================

# --- VALIDAÇÃO 1: "27 unidades da federação e 3.945 municípios aderiram ao Sistema."
df_snc_painel %>%
  mutate(tipo_ente = ifelse(str_length(str_trim(cod_ibge)) <= 2, "Estado", "Município")) %>%
  filter(situacao_adesao == "Publicado no DOU") %>%
  count(tipo_ente, name = "total_aderentes") %>%
  print()


# --- VALIDAÇÃO 2: "Mais de 1.200 novas adesões desde 2021."
df_snc_painel %>%
  filter(situacao_adesao == "Publicado no DOU", !is.na(data_adesao)) %>%
  mutate(data_adesao_formatada = coalesce(dmy(data_adesao), ymd(data_adesao)),
    ano_adesao = year(data_adesao_formatada)) %>%
  filter(ano_adesao >= 2021) %>%
  summarise(novas_adesoes_desde_2021 = n()) %>%
  print()

# --- VALIDAÇÃO 3: "A adesão cresce com o porte: de 64,1% nos municípios com até 20 mil... a 97,4% nos de 100 mil a 900 mil"
df_snc_painel %>%
  filter(str_length(str_trim(cod_ibge)) > 2, !is.na(faixa_populacional)) %>% 
  group_by(faixa_populacional) %>%
  summarise(total_municipios = n(),
    municipios_aderentes = sum(situacao_adesao == "Publicado no DOU", na.rm = TRUE),
    taxa_percentual = municipios_aderentes / total_municipios,
    taxa_formatada = percent(taxa_percentual, accuracy = 0.1, decimal.mark = ",")) %>%
  arrange(taxa_percentual) %>% 
  select(faixa_populacional, total_municipios, municipios_aderentes, taxa_formatada) %>%
  print()

# --- VALIDAÇÃO 4: "23% dos municípios aderentes têm Conselho, Plano e Fundo de Cultura."
df_snc_bivariada %>%
  filter(str_length(str_trim(cod_ibge)) > 2) %>% 
  filter(!str_detect(str_to_lower(situacao_adesao), "possui ades")) %>% 
  summarise(total_aderentes = n(),
    possuem_tripe = sum(tripe_completo == "Sim", na.rm = TRUE),
    taxa_tripe = percent(possuem_tripe / total_aderentes, accuracy = 0.1, decimal.mark = ",")) %>%
  print()


# --- VALIDAÇÃO 5: "O Plano de Cultura é o componente menos frequente: existe em 28%..."
df_snc_bivariada %>%
  filter(str_length(str_trim(cod_ibge)) > 2) %>%
  filter(!str_detect(str_to_lower(situacao_adesao), "possui ades")) %>%
  summarise(total_aderentes = n(),
    perc_conselho = percent(sum(situacao_conselho == "Concluída", na.rm = TRUE) / total_aderentes, accuracy = 0.1, decimal.mark = ","),
    perc_fundo = percent(sum(situacao_fundo == "Concluída", na.rm = TRUE) / total_aderentes, accuracy = 0.1, decimal.mark = ","),
    perc_plano = percent(sum(situacao_plano == "Concluída", na.rm = TRUE) / total_aderentes, accuracy = 0.1, decimal.mark = ",")) %>%
  print()


# --- VALIDAÇÃO 6: "No Sul, 42,7% dos municípios têm os três componentes; no Norte, 5,8%."
df_snc_bivariada %>%
  filter(str_length(str_trim(cod_ibge)) > 2, !is.na(regiao)) %>%
  group_by(regiao) %>%
  summarise(total_municipios = n(),
    aderentes = sum(!str_detect(str_to_lower(situacao_adesao), "possui ades"), na.rm = TRUE),
    possuem_tripe = sum(tripe_completo == "Sim", na.rm = TRUE),
    taxa_sobre_total_mun = percent(possuem_tripe / total_municipios, accuracy = 0.1, decimal.mark = ","),
    taxa_sobre_aderentes = percent(possuem_tripe / aderentes, accuracy = 0.1, decimal.mark = ",")) %>%
  arrange(desc(possuem_tripe / total_municipios)) %>%
  print()

# --- VALIDAÇÃO 7: "2.247 municípios têm Conselho de Cultura instituído por lei; 79,5% deles são paritários."
df_snc_painel %>%
  filter(str_length(str_trim(cod_ibge)) > 2) %>%
  filter(situacao_conselho == "Concluída") %>% 
  summarise(total_conselhos_instituidos = n(),
    conselhos_paritarios = sum(conselho_paritario == "Sim", na.rm = TRUE),
    perc_paritarios = percent(conselhos_paritarios / total_conselhos_instituidos, accuracy = 0.1, decimal.mark = ",")) %>%
  print()

# --- VALIDAÇÃO 8: "% de municípios com data de atualização anterior a 2023"
df_snc_bruto %>%
  filter(str_length(str_trim(cod_ibge)) > 2) %>%
  mutate(data_limpa = str_replace(ultima_atualizacao, " às ", " "),
    ano_atualizacao = year(parse_date_time(data_limpa, 
                                           orders = c("dmy_HMS", "dmy", "ymd_HMS", "ymd"), 
                                           quiet = TRUE))) %>%
  filter(!is.na(ano_atualizacao)) %>%
  summarise(total_municipios_com_data = n(),
    atualizacao_antes_2023 = sum(ano_atualizacao < 2023, na.rm = TRUE),
    perc_defasado = percent(atualizacao_antes_2023 / total_municipios_com_data, accuracy = 0.1, decimal.mark = ",")) %>%
  print()

# --- VALIDAÇÃO 9: TABELA DA SOFIA (Apenas Municípios) ---
df_validacao_sofia <- df_snc_bivariada %>%
  filter(str_length(str_trim(cod_ibge)) > 2, !is.na(regiao)) %>%
  group_by(regiao) %>%
  summarise(Municipios = n(),
    `Conselho (nº)` = sum(situacao_conselho == "Concluída", na.rm = TRUE),
    `Fundo (nº)` = sum(situacao_fundo == "Concluída", na.rm = TRUE),
    `Plano (nº)` = sum(situacao_plano == "Concluída", na.rm = TRUE),
    `CPF completo (nº)` = sum(tripe_completo == "Sim", na.rm = TRUE)) %>%
  mutate(`Conselho (%)` = percent(`Conselho (nº)` / Municipios, accuracy = 0.1, decimal.mark = ","),
    `Fundo (%)` = percent(`Fundo (nº)` / Municipios, accuracy = 0.1, decimal.mark = ","),
    `Plano (%)` = percent(`Plano (nº)` / Municipios, accuracy = 0.1, decimal.mark = ","),
    `CPF completo (%)` = percent(`CPF completo (nº)` / Municipios, accuracy = 0.1, decimal.mark = ",")) %>%
  select(regiao, Municipios, 
         `Conselho (nº)`, `Conselho (%)`, 
         `Fundo (nº)`, `Fundo (%)`, 
         `Plano (nº)`, `Plano (%)`, 
         `CPF completo (nº)`, `CPF completo (%)`)

linha_brasil <- df_validacao_sofia %>%
  summarise(regiao = "Brasil",
    Municipios = sum(Municipios),
    `Conselho (nº)` = sum(`Conselho (nº)`),
    `Fundo (nº)` = sum(`Fundo (nº)`),
    `Plano (nº)` = sum(`Plano (nº)`),
    `CPF completo (nº)` = sum(`CPF completo (nº)`)) %>%
  mutate(`Conselho (%)` = percent(`Conselho (nº)` / Municipios, accuracy = 0.1, decimal.mark = ","),
    `Fundo (%)` = percent(`Fundo (nº)` / Municipios, accuracy = 0.1, decimal.mark = ","),
    `Plano (%)` = percent(`Plano (nº)` / Municipios, accuracy = 0.1, decimal.mark = ","),
    `CPF completo (%)` = percent(`CPF completo (nº)` / Municipios, accuracy = 0.1, decimal.mark = ","))

tabela_sofia <- bind_rows(df_validacao_sofia, linha_brasil) 

# ==============================================================================
# 10. TABELA: PERFIL DOS CONSELHOS INSTITUÍDOS (COM 'NÃO INFORMADO')
# ==============================================================================

df_perfil_conselhos <- df_snc_bruto %>%
  filter(str_length(str_trim(cod_ibge)) > 2,
    situacao_da_lei_do_conselho_de_politica_cultural == "Concluída") %>%
  mutate(data_ata_num = suppressWarnings(as.numeric(data_da_assinatura_da_ata_da_ultima_reuniao)),
    data_ata_formatada = case_when(
      !is.na(data_ata_num) ~ as.Date(data_ata_num, origin = "1899-12-30"),
      TRUE ~ as.Date(parse_date_time(str_replace(as.character(data_da_assinatura_da_ata_da_ultima_reuniao), " às ", " "), 
                                     orders = c("dmy_HMS", "dmy", "ymd_HMS", "ymd"), 
                                     quiet = TRUE))),
    ano_ata = year(data_ata_formatada),
    
    # Indicador 1: Exclusivo (Identifica vazios, NAs e textos que não são Sim)
    cat_exclusivo = case_when(is.na(conselho_exclusivo_de_cultura) | str_trim(as.character(conselho_exclusivo_de_cultura)) == "" ~ "Não informado",
      str_detect(str_to_lower(conselho_exclusivo_de_cultura), "^sim\\b") ~ "Sim",
      str_detect(str_to_lower(conselho_exclusivo_de_cultura), "n[ãa]o") ~ "Não",
      TRUE ~ "Não informado"),
    # Indicador 2: Paritário
    cat_paritario = case_when(is.na(conselho_paritario) | str_trim(as.character(conselho_paritario)) == "" ~ "Não informado",
      str_detect(str_to_lower(conselho_paritario), "^sim\\b") ~ "Sim",
      str_detect(str_to_lower(conselho_paritario), "n[ãa]o") ~ "Não",
      TRUE ~ "Não informado"),
    # Indicador 3: Deliberativo
    cat_deliberativo = case_when(is.na(natureza_do_conselho) | str_trim(as.character(natureza_do_conselho)) == "" ~ "Não informado",
      str_detect(str_to_lower(natureza_do_conselho), "deliberativo") ~ "Sim",
      str_detect(str_to_lower(natureza_do_conselho), "consultivo") ~ "Não",
      TRUE ~ "Não informado"),
    # Indicador 4: Atuante
    cat_atuante = case_when(is.na(possui_ata_da_ultima_reuniao_do_conselho) | str_trim(as.character(possui_ata_da_ultima_reuniao_do_conselho)) == "" ~ "Não informado",
      ano_ata >= 2025 ~ "Sim",
      ano_ata < 2025 ~ "Não",
      str_detect(str_to_lower(possui_ata_da_ultima_reuniao_do_conselho), "n[ãa]o") ~ "Não",
      TRUE ~ "Não informado"))

# 2. Contagem e consolidação das frequências
t1 <- df_perfil_conselhos %>% count(cat_exclusivo) %>% rename(resposta = cat_exclusivo) %>% mutate(indicador = "Conselho exclusivo de cultura?")
t2 <- df_perfil_conselhos %>% count(cat_paritario) %>% rename(resposta = cat_paritario) %>% mutate(indicador = "Conselho paritário?")
t3 <- df_perfil_conselhos %>% count(cat_deliberativo) %>% rename(resposta = cat_deliberativo) %>% mutate(indicador = "Conselho deliberativo?")
t4 <- df_perfil_conselhos %>% count(cat_atuante) %>% rename(resposta = cat_atuante) %>% mutate(indicador = "Realizou reunião entre 2025–2026 (atuante)?")

tabela_perfil <- bind_rows(t1, t2, t3, t4) %>%
  pivot_wider(names_from = resposta, values_from = n, values_fill = 0) %>%
  { if (!"Não" %in% names(.)) mutate(., Não = 0) else . } %>%
  { if (!"Não informado" %in% names(.)) mutate(., `Não informado` = 0) else . } %>%
  select(indicador, Sim, Não, `Não informado`) %>%
  mutate(Total = Sim + Não + `Não informado`,
    Perc_Sim = Sim / Total,
    Perc_Nao = Não / Total,
    Perc_NI = `Não informado` / Total) %>%
  select(indicador, Sim, Perc_Sim, Não, Perc_Nao, `Não informado`, Perc_NI)

# 3. Geração da Tabela em {gt}
gt_perfil <- tabela_perfil %>%
  gt() %>%
  tab_header(title = md("**Perfil dos Conselhos de Cultura municipais**"),
    subtitle = "Entre os 2.247 instituídos por lei") %>%
  cols_label(indicador = "Conselhos de cultura municipais (n=2.247)",
    Sim = "Sim",
    Perc_Sim = "% sim",
    Não = "Não",
    Perc_Nao = "% não",
    `Não informado` = "Não inf.",
    Perc_NI = "% não inf.") %>%
  fmt_number(columns = c(Sim, Não, `Não informado`), decimals = 0, use_seps = TRUE, sep_mark = ".") %>%
  fmt_percent(columns = c(Perc_Sim, Perc_Nao, Perc_NI), decimals = 1, dec_mark = ",", sep_mark = ".") %>%
  tab_style(style = cell_text(weight = "bold", color = "#2C3E50"),
    locations = cells_body(columns = indicador)) %>%
  tab_options(heading.background.color = "#1ABC9C",
    heading.title.font.weight = "bold",
    column_labels.background.color = "#16A085",
    column_labels.font.weight = "bold",
    table.width = pct(100)) %>%
  tab_source_note(source_note = md("*Fonte: Elaboração própria a partir da Plataforma do Sistema Nacional de Cultura, com dados extraídos em setembro de 2026.*"))

gtsave(gt_perfil, here("outputs", "Tabela_SNC_Perfil_Conselhos.html"))
