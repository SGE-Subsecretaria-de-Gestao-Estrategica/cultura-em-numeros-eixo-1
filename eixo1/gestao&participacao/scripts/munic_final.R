# ==============================================================================
# PAINEL MUNIC CULTURA (2006, 2014, 2018, 2021)
# ==============================================================================

# 1. CARREGAMENTO DE PACOTES E CONFIGURAÇÕES
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
# 2. FUNÇÕES AUXILIARES DE LIMPEZA
# ------------------------------------------------------------------------------
fix_sim_nao <- function(x) {
  case_when(str_detect(str_to_lower(as.character(x)), "sim|^1$|^s$") ~ "Sim",
            TRUE ~ "Não")
}

# ------------------------------------------------------------------------------
# 3. EXTRAÇÃO DOS MICRODADOS: ANO A ANO
# ------------------------------------------------------------------------------

# --- 2021 ---
path_21 <- file.path(dir_projeto, "2021", "Base_MUNIC_2021_20240425.xlsx")
df_21 <- read_excel(path_21, sheet = "Cultura") %>% 
  clean_names() %>%
  mutate(cod_municipio = as.character(cod_mun), 
    municipio = mun,
    ano = 2021,
    tem_plano = fix_sim_nao(mcul10),
    tem_conselho = fix_sim_nao(mcul19),
    tem_fundo = fix_sim_nao(mcul33),
    tem_lei_patrimonio = fix_sim_nao(mcul15),
    tem_cons_patrimonio = fix_sim_nao(mcul26),
    tipo_orgao_gestor = mcul01,
    gestor_sexo = mcul03,
    gestor_idade = as.character(mcul04),
    gestor_cor_raca = mcul05,
    gestor_escolaridade = mcul06,
    gestor_escolaridade_agrupada = case_when(
      str_detect(str_to_lower(mcul06), "mestrado|doutorado") ~ "Mestrado e doutorado",
      str_detect(str_to_lower(mcul06), "médio|superior|especialização") ~ "Ensino Médio a Pós-graduação lato sensu",
      str_detect(str_to_lower(mcul06), "fundamental") ~ "Ensino fundamental incompleto e completo",
      TRUE ~ "Sem Informação"),
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
  select(cod_municipio, municipio, ano, tem_conselho, tem_plano, tem_fundo, 
    tem_lei_patrimonio, tem_cons_patrimonio, tipo_orgao_gestor, gestor_sexo, 
    gestor_idade, gestor_cor_raca, gestor_escolaridade, gestor_escolaridade_agrupada, 
    orcamento_perc_executado, 
    equip_biblioteca, equip_museu, equip_teatro, equip_cinema)

# --- 2018 ---
path_18 <- file.path(dir_projeto, "2018", "Base_MUNIC_2018_xlsx_20201103.xlsx")
df_18 <- read_excel(path_18, sheet = "Cultura") %>% 
  clean_names() %>% 
  transmute(cod_municipio = as.character(cod_mun), ano = 2018,
            tipo_orgao_gestor = mcul01,
            tem_plano = fix_sim_nao(mcul10), 
            tem_conselho = fix_sim_nao(mcul19), 
            tem_fundo = fix_sim_nao(mcul33), 
            tem_lei_patrimonio = fix_sim_nao(mcul15), 
            tem_cons_patrimonio = fix_sim_nao(mcul26), 
            equip_biblioteca = mcul362, equip_museu = mcul361, 
            equip_teatro = mcul365, equip_cinema = mcul364, 
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

df_14 <- df_14_org %>% left_join(df_14_plano, by = "cod_municipio") %>% 
  left_join(df_14_cons, by = "cod_municipio") %>%
  left_join(df_14_fund, by = "cod_municipio") %>% 
  left_join(df_14_rh, by = "cod_municipio") %>%
  left_join(df_14_leg, by = "cod_municipio") %>% 
  left_join(df_14_equip, by = "cod_municipio") %>%
  mutate(ano = 2014, cod_municipio = as.character(cod_municipio), gestor_idade = as.character(gestor_idade), gestor_cor_raca = NA_character_, # Modificado aqui
         tem_conselho = fix_sim_nao(tem_conselho), tem_plano = fix_sim_nao(tem_plano), tem_fundo = fix_sim_nao(tem_fundo),
         tem_lei_patrimonio = fix_sim_nao(tem_lei_patrimonio), tem_cons_patrimonio = fix_sim_nao(tem_cons_patrimonio))

# --- 2006 ---
path_06 <- file.path(dir_projeto, "2006", "Base Suplemento Cultura 2006.xls")
df_06_org   <- read_excel(path_06, sheet = "Órgão gestor") %>% clean_names() %>% select(cod_municipio = a1, tipo_orgao_gestor = a2)
df_06_plano <- read_excel(path_06, sheet = "Instrumentos de gestão") %>% clean_names() %>% select(cod_municipio = a1, tem_plano = a104)
df_06_cons  <- read_excel(path_06, sheet = "Conselhos municipais") %>% clean_names() %>% select(cod_municipio = a1, tem_conselho = a130, tem_cons_patrimonio = a164)
df_06_fund  <- read_excel(path_06, sheet = "Fundo municipal") %>% clean_names() %>% select(cod_municipio = a1, tem_fundo = a196)
df_06_rh    <- read_excel(path_06, sheet = "Recursos humanos") %>% clean_names() %>% select(cod_municipio = a1, gestor_escolaridade = a12)
df_06_leg   <- read_excel(path_06, sheet = "Legislação") %>% clean_names() %>% select(cod_municipio = a1, tem_lei_patrimonio = a120)
df_06_equip <- read_excel(path_06, sheet = "Equipamentos") %>% clean_names() %>% select(cod_municipio = a1, equip_biblioteca = a424, equip_museu = a427, equip_teatro = a430, equip_cinema = a439)

df_06 <- df_06_org %>% left_join(df_06_plano, by = "cod_municipio") %>% 
  left_join(df_06_cons, by = "cod_municipio") %>%
  left_join(df_06_fund, by = "cod_municipio") %>% 
  left_join(df_06_rh, by = "cod_municipio") %>%
  left_join(df_06_leg, by = "cod_municipio") %>% 
  left_join(df_06_equip, by = "cod_municipio") %>%
  mutate(ano = 2006, cod_municipio = as.character(cod_municipio), gestor_sexo = NA_character_, gestor_idade = NA_character_, gestor_cor_raca = NA_character_, # Modificado aqui
         tem_conselho = fix_sim_nao(tem_conselho), tem_plano = fix_sim_nao(tem_plano), tem_fundo = fix_sim_nao(tem_fundo),
         tem_lei_patrimonio = fix_sim_nao(tem_lei_patrimonio), tem_cons_patrimonio = fix_sim_nao(tem_cons_patrimonio))

# ------------------------------------------------------------------------------
# 4. CONSOLIDAÇÃO FINAL E LIMPEZA
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
    gestor_escolaridade_agrupada = case_when(str_detect(str_to_lower(gestor_escolaridade), "mestrado|doutorado") ~ "Mestrado e doutorado",
      str_detect(str_to_lower(gestor_escolaridade), "médio|superior|especializa|pós|grau") ~ "Ensino Médio a Pós-graduação lato sensu",
      str_detect(str_to_lower(gestor_escolaridade), "fundamental") ~ "Ensino fundamental incompleto e completo",
      TRUE ~ "Sem Informação")) %>%
  select(cod_municipio, municipio, ano, tipo_orgao_gestor, tem_plano, tem_conselho, tem_fundo, 
         starts_with("tem_"), starts_with("equip_"), starts_with("gestor_"), starts_with("lab_"), everything(),
         -raiz_6_digitos, -cod_oficial, -nome_oficial) %>%
  arrange(cod_municipio, ano)

glimpse(df_painel_historico)

write_excel_csv(df_painel_historico, "munic_cultura_painel_historico_06_21.csv")

# ------------------------------------------------------------------------------
# 5. VISUALIZAÇÕES
# ------------------------------------------------------------------------------
cor_plano <- "#E74C3C"
cor_conselho <- "#2980B9"
cor_fundo <- "#27AE60"

# GRÁFICO 1: EVOLUÇÃO DO TRIPÉ INSTITUCIONAL (2006-2021)
df_tripe <- df_painel_historico %>%
  select(ano, tem_plano, tem_conselho, tem_fundo) %>%
  pivot_longer(cols = -ano, names_to = "instrumento", values_to = "status") %>%
  filter(!is.na(status), status %in% c("Sim", "Não")) %>%
  mutate(tem_instrumento = ifelse(status == "Sim", 1, 0)) %>%
  group_by(ano, instrumento) %>%
  summarise(taxa = mean(tem_instrumento), .groups = 'drop') %>%
  mutate(instrumento = recode(instrumento,
                              "tem_plano" = "Plano de Cultura",
                              "tem_conselho" = "Conselho de Cultura",
                              "tem_fundo" = "Fundo de Cultura"))

ggplot(df_tripe, aes(x = ano, y = taxa, color = instrumento, group = instrumento)) +
  geom_line(size = 1.5) +
  geom_point(size = 4) +
  geom_text(aes(label = percent(taxa, accuracy = 1)), vjust = -1.2, size = 4.5, show.legend = FALSE, fontface = "bold") +
  scale_y_continuous(labels = percent_format(), limits = c(0, 0.6)) +
  scale_x_continuous(breaks = c(2006, 2014, 2018, 2021)) +
  scale_color_manual(values = c("Conselho de Cultura" = cor_conselho, 
                                "Fundo de Cultura" = cor_fundo, 
                                "Plano de Cultura" = cor_plano)) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "bottom",
        plot.title = element_text(face = "bold", size = 16),
        panel.grid.minor = element_blank()) +
  labs(title = "Evolução do Tripé Institucional da Cultura (2006-2021)",
       subtitle = "Proporção de municípios brasileiros com os instrumentos criados",
       x = "Ano da Pesquisa (MUNIC/IBGE)", y = "Porcentagem de Municípios", color = "")

