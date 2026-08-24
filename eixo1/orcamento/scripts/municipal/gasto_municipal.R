#===============================================================================
# SCRIPT: EIXO 1 - ORÇAMENTO (MUNICIPAL INTEGRADO)
# SICONFI + DADOS BB ÁGIL (LAB 1) + MUNIC_FINAL (PORTE) + RCL (META PNC)
#
# INPUTS:
# - data/raw/municipal/municipios_parquet/*.parquet (Arquivos SICONFI Municipais)
# - data/raw/municipal/LAB1 - MUNIC/cubo_execucao_lab1_municipios_*.xlsx (Fonte: BB Ágil)
# - data/raw/municipal/MUNIC_FINAL.xlsx (Fonte: IBGE / MUNIC)
# - data/raw/municipal/RCL_*_Municipios.* (Arquivos SICONFI RCL Municipais)
# 
# OUTPUTS:
# - data/processed/municipal/municipal_final.csv
# - data/processed/municipal/Indicador_1_Meta_2_Porcento_RCL.csv
# - data/processed/municipal/Indicador_2_Centro_Oeste_Meta_RCL.csv
# - data/processed/municipal/Indicador_3_Niveis_Investimento_Série_Histórica.csv
# - data/processed/municipal/Indicador_4_Niveis_Investimento_por_Porte.csv
# - outputs/municipal/grafico_evolucao_nominal.png
# - outputs/municipal/grafico_evolucao_real.png
# - outputs/municipal/grafico_composicao_percentual.png
# - outputs/municipal/grafico_dispersao_interativo.html
# - outputs/municipal/grafico_sankey_interativo.html
# - outputs/municipal/grafico_cabo_guerra.png
# - outputs/municipal/grafico_porte_comportamental.png
#===============================================================================

# 0. CARREGAMENTO DE PACOTES E CONFIGURAÇÕES INICIAIS --------------------------
library(tidyverse)
library(arrow)
library(scales)
library(gt)
library(janitor)
library(purrr)
library(rbcb)
library(readxl)
library(geobr)
library(sf)
library(stringi)
library(leaflet)
library(writexl)
library(plotly)
library(ggrepel)
library(htmlwidgets)
library(here)

options(timeout = 1000)
options(download.file.method = "libcurl")
options(scipen = 999)

# Definição dos Caminhos de Arquivos via here() (.Rproj na pasta orcamento)
path_base_siconfi <- here("data", "raw", "municipal")
path_base_bb      <- here("data", "raw", "municipal")
path_pai_rcl      <- here("data", "raw", "municipal")
path_munic        <- here("data", "raw", "municipal", "MUNIC_FINAL.xlsx")

path_processed_municipal <- here("data", "processed", "municipal")
path_outputs_municipal   <- here("outputs", "municipal")

# Cria as pastas de saída caso não existam
dir.create(path_processed_municipal, recursive = TRUE, showWarnings = FALSE)
dir.create(path_outputs_municipal, recursive = TRUE, showWarnings = FALSE)

# Paleta e Códigos Padrão (Sem erros de encoding)
paleta_cores <- c(
  "Recurso Próprio (Municipal)"       = "#1b2631", 
  "Emendas Parlamentares (Cultura)"   = "#27ae60", 
  "Lei Aldir Blanc 1 (LAB 1)"         = "#8e44ad",
  "Lei Paulo Gustavo (LPG)"           = "#e67e22", 
  "PNAB (Aldir Blanc 2)"              = "#f1c40f"
)

codigos_emendas <- c("3101", "3110", "3111", "3120", "3121", "3130", "3140", 
                     "3201", "3202", "3210", "3211", "3220", "3221")

# 1. CARREGAMENTO DO DEFLATOR (IPCA) E DA MUNIC_FINAL --------------------------

# 1.1 IPCA (Base 2024)
ipca_mensal <- rbcb::get_series(433, start_date = "2019-01-01", end_date = "2025-12-31")

fatores_ipca <- ipca_mensal %>%
  clean_names() %>% rename(var_mensal = x433) %>%
  mutate(ano = as.numeric(format(date, "%Y")),
         indice_encadeado = cumprod(1 + (var_mensal / 100))) %>%
  group_by(ano) %>% summarise(indice_medio_ano = mean(indice_encadeado), .groups = "drop") %>%
  mutate(indice_base = indice_medio_ano[ano == 2024],
         fator_deflacao = indice_base / indice_medio_ano) %>%
  select(exercicio = ano, fator_deflacao)

# 1.2 MUNIC_FINAL (Base com Porte Populacional e Região)
if (!file.exists(path_munic)) {
  stop("ERRO: O arquivo 'MUNIC_FINAL.xlsx' não foi encontrado em data/raw/municipal/.")
}

df_munic_final <- read_excel(path_munic) %>%
  clean_names() %>%
  mutate(codigo_ibge = as.character(cod_ibge)) %>%
  select(codigo_ibge, regiao_munic = regiao, porte_populacional = porte, populacao = populacao) %>%
  distinct(codigo_ibge, .keep_all = TRUE)

# 2. PROCESSAMENTO SICONFI (SEM A LAB 1) ---------------------------------------
arquivos <- list.files(path_base_siconfi, pattern = "\\.parquet$", full.names = TRUE)

df_municipios_bruto <- arquivos %>% map_dfr(function(arq) {
  tryCatch({
    read_parquet(arq) %>% clean_names() %>%
      mutate(across(any_of(c("fonte_recursos", "complemento_fonte", "conta_contabil", "funcao")), as.character)) %>%
      filter(natureza_conta == "C") %>%
      mutate(id_funcao = as.numeric(str_extract(funcao, "\\d+"))) %>%
      filter(id_funcao == 13) %>%
      select(exercicio, uf, fonte_recursos, conta_contabil, complemento_fonte, valor)
  }, error = function(e) return(NULL))
})

