# ==============================================================================
# PAINEL ESTADIC CULTURA COMPLETO (2012 a 2024)
# ==============================================================================

# ------------------------------------------------------------------------------
# 0. AMBIENTE E DEPENDÊNCIAS (renv)
# ------------------------------------------------------------------------------
# renv::restore()

# ------------------------------------------------------------------------------
# 1. PACOTES E CONFIGURAÇÕES
# ------------------------------------------------------------------------------
library(tidyverse)
library(janitor)
library(readxl)
library(scales)
library(ggplot2)
library(geobr)
library(sf)
library(here)
library(geobr)
library(sf)

dir.create(here("data", "processed"), recursive = TRUE, showWarnings = FALSE)
dir.create(here("outputs"), recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------------------------
# 2. FUNÇÕES AUXILIARES
# ------------------------------------------------------------------------------
fix_sim_nao <- function(x) {
  case_when(str_detect(str_to_lower(as.character(x)), "sim|^1$|^s$") ~ "Sim",
            TRUE ~ "Não")
}

read_excel_robust <- function(path, sheet_name) {
  df <- read_excel(path, sheet = sheet_name) %>% clean_names()
  if("codigouf" %in% names(df)) df <- rename(df, cod_uf = codigouf)
  if("a1" %in% names(df)) df <- rename(df, cod_uf = a1)
  df %>% mutate(cod_uf = as.character(cod_uf))
}

# ------------------------------------------------------------------------------
# 3. EXTRAÇÃO DOS MICRODADOS
# ------------------------------------------------------------------------------

# --- 2024 (Módulo Transversal: Igualdade Racial) ---
path_24 <- here("data", "raw", "ESTADIC 2024.xlsx")
df_24_ir <- read_excel(path_24, sheet = "Igualdade Racial") %>% 
  clean_names() %>%
  transmute(cod_uf = as.character(cod_uf),
            ano = 2024,
            ir_gt_cultura = fix_sim_nao(eigr123),
            ir_patrimonio_afro = fix_sim_nao(eigr128),
            ir_patrimonio_quilombola = fix_sim_nao(eigr1210))

# --- 2023 (Módulos Transversais: Primeira Infância e Política para Mulheres) ---
path_23 <- here("data", "raw", "ESTADIC 2023.xlsx")
df_23_pi <- read_excel(path_23, sheet = "Primeira Infância") %>% 
  clean_names() %>%
  transmute(cod_uf = as.character(cod_uf), ano = 2023, pi_arte_cultura = fix_sim_nao(epri0610))

df_23_pm <- read_excel(path_23, sheet = "Política para Mulheres") %>% 
  clean_names() %>%
  transmute(cod_uf = as.character(cod_uf), pm_parceria_cultura = fix_sim_nao(eppm134))

df_estadic_23 <- df_23_pi %>% left_join(df_23_pm, by = "cod_uf")

# --- 2021 (Módulo Direto: Cultura + Patrimônio + Lei de Incentivo) ---
path_21 <- here("data", "raw", "ESTADIC 2021.xlsx")
df_estadic_21 <- read_excel(path_21, sheet = "Cultura") %>% 
  clean_names() %>%
  transmute(cod_uf = as.character(cod_uf),
            ano = 2021,
            tipo_orgao_gestor = ecul01,
            tem_plano = fix_sim_nao(ecul10),
            tem_conselho = fix_sim_nao(ecul19),
            tem_fundo = fix_sim_nao(ecul33),
            tem_lei_patrimonio = fix_sim_nao(ecul15),
            tem_cons_patrimonio = fix_sim_nao(ecul26),
            tem_lei_incentivo = fix_sim_nao(ecul31),
            gestor_sexo = ecul03,
            gestor_cor_raca = ecul05,
            gestor_escolaridade = ecul06,
            cons_paritario = case_when(str_detect(str_to_lower(as.character(ecul192)), "paritá") ~ "Paritário",
              str_detect(str_to_lower(as.character(ecul192)), "representação|governamental|sociedade civil") ~ "Não Paritário",
              TRUE ~ "Sem Informação"),
            cons_competencia = case_when(
              fix_sim_nao(ecul202) == "Sim" ~ "Deliberativo",
              fix_sim_nao(ecul201) == "Sim" ~ "Consultivo",
              fix_sim_nao(ecul203) == "Sim" | fix_sim_nao(ecul204) == "Sim" ~ "Normativo / Fiscalizador",
              TRUE ~ "Sem Informação"))

# --- 2018 (Módulo Direto: Cultura + Patrimônio + Lei de Incentivo) ---
path_18 <- here("data", "raw", "ESTADIC 2018.xlsx")
df_estadic_18 <- read_excel(path_18, sheet = "Cultura") %>% 
  clean_names() %>%
  transmute(cod_uf = as.character(cod_uf),
            ano = 2018,
            tipo_orgao_gestor = ecul01,
            tem_plano = fix_sim_nao(ecul10),
            tem_conselho = fix_sim_nao(ecul19),
            tem_fundo = fix_sim_nao(ecul33),
            tem_lei_patrimonio = fix_sim_nao(ecul15),
            tem_cons_patrimonio = fix_sim_nao(ecul26),
            tem_lei_incentivo = fix_sim_nao(ecul31),
            gestor_sexo = ecul03,
            gestor_cor_raca = ecul05,
            gestor_escolaridade = ecul06,
            cons_paritario = case_when(str_detect(str_to_lower(as.character(ecul192)), "paritá") ~ "Paritário",
              str_detect(str_to_lower(as.character(ecul192)), "representação|governamental|sociedade civil") ~ "Não Paritário",
              TRUE ~ "Sem Informação"),
            cons_competencia = case_when(fix_sim_nao(ecul202) == "Sim" ~ "Deliberativo",
              fix_sim_nao(ecul201) == "Sim" ~ "Consultivo",
              fix_sim_nao(ecul203) == "Sim" | fix_sim_nao(ecul204) == "Sim" ~ "Normativo / Fiscalizador",
              TRUE ~ "Sem Informação"))

# --- 2014 (Módulo Direto: Cultura + Patrimônio) ---
path_14 <- here("data", "raw", "ESTADIC 2014.xls")
df_14_org   <- read_excel_robust(path_14, "Órgão gestor") %>% transmute(cod_uf, tipo_orgao_gestor = a2)
df_14_plano <- read_excel_robust(path_14, "Políticas culturais") %>% transmute(cod_uf, tem_plano = fix_sim_nao(a93))
df_14_cons  <- read_excel_robust(path_14, "Instâncias participativas") %>% transmute(cod_uf, tem_conselho = fix_sim_nao(a305))
df_14_fund  <- read_excel_robust(path_14, "Fundo Cultura") %>% transmute(cod_uf, tem_fundo = fix_sim_nao(a321))
df_14_pat   <- read_excel_robust(path_14, "Legislação") %>% 
  transmute(cod_uf, tem_lei_patrimonio = fix_sim_nao(a237))
df_14_rh    <- read_excel_robust(path_14, "Recursos humanos") %>% transmute(cod_uf, gestor_escolaridade = a20, gestor_sexo = a22)

df_estadic_14 <- df_14_org %>% 
  left_join(df_14_plano, by = "cod_uf") %>% 
  left_join(df_14_cons, by = "cod_uf") %>%
  left_join(df_14_fund, by = "cod_uf") %>% 
  left_join(df_14_pat, by = "cod_uf") %>%
  left_join(df_14_rh, by = "cod_uf") %>%
  mutate(ano = 2014, 
         gestor_cor_raca = NA_character_, 
         tem_lei_incentivo = NA_character_, 
         tem_cons_patrimonio = NA_character_)

# --- 2012 (Módulo Transversal: Conselhos e Fundos Estaduais de Cultura) ---
path_12 <- here("data", "raw", "ESTADIC 2012.xls")
df_12_cons_fund <- read_excel_robust(path_12, "Conselhos e fundos") %>%
  transmute(cod_uf,
            ano = 2012,
            tem_conselho = fix_sim_nao(a90),
            tem_fundo = fix_sim_nao(a94))

# ------------------------------------------------------------------------------
# 4. CONSOLIDAÇÃO DO PAINEL HISTÓRICO E RECONSTRUÇÃO GEOGRÁFICA
# ------------------------------------------------------------------------------

df_estadic_painel <- bind_rows(df_estadic_21, df_estadic_18, df_estadic_14, df_12_cons_fund, df_estadic_23, df_24_ir) %>%
  mutate(sigla_uf = case_match(cod_uf,
                               "11" ~ "RO", "12" ~ "AC", "13" ~ "AM", "14" ~ "RR", "15" ~ "PA", "16" ~ "AP", "17" ~ "TO",
                               "21" ~ "MA", "22" ~ "PI", "23" ~ "CE", "24" ~ "RN", "25" ~ "PB", "26" ~ "PE", "27" ~ "AL", "28" ~ "SE", "29" ~ "BA",
                               "31" ~ "MG", "32" ~ "ES", "33" ~ "RJ", "35" ~ "SP",
                               "41" ~ "PR", "42" ~ "SC", "43" ~ "RS",
                               "50" ~ "MS", "51" ~ "MT", "52" ~ "GO", "53" ~ "DF",
                               .default = "Outro"),
         nome_uf = case_match(sigla_uf,
                              "RO" ~ "Rondônia", "AC" ~ "Acre", "AM" ~ "Amazonas", "RR" ~ "Roraima", "PA" ~ "Pará", "AP" ~ "Amapá", "TO" ~ "Tocantins",
                              "MA" ~ "Maranhão", "PI" ~ "Piauí", "CE" ~ "Ceará", "RN" ~ "Rio Grande do Norte", "PB" ~ "Paraíba", "PE" ~ "Pernambuco", "AL" ~ "Alagoas", "SE" ~ "Sergipe", "BA" ~ "Bahia",
                              "MG" ~ "Minas Gerais", "ES" ~ "Espírito Santo", "RJ" ~ "Rio de Janeiro", "SP" ~ "São Paulo",
                              "PR" ~ "Paraná", "SC" ~ "Santa Catarina", "RS" ~ "Rio Grande do Sul",
                              "MS" ~ "Mato Grosso do Sul", "MT" ~ "Mato Grosso", "GO" ~ "Goiás", "DF" ~ "Distrito Federal",
                              .default = "Outro"),
         regiao = case_when(str_starts(cod_uf, "1") ~ "Norte",
           str_starts(cod_uf, "2") ~ "Nordeste",
           str_starts(cod_uf, "3") ~ "Sudeste",
           str_starts(cod_uf, "4") ~ "Sul",
           str_starts(cod_uf, "5") ~ "Centro-Oeste",
           TRUE ~ "Sem Informação"),
         gestor_escolaridade_agrupada = case_when(
           str_detect(str_to_lower(gestor_escolaridade), "pós|especializa|mestrado|doutorado") ~ "Pós-Graduação",
           str_detect(str_to_lower(gestor_escolaridade), "superior|graduação") ~ "Ensino Superior",
           str_detect(str_to_lower(gestor_escolaridade), "médio|2º grau|2° grau|2o grau|segundo grau") ~ "Ensino Médio",
           str_detect(str_to_lower(gestor_escolaridade), "fundamental|1º grau|1° grau|1o grau|sem instrução|primeiro grau") ~ "Ensino Fundamental",
           TRUE ~ "Sem Informação"),
         tipo_orgao_gestor = case_when(
           str_detect(str_to_lower(tipo_orgao_gestor), "exclusiva|fundação|indireta") ~ "Secretaria Exclusiva / Fundação",
           str_detect(str_to_lower(tipo_orgao_gestor), "conjunto") ~ "Secretaria Conjunta",
           TRUE ~ "Setor Subordinado / Outros")) %>%
  select(cod_uf, sigla_uf, nome_uf, regiao, ano, everything()) %>%
  arrange(cod_uf, ano)

# Salva a base tratada em data/processed/
write_excel_csv(df_estadic_painel, here("data", "processed", "estadic_cultura_painel_transversal_12_24.csv"))

# Cores Padrão
cor_plano <- "#E74C3C"
cor_conselho <- "#2980B9"
cor_fundo <- "#27AE60"

# ==============================================================================
# 5. INDICADORES DO NÚCLEO DURO DE GESTÃO (2014, 2018 E 2021)
# ==============================================================================

# --- GRÁFICO 5.1: AUTONOMIA DO ÓRGÃO GESTOR ESTADUAL ---
df_orgao_est <- df_estadic_painel %>%
  filter(ano %in% c(2014, 2018, 2021), !is.na(tipo_orgao_gestor)) %>%
  count(ano, tipo_orgao_gestor) %>%
  group_by(ano) %>%
  mutate(taxa = n / sum(n))

p_est_1 <- ggplot(df_orgao_est, aes(x = factor(ano), y = taxa, fill = fct_reorder(tipo_orgao_gestor, taxa))) +
  geom_col(width = 0.6, color = "white", linewidth = 0.5) +
  geom_text(aes(label = ifelse(tipo_orgao_gestor == "Setor Subordinado / Outros" & ano == 2018, 
                       "", 
                       paste0(n, " UFs\n(", percent(taxa, accuracy = 1), ")"))), 
    position = position_stack(vjust = 0.5), 
    color = "white", 
    fontface = "bold", 
    size = 4,
    lineheight = 0.9) +
  scale_y_continuous(labels = percent_format(), expand = expansion(mult = c(0, 0.05))) +
  scale_fill_manual(values = c("Secretaria Exclusiva / Fundação" = "#27AE60", 
                               "Secretaria Conjunta" = "#F39C12", 
                               "Setor Subordinado / Outros" = "#7F8C8D")) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "bottom", 
        legend.direction = "horizontal", 
        panel.grid.major.x = element_blank(),
        plot.title = element_text(face = "bold")) +
  labs(title = "Estrutura do Órgão Gestor Estadual (2014-2021)", 
       subtitle = "Distribuição dos estados por nível de autonomia institucional da cultura", 
       x = "Ano da Pesquisa", 
       y = "Proporção de Estados (N = 27)", 
       fill = "")

