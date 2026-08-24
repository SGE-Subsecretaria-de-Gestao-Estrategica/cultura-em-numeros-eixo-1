#===============================================================================
# INSTRUÇÕES DE REPLICABILIDADE DO AMBIENTE (renv)
#===============================================================================
# Este projeto utiliza o {renv} para gerenciar versões de pacotes.
# Se você acabou de clonar este repositório, rode no console:
# > renv::restore() 
# Isso garantirá que você tenha exatamente as mesmas versões de pacotes usadas.
#===============================================================================

#===============================================================================
# SCRIPT: EIXO 1 - ORÇAMENTO (GASTO FEDERAL INTEGRADO)
# 
# INPUTS:
# - data/raw/federal/salic_minc.xlsx (Fonte: SALIC)
# - data/raw/federal/RCL_2011_2025_Uniao_Resumido.xlsx (Fonte: Tesouro Nacional)
# - data/raw/federal/funcoes_orgaos_unidades_rp_..._v2.xlsx (Fonte: SIOP)
# - data/raw/federal/ANCINE - 2005 a 2026.xlsx (Fonte: ANCINE)
# 
# OUTPUTS:
# - data/processed/federal/federal_final.csv
# - outputs/federal/grafico_origem_direto.png
# - outputs/federal/grafico_indireto.png
# - outputs/federal/grafico_pleno_composicao.png
# - outputs/federal/grafico_pleno_matriz.png
# - outputs/federal/grafico_impacto_rcl.png
# - outputs/federal/grafico_pleno_mandato.png
# - outputs/federal/grafico_pleno_evolucao_anual.png
# - outputs/federal/grafico_matriz_lpg_2023.png
# - outputs/federal/grafico_rcl_lpg_2023.png
# - outputs/federal/grafico_evolucao_real.png
#===============================================================================

library(tidyverse)
library(readxl)
library(scales)
library(janitor)
library(rbcb)
library(here)

# 0. CONFIGURAÇÕES E MARCADORES ------------------------------------------------
options(scipen = 999)

# Definição de caminhos usando here() relativos à raiz do projeto (.Rproj na pasta orcamento)
path_raw_federal       <- here("data", "raw", "federal")
path_processed_federal <- here("data", "processed", "federal")
path_outputs_federal   <- here("outputs", "federal")

# Cria as pastas caso não existam
dir.create(path_processed_federal, recursive = TRUE, showWarnings = FALSE)
dir.create(path_outputs_federal, recursive = TRUE, showWarnings = FALSE)

# Dicionários de Cores e Filtros Centralizados (Evita código duplicado)
paleta_minC <- c(
  "Ministério da Cultura (Órgão 42000)" = "#2980b9",
  "PNAB (UO 73120)"                     = "#f1c40f",
  "FSA (UO 74912)"                      = "#27ae60",
  "Lei Aldir Blanc 1"                   = "#e67e22",
  "Lei Paulo Gustavo"                   = "#78281f",
  "Outros Órgãos (Cidadania/Turismo)"   = "#95a5a6",
  "Lei Rouanet"                         = "#1b2631",
  "Incentivo (ANCINE)"                  = "#8e44ad"
)

tema_minC <- theme_minimal() +
  theme(panel.grid = element_blank(),
        legend.position = "top",
        plot.title = element_text(face = "bold", size = 14),
        axis.text = element_text(size = 10))

df_incumbentes <- data.frame(
  ano = c(2003, 2007, 2011, 2015, 2016, 2019, 2023),
  presidente = c("Lula I", "Lula II", "Dilma I", "Dilma II", "Temer", "Bolsonaro", "Lula III"))

# 1. CARREGAMENTO DAS BASES ----------------------------------------------------

# 1.1 SALIC (Incentivo Fiscal) - Teto
salic <- read_xlsx(file.path(path_raw_federal, "salic_minc.xlsx")) %>%
  clean_names() %>%
  mutate(across(c(vl_captado, vl_teto, vl_renunciado), ~ as.numeric(as.character(.)))) %>%
  group_by(ano = as.numeric(ano)) %>%
  summarise(teto       = sum(vl_teto, na.rm = TRUE),
            captado    = sum(vl_captado, na.rm = TRUE),
            renunciado = sum(vl_renunciado, na.rm = TRUE),
            .groups = "drop")