df_municipios_siconfi <- df_municipios_bruto %>%
  mutate(exercicio = as.numeric(exercicio),
         valor = abs(valor), 
         conta_limpa = str_remove_all(conta_contabil, "\\."),
         fonte_string = str_remove_all(as.character(fonte_recursos), "\\."),
         complemento_limpo = str_pad(str_remove_all(complemento_fonte, "[^0-9]"), 4, pad = "0")) %>%
  filter(str_starts(conta_limpa, "62213")) %>%
  separate(uf, into = c("municipio", "uf_sigla"), sep = "_(?=[^_]+$)", fill = "right") %>%
  filter(uf_sigla != "DF") %>%
  mutate(origem = case_when(
    str_detect(fonte_string, "^1719|^2719|^1720|^2720|^719|^720") ~ "PNAB (Aldir Blanc 2)",
    str_detect(fonte_string, "^1715|^2715|^1716|^2716|^715|^716") ~ "Lei Paulo Gustavo (LPG)",
    complemento_limpo %in% codigos_emendas ~ "Emendas Parlamentares (Cultura)",
    TRUE ~ "Recurso Próprio (Municipal)")) %>%
  filter(!is.na(origem)) %>%
  group_by(exercicio, municipio, uf_sigla, origem) %>%
  summarise(valor_nominal_final = sum(valor, na.rm = TRUE), .groups = "drop")

# 3. IMPORTAÇÃO E PROCESSAMENTO DA LAB 1 (BB ÁGIL) -----------------------------
arquivo_lab <- list.files(path = path_base_bb, pattern = "^cubo_execucao_lab1_municipios.*\\.xlsx$", full.names = TRUE)[1]

if (is.na(arquivo_lab) || !file.exists(arquivo_lab)) {
  stop("ERRO: O arquivo da LAB 1 (cubo_execucao_lab1_municipios_*.xlsx) não foi encontrado em data/raw/municipal/LAB1 - MUNIC/.")
}

df_lab1_bruto <- read_excel(arquivo_lab, sheet = "Dados") %>%
  clean_names()

df_lab1_agrupado <- df_lab1_bruto %>%
  filter(is.na(credit_debit_indicator) | credit_debit_indicator != "C") %>% 
  mutate(data_referencia = coalesce(as.character(booking_date), as.character(payment_date), as.character(ano_mes)),
         exercicio = as.numeric(str_extract(data_referencia, "\\d{4}")),
         codigo_ibge = as.character(codigo_ibge_municipio_ente_recebedor_plano_acao)) %>%
  filter(!is.na(exercicio)) %>%
  group_by(exercicio, 
           codigo_ibge,
           municipio = nome_municipio_ente_recebedor_plano_acao, 
           uf_sigla = uf_ente_recebedor_plano_acao) %>%
  summarise(valor_nominal_final = sum(value, na.rm = TRUE), .groups = "drop") %>%
  mutate(origem = "Lei Aldir Blanc 1 (LAB 1)")

# 3.5 PONTE DE DADOS ------------------------
malha_municipios <- jsonlite::fromJSON("https://servicodados.ibge.gov.br/api/v1/localidades/municipios")

dic_ibge_completo <- malha_municipios %>%
  mutate(codigo_ibge = as.character(id),
         municipio = nome,
         uf_sigla = microrregiao$mesorregiao$UF$sigla) %>%
  select(codigo_ibge, municipio, uf_sigla) %>%
  mutate(municipio_limpo = str_trim(toupper(stri_trans_general(municipio, "Latin-ASCII"))),
         chave_join = paste0(municipio_limpo, "_", toupper(uf_sigla)))

df_municipios_siconfi <- df_municipios_siconfi %>%
  mutate(municipio_limpo = str_trim(toupper(stri_trans_general(municipio, "Latin-ASCII"))),
         chave_join = paste0(municipio_limpo, "_", toupper(uf_sigla))) %>%
  left_join(dic_ibge_completo %>% select(chave_join, codigo_ibge), by = "chave_join") %>%
  select(-chave_join, -municipio_limpo)

df_municipios_final <- bind_rows(df_municipios_siconfi, df_lab1_agrupado) %>%
  mutate(municipio = str_trim(toupper(stri_trans_general(municipio, "Latin-ASCII"))),
         origem = factor(origem, levels = names(paleta_cores))) %>%
  left_join(fatores_ipca, by = "exercicio") %>%
  left_join(df_munic_final, by = "codigo_ibge") %>%
  mutate(valor_real_final = valor_nominal_final * fator_deflacao) %>%
  filter(!is.na(valor_real_final))

# Salva a base consolidada municipal
write.csv2(df_municipios_final, file.path(path_processed_municipal, "municipal_final.csv"), row.names = FALSE)

#===============================================================================
# 5. VISUALIZAÇÕES E GRÁFICOS
#===============================================================================

# 5.1 Tabela de Conferência
df_conferencia_totais <- df_municipios_final %>%
  group_by(origem) %>%
  summarise(valor_total_exato = sum(valor_nominal_final, na.rm = TRUE)) %>%
  mutate(percentual = valor_total_exato / sum(valor_total_exato)) %>%
  arrange(desc(valor_total_exato))

