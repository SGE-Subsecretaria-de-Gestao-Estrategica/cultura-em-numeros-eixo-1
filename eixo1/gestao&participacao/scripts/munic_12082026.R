# ==============================================================================
# PAINEL MUNIC CULTURA (2006, 2014, 2018, 2021) - VERSÃO COMPLETA
# ==============================================================================

#------------------------------------------------------------------------------
# 1. PACOTES E CONFIGURAÇÕES
# ------------------------------------------------------------------------------
library(tidyverse)
library(janitor)
library(readxl)
library(geobr)
library(sf)
library(scales)
library(ggplot2)
library(gt)

dir_projeto <- "D:/aeae/Ministerio da Cultura/Cultura em Numeros/Eixo 1/Gestão/MUNIC"
setwd(dir_projeto)

# ------------------------------------------------------------------------------
# 2. FUNÇÕES AUXILIARES
# ------------------------------------------------------------------------------
fix_sim_nao <- function(x) {
  case_when(str_detect(str_to_lower(as.character(x)), "sim|^1$|^s$") ~ "Sim",
            TRUE ~ "Não")
}

# ------------------------------------------------------------------------------
# 3. EXTRAÇÃO DOS MICRODADOS
# ------------------------------------------------------------------------------

# --- 2021 ---
path_21 <- file.path(dir_projeto, "2021", "Base_MUNIC_2021_20240425.xlsx")
df_21 <- read_excel(path_21, sheet = "Cultura") %>% 
  clean_names() %>%
  mutate(cod_municipio = as.character(cod_mun), 
    municipio = mun,
    ano = 2021,
    populacao = as.numeric(pop),
    tem_plano = fix_sim_nao(mcul10),
    plano_tem_lei = fix_sim_nao(mcul101a),
    plano_participacao_soc = fix_sim_nao(mcul11),
    tem_conselho = fix_sim_nao(mcul19),
    cons_qtd_membros = suppressWarnings(as.numeric(mcul22)),
    cons_cap_continuada = fix_sim_nao(mcul231),
    cons_cap_eventual = fix_sim_nao(mcul232), 
    cons_cap_nao_realiza = fix_sim_nao(mcul233),
    tem_fundo = fix_sim_nao(mcul33),
    tem_lei_patrimonio = fix_sim_nao(mcul15),
    tem_cons_patrimonio = fix_sim_nao(mcul26),
    tipo_orgao_gestor = mcul01,
    sec_educacao = fix_sim_nao(mcul1111),
    sec_esporte = fix_sim_nao(mcul1112),
    sec_turismo = fix_sim_nao(mcul1113),
    gestor_sexo = mcul03,
    gestor_idade = as.character(mcul04),
    gestor_cor_raca = mcul05,
    gestor_escolaridade = mcul06,
    orcamento_perc_executado = case_when(str_detect(str_to_lower(mcul41), "^0$") ~ "0%",
      str_detect(str_to_lower(mcul41), "at. 10") ~ "Até 10%",
      str_detect(str_to_lower(mcul41), "11.*20") ~ "11% a 20%",
      str_detect(str_to_lower(mcul41), "21.*30") ~ "21% a 30%",
      str_detect(str_to_lower(mcul41), "31.*40") ~ "31% a 40%",
      str_detect(str_to_lower(mcul41), "41.*50") ~ "41% a 50%",
      str_detect(str_to_lower(mcul41), "51.*60") ~ "51% a 60%",
      str_detect(str_to_lower(mcul41), "61.*70") ~ "61% a 70%",
      str_detect(str_to_lower(mcul41), "71.*80") ~ "71% a 80%",
      str_detect(str_to_lower(mcul41), "81.*90") ~ "81% a 90%",
      str_detect(str_to_lower(mcul41), "mais de 90") ~ "Mais de 90%",
      TRUE ~ "Sem Informação"),
    equip_biblioteca = fix_sim_nao(mcul3901),
    equip_museu = fix_sim_nao(mcul3902),
    equip_teatro = fix_sim_nao(mcul3903),
    equip_cinema = fix_sim_nao(mcul3909)) %>%
  select(cod_municipio, municipio, ano, populacao, tem_conselho, tem_plano, tem_fundo, 
    tem_lei_patrimonio, tem_cons_patrimonio, tipo_orgao_gestor, gestor_sexo, 
    gestor_idade, gestor_cor_raca, gestor_escolaridade, orcamento_perc_executado, 
    equip_biblioteca, equip_museu, equip_teatro, equip_cinema,
    plano_tem_lei, plano_participacao_soc, sec_educacao, sec_esporte, sec_turismo,
    cons_qtd_membros, cons_cap_continuada, cons_cap_eventual, cons_cap_nao_realiza)

# --- 2018 ---
path_18 <- file.path(dir_projeto, "2018", "Base_MUNIC_2018_xlsx_20201103.xlsx")
df_18 <- read_excel(path_18, sheet = "Cultura") %>% 
  clean_names() %>% 
  transmute(cod_municipio = as.character(cod_mun),
    ano = 2018,
    tipo_orgao_gestor = mcul01,
    sec_educacao = fix_sim_nao(mcul1111),
    sec_esporte = fix_sim_nao(mcul1112),
    sec_turismo = fix_sim_nao(mcul1113),
    tem_plano = fix_sim_nao(mcul10),
    plano_tem_lei = fix_sim_nao(mcul101a),
    plano_participacao_soc = fix_sim_nao(mcul11),
    tem_conselho = fix_sim_nao(mcul19), 
    cons_qtd_membros = suppressWarnings(as.numeric(mcul22)),
    cons_cap_continuada = fix_sim_nao(mcul231),
    cons_cap_eventual = fix_sim_nao(mcul232), 
    cons_cap_nao_realiza = fix_sim_nao(mcul233),
    tem_fundo = fix_sim_nao(mcul33), 
    tem_lei_patrimonio = fix_sim_nao(mcul15), 
    tem_cons_patrimonio = fix_sim_nao(mcul26), 
    equip_biblioteca = mcul362,
    equip_museu = mcul361, 
    equip_teatro = mcul365,
    equip_cinema = mcul364, 
    gestor_escolaridade = mcul06, 
    gestor_sexo = mcul03, 
    gestor_idade = as.character(mcul04), 
    gestor_cor_raca = mcul05)

# --- 2014 ---
path_14 <- file.path(dir_projeto, "2014", "base_cultura_MUNIC_xls_2014.xls")
df_14_org   <- read_excel(path_14, sheet = "Órgão gestor") %>% clean_names() %>% select(cod_municipio = a1, tipo_orgao_gestor = a2)
df_14_plano <- read_excel(path_14, sheet = "Políticas culturais") %>% clean_names() %>% select(cod_municipio = a1, tem_plano = a93)
df_14_cons  <- read_excel(path_14, sheet = "Instâncias participativas") %>% clean_names() %>% select(cod_municipio = a1, tem_conselho = a305, tem_cons_patrimonio = a339)
df_14_fund  <- read_excel(path_14, sheet = "Fundo cultura") %>% clean_names() %>% select(cod_municipio = a1, tem_fundo = a372)
df_14_rh    <- read_excel(path_14, sheet = "Recursos humanos") %>% clean_names() %>% select(cod_municipio = a1, gestor_escolaridade = a20, gestor_sexo = a22, gestor_idade = a23)
df_14_leg   <- read_excel(path_14, sheet = "Legislação") %>% clean_names() %>% select(cod_municipio = a1, tem_lei_patrimonio = a288)
df_14_equip <- read_excel(path_14, sheet = "Equipamentos") %>% clean_names() %>% select(cod_municipio = a1, equip_biblioteca = a413, equip_museu = a415, equip_teatro = a417, equip_cinema = a427)