ggsave(here("outputs", "grafico_5_1_orgao_gestor_estadual.png"), plot = p_est_1, width = 10, height = 6, dpi = 300)

# --- GRÁFICO 5.2: ESCOLARIDADE DOS SECRETÁRIOS ESTADUAIS ---
df_esc_est <- df_estadic_painel %>%
  filter(ano %in% c(2014, 2018, 2021), !is.na(gestor_escolaridade_agrupada), gestor_escolaridade_agrupada != "Sem Informação") %>%
  mutate(gestor_escolaridade_agrupada = factor(gestor_escolaridade_agrupada, levels = c("Ensino Fundamental", "Ensino Médio", "Ensino Superior", "Pós-Graduação"))) %>%
  count(ano, gestor_escolaridade_agrupada) %>%
  group_by(ano) %>%
  mutate(taxa = n / sum(n))

p_est_2 <- ggplot(df_esc_est, aes(x = factor(ano), y = taxa, fill = gestor_escolaridade_agrupada)) +
  geom_col(width = 0.6, color = "white") +
  geom_text(aes(label = paste0(n, " UFs")), position = position_stack(vjust = 0.5), color = "white", fontface = "bold", size = 4.5) +
  scale_y_continuous(labels = percent_format()) +
  scale_fill_manual(values = c("Ensino Fundamental" = "#E67E22", "Ensino Médio" = "#F39C12", "Ensino Superior" = "#2980B9", "Pós-Graduação" = "#27AE60")) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "bottom", plot.title = element_text(face = "bold"), panel.grid.major.x = element_blank()) +
  labs(title = "Escolaridade dos Dirigentes Estaduais de Cultura (2014-2021)", subtitle = "Número absoluto de secretários estaduais (UFs) por nível de formação", x = "Ano da Pesquisa", y = "Proporção de Gestores", fill = "Escolaridade:")