tabela_conferencia_nt <- df_conferencia_totais %>%
  gt() %>%
  tab_header(title = md("**Total de Investimento Cultural Municipal por Fonte (2019-2025)**"),
             subtitle = "Valores Nominais Empenhados Acumulados") %>%
  cols_label(origem = "Fonte de Financiamento",
             valor_total_exato = "Valor Total Acumulado (R$)",
             percentual = "Participação (%)") %>%
  fmt_currency(columns = valor_total_exato, currency = "BRL", dec_mark = ",", sep_mark = ".", decimals = 2) %>%
  fmt_percent(columns = percentual, decimals = 2, dec_mark = ",", sep_mark = ".") %>%
  grand_summary_rows(columns = valor_total_exato, fns = list("TOTAL GERAL" = ~sum(., na.rm = TRUE)),
                     fmt = ~ fmt_currency(., currency = "BRL", dec_mark = ",", sep_mark = ".", decimals = 2)) %>%
  grand_summary_rows(columns = percentual, fns = list("TOTAL GERAL" = ~sum(., na.rm = TRUE)),
                     fmt = ~ fmt_percent(., decimals = 2, dec_mark = ",", sep_mark = ".")) %>%
  tab_source_note(source_note = "Fonte: Ministério da Cultura / SICONFI e BB Ágil. Elaboração: Cultura em Números (2026).") %>%
  tab_options(heading.title.font.size = px(15), heading.subtitle.font.size = px(12),
              column_labels.font.weight = "bold", column_labels.background.color = "#f2f4f4",
              grand_summary_row.background.color = "#eaeded", grand_summary_row.text_transform = "uppercase",
              table.border.top.color = "#1b2631", table.font.size = px(13))

tabela_conferencia_nt

# 5.2 Gráfico 1: Evolução Nominal
df_resumo_grafico <- df_municipios_final %>%
  group_by(exercicio, origem) %>%
  summarise(valor = sum(valor_nominal_final, na.rm = TRUE), .groups = "drop")

g1 <- ggplot(df_resumo_grafico, aes(x = factor(exercicio), y = valor, fill = origem)) +
  geom_col(position = position_stack(), width = 0.7, alpha = 0.9) +
  geom_text(aes(label = ifelse(valor > 0.05e9, label_number(scale = 1e-9, suffix = "b", accuracy = 0.1, decimal.mark = ",")(valor), "")), 
            position = position_stack(vjust = 0.5), color = "white", fontface = "bold", size = 2.8) +
  stat_summary(fun = sum, aes(label = label_number(scale = 1e-9, suffix = " bi", accuracy = 0.1, decimal.mark = ",")(after_stat(y)), group = exercicio), 
               geom = "text", vjust = -1.2, size = 3.8, fontface = "bold") +
  scale_y_continuous(labels = label_number(prefix = "R$ ", scale = 1e-9, suffix = " bi", accuracy = 0.1, decimal.mark = ","), expand = expansion(mult = c(0, 0.4))) +
  scale_fill_manual(values = paleta_cores, na.translate = FALSE) +
  labs(title = "Evolução do Investimento Cultural Municipal por Fonte | Valores nominais",
       subtitle = "Valores Empenhados Totais | R$ Bilhões", x = "Ano de Execução", y = "Valor Empenhado", fill = "Origem do Recurso",
       caption = "Fonte: MSC/SICONFI e BB Ágil. Análise: Cultura em Números (2026).") +
  theme_minimal() + 
  theme(legend.position = "bottom", plot.title = element_text(face="bold", size = 14), axis.text.x = element_text(face="bold"))
ggsave(file.path(path_outputs_municipal, "grafico_evolucao_nominal.png"), plot = g1, width = 10, height = 6)

# 5.3 Gráfico 2: Evolução Real (Base 2024)
df_resumo_real <- df_municipios_final %>%
  group_by(exercicio, origem) %>%
  summarise(valor = sum(valor_real_final, na.rm = TRUE), .groups = "drop")

g2 <- ggplot(df_resumo_real, aes(x = factor(exercicio), y = valor, fill = origem)) +
  geom_col(position = position_stack(), width = 0.7, alpha = 0.9) +
  geom_text(aes(label = ifelse(valor > 0.01e9, label_number(scale = 1e-9, suffix = "b", accuracy = 0.01, decimal.mark = ",")(valor), "")), 
            position = position_stack(vjust = 0.5), color = "white", fontface = "bold", size = 2.8) +
  stat_summary(fun = sum, aes(label = label_number(scale = 1e-9, suffix = " bi", accuracy = 0.1, decimal.mark = ",")(after_stat(y)), group = exercicio), 
               geom = "text", vjust = -1.2, size = 3.8, fontface = "bold") +
  scale_y_continuous(labels = label_number(prefix = "R$ ", scale = 1e-9, suffix = " bi", accuracy = 0.1, decimal.mark = ","), expand = expansion(mult = c(0, 0.4))) +
  scale_fill_manual(values = paleta_cores, na.translate = FALSE) +
  labs(title = "Evolução do Investimento Cultural Municipal por Fonte (Valores Reais)",
       subtitle = "Valores Empenhados Corrigidos pela Inflação (Preços Médios de 2024) | R$ Bilhões",
       x = "Ano de Execução", y = "Valor Empenhado Real (R$ Bilhões)", fill = "Origem do Recurso",
       caption = "Fonte: MSC/SICONFI e BB Ágil. Deflação: IPCA/SGS-BCB. Ano-base: 2024.") +
  theme_minimal() + 
  theme(legend.position = "bottom", plot.title = element_text(face="bold", size = 14), axis.text.x = element_text(face="bold"), panel.grid.minor = element_blank())
ggsave(file.path(path_outputs_municipal, "grafico_evolucao_real.png"), plot = g2, width = 10, height = 6)

# 5.4 Gráfico 3: Composição Percentual
df_resumo_percentual <- df_municipios_final %>%
  group_by(exercicio, origem) %>%
  summarise(valor_ano_fonte = sum(valor_real_final, na.rm = TRUE), .groups = "drop_last") %>%
  mutate(participacao = valor_ano_fonte / sum(valor_ano_fonte)) %>%
  ungroup()