# GRÁFICO 2: PERFIL DA BUROCRACIA - GÊNERO 
df_sexo <- df_painel_historico %>%
  filter(ano %in% c(2014, 2018, 2021), 
         gestor_sexo %in% c("Feminino", "Masculino")) %>%
  count(ano, gestor_sexo) %>%
  group_by(ano) %>%
  mutate(porcentagem = n / sum(n))

ggplot(df_sexo, aes(x = factor(ano), y = porcentagem, fill = gestor_sexo)) +
  geom_col(width = 0.5) +
  geom_text(aes(label = percent(porcentagem, accuracy = 0.1)), 
            position = position_stack(vjust = 0.5), color = "white", fontface = "bold", size = 5) +
  scale_y_continuous(labels = percent_format()) +
  scale_fill_manual(values = c("Feminino" = "#8E44AD", "Masculino" = "#34495E")) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "top", 
        plot.title = element_text(face = "bold"),
        panel.grid.major.x = element_blank()) +
  labs(title = "Gênero dos Titulares dos Órgãos Gestores de Cultura",
       subtitle = "Participação feminina e masculina no comando cultural dos municípios",
       x = "Ano", y = "", fill = "")

# GRÁFICO 3: EFEITO ALDIR BLANC - EXECUÇÃO ORÇAMENTÁRIA (2021)
df_lab <- df_painel_historico %>%
  filter(ano == 2021, 
         !is.na(orcamento_perc_executado), 
         orcamento_perc_executado != "Sem Informação") %>%
  mutate(orcamento_perc_executado = factor(orcamento_perc_executado, 
                                           levels = c("0%", "Até 10%", "11% a 20%", "21% a 30%", "31% a 40%", "41% a 50%", 
                                                      "51% a 60%", "61% a 70%", "71% a 80%", "81% a 90%", "Mais de 90%"))) %>%
  count(orcamento_perc_executado) %>%
  mutate(porcentagem = n / sum(n), label_barra = paste0(n, " (", percent(porcentagem, accuracy = 0.1), ")"))