df_14 <- df_14_org %>% 
  left_join(df_14_plano, by = "cod_municipio") %>% 
  left_join(df_14_cons, by = "cod_municipio") %>%
  left_join(df_14_fund, by = "cod_municipio") %>% 
  left_join(df_14_rh, by = "cod_municipio") %>%
  left_join(df_14_leg, by = "cod_municipio") %>% 
  left_join(df_14_equip, by = "cod_municipio") %>%
  mutate(ano = 2014,
    cod_municipio = as.character(cod_municipio),
    gestor_idade = as.character(gestor_idade),
    gestor_cor_raca = NA_character_,
    tem_conselho = fix_sim_nao(tem_conselho),
    tem_plano = fix_sim_nao(tem_plano),
    tem_fundo = fix_sim_nao(tem_fundo),
    tem_lei_patrimonio = fix_sim_nao(tem_lei_patrimonio),
    tem_cons_patrimonio = fix_sim_nao(tem_cons_patrimonio))

# --- 2006 ---
path_06 <- file.path(dir_projeto, "2006", "Base Suplemento Cultura 2006.xls")
df_06_org   <- read_excel(path_06, sheet = "Órgão gestor") %>% clean_names() %>% select(cod_municipio = a1, tipo_orgao_gestor = a2)
df_06_plano <- read_excel(path_06, sheet = "Instrumentos de gestão") %>% clean_names() %>% select(cod_municipio = a1, tem_plano = a104)
df_06_cons  <- read_excel(path_06, sheet = "Conselhos municipais") %>% clean_names() %>% select(cod_municipio = a1, tem_conselho = a130, tem_cons_patrimonio = a164)
df_06_fund  <- read_excel(path_06, sheet = "Fundo municipal") %>% clean_names() %>% select(cod_municipio = a1, tem_fundo = a196)
df_06_rh    <- read_excel(path_06, sheet = "Recursos humanos") %>% clean_names() %>% select(cod_municipio = a1, gestor_escolaridade = a12)
df_06_leg   <- read_excel(path_06, sheet = "Legislação") %>% clean_names() %>% select(cod_municipio = a1, tem_lei_patrimonio = a120)
df_06_equip <- read_excel(path_06, sheet = "Equipamentos") %>% clean_names() %>% select(cod_municipio = a1, equip_biblioteca = a424, equip_museu = a427, equip_teatro = a430, equip_cinema = a439)

df_06 <- df_06_org %>% 
  left_join(df_06_plano, by = "cod_municipio") %>% 
  left_join(df_06_cons, by = "cod_municipio") %>%
  left_join(df_06_fund, by = "cod_municipio") %>% 
  left_join(df_06_rh, by = "cod_municipio") %>%
  left_join(df_06_leg, by = "cod_municipio") %>% 
  left_join(df_06_equip, by = "cod_municipio") %>%
  mutate(ano = 2006,
    cod_municipio = as.character(cod_municipio),
    gestor_sexo = NA_character_,
    gestor_idade = NA_character_,
    gestor_cor_raca = NA_character_,
    tem_conselho = fix_sim_nao(tem_conselho),
    tem_plano = fix_sim_nao(tem_plano),
    tem_fundo = fix_sim_nao(tem_fundo),
    tem_lei_patrimonio = fix_sim_nao(tem_lei_patrimonio),
    tem_cons_patrimonio = fix_sim_nao(tem_cons_patrimonio))

# --- Extração Específica: Conselhos de Cultura (2014, 2018, 2021) ---
df_cons_21 <- read_excel(path_21, sheet = "Cultura") %>%
  clean_names() %>%
  filter(fix_sim_nao(mcul19) == "Sim") %>%
  mutate(cod_municipio = as.character(cod_mun),
    ano = 2021,
    cons_paritario = case_when(str_detect(str_to_lower(as.character(mcul21)), "sim|^1$|^s$|parit") ~ "Paritário",
      str_detect(str_to_lower(as.character(mcul21)), "não|^0$|^2$|^n$") ~ "Não Paritário",
      TRUE ~ "Sem Informação"),
    tem_deliberativo = fix_sim_nao(mcul202) == "Sim",
    tem_consultivo   = fix_sim_nao(mcul201) == "Sim",
    tem_norm_fisc    = fix_sim_nao(mcul203) == "Sim" | fix_sim_nao(mcul204) == "Sim",
    cons_competencia = case_when(tem_deliberativo ~ "Deliberativo (com ou sem consultivo)",
      !tem_deliberativo & tem_consultivo ~ "Apenas Consultivo",
      !tem_deliberativo & !tem_consultivo & tem_norm_fisc ~ "Normativo / Fiscalizador",
      TRUE ~ "Sem Informação")) %>%
  select(cod_municipio, ano, cons_paritario, cons_competencia)

df_cons_18 <- read_excel(path_18, sheet = "Cultura") %>%
  clean_names() %>%
  filter(fix_sim_nao(mcul19) == "Sim") %>%
  mutate(cod_municipio = as.character(cod_mun),
    ano = 2018,
    cons_paritario = NA_character_,
    tem_deliberativo = fix_sim_nao(mcul202) == "Sim",
    tem_consultivo   = fix_sim_nao(mcul201) == "Sim",
    tem_norm_fisc    = fix_sim_nao(mcul203) == "Sim" | fix_sim_nao(mcul204) == "Sim",
    cons_competencia = case_when(tem_deliberativo ~ "Deliberativo (com ou sem consultivo)",
      !tem_deliberativo & tem_consultivo ~ "Apenas Consultivo",
      !tem_deliberativo & !tem_consultivo & tem_norm_fisc ~ "Normativo / Fiscalizador",
      TRUE ~ "Sem Informação")) %>%
  select(cod_municipio, ano, cons_paritario, cons_competencia)

df_cons_14 <- read_excel(path_14, sheet = "Instâncias participativas") %>%
  clean_names() %>%
  filter(fix_sim_nao(a305) == "Sim") %>%
  mutate(cod_municipio = as.character(a1),
    ano = 2014,
    cons_paritario = case_when(str_detect(str_to_lower(as.character(a307)), "é paritário|^parit|sim|^1$") ~ "Paritário",
      str_detect(str_to_lower(as.character(a307)), "maior representação|governamental|sociedade civil|não|^2$") ~ "Não Paritário",
      TRUE ~ "Sem Informação"),
    tem_deliberativo = fix_sim_nao(a309) == "Sim",
    tem_consultivo   = fix_sim_nao(a308) == "Sim",
    tem_norm_fisc    = fix_sim_nao(a310) == "Sim" | fix_sim_nao(a311) == "Sim",
    cons_competencia = case_when(tem_deliberativo ~ "Deliberativo (com ou sem consultivo)",
      !tem_deliberativo & tem_consultivo ~ "Apenas Consultivo",
      !tem_deliberativo & !tem_consultivo & tem_norm_fisc ~ "Normativo / Fiscalizador",
      TRUE ~ "Sem Informação")) %>%
  select(cod_municipio, ano, cons_paritario, cons_competencia)

df_conselhos_detalhado <- bind_rows(df_cons_14, df_cons_18, df_cons_21)

# ------------------------------------------------------------------------------
# 4. CONSOLIDAÇÃO, PADRONIZAÇÃO E LIMPEZA DA SESSÃO
# ------------------------------------------------------------------------------
dicionario_municipios <- df_21 %>%
  select(cod_oficial = cod_municipio, nome_oficial = municipio) %>%
  distinct() %>%
  mutate(raiz_6_digitos = str_sub(cod_oficial, 1, 6))