g3 <- ggplot(df_resumo_percentual, aes(x = factor(exercicio), y = participacao, fill = origem)) +
  geom_col(position = position_stack(), width = 0.7, alpha = 0.9) +
  geom_text(aes(label = ifelse(participacao > 0.02, label_percent(accuracy = 0.1, decimal.mark = ",")(participacao), "")), 
            position = position_stack(vjust = 0.5), color = "white", fontface = "bold", size = 2.8) +
  scale_y_continuous(labels = label_percent(decimal.mark = ","), expand = expansion(mult = c(0, 0.05))) +
  scale_fill_manual(values = paleta_cores, na.translate = FALSE) +
  labs(title = "Composição Percentual do Investimento Cultural Municipal por Fonte",
       subtitle = "Participação Relativa das Fontes sobre o Investimento Real Empenhado (Base 2024)",
       x = "Ano de Execução", y = "Percentual (%)", fill = "Origem do Recurso",
       caption = "Fonte: MSC/SICONFI e BB Ágil. Deflação: IPCA/SGS-BCB (2024).") +
  theme_minimal() + 
  theme(legend.position = "bottom", 
        plot.title = element_text(face = "bold", size = 14),
        axis.text.x = element_text(face = "bold"), 
        panel.grid.minor = element_blank(), 
        panel.grid.major.x = element_blank())
ggsave(file.path(path_outputs_municipal, "grafico_composicao_percentual.png"), plot = g3, width = 10, height = 6)


#===============================================================================
# 6. ANÁLISE DE CLUSTER TEMPORAL (K-MEANS) - RECURSOS PRÓPRIOS (2020-2024)
#===============================================================================
df_temporal_base <- df_municipios_final %>%
  filter(exercicio >= 2020 & exercicio <= 2024,
         !is.na(codigo_ibge), 
         !is.na(populacao), 
         populacao > 0,
         str_starts(as.character(origem), "Recurso")) %>%
  group_by(codigo_ibge, municipio, uf_sigla, exercicio) %>%
  summarise(valor_proprio = sum(valor_real_final, na.rm = TRUE),
            populacao_ano = mean(populacao, na.rm = TRUE),
            .groups = "drop") %>%
  mutate(pc_proprio = valor_proprio / populacao_ano)

df_cidades_estatico <- df_temporal_base %>%
  group_by(codigo_ibge, municipio, uf_sigla) %>%
  summarise(populacao_media = mean(populacao_ano, na.rm = TRUE), .groups = "drop") %>%
  mutate(regiao = case_when(uf_sigla %in% c("AM", "RR", "AP", "PA", "TO", "RO", "AC") ~ "Norte",
                            uf_sigla %in% c("MA", "PI", "CE", "RN", "PB", "PE", "AL", "SE", "BA") ~ "Nordeste",
                            uf_sigla %in% c("MT", "MS", "GO", "DF") ~ "Centro-Oeste",
                            uf_sigla %in% c("SP", "RJ", "MG", "ES") ~ "Sudeste",
                            uf_sigla %in% c("PR", "SC", "RS") ~ "Sul",
                            TRUE ~ "Outros"),
         porte_populacional = case_when(populacao_media <= 5000 ~ "Até 5.000",
                                        populacao_media <= 10000 ~ "5.001 a 10.000",
                                        populacao_media <= 20000 ~ "10.001 a 20.000",
                                        populacao_media <= 50000 ~ "20.001 a 50.000",
                                        populacao_media <= 100000 ~ "50.001 a 100.000",
                                        populacao_media <= 500000 ~ "100.001 a 500.000",
                                        TRUE ~ "Mais de 500.000"),
         porte_populacional = factor(porte_populacional, levels = c("Até 5.000", "5.001 a 10.000", "10.001 a 20.000", 
                                                                    "20.001 a 50.000", "50.001 a 100.000", "100.001 a 500.000", "Mais de 500.000")))

df_trajetoria_wide <- df_temporal_base %>%
  select(codigo_ibge, exercicio, pc_proprio) %>%
  pivot_wider(names_from = exercicio, 
              values_from = pc_proprio, 
              values_fill = 0,
              names_prefix = "pc_") %>%
  left_join(df_cidades_estatico, by = "codigo_ibge") %>%
  filter(pc_2020 <= 500, pc_2021 <= 500, pc_2022 <= 500, pc_2023 <= 500, pc_2024 <= 500)

matriz_trajetoria <- df_trajetoria_wide %>%
  select(pc_2020, pc_2021, pc_2022, pc_2023, pc_2024) %>%
  as.matrix()

matriz_scaled <- scale(matriz_trajetoria)

set.seed(123)
modelo_kmeans_temp <- kmeans(matriz_scaled, centers = 3, nstart = 25)

df_trajetoria_wide$cluster_id <- as.factor(modelo_kmeans_temp$cluster)

resumo_temp_clusters <- df_trajetoria_wide %>%
  group_by(cluster_id) %>%
  summarise(m_2020 = mean(pc_2020),
            m_2021 = mean(pc_2021),
            m_2022 = mean(pc_2022),
            m_2023 = mean(pc_2023),
            m_2024 = mean(pc_2024),
            media_geral = (m_2020 + m_2021 + m_2022 + m_2023 + m_2024) / 5,
            .groups = "drop") %>%
  arrange(desc(media_geral)) %>%
  mutate(Perfil_Temporal = c("1. Trajetória de Alto Investimento Próprio",
                             "2. Trajetória de Médio Investimento Próprio",
                             "3. Trajetória de Baixo Investimento"))

df_cluster_longitudinal <- df_trajetoria_wide %>%
  left_join(resumo_temp_clusters %>% select(cluster_id, Perfil_Temporal), by = "cluster_id")

df_trajetorias_long <- df_cluster_longitudinal %>%
  pivot_longer(cols = starts_with("pc_"), 
               names_to = "ano", 
               names_prefix = "pc_", 
               values_to = "pc_proprio") %>%
  mutate(ano = as.numeric(ano))

# Visualização 1
df_media_trajetoria <- df_trajetorias_long %>%
  group_by(Perfil_Temporal, ano) %>%
  summarise(pc_medio = mean(pc_proprio), .groups = "drop")