ggplot(df_lab, aes(y = fct_rev(orcamento_perc_executado), x = n)) +
  geom_col(fill = "#16A085", width = 0.7) +
  geom_text(aes(label = label_barra), hjust = -0.1, color = "#2C3E50", size = 4.5, fontface = "bold") +
  scale_x_continuous(expand = expansion(mult = c(0, 0.2))) +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(face = "bold"),
        panel.grid.major.y = element_blank()) +
  labs(title = "Orçamento Executado (2021)",
       subtitle = "Número absoluto de municípios e proporção (%) do nível de execução do orçamento",
       x = "Quantidade de Municípios",
       y = "Percentual do Orçamento Executado",
       caption = "Fonte: Elaboração própria com base na MUNIC/IBGE 2021.")

# GRÁFICO 4: EVOLUÇÃO DO TIPO DE ÓRGÃO GESTOR 
df_orgao_evol <- df_painel_historico %>%
  filter(!is.na(tipo_orgao_gestor), tipo_orgao_gestor != "Recusa", tipo_orgao_gestor != "Sem Informação") %>%
  mutate(tipo_simplificado = case_when(str_detect(str_to_lower(tipo_orgao_gestor), "exclusiva|fundação") ~ "Secretaria Exclusiva / Fundação",
                                       str_detect(str_to_lower(tipo_orgao_gestor), "conjunto") ~ "Secretaria em Conjunto (Ex: Educação e Cultura)",
                                       TRUE ~ "Setor Subordinado / Outros")) %>%
  count(ano, tipo_simplificado) %>%
  group_by(ano) %>%
  mutate(porcentagem = n / sum(n))