ggsave(here("outputs", "grafico_5_2_escolaridade_estaduais.png"), plot = p_est_2, width = 10, height = 6, dpi = 300)

# --- GRÁFICO 5.3: PARIDADE NOS CONSELHOS ESTADUAIS ---
df_paridade_est <- df_estadic_painel %>%
  filter(ano %in% c(2018, 2021), tem_conselho == "Sim") %>%
  mutate(cons_paritario = str_trim(cons_paritario)) %>%
  filter(cons_paritario %in% c("Paritário", "Não Paritário")) %>%
  count(ano, cons_paritario) %>%
  group_by(ano) %>%
  mutate(taxa = n / sum(n))

p_est_3 <- ggplot(df_paridade_est, aes(x = factor(ano), y = taxa, fill = cons_paritario)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.6) +
  geom_text(aes(label = paste0(n, " UFs\n(", percent(taxa, accuracy = 1), ")")), 
            position = position_dodge(width = 0.7), vjust = -0.5, fontface = "bold", size = 3.5) +
  scale_y_continuous(labels = percent_format(), expand = expansion(mult = c(0, 0.18))) +
  scale_fill_manual(values = c("Paritário" = "#27AE60", "Não Paritário" = "#E74C3C")) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "top", plot.title = element_text(face = "bold"), panel.grid.minor = element_blank()) +
  labs(title = "Paridade nos Conselhos Estaduais de Cultura", 
       subtitle = "Dentre os Conselhos Ativos, quantos possuem representação paritária? (2018-2021)", 
       x = "Ano da Pesquisa", 
       y = "Proporção dos Conselhos Ativos", 
       fill = "Composição:")