ggplot(df_media_trajetoria, aes(x = ano, y = pc_medio, color = Perfil_Temporal, group = Perfil_Temporal)) +
  geom_line(linewidth = 1.3) +
  geom_point(size = 3.5) +
  scale_y_continuous(limits = c(0, NA),
                     labels = label_number(prefix = "R$ ", decimal.mark = ",")) +
  scale_color_viridis_d(option = "turbo", direction = -1) +
  labs(title = "Evolução Temporal do Esforço Fiscal Próprio em Cultura (2020-2024)",
       subtitle = "Trajetória média do investimento municipal per capita por perfil comportamental",
       x = "Ano de Exercício",
       y = "Investimento Próprio (R$/hab)",
       color = "Perfil Temporal:",
       caption = "Algoritmo: K-Means Longitudinal. Fonte: SICONFI. Elaboração: Cultura em Números (2026).") +
  theme_minimal() +
  theme(legend.position = "bottom",
        legend.direction = "vertical",
        plot.title = element_text(face = "bold", size = 14),
        axis.text = element_text(face = "bold"))

# Visualização 2
df_volume_financeiro <- df_temporal_base %>%
  left_join(df_cluster_longitudinal %>% select(codigo_ibge, Perfil_Temporal), by = "codigo_ibge") %>%
  filter(!is.na(Perfil_Temporal)) %>%
  group_by(ano = exercicio, Perfil_Temporal) %>%
  summarise(volume_total = sum(valor_proprio, na.rm = TRUE), .groups = "drop") %>%
  group_by(ano) %>%
  mutate(pct_volume = volume_total / sum(volume_total)) %>%
  ungroup()

ggplot(df_volume_financeiro, aes(x = as.factor(ano), y = pct_volume, fill = Perfil_Temporal)) +
  geom_col(position = "fill", width = 0.7, alpha = 0.9) +
  geom_text(aes(label = ifelse(pct_volume > 0.03, label_percent(accuracy = 0.1, decimal.mark = ",")(pct_volume), "")),
            position = position_fill(vjust = 0.5), color = "white", fontface = "bold", size = 3.5) +
  scale_y_continuous(labels = label_percent(decimal.mark = ","), expand = expansion(mult = c(0, 0.05))) +
  scale_fill_viridis_d(option = "turbo", direction = -1) +
  labs(title = "Participação no Volume Financeiro Nacional (2020-2024)",
       subtitle = "Fatia do montante global de recursos Próprios executada por cada perfil",
       x = "Ano de Exercício",
       y = "Proporção do Montante Nacional (%)",
       fill = "Perfil Temporal:",
       caption = "Fonte: SICONFI. Elaboração: Cultura em Números (2026).") +
  theme_minimal() +
  theme(legend.position = "bottom",
        legend.direction = "vertical",
        plot.title = element_text(face = "bold", size = 14),
        axis.text = element_text(face = "bold"))

# Visualização 3
df_porte_cluster <- df_cluster_longitudinal %>%
  filter(!is.na(porte_populacional)) %>%
  group_by(porte_populacional, Perfil_Temporal) %>%
  summarise(n = n(), .groups = "drop_last") %>%
  mutate(pct = n / sum(n))

ggplot(df_porte_cluster, aes(x = porte_populacional, y = pct, fill = Perfil_Temporal)) +
  geom_col(position = "fill", width = 0.7, alpha = 0.9) +
  geom_text(aes(label = ifelse(pct > 0.05, label_percent(accuracy = 0.1, decimal.mark = ",")(pct), "")),
            position = position_fill(vjust = 0.5), color = "white", fontface = "bold", size = 3.2) +
  scale_y_continuous(labels = label_percent(decimal.mark = ","), expand = expansion(mult = c(0, 0.05))) +
  scale_fill_viridis_d(option = "turbo", direction = -1) +
  coord_flip() +
  labs(title = "Comportamento do Esforço Próprio por Porte Populacional (2020-2024)",
       subtitle = "Distribuição das Trajetórias temporais de investimento Próprio conforme o porte do Município",
       x = "Porte Populacional",
       y = "Proporção de Municípios (%)",
       fill = "Perfil Temporal",
       caption = "Fonte: SICONFI. Elaboração: Cultura em Números (2026).") +
  theme_minimal() +
  theme(legend.position = "bottom",
        legend.direction = "vertical",
        plot.title = element_text(face = "bold", size = 13),
        axis.text.y = element_text(face = "bold"))

# Visualização 4
df_regiao_cluster <- df_cluster_longitudinal %>%
  filter(!is.na(regiao), regiao != "Outros") %>%
  group_by(regiao, Perfil_Temporal) %>%
  summarise(n = n(), .groups = "drop_last") %>%
  mutate(pct = n / sum(n))

ggplot(df_regiao_cluster, aes(x = regiao, y = pct, fill = Perfil_Temporal)) +
  geom_col(position = "fill", width = 0.7, alpha = 0.9) +
  geom_text(aes(label = ifelse(pct > 0.05, label_percent(accuracy = 0.1, decimal.mark = ",")(pct), "")),
            position = position_fill(vjust = 0.5), color = "white", fontface = "bold", size = 3.2) +
  scale_y_continuous(labels = label_percent(decimal.mark = ","), expand = expansion(mult = c(0, 0.05))) +
  scale_fill_viridis_d(option = "turbo", direction = -1) +
  labs(title = "Comportamento do Esforço Próprio por Região do Brasil (2020-2024)",
       subtitle = "Distribuição das Trajetórias temporais de investimento Próprio por Macro-Região",
       x = "Macro-Região",
       y = "Proporção de Municípios (%)",
       fill = "Perfil Temporal",
       caption = "Fonte: SICONFI. Elaboração: Cultura em Números (2026).") +
  theme_minimal() +
  theme(legend.position = "bottom",
        legend.direction = "vertical",
        plot.title = element_text(face = "bold", size = 13),
        axis.text = element_text(face = "bold"))