df_painel_historico <- bind_rows(df_21, df_18, df_14, df_06) %>%
  mutate(raiz_6_digitos = str_sub(cod_municipio, 1, 6)) %>%
  left_join(dicionario_municipios, by = "raiz_6_digitos") %>%
  mutate(cod_municipio = coalesce(cod_oficial, cod_municipio),
    municipio = coalesce(nome_oficial, municipio),
    cod_uf = str_sub(cod_municipio, 1, 2),
    uf = case_match(cod_uf,
      "11" ~ "RO", "12" ~ "AC", "13" ~ "AM", "14" ~ "RR", "15" ~ "PA", "16" ~ "AP", "17" ~ "TO",
      "21" ~ "MA", "22" ~ "PI", "23" ~ "CE", "24" ~ "RN", "25" ~ "PB", "26" ~ "PE", "27" ~ "AL", "28" ~ "SE", "29" ~ "BA",
      "31" ~ "MG", "32" ~ "ES", "33" ~ "RJ", "35" ~ "SP",
      "41" ~ "PR", "42" ~ "SC", "43" ~ "RS",
      "50" ~ "MS", "51" ~ "MT", "52" ~ "GO", "53" ~ "DF",
      .default = "Outro"),
    regiao = case_when(str_starts(cod_municipio, "1") ~ "Norte",
      str_starts(cod_municipio, "2") ~ "Nordeste",
      str_starts(cod_municipio, "3") ~ "Sudeste",
      str_starts(cod_municipio, "4") ~ "Sul",
      str_starts(cod_municipio, "5") ~ "Centro-Oeste",
      TRUE ~ "Sem Informação"),
    gestor_idade_num = suppressWarnings(as.numeric(gestor_idade)),
    gestor_faixa_etaria = case_when(gestor_idade_num < 30 ~ "Até 29 anos",
      gestor_idade_num >= 30 & gestor_idade_num <= 39 ~ "30 a 39 anos",
      gestor_idade_num >= 40 & gestor_idade_num <= 49 ~ "40 a 49 anos",
      gestor_idade_num >= 50 & gestor_idade_num <= 59 ~ "50 a 59 anos",
      gestor_idade_num >= 60 ~ "60 anos ou mais",
      TRUE ~ NA_character_),
    gestor_cor_raca_limpa = case_when(gestor_cor_raca %in% c("Branca", "Preta", "Parda", "Amarela", "Indígena") ~ gestor_cor_raca,
      TRUE ~ NA_character_),
    gestor_grupo_raca = case_when(gestor_cor_raca_limpa %in% c("Preta", "Parda") ~ "Negros (Pretos e Pardos)",
      gestor_cor_raca_limpa == "Branca" ~ "Brancos",
      gestor_cor_raca_limpa %in% c("Amarela", "Indígena") ~ "Amarela / Indígena",
      TRUE ~ NA_character_),
    gestor_escolaridade_agrupada = case_when(str_detect(str_to_lower(gestor_escolaridade), "pós|especializa|mestrado|doutorado") ~ "Pós-Graduação",
      str_detect(str_to_lower(gestor_escolaridade), "superior|graduação") ~ "Ensino Superior",
      str_detect(str_to_lower(gestor_escolaridade), "médio|2º grau|2° grau|2o grau|segundo grau") ~ "Ensino Médio",
      str_detect(str_to_lower(gestor_escolaridade), "fundamental|1º grau|1° grau|1o grau|sem instrução|primeiro grau") ~ "Ensino Fundamental",
      TRUE ~ "Sem Informação")) %>%
  select(cod_municipio, municipio, cod_uf, uf, regiao, ano, populacao, tipo_orgao_gestor, tem_plano, tem_conselho, tem_fundo, 
    starts_with("tem_"), starts_with("equip_"), starts_with("gestor_"), starts_with("plano_"), starts_with("sec_"), starts_with("cons_"), starts_with("lab_"), everything(),
    -raiz_6_digitos, -cod_oficial, -nome_oficial) %>%
  arrange(cod_municipio, ano)

write_excel_csv(df_painel_historico, "munic_cultura_painel_historico_06_21.csv")

rm(df_21, df_18, df_14, df_06, df_cons_21, df_cons_18, df_cons_14, dicionario_municipios,
  df_14_org, df_14_plano, df_14_cons, df_14_fund, df_14_rh, df_14_leg, df_14_equip,
  df_06_org, df_06_plano, df_06_cons, df_06_fund, df_06_rh, df_06_leg, df_06_equip)
gc()

# ------------------------------------------------------------------------------
# 5. CONFIGURAÇÃO VISUAL E MAPAS BASE
# ------------------------------------------------------------------------------
cor_plano <- "#E74C3C"
cor_conselho <- "#2980B9"
cor_fundo <- "#27AE60"

tema_mapa_nt <- theme_void(base_size = 14) +
  theme(legend.position = "bottom",
    legend.direction = "horizontal",
    legend.title = element_text(face = "bold", size = 12, color = "#2C3E50"),
    legend.text = element_text(size = 11, color = "#34495E"),
    plot.title = element_text(face = "bold", hjust = 0.5, size = 16, color = "#2C3E50"),
    plot.subtitle = element_text(hjust = 0.5, size = 12, color = "#7F8C8D", margin = margin(b = 20)),
    plot.margin = margin(t = 20, r = 20, b = 20, l = 20))

# ==============================================================================
# 6. VISUALIZAÇÕES: GRÁFICOS
# ==============================================================================

# --- GRÁFICO 1: EVOLUÇÃO DO TRIPÉ INSTITUCIONAL (2006-2021) ---
df_tripe <- df_painel_historico %>%
  select(ano, tem_plano, tem_conselho, tem_fundo) %>%
  pivot_longer(cols = -ano, names_to = "instrumento", values_to = "status") %>%
  filter(!is.na(status), status %in% c("Sim", "Não")) %>%
  mutate(tem_instrumento = ifelse(status == "Sim", 1, 0)) %>%
  group_by(ano, instrumento) %>%
  summarise(taxa = mean(tem_instrumento), .groups = 'drop') %>%
  mutate(instrumento = recode(instrumento, "tem_plano" = "Plano de Cultura", "tem_conselho" = "Conselho de Cultura", "tem_fundo" = "Fundo de Cultura"))

ggplot(df_tripe, aes(x = ano, y = taxa, color = instrumento, group = instrumento)) +
  geom_line(linewidth = 1.5) +
  geom_point(size = 4) +
  geom_text(aes(label = percent(taxa, accuracy = 1)), vjust = -1.2, size = 4.5, show.legend = FALSE, fontface = "bold") +
  scale_y_continuous(labels = percent_format(), limits = c(0, 0.6)) +
  scale_x_continuous(breaks = c(2006, 2014, 2018, 2021)) +
  scale_color_manual(values = c("Conselho de Cultura" = cor_conselho, "Fundo de Cultura" = cor_fundo, "Plano de Cultura" = cor_plano)) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "bottom", plot.title = element_text(face = "bold", size = 16), panel.grid.minor = element_blank()) +
  labs(title = "Evolução do Tripé Institucional da Cultura (2006-2021)", subtitle = "Proporção de municípios brasileiros com os instrumentos criados", x = "Ano da Pesquisa (MUNIC/IBGE)", y = "Porcentagem de Municípios", color = "")

# --- GRÁFICO 2: PERFIL DA BUROCRACIA - GÊNERO ---
df_sexo <- df_painel_historico %>%
  filter(ano %in% c(2014, 2018, 2021), gestor_sexo %in% c("Feminino", "Masculino")) %>%
  count(ano, gestor_sexo) %>%
  group_by(ano) %>%
  mutate(porcentagem = n / sum(n))