# 1.2 RCL (Receita Corrente Líquida)
rcl <- read_xlsx(file.path(path_raw_federal, "RCL_2011_2025_Uniao_Resumido.xlsx")) %>%
  clean_names() %>%
  transmute(ano = as.numeric(ano), rcl = as.numeric(rcl))

# 1.3 SIOP (Gasto Direto)
id_minc       <- "42000" 
ids_transicao <- c("54000", "55000") 
ids_fundos    <- c("73120", "74912", "73117") 

# Busca o arquivo SIOP dinamicamente
arquivo_siop <- list.files(path = path_raw_federal, pattern = "(?i)^funcoes_orgaos.*\\.xlsx$", full.names = TRUE)[1]

dados_siop <- read_xlsx(arquivo_siop) %>% 
  clean_names() %>%
  mutate(across(c(ano, empenhado, liquidado), as.numeric)) %>%
  filter(ano != 2026)

anos_com_minc <- dados_siop %>%
  filter(str_sub(orgao_orcamentario, 1, 5) == id_minc) %>%
  pull(ano) %>% unique()

# 1.4 ANCINE (Renúncia fiscal)
# VERIFICAÇÃO DE DEPENDÊNCIA
caminho_ancine <- file.path(path_raw_federal, "ANCINE - 2005 a 2026.xlsx")
if (!file.exists(caminho_ancine)) {
  stop("ERRO: O arquivo 'ANCINE - 2005 a 2026.xlsx' não foi encontrado em data/raw/federal/. A execução foi interrompida.")
}

ancine_raw <- read_xlsx(caminho_ancine) %>% 
  clean_names()

colunas_renuncia <- c("art_1a", "art_3a", "art1", "art18_lei_8_313_91_rouanet", 
                      "art25_lei_8_313_91_rouanet", "art3", "art39_condecine", "art41_funcines")

ancine_anual <- ancine_raw %>%
  filter(!is.na(as.numeric(ano))) %>% 
  mutate(ano = as.numeric(ano)) %>%
  mutate(across(all_of(colunas_renuncia), ~ as.numeric(as.character(.)))) %>%
  mutate(across(all_of(colunas_renuncia), ~ replace_na(., 0))) %>%
  mutate(ancine_captado = rowSums(select(., all_of(colunas_renuncia)), na.rm = TRUE)) %>%
  select(ano, ancine_captado)

# 2. PROCESSAMENTO E CONSOLIDAÇÃO ----------------------------------------------

# Lógica de Filtro FASE 1/2/3 extraída para uso comum
filtro_fases_cultura <- function(df) {
  df %>% filter(
    # FASE 1: 2019 (Regra Híbrida)
    (ano == 2019 & (str_sub(orgao_orcamentario, 1, 5) == id_minc | 
                      (str_sub(orgao_orcamentario, 1, 5) == "55000" & (str_detect(funcao, "13") | 
                                                                         (str_detect(funcao, "28") & str_sub(unidade_orcamentaria, 1, 5) != "55901"))) |
                      str_sub(unidade_orcamentaria, 1, 5) %in% ids_fundos)) |
      # FASE 2: Anos com MinC Ativo
      (ano != 2019 & ano %in% anos_com_minc & (str_sub(orgao_orcamentario, 1, 5) == id_minc | 
                                                 str_sub(unidade_orcamentaria, 1, 5) %in% ids_fundos)) |
      # FASE 3: Anos Sem MinC
      (!(ano %in% anos_com_minc) & ano != 2019 & ((str_sub(orgao_orcamentario, 1, 5) %in% 
                                                     ids_transicao & (str_detect(funcao, "13") | (str_detect(funcao, "28") & str_sub(unidade_orcamentaria, 1, 5) != "55901"))) | 
                                                    str_sub(unidade_orcamentaria, 1, 5) %in% ids_fundos))
  )
}

df_siop_consolidado <- dados_siop %>%
  filtro_fases_cultura() %>%
  group_by(ano, orgao_orcamentario, unidade_orcamentaria, resultado_primario) %>%
  summarise(valor_empenhado = sum(empenhado, na.rm = TRUE), .groups = "drop") %>%
  group_by(ano) %>%
  summarise(siop_direto = sum(valor_empenhado), .groups = "drop")