#===============================================================================
# 7. ANÁLISE COMPORTAMENTAL: EFEITO INDUTOR VS SUBSTITUIÇÃO (2020 vs 2023-2024)
#===============================================================================
taxa_pct <- 0.20
k_abs <- 5.00

legenda_criterios <- sprintf("Critério de Classificação: Variação da Trajetória (> %.0f%% + R$ %.2f de margem). Fonte: SICONFI.", taxa_pct*100, k_abs)

df_transicao <- df_municipios_final %>%
  filter(exercicio %in% c(2020, 2023, 2024),
         !is.na(codigo_ibge), !is.na(populacao), populacao > 0,
         str_starts(as.character(origem), "Recurso")) %>%
  group_by(codigo_ibge, municipio, uf_sigla, regiao_munic, porte_populacional, exercicio) %>%
  summarise(pc_proprio = sum(valor_real_final, na.rm = TRUE) / mean(populacao, na.rm = TRUE),
            .groups = "drop") %>%
  pivot_wider(names_from = exercicio, 
              values_from = pc_proprio, 
              values_fill = 0, 
              names_prefix = "ano_") %>%
  mutate(media_pos = (ano_2023 + ano_2024) / 2,
         status_antes = ifelse(ano_2020 > 0, "Investia (> R$ 0)", "Nao Investia (R$ 0)"),
         status_depois = ifelse(media_pos > 0, "Investe (> R$ 0)", "Nao Investe (R$ 0)"),
         # Teto do Corredor Híbrido calculado como (ano_2020 * 1.20) + 5.00
         limite_superior = (ano_2020 * (1 + taxa_pct)) + k_abs,
         # Piso do Corredor Híbrido calculado como (ano_2020 * 0.80) - 5.00
         limite_inferior = (ano_2020 * (1 - taxa_pct)) - k_abs,
         perfil_mudanca = case_when(ano_2020 == 0 & media_pos == 0 ~ "3. Inertes (Dependência Exclusiva)",
                                    media_pos > limite_superior ~ "1. Despertados (Efeito Indutor)",
                                    media_pos < limite_inferior ~ "4. Efeito Substituição (Retração Local)",
                                    TRUE ~ "2. Constantes (Sustentabilidade)"))

resumo_mudanca <- df_transicao %>%
  group_by(perfil_mudanca) %>%
  summarise(Qtd_Municipios = n(), .groups = "drop") %>%
  mutate(Percentual = (Qtd_Municipios / sum(Qtd_Municipios)) * 100) %>%
  arrange(perfil_mudanca)

print(resumo_mudanca)

# 7.4 IDENTIFICAÇÃO NOMINAL DOS MUNICÍPIOS POR PERFIL
df_exportacao_comportamento <- df_transicao %>%
  select(`Código IBGE` = codigo_ibge, `UF` = uf_sigla, `Município` = municipio, `Macro-Região` = regiao_munic,
         `Porte Populacional` = porte_populacional, `Perfil de Transição` = perfil_mudanca,
         `Gasto Per Capita (2020)` = ano_2020, `Média Per Capita (2023-2024)` = media_pos) %>%
  arrange(`Perfil de Transição`, UF, `Município`)

# 7.6 MAPA DE DISPERSÃO: IDENTIFICAÇÃO DOS MUNICÍPIOS
df_dispersao <- df_transicao %>% filter(ano_2020 <= 200 & media_pos <= 200)

df_dispersao <- df_dispersao %>%
  mutate(rotulo = ifelse((str_starts(perfil_mudanca, "1") & media_pos > quantile(media_pos, 0.98)) |
                           (str_starts(perfil_mudanca, "4") & ano_2020 > quantile(ano_2020, 0.98)),
                         paste0(municipio, "-", uf_sigla), ""),
         texto_interativo = paste("Município:", municipio, "-", uf_sigla, 
                                  "<br>Porte:", porte_populacional, 
                                  "<br>Gasto 2020: R$", round(ano_2020, 2), 
                                  "<br>Gasto 23/24: R$", round(media_pos, 2)))

grafico_dispersao <- ggplot(df_dispersao, aes(x = ano_2020, y = media_pos, color = perfil_mudanca, text = texto_interativo)) +
  geom_point(alpha = 0.6, size = 2.5) +
  geom_abline(intercept = 0, slope = 1, linetype = "solid", color = "gray20", linewidth = 0.8) + 
  # Linhas explícitas do Teto e Piso do Corredor Híbrido
  geom_abline(intercept = k_abs, slope = 1 + taxa_pct, linetype = "dashed", color = "gray50", linewidth = 0.8) +
  geom_abline(intercept = -k_abs, slope = 1 - taxa_pct, linetype = "dashed", color = "gray50", linewidth = 0.8) +
  ggrepel::geom_text_repel(aes(label = rotulo), size = 3, show.legend = FALSE, max.overlaps = 15, color = "black") +
  scale_color_manual(values = c("1. Despertados (Efeito Indutor)" = "#27ae60", 
                                "2. Constantes (Sustentabilidade)" = "#2980b9",
                                "3. Inertes (Dependência Exclusiva)" = "#7f8c8d", 
                                "4. Efeito Substituição (Retração Local)" = "#c0392b")) +
  labs(title = "Dispersão do Esforço Fiscal Próprio: 2020 vs 2023-2024",
       subtitle = sprintf("Corredor Híbrido: Teto = (2020 * 1.20) + 5.00 | Piso = (2020 * 0.80) - 5.00"),
       x = "Investimento Próprio Per Capita em 2020 (R$)", 
       y = "Investimento Próprio Médio Per Capita 23/24 (R$)", 
       color = "Perfil Comportamental:",
       caption = legenda_criterios) +
  theme_minimal() + 
  theme(legend.position = "bottom", plot.title = element_text(face = "bold", size = 14))

grafico_interativo <- plotly::ggplotly(grafico_dispersao, tooltip = "text")
print(grafico_interativo)