ggplot(df_sexo, aes(x = factor(ano), y = porcentagem, fill = gestor_sexo)) +
  geom_col(width = 0.5) +
  geom_text(aes(label = percent(porcentagem, accuracy = 0.1)), position = position_stack(vjust = 0.5), color = "white", fontface = "bold", size = 5) +
  scale_y_continuous(labels = percent_format()) +
  scale_fill_manual(values = c("Feminino" = "#8E44AD", "Masculino" = "#34495E")) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "top", plot.title = element_text(face = "bold"), panel.grid.major.x = element_blank()) +
  labs(title = "Gênero dos Titulares dos Órgãos Gestores de Cultura", subtitle = "Participação feminina e masculina no comando cultural dos municípios", x = "Ano", y = "", fill = "")

# --- GRÁFICO 3: EFEITO ALDIR BLANC - EXECUÇÃO ORÇAMENTÁRIA (2021) ---
df_lab <- df_painel_historico %>%
  filter(ano == 2021, !is.na(orcamento_perc_executado), orcamento_perc_executado != "Sem Informação") %>%
  mutate(orcamento_perc_executado = factor(orcamento_perc_executado, levels = c("0%", "Até 10%", "11% a 20%", "21% a 30%", "31% a 40%", "41% a 50%", "51% a 60%", "61% a 70%", "71% a 80%", "81% a 90%", "Mais de 90%"))) %>%
  count(orcamento_perc_executado) %>%
  mutate(porcentagem = n / sum(n), label_barra = paste0(n, " (", percent(porcentagem, accuracy = 0.1), ")"))

ggplot(df_lab, aes(y = fct_rev(orcamento_perc_executado), x = n)) +
  geom_col(fill = "#16A085", width = 0.7) +
  geom_text(aes(label = label_barra), hjust = -0.1, color = "#2C3E50", size = 4.5, fontface = "bold") +
  scale_x_continuous(expand = expansion(mult = c(0, 0.2))) +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(face = "bold"), panel.grid.major.y = element_blank()) +
  labs(title = "Orçamento Executado (2021)", subtitle = "Número absoluto de municípios e proporção (%) do nível de execução do orçamento", x = "Quantidade de Municípios", y = "Percentual do Orçamento Executado", caption = "Fonte: Elaboração própria com base na MUNIC/IBGE 2021.")

# --- GRÁFICO 4: EVOLUÇÃO DO TIPO DE ÓRGÃO GESTOR ---
df_orgao_evol <- df_painel_historico %>%
  filter(!is.na(tipo_orgao_gestor), tipo_orgao_gestor != "Recusa", tipo_orgao_gestor != "Sem Informação") %>%
  mutate(tipo_simplificado = case_when(str_detect(str_to_lower(tipo_orgao_gestor), "exclusiva|fundação") ~ "Secretaria Exclusiva / Fundação",
    str_detect(str_to_lower(tipo_orgao_gestor), "conjunto") ~ "Secretaria em Conjunto (Ex: Educação e Cultura)",
    TRUE ~ "Setor Subordinado / Outros")) %>%
  count(ano, tipo_simplificado) %>%
  group_by(ano) %>%
  mutate(porcentagem = n / sum(n))

ggplot(df_orgao_evol, aes(x = factor(ano), y = porcentagem, fill = fct_reorder(tipo_simplificado, porcentagem))) +
  geom_col(width = 0.6, color = "white", linewidth = 0.5) +
  geom_text(aes(label = percent(porcentagem, accuracy = 1)), position = position_stack(vjust = 0.5), color = "white", fontface = "bold", size = 4.5) +
  scale_y_continuous(labels = percent_format()) +
  scale_fill_manual(values = c("Secretaria Exclusiva / Fundação" = "#27AE60", "Secretaria em Conjunto (Ex: Educação e Cultura)" = "#F39C12", "Setor Subordinado / Outros" = "#7F8C8D")) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "bottom", legend.direction = "vertical", panel.grid.major.x = element_blank()) +
  labs(title = "A Estrutura do Órgão Gestor de Cultura (2006-2021)", subtitle = "O espaço das secretarias exclusivas de cultura resistiu às crises?", x = "Ano da Pesquisa", y = "Proporção de Municípios", fill = "")

# --- GRÁFICO 5: GESTORES ALTAMENTE INSTITUCIONALIZADOS ---
df_cruzamento <- df_painel_historico %>%
  filter(ano == 2021, !is.na(gestor_escolaridade_agrupada), gestor_escolaridade_agrupada != "Sem Informação") %>%
  mutate(p_num = ifelse(tem_plano == "Sim", 1, 0),
    c_num = ifelse(tem_conselho == "Sim", 1, 0),
    f_num = ifelse(tem_fundo == "Sim", 1, 0),
    tripe_completo = ifelse((p_num + c_num + f_num) == 3, "Tripé Completo (Os 3)", "Incompleto/Nenhum")) %>%
  count(gestor_escolaridade_agrupada, tripe_completo) %>%
  group_by(gestor_escolaridade_agrupada) %>%
  mutate(percentual = n / sum(n)) %>%
  filter(tripe_completo == "Tripé Completo (Os 3)") %>%
  mutate(gestor_escolaridade_agrupada = factor(
    gestor_escolaridade_agrupada,
    levels = c("Ensino Fundamental", "Ensino Médio", "Ensino Superior", "Pós-Graduação")))

ggplot(df_cruzamento, aes(x = gestor_escolaridade_agrupada, y = percentual)) +
  geom_col(fill = "#8E44AD", width = 0.6) +
  geom_text(aes(label = percent(percentual, accuracy = 0.1)), hjust = -0.2, color = "black", size = 4.5, fontface = "bold") +
  coord_flip() +
  scale_y_continuous(labels = percent_format(), expand = expansion(mult = c(0, 0.2))) +
  theme_minimal(base_size = 14) +
  theme(panel.grid.major.y = element_blank(), plot.title = element_text(face = "bold")) +
  labs(title = "Escolaridade do Gestor vs. Institucionalização (2021)", subtitle = "Percentual de municípios com o Tripé Completo (Plano, Fundo e Conselho)", x = "Nível de Escolaridade do Titular da Cultura", y = "Percentual de Municípios")

# --- GRÁFICO 6: PERFIL ÉTNICO-RACIAL DOS GESTORES DE CULTURA (2018 vs. 2021) ---
df_raca <- df_painel_historico %>%
  filter(ano %in% c(2018, 2021), !is.na(gestor_cor_raca_limpa)) %>%
  count(ano, gestor_cor_raca_limpa) %>%
  group_by(ano) %>%
  mutate(porcentagem = n / sum(n))

ggplot(df_raca, aes(x = factor(ano), y = porcentagem, fill = fct_reorder(gestor_cor_raca_limpa, porcentagem))) +
  geom_col(width = 0.55, position = "stack", color = "white") +
  geom_text(aes(label = percent(porcentagem, accuracy = 0.1)), position = position_stack(vjust = 0.5), color = "white", fontface = "bold", size = 4.5) +
  scale_y_continuous(labels = percent_format()) +
  scale_fill_manual(values = c("Parda" = "#D35400", "Branca" = "#2980B9", "Preta" = "#8E44AD", "Indígena" = "#27AE60", "Amarela" = "#F1C40F")) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "right", plot.title = element_text(face = "bold", size = 16), panel.grid.major.x = element_blank()) +
  labs(title = "Perfil Étnico-Racial dos Gestores Municipais de Cultura", subtitle = "Distribuição percentual dos titulares por raça/cor autodeclarada (2018-2021)", x = "Ano da Pesquisa", y = "Proporção de Gestores", fill = "Cor / Raça")

# --- GRÁFICO 7: INTERSECCIONALIDADE NA GESTÃO CULTURAL (2021) ---
df_interseccional <- df_painel_historico %>%
  filter(ano == 2021, gestor_sexo %in% c("Feminino", "Masculino"), !is.na(gestor_grupo_raca)) %>%
  mutate(perfil_intersec = paste(gestor_sexo, "-", gestor_grupo_raca)) %>%
  count(perfil_intersec) %>%
  mutate(porcentagem = n / sum(n))