# 2.2 União Final para Gasto Pleno
df_final <- df_siop_consolidado %>%
  left_join(salic, by = "ano") %>%
  left_join(ancine_anual, by = "ano") %>%
  left_join(rcl, by = "ano") %>%
  mutate(total_incentivo = replace_na(teto, 0) + replace_na(ancine_captado, 0),
         total_pleno = siop_direto + total_incentivo,
         perc_rcl = (total_pleno / rcl) * 100)

#-------------------------------------------------------------------------------
# SEQUÊNCIA DE GRÁFICOS PARA APRESENTAÇÃO
#-------------------------------------------------------------------------------
df_grafico_origem <- dados_siop %>%
  filter(!is.na(unidade_orcamentaria)) %>%
  filtro_fases_cultura() %>%
  mutate(categoria_origem = case_when(
    str_sub(unidade_orcamentaria, 1, 5) == "73120" ~ "PNAB (UO 73120)",
    str_sub(unidade_orcamentaria, 1, 5) == "74912" ~ "FSA (UO 74912)",
    str_sub(unidade_orcamentaria, 1, 5) == "73117" & ano >= 2022 ~ "Lei Paulo Gustavo",
    str_sub(unidade_orcamentaria, 1, 5) == "73117" & ano < 2022 ~ "Lei Aldir Blanc 1",
    str_sub(orgao_orcamentario, 1, 5) == "42000" ~ "Ministério da Cultura (Órgão 42000)",
    TRUE ~ "Outros Órgãos (Cidadania/Turismo)")) %>% 
  filter(!is.na(categoria_origem)) %>%
  group_by(ano, categoria_origem) %>%
  summarise(valor_total = sum(empenhado, na.rm = TRUE), .groups = "drop")

# I. GASTO FEDERAL DIRETO
p1 <- ggplot(df_grafico_origem, aes(x = factor(ano), y = valor_total, fill = categoria_origem)) +
  geom_col(width = 0.7, alpha = 0.9) +
  geom_text(aes(label = ifelse(valor_total > 150000000, 
                               label_number(scale = 1e-9, suffix = "b", accuracy = 0.1, decimal.mark = ",")(valor_total), "")), 
            position = position_stack(vjust = 0.5), size = 2.5, fontface = "bold", color = "white") +
  stat_summary(fun = sum, aes(label = label_number(scale = 1e-9, suffix = " bi", accuracy = 0.1, decimal.mark = ",")(after_stat(y)), group = ano), 
               geom = "text", vjust = -0.7, size = 3, fontface = "bold") +
  scale_y_continuous(labels = label_number(scale = 1e-9, suffix = " bi"), expand = expansion(mult = c(0, 0.4))) +
  scale_fill_manual(values = paleta_minC, na.translate = FALSE) + 
  labs(title = "Evolução do Gasto Federal Direto em Cultura",
       x = "Ano", y = "R$ Bilhões", fill = "Origem do Recurso",
       caption = "Fonte: SIOP. LPG (2022) e LAB 1 (2020-21) diferenciadas pela UO 73117.") +
  tema_minC + 
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
ggsave(file.path(path_outputs_federal, "grafico_origem_direto.png"), plot = p1, width = 10, height = 6)

# II. Gasto Indireto
df_grafico_indireto <- df_final %>%
  filter(ano >= 2006 & ano <= 2025) %>%
  select(ano, `Lei Rouanet` = teto, 
         `Incentivo (ANCINE)` = ancine_captado) %>%
  pivot_longer(cols = -ano, names_to = "origem", values_to = "valor") %>%
  mutate(origem = factor(origem, levels = c("Lei Rouanet", "Incentivo (ANCINE)")))