ggsave(here("outputs", "grafico_5_3_paridade_conselhos_estaduais.png"), plot = p_est_3, width = 10, height = 6, dpi = 300)

# --- GRÁFICO 5.4: COMPETÊNCIA E ATUAÇÃO DOS CONSELHOS ESTADUAIS ---
df_competencia_est <- df_estadic_painel %>%
  filter(ano %in% c(2014, 2018, 2021), tem_conselho == "Sim", cons_competencia != "Sem Informação") %>%
  count(ano, cons_competencia) %>%
  group_by(ano) %>%
  mutate(taxa = n / sum(n))

p_est_4 <- ggplot(df_competencia_est, aes(x = factor(ano), y = taxa, fill = cons_competencia)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.6) +
  geom_text(aes(label = paste0(n, " UFs\n(", percent(taxa, accuracy = 1), ")")), 
            position = position_dodge(width = 0.7), vjust = -0.5, fontface = "bold", size = 3.5, color = "#2C3E50") +
  scale_y_continuous(labels = percent_format(), expand = expansion(mult = c(0, 0.18))) +
  scale_fill_manual(values = c("Deliberativo" = "#2980B9", 
                               "Consultivo" = "#F39C12", 
                               "Normativo / Fiscalizador" = "#27AE60")) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "top", 
        plot.title = element_text(face = "bold", size = 16), 
        panel.grid.minor = element_blank()) +
  labs(title = "Caráter e Competência Predominante dos Conselhos Estaduais", 
       subtitle = "Atuação institucional declarada pelas UFs com conselhos ativos (2014-2021)", 
       x = "Ano da Pesquisa", 
       y = "Proporção dos Conselhos Ativos", 
       fill = "Natureza do Conselho:")