ggplot(df_interseccional, aes(x = fct_reorder(perfil_intersec, porcentagem), y = porcentagem, fill = perfil_intersec)) +
  geom_col(width = 0.65, show.legend = FALSE) +
  geom_text(aes(label = percent(porcentagem, accuracy = 0.1)), hjust = -0.15, fontface = "bold", size = 4.5, color = "#2C3E50") +
  coord_flip() +
  scale_y_continuous(labels = percent_format(), expand = expansion(mult = c(0, 0.18))) +
  scale_fill_brewer(palette = "Set2") +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(face = "bold"), panel.grid.major.y = element_blank()) +
  labs(title = "Interseccionalidade no Comando da Cultura Municipal (2021)", subtitle = "Cruzamento de gênero e raça dos titulares dos órgãos gestores de cultura", x = "", y = "Proporção de Municípios")

# --- GRÁFICO 8: EVOLUÇÃO DA ESCOLARIDADE DOS GESTORES (2006-2021) ---
df_esc_evol <- df_painel_historico %>%
  filter(!is.na(gestor_escolaridade_agrupada), gestor_escolaridade_agrupada != "Sem Informação") %>%
  mutate(gestor_escolaridade_agrupada = factor(gestor_escolaridade_agrupada,
    levels = c("Ensino Fundamental", "Ensino Médio", "Ensino Superior", "Pós-Graduação"))) %>%
  count(ano, gestor_escolaridade_agrupada) %>%
  group_by(ano) %>%
  mutate(porcentagem = n / sum(n))

ggplot(df_esc_evol, aes(x = factor(ano), y = porcentagem, fill = gestor_escolaridade_agrupada)) +
  geom_col(width = 0.6, color = "white") +
  geom_text(aes(label = percent(porcentagem, accuracy = 1)), position = position_stack(vjust = 0.5), color = "white", fontface = "bold", size = 4.3) +
  scale_y_continuous(labels = percent_format()) +
  scale_fill_manual(values = c("Ensino Fundamental" = "#E67E22", "Ensino Médio" = "#F39C12", "Ensino Superior" = "#2980B9", "Pós-Graduação" = "#27AE60")) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "bottom", legend.direction = "horizontal", plot.title = element_text(face = "bold"), panel.grid.major.x = element_blank()) +
  labs(title = "Nível de Escolaridade dos Gestores de Cultura (2006-2021)", subtitle = "Distribuição percentual da escolaridade dos dirigentes municipais de cultura", x = "Ano da Pesquisa", y = "Proporção de Gestores", fill = "Escolaridade:")

# --- GRÁFICO 9: ESTRUTURA ETÁRIA DOS GESTORES (2014, 2018, 2021) ---
df_idade_evol <- df_painel_historico %>%
  filter(ano %in% c(2014, 2018, 2021), !is.na(gestor_faixa_etaria)) %>%
  mutate(gestor_faixa_etaria = factor(gestor_faixa_etaria,
    levels = c("Até 29 anos", "30 a 39 anos", "40 a 49 anos", "50 a 59 anos", "60 anos ou mais"))) %>%
  count(ano, gestor_faixa_etaria) %>%
  group_by(ano) %>%
  mutate(porcentagem = n / sum(n))

ggplot(df_idade_evol, aes(x = gestor_faixa_etaria, y = porcentagem, fill = factor(ano))) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7) +
  geom_text(aes(label = percent(porcentagem, accuracy = 1)), position = position_dodge(width = 0.8), vjust = -0.4, fontface = "bold", size = 3.8) +
  scale_y_continuous(labels = percent_format(), expand = expansion(mult = c(0, 0.15))) +
  scale_fill_manual(values = c("2014" = "#95A5A6", "2018" = "#3498DB", "2021" = "#2C3E50")) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "top", plot.title = element_text(face = "bold"), panel.grid.minor = element_blank()) +
  labs(title = "Distribuição Etária dos Dirigentes de Cultura", subtitle = "Comparativo das faixas etárias dos titulares da pasta (2014, 2018 e 2021)", x = "Faixa Etária", y = "Proporção de Gestores", fill = "Ano:")

# --- GRÁFICO 10: RANKING POR UF DO TRIPÉ INSTITUCIONAL COMPLETO (2021) ---
df_tripe_uf <- df_painel_historico %>%
  filter(ano == 2021, uf != "Outro") %>%
  mutate(tem_p = ifelse(tem_plano == "Sim", 1, 0),
    tem_c = ifelse(tem_conselho == "Sim", 1, 0),
    tem_f = ifelse(tem_fundo == "Sim", 1, 0),
    tripe_completo = ifelse(tem_p + tem_c + tem_f == 3, 1, 0)) %>%
  group_by(regiao, uf) %>%
  summarise(taxa_tripe = mean(tripe_completo, na.rm = TRUE), total_mun = n(), .groups = 'drop') %>%
  arrange(desc(taxa_tripe))

ggplot(df_tripe_uf, aes(x = reorder(uf, taxa_tripe), y = taxa_tripe, fill = regiao)) +
  geom_col(width = 0.7) +
  geom_text(aes(label = percent(taxa_tripe, accuracy = 1)), hjust = -0.15, size = 3.5, fontface = "bold", color = "#2C3E50") +
  coord_flip() +
  scale_y_continuous(labels = percent_format(), expand = expansion(mult = c(0, 0.15))) +
  scale_fill_brewer(palette = "Dark2") +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"), panel.grid.major.y = element_blank(), legend.position = "bottom") +
  labs(title = "Tripé Institucional Completo por UF (2021)", subtitle = "Percentual de municípios com Conselho, Fundo e Plano simultaneamente ativos", x = "Unidade da Federação", y = "Taxa de Adesão Plena ao Tripé", fill = "Região:")

# --- GRÁFICO 11: EVOLUÇÃO DE EQUIPAMENTOS CULTURAIS MUNICIPAIS (2006-2021) ---
df_equip <- df_painel_historico %>%
  select(ano, equip_biblioteca, equip_museu, equip_teatro, equip_cinema) %>%
  pivot_longer(cols = -ano, names_to = "equipamento", values_to = "status") %>%
  filter(!is.na(status), status %in% c("Sim", "Não")) %>%
  mutate(tem_equip = ifelse(status == "Sim", 1, 0),
    equipamento = case_match(equipamento,
      "equip_biblioteca" ~ "Biblioteca Pública",
      "equip_museu" ~ "Museu",
      "equip_teatro" ~ "Teatro / Casa de Espetáculos",
      "equip_cinema" ~ "Cinema / Sala de Exibição")) %>%
  group_by(ano, equipamento) %>%
  summarise(taxa = mean(tem_equip, na.rm = TRUE), .groups = 'drop')

ggplot(df_equip, aes(x = ano, y = taxa, color = equipamento, group = equipamento)) +
  geom_line(linewidth = 1.3) +
  geom_point(size = 3.8) +
  geom_text(aes(label = percent(taxa, accuracy = 1)), vjust = -1.1, size = 4, fontface = "bold", show.legend = FALSE) +
  scale_y_continuous(labels = percent_format(), limits = c(0, 1)) +
  scale_x_continuous(breaks = c(2006, 2014, 2018, 2021)) +
  scale_color_brewer(palette = "Set1") +
  theme_minimal(base_size = 14) +
  theme(legend.position = "bottom", plot.title = element_text(face = "bold"), panel.grid.minor = element_blank()) +
  labs(title = "Presença de Equipamentos Culturais nos Municípios (2006-2021)", subtitle = "Proporção de cidades com bibliotecas, museus, teatros e cinemas municipais", x = "Ano da Pesquisa", y = "Percentual de Municípios", color = "")

