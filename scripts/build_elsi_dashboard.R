#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) stop("Usage: build_elsi_dashboard.R <input.dta> <output.json>")

suppressPackageStartupMessages({
  library(readstata13)
  library(dplyr)
  library(survey)
  library(jsonlite)
})

raw <- read.dta13(args[[1]], nonint.factors = TRUE)

disease_vars <- c(
  hiper = "n28", diab = "n35", dcard = "n50", avc = "n52", asma = "n54",
  dpoc = "n55", artrite = "n56", osteo = "n57", depre = "n59", cancer = "n60",
  renal = "n61", alz = "n63"
)

yes_binary <- function(x) {
  x_chr <- trimws(as.character(x))
  ifelse(x_chr == "Sim", 1, ifelse(x_chr == "Não", 0, NA_real_))
}

df <- raw %>%
  transmute(
    id, upa, estrato, peso_calibrado, regiao, zona, idade, sexo, rendaind,
    estado_marital = e7, cor = e9, e11, e12, e13,
    educacao_raw = e22,
    hiper = yes_binary(n28), diab = yes_binary(n35), dcard = yes_binary(n50),
    avc = yes_binary(n52), asma = yes_binary(n54), dpoc = yes_binary(n55),
    artrite = yes_binary(n56), osteo = yes_binary(n57), depre = yes_binary(n59),
    cancer = yes_binary(n60), renal = yes_binary(n61), alz = yes_binary(n63)
  ) %>%
  mutate(
    grupo_idade = cut(
      idade, breaks = c(50, 55, 60, 65, 70, 75, 80, 85, Inf),
      labels = c("50–54", "55–59", "60–64", "65–69", "70–74", "75–79", "80–84", "85+"),
      include.lowest = TRUE, right = FALSE
    ),
    renda = case_when(
      rendaind < 789 ~ "Até 1 SM",
      rendaind <= 1576 ~ "Entre 1 e 2 SM",
      rendaind > 1576 ~ "Mais de 2 SM",
      TRUE ~ NA_character_
    ),
    educacao_num = as.numeric(educacao_raw),
    educacao = case_when(
      educacao_num == 1 ~ "Sem escolaridade",
      educacao_num %in% 2:9 ~ "Baixa escolaridade",
      educacao_num %in% 10:14 ~ "Média escolaridade",
      educacao_num %in% 15:19 ~ "Alta escolaridade",
      TRUE ~ NA_character_
    ),
    parentes_proximos = case_when(
      e11 == 99 | e12 == 99 | e13 == 99 ~ "Não sabe/Não respondeu",
      rowSums(across(c(e11, e12, e13)), na.rm = FALSE) == 0 ~ "Não tem",
      TRUE ~ "Tem parentes próximos"
    )
  )

disease_names <- names(disease_vars)
complete_conditions <- complete.cases(df[, disease_names])
df <- df %>% mutate(
  somatorio_dc = ifelse(complete_conditions, rowSums(across(all_of(disease_names))), NA_real_),
  multimorb = ifelse(is.na(somatorio_dc), NA_real_, as.numeric(somatorio_dc >= 2))
)

design <- svydesign(ids = ~upa, strata = ~estrato, weights = ~peso_calibrado, data = df, nest = TRUE)

weighted_rate <- function(formula, by = NULL) {
  if (is.null(by)) {
    x <- svymean(formula, design, na.rm = TRUE)
    tibble(estimate = as.numeric(coef(x)), se = as.numeric(SE(x)))
  } else {
    x <- svyby(formula, by, design, svymean, na.rm = TRUE, vartype = "ci", keep.names = FALSE)
    as_tibble(x)
  }
}

ci_rows <- function(tbl, estimate_col = "multimorb") {
  est <- tbl[[estimate_col]]
  mutate(tbl, prevalence = round(100 * est, 1), ci_low = round(100 * pmax(0, ci_l), 1), ci_high = round(100 * pmin(1, ci_u), 1))
}

age <- weighted_rate(~multimorb, ~grupo_idade) %>% ci_rows() %>% transmute(group = as.character(grupo_idade), prevalence, ci_low, ci_high)
sex <- weighted_rate(~multimorb, ~sexo) %>% ci_rows() %>% transmute(group = as.character(sexo), prevalence, ci_low, ci_high)
marital <- weighted_rate(~multimorb, ~estado_marital) %>% ci_rows() %>% transmute(group = as.character(estado_marital), prevalence, ci_low, ci_high)
region <- weighted_rate(~multimorb, ~regiao) %>% ci_rows() %>% transmute(region = as.character(regiao), prevalence, ci_low, ci_high)

condition_mean <- svymean(as.formula(paste("~", paste(disease_names, collapse = "+"))), design, na.rm = TRUE)
conditions <- tibble(
  condition = c("Hipertensão", "Diabetes", "Doença cardíaca", "AVC", "Asma", "DPOC", "Artrite", "Osteoporose", "Depressão", "Câncer", "Doença renal", "Alzheimer"),
  prevalence = round(100 * as.numeric(coef(condition_mean)), 1),
  se = as.numeric(SE(condition_mean))
) %>% mutate(ci_low = round(100 * pmax(0, prevalence / 100 - 1.96 * se), 1), ci_high = round(100 * pmin(1, prevalence / 100 + 1.96 * se), 1)) %>% select(-se) %>% arrange(desc(prevalence))

model <- svyglm(multimorb ~ estado_marital + grupo_idade + sexo + parentes_proximos + renda + educacao + cor, design = design, family = quasibinomial())
model_terms <- summary(model)$coefficients
ci <- confint(model)
forest <- tibble(
  term = rownames(model_terms), estimate = exp(model_terms[, "Estimate"]),
  p_value = model_terms[, "Pr(>|t|)"], ci_low = exp(ci[, 1]), ci_high = exp(ci[, 2])
) %>%
  filter(term != "(Intercept)") %>%
  filter(grepl("estado_marital|sexo", term)) %>%
  mutate(
    label = recode(term,
      "estado_maritalCasado/amasiado/união estável" = "Casado/união estável",
      "estado_maritalDivorciado(a) ou separado(a)" = "Divorciado/separado",
      "estado_maritalViúvo(a)" = "Viúvo(a)",
      "sexoMasculino" = "Masculino"
    ),
    estimate = round(estimate, 2), ci_low = round(ci_low, 2), ci_high = round(ci_high, 2),
    p_value = round(p_value, 4)
  )

overall <- weighted_rate(~multimorb) %>% pull(estimate)
valid_outcome <- mean(!is.na(df$multimorb))
quality <- tibble(
  metric = c("Registros na linha de base", "Cobertura de desfecho completo", "Ausência de identificador duplicado", "Desenho amostral"),
  value = c(nrow(df), round(100 * valid_outcome, 1), ifelse(anyDuplicated(df$id) == 0, "Sim", "Não"), "Peso + estrato + UPA")
)

payload <- list(
  meta = list(n = nrow(df), overall_prevalence = round(100 * overall, 1), outcome_coverage = round(100 * valid_outcome, 1), generated_at = format(Sys.time(), tz = "UTC", usetz = TRUE)),
  age = age, sex = sex, marital = marital, region = region, conditions = conditions,
  forest = forest, quality = quality
)

write_json(payload, args[[2]], auto_unbox = TRUE, pretty = TRUE, na = "null")