ggplot(df_orgao_evol, aes(x = factor(ano), y = porcentagem, fill = fct_reorder(tipo_simplificado, porcentagem))) +
  geom_col(width = 0.6, color = "white", size = 0.5) +
  geom_text(aes(label = percent(porcentagem, accuracy = 1)), 
            position = position_stack(vjust = 0.5), 
            color = "white", fontface = "bold", size = 4.5) +
  scale_y_continuous(labels = percent_format()) +
  scale_fill_manual(values = c("Secretaria Exclusiva / Fundação" = "#27AE60",
                               "Secretaria em Conjunto (Ex: Educação e Cultura)" = "#F39C12",
                               "Setor Subordinado / Outros" = "#7F8C8D")) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "bottom", 
        legend.direction = "vertical",
        panel.grid.major.x = element_blank()) +
  labs(title = "A Estrutura do Órgão Gestor de Cultura (2006-2021)",
       subtitle = "O espaço das secretarias exclusivas de cultura resistiu às crises?",
       x = "Ano da Pesquisa", y = "Proporção de Municípios", fill = "")

# GRÁFICO 5: GESTORES "ALTAMENTE INSTITUCIONALIZADOS"
df_cruzamento <- df_painel_historico %>%
  filter(ano == 2021, 
         !is.na(gestor_escolaridade_agrupada), 
         gestor_escolaridade_agrupada != "Sem Informação") %>%
  mutate(p_num = ifelse(tem_plano == "Sim", 1, 0),
         c_num = ifelse(tem_conselho == "Sim", 1, 0),
         f_num = ifelse(tem_fundo == "Sim", 1, 0),
         tripe_completo = ifelse((p_num + c_num + f_num) == 3, "Tripé Completo (Os 3)", "Incompleto/Nenhum")) %>%
  count(gestor_escolaridade_agrupada, tripe_completo) %>%
  group_by(gestor_escolaridade_agrupada) %>%
  mutate(percentual = n / sum(n)) %>%
  filter(tripe_completo == "Tripé Completo (Os 3)") %>%
  mutate(gestor_escolaridade_agrupada = factor(gestor_escolaridade_agrupada, 
                                               levels = c("Ensino fundamental incompleto e completo", 
                                                          "Ensino Médio a Pós-graduação lato sensu", 
                                                          "Mestrado e doutorado")))