# --- GRÁFICO 12: PROTEÇÃO AO PATRIMÔNIO CULTURAL (LEI E CONSELHO 2006-2021) ---
df_patrimonio <- df_painel_historico %>%
  select(ano, tem_lei_patrimonio, tem_cons_patrimonio) %>%
  pivot_longer(cols = -ano, names_to = "instrumento", values_to = "status") %>%
  filter(!is.na(status), status %in% c("Sim", "Não")) %>%
  mutate(tem_inst = ifelse(status == "Sim", 1, 0),
    instrumento = case_match(instrumento,
      "tem_lei_patrimonio" ~ "Legislação Específica de Patrimônio",
      "tem_cons_patrimonio" ~ "Conselho de Patrimônio Cultural")) %>%
  group_by(ano, instrumento) %>%
  summarise(taxa = mean(tem_inst, na.rm = TRUE), .groups = 'drop')

ggplot(df_patrimonio, aes(x = ano, y = taxa, color = instrumento, group = instrumento)) +
  geom_line(linewidth = 1.4) +
  geom_point(size = 4) +
  geom_text(aes(label = percent(taxa, accuracy = 1)), vjust = -1.2, size = 4.5, fontface = "bold", show.legend = FALSE) +
  scale_y_continuous(labels = percent_format(), limits = c(0, 0.65)) +
  scale_x_continuous(breaks = c(2006, 2014, 2018, 2021)) +
  scale_color_manual(values = c("Legislação Específica de Patrimônio" = "#8E44AD", "Conselho de Patrimônio Cultural" = "#D35400")) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "bottom", plot.title = element_text(face = "bold"), panel.grid.minor = element_blank()) +
  labs(title = "Institucionalização do Patrimônio Cultural nos Municípios", subtitle = "Evolução da existência de lei de tombamento/registro e conselho de patrimônio", x = "Ano da Pesquisa", y = "Percentual de Municípios", color = "")

# --- GRÁFICO 13: PARIDADE DOS CONSELHOS MUNICIPAIS DE CULTURA (2014 vs. 2021) ---
df_paridade_grafico <- df_conselhos_detalhado %>%
  filter(!is.na(cons_paritario), cons_paritario %in% c("Paritário", "Não Paritário")) %>%
  count(ano, cons_paritario) %>%
  group_by(ano) %>%
  mutate(porcentagem = n / sum(n))

ggplot(df_paridade_grafico, aes(x = factor(ano), y = porcentagem, fill = cons_paritario)) +
  geom_col(width = 0.5, position = "stack", color = "white") +
  geom_text(aes(label = paste0(percent(porcentagem, accuracy = 0.1), "\n(", n, ")")), position = position_stack(vjust = 0.5), color = "white", fontface = "bold", size = 4.5) +
  scale_y_continuous(labels = percent_format()) +
  scale_fill_manual(values = c("Paritário" = "#27AE60", "Não Paritário" = "#E74C3C")) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "top", plot.title = element_text(face = "bold", size = 16), panel.grid.major.x = element_blank()) +
  labs(title = "Composição dos Conselhos Municipais de Cultura: Paridade", subtitle = "Proporção de conselhos ativos paritários entre sociedade civil e poder público (2014 e 2021)", x = "Ano da Pesquisa", y = "Proporção dos Conselhos Ativos", fill = "Composição:")

# --- GRÁFICO 14: COMPETÊNCIA E ATUAÇÃO DOS CONSELHOS DE CULTURA (2014, 2018, 2021) ---
df_competencia_grafico <- df_conselhos_detalhado %>%
  filter(cons_competencia != "Sem Informação") %>%
  count(ano, cons_competencia) %>%
  group_by(ano) %>%
  mutate(porcentagem = n / sum(n))

ggplot(df_competencia_grafico, aes(x = factor(ano), y = porcentagem, fill = cons_competencia)) +
  geom_col(width = 0.6, position = "dodge", color = "white") +
  geom_text(aes(label = percent(porcentagem, accuracy = 0.1)), position = position_dodge(width = 0.6), vjust = -0.5, fontface = "bold", size = 3.8, color = "#2C3E50") +
  scale_y_continuous(labels = percent_format(), expand = expansion(mult = c(0, 0.15))) +
  scale_fill_manual(values = c("Deliberativo (com ou sem consultivo)" = "#2980B9", "Apenas Consultivo" = "#F39C12", "Normativo / Fiscalizador" = "#7F8C8D")) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "bottom", legend.direction = "vertical", plot.title = element_text(face = "bold", size = 16), panel.grid.minor = element_blank()) +
  labs(title = "Caráter e Competência dos Conselhos de Cultura", subtitle = "Atuação deliberativa, consultiva ou normativa dos conselhos municipais ativos (2014, 2018 e 2021)", x = "Ano da Pesquisa", y = "Proporção dos Conselhos Ativos", fill = "Competência do Conselho:")

# --- GRÁFICO 15: ADESÃO AO SNC POR PORTE POPULACIONAL (2021) ---
df_porte <- df_painel_historico %>%
  filter(ano == 2021, !is.na(populacao)) %>%
  mutate(porte_pop = case_when(
      populacao <= 20000 ~ "Até 20 mil hab.",
      populacao <= 50000 ~ "20.001 a 50 mil hab.",
      populacao <= 100000 ~ "50.001 a 100 mil hab.",
      populacao > 100000 ~ "Mais de 100 mil hab.",
      TRUE ~ "Sem Informação"),
    porte_pop = factor(porte_pop, levels = c("Até 20 mil hab.", "20.001 a 50 mil hab.", "50.001 a 100 mil hab.", "Mais de 100 mil hab.")),
    tem_p = ifelse(tem_plano == "Sim", 1, 0),
    tem_c = ifelse(tem_conselho == "Sim", 1, 0),
    tem_f = ifelse(tem_fundo == "Sim", 1, 0),
    tripe_completo = ifelse(tem_p + tem_c + tem_f == 3, 1, 0)) %>%
  group_by(porte_pop) %>%
  summarise(taxa_tripe = mean(tripe_completo, na.rm = TRUE), .groups = 'drop')

ggplot(df_porte, aes(x = porte_pop, y = taxa_tripe, fill = porte_pop)) +
  geom_col(width = 0.6) +
  geom_text(aes(label = percent(taxa_tripe, accuracy = 0.1)), vjust = -0.5, fontface = "bold", size = 4.5, color = "#2C3E50") +
  scale_y_continuous(labels = percent_format(), expand = expansion(mult = c(0, 0.15))) +
  scale_fill_brewer(palette = "Blues") +
  theme_minimal(base_size = 14) +
  theme(legend.position = "none", plot.title = element_text(face = "bold"), panel.grid.major.x = element_blank()) +
  labs(title = "Tripé Institucional Completo por Porte Populacional (2021)", subtitle = "Adesão simultânea a Conselho, Fundo e Plano segundo o tamanho do município", x = "Porte Populacional", y = "Taxa de Adesão Plena ao Tripé")