p2 <- ggplot(df_grafico_indireto, aes(x = factor(ano), y = valor, fill = origem)) +
  geom_col(position = "stack", width = 0.7, alpha = 0.9) +
  geom_text(aes(label = ifelse(valor > 100000000, 
                               label_number(scale = 1e-9, suffix = "b", accuracy = 0.1, decimal.mark = ",")(valor), "")), 
            position = position_stack(vjust = 0.5), 
            size = 2.5, fontface = "bold", color = "white") +
  stat_summary(fun = sum, aes(label = label_number(scale = 1e-9, suffix = " bi", accuracy = 0.1, decimal.mark = ",")(after_stat(y)), group = ano), 
               geom = "text", vjust = -0.7, size = 3.5, fontface = "bold", color = "black") +
  scale_y_continuous(labels = label_number(scale = 1e-9, suffix = " bi"), 
                     expand = expansion(mult = c(0, 0.3))) +
  scale_fill_manual(values = paleta_minC) +
  labs(title = "Evolução do Gasto Federal Indireto em Cultura",
       subtitle = "Série Histórica: Incentivos Fiscais via Lei Rouanet (Teto) e Setor Audiovisual (Captação)",
       x = "Ano", 
       y = "R$ Bilhões", 
       fill = "Origem do Recurso",
       caption = "Fonte: SALIC e ANCINE. Valores nominais.") +
  tema_minC + 
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "top",
        legend.justification = "left")
ggsave(file.path(path_outputs_federal, "grafico_indireto.png"), plot = p2, width = 10, height = 6)

# IV. GASTO TOTAL PLENO
df_detalhado_reais <- df_grafico_origem %>%
  rename(fonte = categoria_origem, valor = valor_total) %>%
  bind_rows(df_final %>%
              filter(ano >= 2006) %>%
              select(ano, `Lei Rouanet` = teto,
                     `Incentivo (ANCINE)` = ancine_captado) %>%
              pivot_longer(cols = -ano, names_to = "fonte", values_to = "valor")) %>%
  filter(!is.na(valor), valor > 0)

p3 <- ggplot(df_detalhado_reais, aes(x = factor(ano), y = valor, fill = fonte)) +
  geom_col(position = "stack", width = 0.7, alpha = 0.9) +
  geom_text(aes(label = ifelse(valor > 150000000, 
                               label_number(scale = 1e-9, suffix = "b", accuracy = 0.1, decimal.mark = ",")(valor), "")), 
            position = position_stack(vjust = 0.5),  
            size = 3.2, 
            fontface = "bold", color = "white") + 
  stat_summary(fun = sum, aes(label = label_number(scale = 1e-9, suffix = " bi", accuracy = 0.1, decimal.mark = ",")(after_stat(y)), group = ano),  
               geom = "text", vjust = -0.7, 
               size = 4, 
               fontface = "bold", color = "black") + 
  scale_y_continuous(labels = label_number(scale = 1e-9, suffix = " bi"),  
                     expand = expansion(mult = c(0, 0.4))) + 
  scale_fill_manual(values = paleta_minC, na.translate = FALSE) + 
  labs(title = "Composição Detalhada do Gasto Federal Pleno", 
       subtitle = "Decomposição por Unidade Orçamentária (SIOP) e Renúncia Fiscal (Lei Rouanet/ANCINE)", 
       x = "Ano", y = "R$ Bilhões", fill = "Fonte", 
       caption = "Fonte: SIOP, SALIC e ANCINE. Rótulos superiores indicam o total anual empenhado + teto de renúncia.") + 
  tema_minC + 
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.text = element_text(size = 8))
ggsave(file.path(path_outputs_federal, "grafico_pleno_composicao.png"), plot = p3, width = 10, height = 6)


# V. DETALHAMENTO DA MATRIZ POR FONTE (DECOMPOSTO)
df_fontes_detalhado <- df_detalhado_reais %>%
  group_by(ano) %>%
  mutate(pct = valor / sum(valor, na.rm = TRUE)) %>%
  ungroup()

p4 <- ggplot(df_fontes_detalhado, aes(x = factor(ano), y = valor, fill = fonte)) +
  geom_col(position = "fill", width = 0.7, alpha = 0.9) +
  geom_text(aes(label = ifelse(pct > 0.02, percent(pct, accuracy = 0.1, decimal.mark = ","), "")), 
            position = position_fill(vjust = 0.5), 
            size = 2.5, fontface = "bold", color = "white") +
  scale_y_continuous(labels = percent_format()) +
  scale_fill_manual(values = paleta_minC, na.translate = FALSE) +
  labs(title = "Matriz de Financiamento por Fonte",
       x = "Ano", y = "Proporção do Investimento (%)", fill = "Fonte",
       caption = "Fonte: SIOP, SALIC e ANCINE") + 
  tema_minC + 
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.text = element_text(size = 8))
ggsave(file.path(path_outputs_federal, "grafico_pleno_matriz.png"), plot = p4, width = 10, height = 6)