ggplot(df_cruzamento, aes(x = gestor_escolaridade_agrupada, y = percentual)) +
  geom_col(fill = "#8E44AD", width = 0.6) +
  geom_text(aes(label = percent(percentual, accuracy = 0.1)), 
            hjust = -0.2, color = "black", size = 4.5, fontface = "bold") +
  coord_flip() +
  scale_y_continuous(labels = percent_format(), expand = expansion(mult = c(0, 0.2))) +
  theme_minimal(base_size = 14) +
  theme(panel.grid.major.y = element_blank(),
        plot.title = element_text(face = "bold")) +
  labs(title = "Escolaridade do Gestor vs. Institucionalização (2021)",
       subtitle = "Percentual de municípios com o Tripé Completo (Plano, Fundo e Conselho)",
       x = "Nível de Escolaridade do Titular da Cultura",
       y = "Percentual de Municípios")

# MAPA 1: ÍNDICE DO TRIPÉ INSTITUCIONAL (Plano, Conselho e Fundo)
mapa_br <- read_municipality(year = 2020, showProgress = FALSE)
mapa_estados <- read_state(year = 2020, showProgress = FALSE)

tema_mapa_nt <- theme_void(base_size = 14) +
  theme(legend.position = "bottom",
        legend.direction = "horizontal",
        legend.title = element_text(face = "bold", size = 12, color = "#2C3E50"),
        legend.text = element_text(size = 11, color = "#34495E"),
        plot.title = element_text(face = "bold", hjust = 0.5, size = 16, color = "#2C3E50"),
        plot.subtitle = element_text(hjust = 0.5, size = 12, color = "#7F8C8D", margin = margin(b = 20)),
        plot.margin = margin(t = 20, r = 20, b = 20, l = 20))

df_mapa_tripe <- df_painel_historico %>%
  filter(ano == 2021) %>%
  mutate(p_num = ifelse(tem_plano == "Sim", 1, 0),
         c_num = ifelse(tem_conselho == "Sim", 1, 0),
         f_num = ifelse(tem_fundo == "Sim", 1, 0),
         indice = p_num + c_num + f_num,
         indice_cat = factor(indice, levels = c(0, 1, 2, 3), 
                             labels = c("Nenhum (0)", "1 Instrumento", "2 Instrumentos", "Tripé Completo (3)"))) %>%
  mutate(code_muni = as.numeric(cod_municipio))

mapa_tripe <- left_join(mapa_br, df_mapa_tripe, by = "code_muni")

ggplot() +
  geom_sf(data = mapa_tripe, aes(fill = indice_cat), color = "transparent") +
  geom_sf(data = mapa_estados, fill = NA, color = "#34495E", linewidth = 0.3) +
  scale_fill_manual(values = c("Nenhum (0)" = "#EAECEE", 
                               "1 Instrumento" = "#AED6F1", 
                               "2 Instrumentos" = "#2E86C1", 
                               "Tripé Completo (3)" = "#154360"),
                    na.value = "#EAECEE") +
  tema_mapa_nt + labs(title = "Institucionalização Cultural no Território (2021)",
       subtitle = "Índice de presença simultânea: Conselho, Fundo e Plano Municipal",
       fill = "Nº de Instrumentos:")

# MAPA 2: ESTRUTURA DO ÓRGÃO GESTOR DE CULTURA
df_mapa_orgao <- df_painel_historico %>%
  filter(ano == 2021) %>%
  mutate(tipo_simplificado = case_when(str_detect(str_to_lower(tipo_orgao_gestor), "exclusiva|fundação") ~ "Secretaria Exclusiva / Fundação",
      str_detect(str_to_lower(tipo_orgao_gestor), "conjunto") ~ "Secretaria Conjunta",
      TRUE ~ "Setor Subordinado / Outros"), tipo_simplificado = factor(tipo_simplificado, 
                               levels = c("Setor Subordinado / Outros", 
                                          "Secretaria Conjunta", 
                                          "Secretaria Exclusiva / Fundação")),
    code_muni = as.numeric(cod_municipio))

mapa_orgao <- left_join(mapa_br, df_mapa_orgao, by = "code_muni")