# --- GRÁFICO 16: SETORES COMPARTILHADOS NAS SECRETARIAS MISTAS (2018-2021) ---
df_setores <- df_painel_historico %>%
  filter(ano %in% c(2018, 2021), 
    !is.na(tipo_orgao_gestor), 
    tipo_orgao_gestor != "Recusa", 
    tipo_orgao_gestor != "Sem Informação") %>%
  mutate(e_exclusiva = str_detect(str_to_lower(tipo_orgao_gestor), "exclusiva|fundação|indireta"),
    e_conjunto  = str_detect(str_to_lower(tipo_orgao_gestor), "conjunto"),
    arranjo = case_when(e_exclusiva ~ "Apenas Cultura (Secretaria Exclusiva / Fundação)",
      e_conjunto & sec_educacao == "Sim" & sec_esporte == "Sim" & sec_turismo == "Sim" ~ "Cultura, Educação, Esporte e Turismo",
      e_conjunto & sec_educacao == "Sim" & sec_esporte == "Sim" ~ "Cultura, Educação e Esporte",
      e_conjunto & sec_educacao == "Sim" & sec_turismo == "Sim" ~ "Cultura, Educação e Turismo",
      e_conjunto & sec_esporte == "Sim" & sec_turismo == "Sim" ~ "Cultura, Esporte e Turismo",
      e_conjunto & sec_educacao == "Sim" ~ "Cultura e Educação",
      e_conjunto & sec_esporte == "Sim" ~ "Cultura e Esporte",
      e_conjunto & sec_turismo == "Sim" ~ "Cultura e Turismo",
      e_conjunto ~ "Cultura e Outros Setores Compartilhados",
      TRUE ~ "Setor Subordinado / Outras Estruturas")) %>%
  count(ano, arranjo) %>%
  group_by(ano) %>%
  mutate(taxa = n / sum(n)) %>%
  ungroup()

ggplot(df_setores, aes(x = taxa, y = fct_reorder(arranjo, taxa, .fun = sum), fill = factor(ano))) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7) +
  geom_text(aes(label = percent(taxa, accuracy = 0.1)), 
    position = position_dodge(width = 0.8), 
    hjust = -0.15, 
    fontface = "bold", 
    size = 3.8) +
  scale_x_continuous(labels = percent_format(), expand = expansion(mult = c(0, 0.2))) +
  scale_fill_manual(values = c("2018" = "#95A5A6", "2021" = "#E67E22")) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "top", 
    plot.title = element_text(face = "bold"), 
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank()) +
  labs(title = "Estrutura e Arranjos Organizacionais da Gestão Cultural", 
    subtitle = "Distribuição percentual de todos os tipos de órgãos gestores nos municípios (Soma 100%)", 
    x = "Proporção do Total de Municípios", 
    y = "Estrutura / Combinação Institucional", 
    fill = "Ano:")

# --- GRÁFICO 17: MATURIDADE DO PLANO DE CULTURA (LEI E PARTICIPAÇÃO) (2018-2021) ---
df_lei_plano <- df_painel_historico %>%
  filter(ano %in% c(2018, 2021), tem_plano == "Sim") %>%
  mutate(status_lei = case_when(plano_tem_lei == "Sim" ~ "Possui Lei Específica",
    plano_tem_lei == "Não" ~ "Sem Lei Específica",
    TRUE ~ "Sem Informação / Em tramitação")) %>%
  count(ano, status_lei) %>%
  group_by(ano) %>%
  mutate(taxa = n / sum(n))

ggplot(df_lei_plano, aes(x = factor(ano), y = taxa, fill = status_lei)) +
  geom_col(width = 0.5, position = "stack", color = "white") +
  geom_text(aes(label = percent(taxa, accuracy = 1)), position = position_stack(vjust = 0.5), color = "white", fontface = "bold", size = 4.5) +
  scale_y_continuous(labels = percent_format()) +
  scale_fill_manual(values = c("Possui Lei Específica" = "#27AE60", "Sem Lei Específica" = "#E74C3C", "Sem Informação / Em tramitação" = "#95A5A6")) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "right", plot.title = element_text(face = "bold"), panel.grid.major.x = element_blank()) +
  labs(title = "Plano Municipal de Cultura: Instituição por Lei", subtitle = "Dentre os municípios que possuem Plano, quantos foram aprovados por lei específica?", x = "Ano da Pesquisa", y = "Proporção de Municípios com Plano", fill = "Situação Legal:")


# GRÁFICO 18: PLANO DE CULTURA - PARTICIPAÇÃO SOCIAL
df_part_plano <- df_painel_historico %>%
  filter(ano %in% c(2018, 2021), tem_plano == "Sim") %>%
  mutate(status_part = case_when(plano_participacao_soc == "Sim" ~ "Com Participação Social",
    plano_participacao_soc == "Não" ~ "Sem Participação",
    TRUE ~ "Sem Informação")) %>%
  count(ano, status_part) %>%
  group_by(ano) %>%
  mutate(taxa = n / sum(n))

ggplot(df_part_plano, aes(x = factor(ano), y = taxa, fill = status_part)) +
  geom_col(width = 0.5, position = "stack", color = "white") +
  geom_text(aes(label = percent(taxa, accuracy = 1)), position = position_stack(vjust = 0.5), color = "white", fontface = "bold", size = 4.5) +
  scale_y_continuous(labels = percent_format()) +
  scale_fill_manual(values = c("Com Participação Social" = "#2980B9", "Sem Participação" = "#E67E22", "Sem Informação" = "#BDC3C7")) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "right", plot.title = element_text(face = "bold"), panel.grid.major.x = element_blank()) +
  labs(title = "Plano Municipal de Cultura: Participação Social", subtitle = "Dentre os municípios que possuem Plano, proporção com participação da sociedade civil", x = "Ano da Pesquisa", y = "Proporção de Municípios com Plano", fill = "Construção do Plano:")

# --- GRÁFICO 19: CAPACITAÇÃO DE CONSELHEIROS DE CULTURA (2018-2021) ---
df_cap_cons <- df_painel_historico %>%
  filter(ano %in% c(2018, 2021), tem_conselho == "Sim") %>%
  mutate(status_cap = case_when(cons_cap_continuada == "Sim" ~ "Capacitação Continuada",
    cons_cap_eventual == "Sim" ~ "Capacitação Eventual",
    cons_cap_nao_realiza == "Sim" ~ "Não Realiza Capacitação",
    TRUE ~ "Sem Informação")) %>%
  filter(status_cap != "Sem Informação") %>%
  count(ano, status_cap) %>%
  group_by(ano) %>%
  mutate(perc = n / sum(n)) %>%
  ungroup() %>%
  mutate(status_cap = factor(status_cap, levels = c("Capacitação Continuada", "Capacitação Eventual", "Não Realiza Capacitação")))

ggplot(df_cap_cons, aes(x = status_cap, y = perc, fill = factor(ano))) +
  geom_col(position = position_dodge(width = 0.7), width = 0.6) +
  geom_text(aes(label = percent(perc, accuracy = 1)), position = position_dodge(width = 0.7), vjust = -0.5, fontface = "bold", size = 4) +
  scale_y_continuous(labels = percent_format(), expand = expansion(mult = c(0, 0.15))) +
  scale_fill_manual(values = c("2018" = "#8E44AD", "2021" = "#D35400")) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "top", plot.title = element_text(face = "bold"), panel.grid.minor = element_blank()) +
  labs(title = "Capacitação dos Conselheiros de Cultura", subtitle = "Frequência de formação oferecida aos membros dos conselhos ativos", x = "Status de Capacitação", y = "Proporção de Conselhos", fill = "Ano:")

# --- GRÁFICO 20: MÉDIA DE MEMBROS NOS CONSELHOS POR REGIÃO (2021) ---
df_membros <- df_painel_historico %>%
  filter(ano == 2021, tem_conselho == "Sim", !is.na(cons_qtd_membros), cons_qtd_membros > 0, cons_qtd_membros < 150) %>% 
  group_by(regiao) %>%
  summarise(media_membros = round(mean(cons_qtd_membros, na.rm = TRUE), 1), .groups = 'drop')