saveWidget(widget = grafico_interativo, 
           file = file.path(path_outputs_municipal, "grafico_dispersao_interativo.html"), 
           selfcontained = TRUE)

df_dispersao %>%
  select(codigo_ibge, municipio, uf_sigla, porte_populacional, ano_2020, media_pos, perfil_mudanca) %>%
  write_excel_csv2(file.path(path_processed_municipal, "grafico_dispersao_dados.csv"))

# 7.7 BALANÇO LÍQUIDO DA POLÍTICA PÚBLICA (CABO DE GUERRA)
df_balanco_liquido <- df_transicao %>%
  group_by(regiao_munic) %>%
  summarise(pct_indutor = mean(perfil_mudanca == "1. Despertados (Efeito Indutor)") * 100,
            pct_substituicao = mean(perfil_mudanca == "4. Efeito Substituição (Retração Local)") * -100, 
            .groups = "drop") %>%
  pivot_longer(cols = c(pct_indutor, pct_substituicao), names_to = "Efeito", values_to = "Valor") %>%
  mutate(Efeito = ifelse(Efeito == "pct_indutor", "Efeito Indutor (+)", "Efeito Substituição (-)"))

write_excel_csv2(df_balanco_liquido, file.path(path_processed_municipal, "balanco_liquido_efeitos.csv"))

grafico_cabo_guerra <- ggplot(df_balanco_liquido, aes(x = reorder(regiao_munic, Valor, FUN = max), y = Valor, fill = Efeito)) +
  geom_col(width = 0.6, alpha = 0.9) +
  geom_text(aes(label = sprintf("%.1f%%", abs(Valor)), 
                hjust = ifelse(Valor > 0, -0.2, 1.2)), 
            fontface = "bold", size = 3.5) +
  geom_hline(yintercept = 0, color = "black", linewidth = 1) + 
  coord_flip() +
  scale_y_continuous(labels = function(x) paste0(abs(x), "%"), 
                     limits = c(min(df_balanco_liquido$Valor) * 1.3, max(df_balanco_liquido$Valor) * 1.3)) +
  scale_fill_manual(values = c("Efeito Indutor (+)" = "#27ae60", "Efeito Substituição (-)" = "#c0392b")) +
  labs(title = "O 'Cabo de Guerra' da Política Cultural (Saldo Líquido)",
       subtitle = "Municípios que aceleraram aportes (Verde) vs Os que desinvestiram (Vermelho)",
       x = "Macro-Região", y = "Proporção da Rede Municipal (%)", fill = "Dinâmica de Repasse:",
       caption = legenda_criterios) +
  theme_minimal() + 
  theme(legend.position = "bottom", plot.title = element_text(face = "bold", size = 14), 
        axis.text = element_text(face = "bold"), panel.grid.minor = element_blank())

# Renderização explícita do gráfico do Cabo de Guerra
print(grafico_cabo_guerra)
ggsave(file.path(path_outputs_municipal, "grafico_cabo_guerra.png"), plot = grafico_cabo_guerra, width = 10, height = 6)

# 7.8 O IMPACTO DEMOGRÁFICO: TRANSIÇÃO POR PORTE POPULACIONAL (PERFIL COMPORTAMENTAL)
df_grafico_porte <- df_transicao %>%
  filter(!is.na(porte_populacional)) %>%
  group_by(porte_populacional, perfil_mudanca) %>%
  summarise(n = n(), .groups = "drop_last") %>%
  mutate(pct = n / sum(n))

write_excel_csv2(df_grafico_porte %>% mutate(pct_formatado = label_percent(accuracy = 0.1, decimal.mark = ",")(pct)), file.path(path_processed_municipal, "efeito_comportamental_por_porte.csv"))

grafico_porte <- ggplot(df_grafico_porte, aes(x = porte_populacional, y = pct, fill = perfil_mudanca)) +
  geom_col(position = "fill", width = 0.7, alpha = 0.9) +
  geom_text(aes(label = label_percent(accuracy = 0.1, decimal.mark = ",")(pct)),
            position = position_fill(vjust = 0.5), color = "white", fontface = "bold", size = 3) +
  scale_y_continuous(labels = label_percent(decimal.mark = ","), expand = expansion(mult = c(0, 0.05))) +
  scale_fill_manual(values = c("1. Despertados (Efeito Indutor)" = "#27ae60", "2. Constantes (Sustentabilidade)" = "#2980b9",
                               "3. Inertes (Dependência Exclusiva)" = "#7f8c8d", "4. Efeito Substituição (Retração Local)" = "#c0392b")) +
  coord_flip() + 
  labs(title = "Efeito Comportamental por Porte Populacional",
       subtitle = "Como o tamanho do Município influenciou a reação às transferências federais",
       x = "Porte Populacional", y = "Proporção de Municípios (%)", fill = "Comportamento Pós-repasses:",
       caption = legenda_criterios) +
  theme_minimal() + 
  theme(legend.position = "bottom", legend.direction = "vertical", 
        plot.title = element_text(face = "bold", size = 14), axis.text.y = element_text(face = "bold"))

# Renderização explícita do gráfico do Perfil Comportamental por Porte
print(grafico_porte)
ggsave(file.path(path_outputs_municipal, "grafico_porte_comportamental.png"), plot = grafico_porte, width = 10, height = 6)


# ==============================================================================
# 8. INDICADORES FINAIS DA RCL (META PNC)
# ==============================================================================
arquivos_rcl <- list.files(path = path_pai_rcl, 
                           pattern = "(?i)^RCL_.*\\.(csv|xlsx|xls)$", 
                           full.names = TRUE)