ggplot() +
  geom_sf(data = mapa_orgao, aes(fill = tipo_simplificado), color = "transparent") +
  geom_sf(data = mapa_estados, fill = NA, color = "#34495E", linewidth = 0.3) +
  scale_fill_manual(values = c("Setor Subordinado / Outros" = "#D5DBDB", 
                               "Secretaria Conjunta" = "#F4D03F", 
                               "Secretaria Exclusiva / Fundação" = "#148F77"),
                    na.value = "#D5DBDB") + tema_mapa_nt +
  theme(legend.direction = "vertical") +
  labs(title = "Estrutura e Autonomia do Órgão Gestor (2021)",
       subtitle = "Nível de independência institucional da pasta da cultura nos municípios",
       fill = "")


# TABELA VISUAL 1: Gasto da Lei Aldir Blanc 1 por Região (2021)
df_painel_historico <- df_painel_historico %>%
  mutate(regiao = case_when(str_starts(cod_municipio, "1") ~ "Norte",
    str_starts(cod_municipio, "2") ~ "Nordeste",
    str_starts(cod_municipio, "3") ~ "Sudeste",
    str_starts(cod_municipio, "4") ~ "Sul",
    str_starts(cod_municipio, "5") ~ "Centro-Oeste",
    TRUE ~ "Sem Informação"))

tabela_lab_dados <- df_painel_historico %>%
  filter(ano == 2021, !is.na(orcamento_perc_executado), 
         orcamento_perc_executado != "Sem Informação") %>%
  mutate(orcamento_perc_executado = factor(orcamento_perc_executado, 
                                           levels = c("0%", "Até 10%", "11% a 20%", "21% a 30%", 
                                                      "31% a 40%", "41% a 50%", "51% a 60%", 
                                                      "61% a 70%", "71% a 80%", "81% a 90%", "Mais de 90%"))) %>%
  count(regiao, orcamento_perc_executado) %>%
  group_by(regiao) %>%
  mutate(perc = n / sum(n)) %>%
  select(-n) %>%
  pivot_wider(names_from = orcamento_perc_executado, 
              values_from = perc, 
              values_fill = 0)

gt_tabela_lab <- tabela_lab_dados %>%
  gt() %>% 
  tab_header(title = md("**Execução Orçamentária da Lei Aldir Blanc por Região (2021)**"),
    subtitle = "Distribuição percentual dos municípios conforme o nível de execução do repasse") %>%
  cols_label(regiao = "Região") %>%
  fmt_percent(columns = -regiao,
    decimals = 1) %>%
  data_color(columns = -regiao,
    colors = scales::col_numeric(
      palette = c("white", "#AED6F1", "#2E86C1"), 
      domain = c(0, 1))) %>%
  tab_options(heading.background.color = "#2C3E50",
    heading.title.font.size = px(18),
    heading.subtitle.font.size = px(14),
    column_labels.background.color = "#34495E",
    column_labels.font.weight = "bold",
    table.border.top.color = "transparent",
    table.border.bottom.color = "transparent") %>%
  tab_source_note(source_note = md("*Fonte: Elaboração própria com base na MUNIC/IBGE 2021.*"))

gtsave(gt_tabela_lab, "Tabela_Visual_1_LAB_Regiao.png")

# TABELA VISUAL 2: Evolução do Tripé Institucional por Região (2006 a 2021)
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
  fmt_percent(columns = c(perc_conselho, perc_fundo, perc_plano, perc_tripe_completo),
    decimals = 1) %>%
  tab_style(style = cell_text(weight = "bold", color = "#C0392B"),
    locations = cells_body(columns = perc_tripe_completo)) %>%
  tab_options(row_group.background.color = "#ECF0F1",
    row_group.font.weight = "bold",
    heading.background.color = "#2C3E50",
    heading.title.font.size = px(18),
    heading.subtitle.font.size = px(14),
    column_labels.background.color = "#34495E",
    column_labels.font.weight = "bold") %>%
  tab_source_note(
    source_note = md("*Fonte: Elaboração própria com base na MUNIC/IBGE.*"))

gtsave(gt_tabela_tripe, "Tabela_Visual_2_Tripe_Regiao.png")