ggsave(here("outputs", "grafico_5_4_competencia_conselhos_estaduais.png"), plot = p_est_4, width = 10, height = 6, dpi = 300)

# ==============================================================================
# 6. INDICADORES DA SÉRIE HISTÓRICA COMPLETA (2012 A 2024)
# ==============================================================================

# --- GRÁFICO 6.1: EXPANSÃO DO TRIPÉ DO SNC NOS ESTADOS (SÉRIE 2012-2021) ---
df_tripe_longo <- df_estadic_painel %>%
  filter(ano %in% c(2014, 2018, 2021)) %>%
  select(ano, tem_plano, tem_conselho, tem_fundo) %>%
  pivot_longer(cols = -ano, names_to = "instrumento", values_to = "status") %>%
  filter(!is.na(status), status %in% c("Sim", "Não")) %>%
  group_by(ano, instrumento) %>%
  summarise(taxa = mean(status == "Sim"), n_sim = sum(status == "Sim"), .groups = 'drop') %>%
  mutate(instrumento = recode(instrumento, "tem_plano" = "Plano Estadual", "tem_conselho" = "Conselho Estadual", "tem_fundo" = "Fundo Estadual"))

p_est_6_1 <- ggplot(df_tripe_longo, aes(x = ano, y = taxa, color = instrumento, group = instrumento)) +
  geom_line(linewidth = 1.4) +
  geom_point(size = 4) +
  geom_text(aes(label = paste0(n_sim, " UFs (", percent(taxa, accuracy = 1), ")")), 
            vjust = -1.3, fontface = "bold", size = 3.2, show.legend = FALSE,
            position = position_dodge(width = 0.2)) +
  scale_y_continuous(labels = percent_format(), limits = c(0, 1.05), expand = expansion(mult = c(0.05, 0.2))) +
  scale_x_continuous(breaks = c(2014, 2018, 2021)) +
  scale_color_manual(values = c("Conselho Estadual" = cor_conselho, "Fundo Estadual" = cor_fundo, "Plano Estadual" = cor_plano)) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "bottom", plot.title = element_text(face = "bold", size = 16), panel.grid.minor = element_blank()) +
  labs(title = "Evolução do Tripé Institucional da Cultura nos Estados",
       subtitle = "Presença de Conselho, Fundo e Plano de Cultura nas 27 UFs (2014-2021)",
       x = "Ano da Pesquisa ESTADIC", y = "Proporção das UFs", color = "")