ggplot(df_membros, aes(x = reorder(regiao, media_membros), y = media_membros, fill = regiao)) +
  geom_col(width = 0.6, show.legend = FALSE) +
  geom_text(aes(label = media_membros), hjust = -0.2, fontface = "bold", size = 4.5, color = "#2C3E50") +
  coord_flip() +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  scale_fill_brewer(palette = "Set2") +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(face = "bold"), panel.grid.major.y = element_blank()) +
  labs(title = "Tamanho Médio dos Conselhos de Cultura por Região (2021)", subtitle = "Média de conselheiros (titulares e suplentes) nos conselhos ativos", x = "Região", y = "Número Médio de Conselheiros")

# ==============================================================================
# 7. VISUALIZAÇÕES: TABELAS
# ==============================================================================

# --- TABELA 1: GASTO DA LEI ALDIR BLANC POR REGIÃO (2021) ---
tabela_lab_dados <- df_painel_historico %>%
  filter(ano == 2021, !is.na(orcamento_perc_executado), orcamento_perc_executado != "Sem Informação") %>%
  mutate(orcamento_perc_executado = factor(orcamento_perc_executado, 
    levels = c("0%", "Até 10%", "11% a 20%", "21% a 30%", "31% a 40%", "41% a 50%", "51% a 60%", "61% a 70%", "71% a 80%", "81% a 90%", "Mais de 90%"))) %>%
  count(regiao, orcamento_perc_executado) %>%
  group_by(regiao) %>%
  mutate(perc = n / sum(n)) %>%
  select(-n) %>%
  pivot_wider(names_from = orcamento_perc_executado, values_from = perc, values_fill = 0)

gt_tabela_lab <- tabela_lab_dados %>%
  gt() %>% 
  tab_header(title = md("**Execução Orçamentária da Lei Aldir Blanc por Região (2021)**"),
    subtitle = "Distribuição percentual dos municípios conforme o nível de execução do repasse") %>%
  cols_label(regiao = "Região") %>%
  fmt_percent(columns = -regiao, decimals = 1) %>%
  data_color(columns = -regiao,
    colors = scales::col_numeric(palette = c("white", "#AED6F1", "#2E86C1"), domain = c(0, 1))) %>%
  tab_options(heading.background.color = "#2C3E50",
    heading.title.font.size = px(18),
    heading.subtitle.font.size = px(14),
    column_labels.background.color = "#34495E",
    column_labels.font.weight = "bold",
    table.border.top.color = "transparent",
    table.border.bottom.color = "transparent") %>%
  tab_source_note(source_note = md("*Fonte: Elaboração própria com base na MUNIC/IBGE 2021.*"))

gtsave(gt_tabela_lab, "Tabela_Visual_1_LAB_Regiao.png")

# --- TABELA 2: EVOLUÇÃO DO TRIPÉ INSTITUCIONAL POR REGIÃO (2006-2021) ---
tabela_tripe_dados <- df_painel_historico %>%
  mutate(tem_p = ifelse(tem_plano == "Sim", 1, 0),
    tem_c = ifelse(tem_conselho == "Sim", 1, 0),
    tem_f = ifelse(tem_fundo == "Sim", 1, 0),
    tripe_completo = ifelse(tem_p + tem_c + tem_f == 3, 1, 0)) %>%
  group_by(ano, regiao) %>%
  summarise(perc_conselho = mean(tem_c, na.rm = TRUE),
    perc_fundo = mean(tem_f, na.rm = TRUE),
    perc_plano = mean(tem_p, na.rm = TRUE),
    perc_tripe_completo = mean(tripe_completo, na.rm = TRUE),
    .groups = 'drop') %>%
  arrange(ano, regiao)

gt_tabela_tripe <- tabela_tripe_dados %>%
  gt(groupname_col = "ano") %>%
  tab_header(title = md("**Evolução Regional do Tripé Institucional da Cultura**"),
    subtitle = "Proporção de municípios com Conselhos, Fundos, Planos e Tripé Completo (2006-2021)") %>%
  cols_label(regiao = "Região",
    perc_conselho = "Conselho",
    perc_fundo = "Fundo",
    perc_plano = "Plano",
    perc_tripe_completo = "Tripé Completo") %>%
  fmt_percent(columns = c(perc_conselho, perc_fundo, perc_plano, perc_tripe_completo), decimals = 1) %>%
  tab_style(style = cell_text(weight = "bold", color = "#C0392B"),
    locations = cells_body(columns = perc_tripe_completo)) %>%
  tab_options(row_group.background.color = "#ECF0F1",
    row_group.font.weight = "bold",
    heading.background.color = "#2C3E50",
    heading.title.font.size = px(18),
    heading.subtitle.font.size = px(14),
    column_labels.background.color = "#34495E",
    column_labels.font.weight = "bold") %>%
  tab_source_note(source_note = md("*Fonte: Elaboração própria com base na MUNIC/IBGE.*"))

gtsave(gt_tabela_tripe, "Tabela_Visual_2_Tripe_Regiao.png")

# --- TABELA 3: MATRIZ REGIONAL DA GESTÃO E DIVERSIDADE (2021) ---
tabela_matriz_2021 <- df_painel_historico %>%
  filter(ano == 2021, regiao != "Sem Informação") %>%
  mutate(sec_exclusiva = ifelse(str_detect(str_to_lower(tipo_orgao_gestor), "exclusiva|fundação"), 1, 0),
    mulheres = ifelse(gestor_sexo == "Feminino", 1, 0),
    negros = ifelse(gestor_cor_raca_limpa %in% c("Preta", "Parda"), 1, 0),
    superior_pos = ifelse(str_detect(str_to_lower(gestor_escolaridade), "superior|especializa|mestrado|doutorado|pós"), 1, 0),
    tem_p = ifelse(tem_plano == "Sim", 1, 0),
    tem_c = ifelse(tem_conselho == "Sim", 1, 0),
    tem_f = ifelse(tem_fundo == "Sim", 1, 0),
    tripe_completo = ifelse(tem_p + tem_c + tem_f == 3, 1, 0)) %>%
  group_by(regiao) %>%
  summarise(total_mun = n(),
    perc_exclusiva = mean(sec_exclusiva, na.rm = TRUE),
    perc_mulheres = mean(mulheres, na.rm = TRUE),
    perc_negros = mean(negros, na.rm = TRUE),
    perc_superior = mean(superior_pos, na.rm = TRUE),
    perc_tripe = mean(tripe_completo, na.rm = TRUE),
    .groups = 'drop')

gt_tabela_matriz <- tabela_matriz_2021 %>%
  gt() %>%
  tab_header(title = md("**Panorama Regional da Gestão Cultural Municipal (2021)**"),
    subtitle = "Estrutura institucional, representatividade na liderança e maturidade no SNC") %>%
  cols_label(regiao = "Região",
    total_mun = "Nº Municípios",
    perc_exclusiva = "Sec. Exclusiva / Fundação",
    perc_mulheres = "Mulheres Gestoras",
    perc_negros = "Gestores Negros",
    perc_superior = "Superior ou Pós",
    perc_tripe = "Tripé Completo") %>%
  fmt_number(columns = total_mun, decimals = 0) %>%
  fmt_percent(columns = starts_with("perc_"), decimals = 1) %>%
  data_color(columns = c(perc_exclusiva, perc_mulheres, perc_negros, perc_superior, perc_tripe),
    colors = scales::col_numeric(palette = c("#FFFFFF", "#D4E6F1", "#2874A6"), domain = c(0, 1))) %>%
  tab_options(heading.background.color = "#2C3E50",
    heading.title.font.size = px(18),
    heading.subtitle.font.size = px(13),
    column_labels.background.color = "#34495E",
    column_labels.font.weight = "bold") %>%
  tab_source_note(source_note = md("*Fonte: Elaboração própria com base na MUNIC/IBGE 2021.*"))

gtsave(gt_tabela_matriz, "Tabela_Visual_3_Matriz_Regional_2021.png")