# VI. IMPACTO FISCAL DO GASTO DIRETO (% DA RCL)
p5 <- ggplot(df_final %>% 
               mutate(perc_direto_rcl = (siop_direto / rcl) * 100) %>% 
               filter(!is.na(perc_direto_rcl)), 
             aes(x = ano, y = perc_direto_rcl)) +
  geom_line(color = "#2980b9", linewidth = 1.2) + 
  geom_point(color = "#2980b9", size = 2) +
  geom_text(aes(label = paste0(round(perc_direto_rcl, 3), "%")), 
            vjust = -1.5, size = 3, fontface = "bold") +
  scale_x_continuous(breaks = seq(min(df_final$ano), 2025, 1)) +
  scale_y_continuous(labels = label_number(suffix = "%"), 
                     expand = expansion(mult = c(0, 0.5))) +
  labs(title = "Gasto Federal Direto em Cultura como % da RCL",
       subtitle = "Participação da Execução Orçamentária (SIOP) na Receita Corrente Líquida da União",
       x = "Ano", y = "Percentual",
       caption = "Fonte: SIOP e Tesouro Nacional. Valores nominais.") + 
  tema_minC +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
ggsave(file.path(path_outputs_federal, "grafico_impacto_rcl.png"), plot = p5, width = 10, height = 6)


############################ VOLUME FINANCEIRO REAL ######################################

ipca_bruto <- get_series(433, start_date = "2003-01-01")

ipca_acum <- ipca_bruto %>%
  rename(data = date, mensal = `433`) %>%
  mutate(indice = cumprod(1 + mensal/100))

media_indice_2024 <- ipca_acum %>%
  filter(format(data, "%Y") == "2024") %>%
  summarise(m = mean(indice)) %>%
  pull(m)

tabela_fator <- ipca_acum %>%
  mutate(ano = as.numeric(format(data, "%Y"))) %>%
  group_by(ano) %>%
  summarise(indice_medio_ano = mean(indice)) %>%
  mutate(fator_correcao = media_indice_2024 / indice_medio_ano)

# VII. GASTO TOTAL PLENO POR INCUMBENTE (VALORES CORRENTES E REAIS)
df_incumbente_ajustado <- df_detalhado_reais %>%
  mutate(ano = as.numeric(ano),
         fonte = trimws(fonte)) %>%
  mutate(incumbente = case_when(fonte == "Lei Paulo Gustavo" & ano == 2022 ~ "Lula III",
                                ano == 2006 ~ "Lula I (Final)",
                                ano >= 2007 & ano <= 2010 ~ "Lula II",
                                ano >= 2011 & ano <= 2014 ~ "Dilma I",
                                ano == 2015 ~ "Dilma II",
                                ano >= 2016 & ano <= 2018 ~ "Temer",
                                ano >= 2019 & ano <= 2022 ~ "Bolsonaro",
                                ano >= 2023 ~ "Lula III")) %>%
  filter(!is.na(incumbente), ano >= 2006) %>%
  left_join(tabela_fator, by = "ano") %>%
  mutate(Real = valor * fator_correcao,
         Nominal = valor) %>%
  pivot_longer(cols = c(Nominal, Real), names_to = "tipo_valor", values_to = "valor_final") %>%
  group_by(incumbente, tipo_valor, fonte) %>%
  summarise(valor_final = sum(valor_final, na.rm = TRUE), .groups = "drop") %>%
  mutate(incumbente = factor(incumbente, levels = c(
    "Lula I (Final)", "Lula II", "Dilma I", "Dilma II", "Temer", "Bolsonaro", "Lula III")),
    tipo_valor = factor(tipo_valor, levels = c("Nominal", "Real")),
    fonte = factor(fonte, levels = names(paleta_minC)))