ggsave(here("outputs", "grafico_6_1_tripe_estaduais.png"), plot = p_est_6_1, width = 11, height = 6, dpi = 300)

# --- GRÁFICO 6.2: TRANSVERSALIDADE DA CULTURA NAS POLÍTICAS SOCIAIS (2023-2024) ---
df_transversal <- df_estadic_painel %>%
  filter(ano %in% c(2023, 2024)) %>%
  summarise(`Arte e Cultura na Primeira Infância (2023)` = mean(pi_arte_cultura == "Sim", na.rm = TRUE),
            `Articulação Mulheres x Órgão de Cultura (2023)` = mean(pm_parceria_cultura == "Sim", na.rm = TRUE),
            `Cultura em GTs de Igualdade Racial (2024)` = mean(ir_gt_cultura == "Sim", na.rm = TRUE),
            `Preservação Patrimônio Afro-Brasileiro (2024)` = mean(ir_patrimonio_afro == "Sim", na.rm = TRUE),
            `Preservação Patrimônio Quilombola (2024)` = mean(ir_patrimonio_quilombola == "Sim", na.rm = TRUE)) %>%
  pivot_longer(cols = everything(), names_to = "indicador", values_to = "taxa")

p_est_6_2 <- ggplot(df_transversal, aes(x = taxa, y = fct_reorder(indicador, taxa))) +
  geom_col(fill = "#8E44AD", width = 0.6) +
  geom_text(aes(label = paste0(round(taxa * 27, 0), " UFs (", percent(taxa, accuracy = 1), ")")), hjust = -0.15, fontface = "bold", size = 4, color = "#2C3E50") +
  scale_x_continuous(labels = percent_format(), limits = c(0, 0.80), expand = expansion(mult = c(0, 0.05))) +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(face = "bold"), panel.grid.major.y = element_blank()) +
  labs(title = "Transversalidade da Cultura em Outras Políticas Estaduais",
       subtitle = "Estados (UFs) com ações culturais integradas à Infância, Mulheres e Igualdade Racial",
       x = "Proporção de Estados (UFs)", y = "")

ggsave(here("outputs", "grafico_6_2_transversalidade_estaduais.png"), plot = p_est_6_2, width = 11, height = 6, dpi = 300)

# --- GRÁFICO 6.3: INSTITUCIONALIZAÇÃO DO PATRIMÔNIO CULTURAL ESTADUAL (2014-2021) ---
df_patrimonio_est <- df_estadic_painel %>%
  filter(ano %in% c(2014, 2018, 2021)) %>%
  select(ano, tem_lei_patrimonio) %>%
  pivot_longer(cols = -ano, names_to = "instrumento", values_to = "status") %>%
  filter(!is.na(status), status %in% c("Sim", "Não")) %>%
  group_by(ano, instrumento) %>%
  summarise(taxa = mean(status == "Sim"), n_sim = sum(status == "Sim"), .groups = 'drop') %>%
  mutate(instrumento = recode(instrumento, "tem_lei_patrimonio" = "Legislação de Patrimônio"))