ler_limpar_rcl <- function(caminho_arquivo) {
  nome_arq <- basename(caminho_arquivo)
  ano_arquivo <- as.numeric(str_extract(nome_arq, "\\d{4}"))
  extensao <- tools::file_ext(caminho_arquivo)
  
  df_raw <- tryCatch({
    if (extensao == "csv") {
      linhas <- readLines(caminho_arquivo, n = 30, encoding = "latin1", warn = FALSE)
      linha_cabecalho <- which(str_count(linhas, ";") > 2)[1]
      if (is.na(linha_cabecalho)) linha_cabecalho <- 1
      
      read_delim(
        caminho_arquivo, 
        delim = ";", 
        skip = linha_cabecalho - 1, 
        locale = locale(encoding = "latin1", decimal_mark = ",", grouping_mark = "."),
        show_col_types = FALSE
      )
    } else {
      preview <- read_excel(caminho_arquivo, n_max = 20, col_names = FALSE)
      linha_cab <- which(apply(preview, 1, function(x) any(str_detect(toupper(as.character(x)), "COD\\.?IBGE"))))[1]
      if (is.na(linha_cab)) linha_cab <- 1
      read_excel(caminho_arquivo, skip = linha_cab - 1)
    }
  }, error = function(e) return(NULL))
  
  if (is.null(df_raw) || nrow(df_raw) == 0) return(NULL)
  
  df_limpo <- df_raw %>% clean_names()
  
  df_processado <- df_limpo %>%
    filter(str_detect(str_to_upper(conta), "RECEITA CORRENTE L.QUIDA"),
           str_detect(str_to_upper(coluna), "<TOTAL>|TOTAL")) %>%
    mutate(exercicio = ano_arquivo,
           codigo_ibge_str = as.character(cod_ibge),
           valor_rcl = as.numeric(valor)) %>%
    filter(!is.na(codigo_ibge_str), 
           str_detect(codigo_ibge_str, "^\\d{6,7}$"), 
           !is.na(valor_rcl),
           valor_rcl > 0) %>%
    mutate(codigo_ibge_6 = str_sub(str_pad(codigo_ibge_str, 7, pad = "0"), 1, 6)) %>%
    group_by(codigo_ibge_6, exercicio) %>%
    summarise(valor_rcl = max(valor_rcl, na.rm = TRUE), .groups = "drop")
  
  return(df_processado)
}

df_rcl_consolidado <- map_dfr(arquivos_rcl, ler_limpar_rcl)

df_municipios_final <- df_municipios_final %>%
  mutate(codigo_ibge_6 = str_sub(str_pad(as.character(codigo_ibge), 7, pad = "0"), 1, 6),
         exercicio     = as.numeric(exercicio)) %>%
  select(-any_of(c("valor_rcl", "percentual_rcl"))) %>%
  left_join(df_rcl_consolidado, by = c("codigo_ibge_6", "exercicio")) %>%
  mutate(percentual_rcl = if_else(!is.na(valor_rcl) & valor_rcl > 0, (valor_nominal_final / valor_rcl) * 100, NA_real_))

df_esforco <- df_municipios_final %>%
  filter(str_starts(as.character(origem), "Recurso Próprio"),
         !is.na(percentual_rcl))

ind_1 <- df_esforco %>%
  group_by(exercicio) %>%
  summarise(`Total de Municípios Analisados` = n(),
            `Qtd Municípios (> 2% RCL)` = sum(percentual_rcl > 2.0, na.rm = TRUE),
            `Percentual do Total (%)` = round((`Qtd Municípios (> 2% RCL)` / `Total de Municípios Analisados`) * 100, 2),
            .groups = "drop") %>%
  arrange(exercicio)
print(ind_1)

ind_2 <- df_esforco %>%
  filter(regiao_munic == "Centro-Oeste") %>%
  group_by(exercicio) %>%
  summarise(`Total Analisado (CO)` = n(),
            `Atingiram a Meta (> 2%)` = sum(percentual_rcl > 2.0, na.rm = TRUE),
            `Percentual de Sucesso (%)` = round((`Atingiram a Meta (> 2%)` / `Total Analisado (CO)`) * 100, 2),
            .groups = "drop") %>%
  arrange(exercicio)
print(ind_2)

df_niveis <- df_esforco %>%
  mutate(nivel_invest_cat = case_when(percentual_rcl <= 0.5 ~ "1. Até 0,5%",
                                      percentual_rcl > 0.5 & percentual_rcl <= 1.0 ~ "2. Entre 0,5% e 1,0%",
                                      percentual_rcl > 1.0 & percentual_rcl <= 2.0 ~ "3. Entre 1,0% e 2,0%",
                                      percentual_rcl > 2.0 ~ "4. Mais de 2,0%",
                                      TRUE ~ "Sem Classificação"))

ind_3 <- df_niveis %>%
  group_by(exercicio, nivel_invest_cat) %>%
  summarise(Qtd = n(), .groups = "drop") %>%
  pivot_wider(names_from = exercicio, values_from = Qtd, values_fill = 0) %>%
  arrange(nivel_invest_cat)
print(ind_3)

ind_4 <- df_niveis %>%
  filter(!is.na(porte_populacional)) %>%
  group_by(exercicio, nivel_invest_cat, porte_populacional) %>%
  summarise(Qtd_Municipios = n(), .groups = "drop") %>%
  pivot_wider(names_from = porte_populacional, values_from = Qtd_Municipios, values_fill = 0) %>%
  arrange(exercicio, nivel_invest_cat)

print(ind_4, n = Inf)

# 9. EXPORTAÇÃO DOS INDICADORES PARA CSV
write_excel_csv2(ind_1, file.path(path_processed_municipal, "Indicador_1_Meta_2_Porcento_RCL.csv"))
write_excel_csv2(ind_2, file.path(path_processed_municipal, "Indicador_2_Centro_Oeste_Meta_RCL.csv"))
write_excel_csv2(ind_3, file.path(path_processed_municipal, "Indicador_3_Niveis_Investimento_Série_Histórica.csv"))
write_excel_csv2(ind_4, file.path(path_processed_municipal, "Indicador_4_Niveis_Investimento_por_Porte.csv"))