p6 <- ggplot(df_incumbente_ajustado, aes(x = tipo_valor, y = valor_final, fill = fonte)) +
  geom_col(position = "stack", width = 0.8, alpha = 0.9) +
  geom_text(aes(label = ifelse(valor_final > 3e8, 
                               label_number(scale = 1e-9, suffix = "b", accuracy = 0.1, decimal.mark = ",")(valor_final), "")),
            position = position_stack(vjust = 0.5), 
            color = "white", size = 2.4, fontface = "bold") +
  stat_summary(fun = sum, 
               aes(label = label_number(scale = 1e-9, suffix = " bi", accuracy = 0.1, decimal.mark = ",")(after_stat(y)), 
                   group = tipo_valor),
               geom = "text", vjust = -1, size = 3.2, fontface = "bold", color = "black") +
  facet_wrap(~incumbente, strip.position = "bottom", nrow = 1) +
  scale_y_continuous(labels = label_number(scale = 1e-9, suffix = " bi"),
                     expand = expansion(mult = c(0, 0.4))) +
  scale_fill_manual(values = paleta_minC) +
  labs(title = "Gasto Federal Pleno por Mandato: Nominal vs. Real",
       subtitle = "Teste Analítico: Lei Paulo Gustavo (2022) reclassificada para o ciclo de execução de Lula III",
       x = NULL, y = "R$ Bilhões (Acumulado)", fill = "Fonte") +
  tema_minC +
  theme(legend.position = "bottom",
        strip.placement = "outside",
        strip.text = element_text(face = "bold", size = 9),
        panel.spacing = unit(0.2, "lines"),
        axis.text.x = element_text(size = 7.5, face = "italic"))
ggsave(file.path(path_outputs_federal, "grafico_pleno_mandato.png"), plot = p6, width = 12, height = 6)


############################################# LPG EM 2023 ####################################

# VIII. EVOLUÇÃO ANUAL - VALORES NOMINAIS (LPG EM 2023)
df_anual_ajustado <- df_detalhado_reais %>%
  mutate(ano = as.numeric(ano),
         ano = ifelse(fonte == "Lei Paulo Gustavo" & ano == 2022, 2023, ano)) %>%
  group_by(ano, fonte) %>%
  summarise(valor = sum(valor, na.rm = TRUE), .groups = "drop") %>%
  left_join(tabela_fator, by = "ano") %>%
  mutate(valor_real = valor * fator_correcao,
         valor_nominal = valor) %>%
  mutate(fonte = factor(fonte, levels = names(paleta_minC)))

p7 <- ggplot(df_anual_ajustado, aes(x = factor(ano), y = valor_nominal, fill = fonte)) +
  geom_col(position = "stack", width = 0.7, alpha = 0.9) +
  geom_text(aes(label = ifelse(valor_nominal > 4e8, 
                               label_number(scale = 1e-9, suffix = "b", accuracy = 0.1, decimal.mark = ",")(valor_nominal), "")),
            position = position_stack(vjust = 0.5), 
            color = "white", size = 3.5, fontface = "bold") +
  stat_summary(fun = sum, 
               aes(label = label_number(scale = 1e-9, suffix = " bi", accuracy = 0.1, decimal.mark = ",")(after_stat(y)), group = ano),
               geom = "text", vjust = -0.7, size = 4.5, fontface = "bold", color = "black") +
  scale_y_continuous(labels = label_number(scale = 1e-9, suffix = " bi"), 
                     expand = expansion(mult = c(0, 0.4))) +
  scale_fill_manual(values = paleta_minC, na.translate = FALSE) +
  labs(title = "Evolução do Gasto Federal Pleno",
       subtitle = "Valores nominais",
       x = "Ano", y = "R$ Bilhões", fill = "Fonte",
       caption = "Fonte: SIOP, SALIC e ANCINE. Valores empenhados (direto) e teto/captado (indireto).") +
  tema_minC + 
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "top",
        legend.text = element_text(size = 9))
ggsave(file.path(path_outputs_federal, "grafico_pleno_evolucao_anual.png"), plot = p7, width = 10, height = 6)


# Matriz de Financiamento - LPG em 2023
df_percentual_ajustado <- df_anual_ajustado %>%
  group_by(ano) %>%
  mutate(pct = valor_nominal / sum(valor_nominal, na.rm = TRUE)) %>%
  ungroup()