p_est_7_1 <- ggplot(df_patrimonio_est, aes(x = ano, y = taxa, color = instrumento, group = instrumento)) +
  geom_line(linewidth = 1.4) +
  geom_point(size = 4) +
  geom_text(aes(label = paste0(n_sim, " UFs (", percent(taxa, accuracy = 1), ")")), vjust = -1.2, fontface = "bold", size = 3.5, show.legend = FALSE) +
  scale_y_continuous(labels = percent_format(), limits = c(0, 1.00), expand = expansion(mult = c(0.05, 0.15))) +
  scale_x_continuous(breaks = c(2014, 2018, 2021)) +
  scale_color_manual(values = c("Legislação de Patrimônio" = "#8E44AD")) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "bottom", plot.title = element_text(face = "bold", size = 16), panel.grid.minor = element_blank()) +
  labs(title = "Proteção ao Patrimônio Cultural nos Estados",
       subtitle = "Evolução da existência de leis específicas de tombamento (2014-2021)",
       x = "Ano da Pesquisa ESTADIC", y = "Proporção das UFs", color = "")

ggsave(here("outputs", "grafico_7_1_patrimonio_estaduais.png"), plot = p_est_7_1, width = 11, height = 6, dpi = 300)

# --- GRÁFICO 6.4: MECANISMOS DE FOMENTO PRÓPRIOS (LEIS DE INCENTIVO ESTADUAIS) ---
df_incentivo_est <- df_estadic_painel %>%
  filter(ano %in% c(2018, 2021), !is.na(tem_lei_incentivo)) %>%
  count(ano, tem_lei_incentivo) %>%
  group_by(ano) %>%
  mutate(taxa = n / sum(n))

p_est_7_2 <- ggplot(df_incentivo_est, aes(x = factor(ano), y = taxa, fill = tem_lei_incentivo)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.6) +
  geom_text(aes(label = paste0(n, " UFs\n(", percent(taxa, accuracy = 1), ")")), 
            position = position_dodge(width = 0.7), vjust = -0.5, fontface = "bold", size = 3.5) +
  scale_y_continuous(labels = percent_format(), expand = expansion(mult = c(0, 0.18))) +
  scale_fill_manual(values = c("Sim" = "#27AE60", "Não" = "#E74C3C")) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "top", plot.title = element_text(face = "bold"), panel.grid.minor = element_blank()) +
  labs(title = "Existência de Lei Estadual Própria de Incentivo à Cultura", 
       subtitle = "Proporção de estados com mecanismos estaduais de renúncia fiscal para o setor", 
       x = "Ano da Pesquisa", 
       y = "Proporção de UFs", 
       fill = "Possui Mecenato Estadual:")

ggsave(here("outputs", "grafico_7_2_leis_incentivo_estaduais.png"), plot = p_est_7_2, width = 10, height = 6, dpi = 300)

# ==============================================================================
# 7. ANÁLISE CARTOGRÁFICA E DISTRIBUIÇÃO ESPACIAL (MAPAS)
# ==============================================================================

rm(list = setdiff(ls(), "df_estadic_painel"))
gc()

malha_uf <- read_state(year = 2019, showProgress = FALSE) %>%
  mutate(cod_uf = as.character(code_state))

# --- PREPARAÇÃO DA BASE ESPACIAL ---
df_mapa_21 <- df_estadic_painel %>%
  filter(ano == 2021) %>%
  mutate(status_tripe = (tem_plano == "Sim") + (tem_conselho == "Sim") + (tem_fundo == "Sim"),
    maturidade_snc = case_when(
      status_tripe == 3 ~ "Tripé Completo",
      status_tripe %in% c(1, 2) ~ "Institucionalização Parcial",
      status_tripe == 0 ~ "Nenhum Instrumento"),
    maturidade_snc = factor(maturidade_snc, levels = c("Tripé Completo", "Institucionalização Parcial", "Nenhum Instrumento")))

mapa_dados_21 <- malha_uf %>% left_join(df_mapa_21, by = "cod_uf")

# --- MAPA 7.1: MATURIDADE DO TRIPÉ INSTITUCIONAL (SNC) ---
p_mapa_tripe <- ggplot(mapa_dados_21) +
  geom_sf(aes(fill = maturidade_snc), color = "white", linewidth = 0.4) +
  geom_sf_text(aes(label = sigla_uf), size = 3, color = "black", fontface = "bold") +
  scale_fill_manual(values = c("Tripé Completo" = "#27AE60", 
                               "Institucionalização Parcial" = "#F39C12", 
                               "Nenhum Instrumento" = "#E74C3C"),
                    na.value = "#BDC3C7") +
  theme_void(base_size = 14) +
  theme(legend.position = "bottom", plot.title = element_text(face = "bold", hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) +
  labs(title = "Maturidade do Sistema Estadual de Cultura (2021)",
       subtitle = "Consolidação de Conselhos, Fundos e Planos Estaduais",
       fill = "Situação do Tripé:")

ggsave(here("outputs", "mapa_8_1_maturidade_tripe_2021.png"), plot = p_mapa_tripe, width = 10, height = 8, dpi = 300, bg = "white")


# --- MAPA 7.2: AUTONOMIA DO ÓRGÃO GESTOR ---
p_mapa_autonomia <- ggplot(mapa_dados_21) +
  geom_sf(aes(fill = tipo_orgao_gestor), color = "white", linewidth = 0.4) +
  geom_sf_text(aes(label = sigla_uf), size = 3, color = "white", fontface = "bold") +
  scale_fill_manual(values = c("Secretaria Exclusiva / Fundação" = "#2980B9", 
                               "Secretaria Conjunta" = "#F39C12", 
                               "Setor Subordinado / Outros" = "#7F8C8D"),
                    na.value = "#BDC3C7") +
  theme_void(base_size = 14) +
  theme(legend.position = "bottom", plot.title = element_text(face = "bold", hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) +
  labs(title = "Autonomia do Órgão Gestor Estadual (2021)",
       subtitle = "Tipologia das pastas que respondem pela cultura nos estados",
       fill = "Estrutura do Órgão:")

ggsave(here("outputs", "mapa_8_2_autonomia_gestor_2021.png"), plot = p_mapa_autonomia, width = 10, height = 8, dpi = 300, bg = "white")


# --- MAPA 7.3: PRESERVAÇÃO E MECENATO (Lei de Patrimônio + Lei de Incentivo) ---
df_mapa_fomento <- df_estadic_painel %>%
  filter(ano == 2021) %>%
  mutate(perfil_fomento = case_when(
    tem_lei_patrimonio == "Sim" & tem_lei_incentivo == "Sim" ~ "Possui Ambas as Leis",
    tem_lei_patrimonio == "Sim" & tem_lei_incentivo == "Não" ~ "Apenas Lei de Patrimônio",
    tem_lei_patrimonio == "Não" & tem_lei_incentivo == "Sim" ~ "Apenas Lei de Incentivo",
    TRUE ~ "Não Possui/Sem Informação"),
    perfil_fomento = factor(perfil_fomento, levels = c("Possui Ambas as Leis", "Apenas Lei de Patrimônio", "Apenas Lei de Incentivo", "Não Possui/Sem Informação")))

mapa_fomento_21 <- malha_uf %>% left_join(df_mapa_fomento, by = "cod_uf")

p_mapa_fomento <- ggplot(mapa_fomento_21) +
  geom_sf(aes(fill = perfil_fomento), color = "white", linewidth = 0.4) +
  geom_sf_text(aes(label = sigla_uf), size = 3.5, color = "white", fontface = "bold") +
  scale_fill_manual(values = c("Possui Ambas as Leis" = "#8E44AD", 
                               "Apenas Lei de Patrimônio" = "#3498DB", 
                               "Apenas Lei de Incentivo" = "#E67E22",
                               "Não Possui/Sem Informação" = "#BDC3C7")) +
  theme_void(base_size = 14) +
  theme(legend.position = "bottom", plot.title = element_text(face = "bold", hjust = 0.5), plot.subtitle = element_text(hjust = 0.5)) +
  labs(title = "Marcos Legais Estaduais (Patrimônio e Incentivo)",
       subtitle = "Cruzamento territorial entre leis de tombamento e mecanismos de renúncia fiscal (2021)",
       fill = "Situação Legal:")

ggsave(here("outputs", "mapa_8_3_fomento_patrimonio_2021.png"), plot = p_mapa_fomento, width = 10, height = 8, dpi = 300, bg = "white")