p8 <- ggplot(df_percentual_ajustado, aes(x = factor(ano), y = pct, fill = fonte)) +
  geom_col(position = "fill", width = 0.7, alpha = 0.9) +
  geom_text(aes(label = ifelse(pct > 0.03, scales::percent(pct, accuracy = 0.1, decimal.mark = ","), "")), 
            position = position_fill(vjust = 0.5), 
            color = "white", size = 2.8, fontface = "bold") +
  scale_y_continuous(labels = scales::percent_format(decimal.mark = ","), 
                     expand = expansion(mult = c(0, 0.05))) +
  scale_fill_manual(values = paleta_minC, na.translate = FALSE) +
  labs(title = "Composição Percentual da Matriz de Financiamento Federal",
       subtitle = "Valores nominais",
       x = "Ano", y = "Percentual da Execução (%)", fill = "Fonte",
       caption = "Fonte: SIOP, SALIC e ANCINE. Obs: Gasto Federal Pleno") +
  tema_minC + 
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "top",
        legend.text = element_text(size = 8))
ggsave(file.path(path_outputs_federal, "grafico_matriz_lpg_2023.png"), plot = p8, width = 10, height = 6)


# Percentual da RCL - LPG em 2023
df_ajustado_rcl <- df_final %>%
  mutate(valor_lpg_2022 = ifelse(ano == 2022, 
                                 df_grafico_origem$valor_total[df_grafico_origem$ano == 2022 & 
                                                                 df_grafico_origem$categoria_origem == "Lei Paulo Gustavo"], 0),
         siop_direto_ajustado = case_when(ano == 2022 ~ siop_direto - valor_lpg_2022,
                                          ano == 2023 ~ siop_direto + valor_lpg_2022,
                                          TRUE ~ siop_direto),
         perc_direto_rcl = (siop_direto_ajustado / rcl) * 100) %>%
  filter(!is.na(perc_direto_rcl))

p9 <- ggplot(df_ajustado_rcl, aes(x = ano, y = perc_direto_rcl)) +
  geom_line(color = "#2980b9", linewidth = 1.2) + 
  geom_point(color = "#2980b9", size = 2.5) +
  geom_text(aes(label = paste0(round(perc_direto_rcl, 2), "%")), 
            vjust = -1.5, size = 3.5, fontface = "bold") +
  scale_x_continuous(breaks = seq(min(df_ajustado_rcl$ano), 2025, 1)) +
  scale_y_continuous(labels = label_number(suffix = "%", decimal.mark = ","), 
                     expand = expansion(mult = c(0, 0.5))) +
  labs(title = "Gasto Federal Direto em Cultura como % da RCL",
       subtitle = "Participação da Execução Orçamentária (SIOP) na RCL",
       x = "Ano", y = "% da Receita Corrente Líquida",
       caption = "Fonte: SIOP e Tesouro Nacional. Nota: Valores nominais.") + 
  tema_minC +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
ggsave(file.path(path_outputs_federal, "grafico_rcl_lpg_2023.png"), plot = p9, width = 10, height = 6)


# IX. EVOLUÇÃO ANUAL - VALORES REAIS (LPG EM 2023)
p10 <- ggplot(df_anual_ajustado, aes(x = factor(ano), y = valor_real, fill = fonte)) +
  geom_col(position = "stack", width = 0.7, alpha = 0.9) +
  geom_text(aes(label = ifelse(valor_real > 4e8, 
                               label_number(scale = 1e-9, suffix = "b", accuracy = 0.1, decimal.mark = ",")(valor_real), "")),
            position = position_stack(vjust = 0.5), 
            color = "white", size = 2.2, fontface = "bold") +
  stat_summary(fun = sum, 
               aes(label = label_number(scale = 1e-9, suffix = " bi", accuracy = 0.1, decimal.mark = ",")(after_stat(y)), group = ano),
               geom = "text", vjust = -0.7, size = 3, fontface = "bold", color = "black") +
  scale_y_continuous(labels = label_number(scale = 1e-9, suffix = " bi"), expand = expansion(mult = c(0, 0.4))) +
  scale_fill_manual(values = paleta_minC) +
  labs(title = "Evolução do Gasto Federal Pleno: Valores Reais",
       subtitle = "Série Histórica corrigida (IPCA 2024) | LPG alocada em 2023",
       x = "Ano", y = "R$ Bilhões (Preços de 2024)", fill = "Fonte") +
  tema_minC + theme(axis.text.x = element_text(angle = 45, hjust = 1))
ggsave(file.path(path_outputs_federal, "grafico_evolucao_real.png"), plot = p10, width = 10, height = 6)


# EXPORTAÇÃO DA BASE PROCESSADA
write_excel_csv2(df_anual_ajustado, file.path(path_processed_federal, "federal_final.csv"))
