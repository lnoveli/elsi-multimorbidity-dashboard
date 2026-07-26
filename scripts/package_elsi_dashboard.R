#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) stop("Usage: package_elsi_dashboard.R <data.json> <artifact.json>")

suppressPackageStartupMessages(library(jsonlite))
d <- fromJSON(args[[1]], simplifyDataFrame = TRUE)

overview <- data.frame(
  multimorbidity_prevalence = d$meta$overall_prevalence / 100,
  sample_n = d$meta$n,
  outcome_coverage = d$meta$outcome_coverage / 100,
  top_condition_prevalence = d$conditions$prevalence[[1]] / 100
)

sources <- list(
  list(
    id = "elsi_baseline",
    label = "ELSI-Brasil — linha de base",
    path = "Elsi baseline.dta",
    query = list(
      engine = "R / survey",
      query = "work/build_elsi_dashboard.R",
      sql = "SELECT * FROM read_stata('Elsi baseline.dta')",
      language = "R",
      description = "Leitura da linha de base do ELSI-Brasil e estimação ponderada com peso calibrado, estrato e unidade primária de amostragem.",
      filters = list("População: participantes com 50 anos ou mais", "Multimorbidade: duas ou mais entre 12 condições autorreferidas", "Desfecho calculado somente para respostas válidas nas 12 condições"),
      metric_definitions = list("Prevalência de multimorbidade: proporção ponderada de pessoas com duas ou mais condições crônicas.", "Intervalos de confiança: IC95% estimados respeitando o desenho amostral complexo.", "Associações ajustadas: regressão logística ponderada; estimativas apresentadas como odds ratios com IC95%."),
      tables_used = list("Elsi baseline.dta")
    )
  )
)

manifest <- list(
  version = 1,
  surface = "dashboard",
  title = "Multimorbidade no Brasil 50+",
  description = "Painel analítico de desigualdades em saúde na linha de base do ELSI-Brasil.",
  generatedAt = gsub(" ", "T", d$meta$generated_at, fixed = TRUE),
  cards = list(
    list(id = "prevalence", description = "Pessoas com duas ou mais condições crônicas; estimativa ponderada.", dataset = "overview", sourceId = "elsi_baseline", metrics = list(list(label = "Multimorbidade", field = "multimorbidity_prevalence", format = "percent"))),
    list(id = "sample", description = "Participantes na linha de base incluídos na análise.", dataset = "overview", sourceId = "elsi_baseline", metrics = list(list(label = "Amostra", field = "sample_n", format = "compact"))),
    list(id = "coverage", description = "Proporção com resposta válida para as 12 condições incluídas no desfecho.", dataset = "overview", sourceId = "elsi_baseline", metrics = list(list(label = "Cobertura do desfecho", field = "outcome_coverage", format = "percent"))),
    list(id = "hypertension", description = "Condição crônica autorreferida mais prevalente na análise ponderada.", dataset = "overview", sourceId = "elsi_baseline", metrics = list(list(label = "Hipertensão", field = "top_condition_prevalence", format = "percent")))
  ),
  charts = list(
    list(id = "age_chart", title = "Prevalência de multimorbidade segundo faixa etária", subtitle = "Estimativa ponderada entre pessoas com 50 anos ou mais; IC95% disponível na tabela de apoio.", type = "line", dataset = "age", sourceId = "elsi_baseline", layout = "half", encodings = list(x = list(field = "group", type = "ordinal", label = "Faixa etária"), y = list(field = "prevalence", type = "quantitative", format = "number", unit = "%", label = "Prevalência"))),
    list(id = "condition_chart", title = "Prevalência das condições crônicas que compõem a multimorbidade", subtitle = "Condições autorreferidas na população com 50 anos ou mais; estimativas ponderadas.", type = "horizontalBar", dataset = "conditions", sourceId = "elsi_baseline", layout = "half", encodings = list(x = list(field = "condition", type = "nominal", label = "Condição"), y = list(field = "prevalence", type = "quantitative", format = "number", unit = "%", label = "Prevalência"))),
    list(id = "region_chart", title = "Prevalência de multimorbidade segundo região do Brasil", subtitle = "Comparação regional ponderada; interpretar com os IC95% na tabela de apoio.", type = "bar", dataset = "region", sourceId = "elsi_baseline", layout = "half", encodings = list(x = list(field = "region", type = "nominal", label = "Região"), y = list(field = "prevalence", type = "quantitative", format = "number", unit = "%", label = "Prevalência"))),
    list(id = "association_chart", title = "Chance de multimorbidade segundo estado marital e sexo", subtitle = "Odds ratios ajustados por idade, rede de apoio, renda, escolaridade e raça/cor; referência: solteiro(a) e feminino.", type = "horizontalBar", dataset = "forest", sourceId = "elsi_baseline", layout = "half", encodings = list(x = list(field = "label", type = "nominal", label = "Grupo"), y = list(field = "estimate", type = "quantitative", format = "number", label = "Odds ratio")), referenceLines = list(list(value = 1, label = "Referência")))
  ),
  tables = list(
    list(id = "age_table", title = "Detalhamento: prevalência de multimorbidade por faixa etária", subtitle = "Estimativas ponderadas e intervalos de confiança de 95%.", dataset = "age", sourceId = "elsi_baseline", layout = "half", defaultSort = list(field = "prevalence", direction = "desc"), columns = list(list(field = "group", label = "Faixa etária"), list(field = "prevalence", label = "Prevalência", format = "number"), list(field = "ci_low", label = "IC95% inferior", format = "number"), list(field = "ci_high", label = "IC95% superior", format = "number"))),
    list(id = "association_table", title = "Detalhamento: chance ajustada de multimorbidade", subtitle = "Modelo ajustado por idade, sexo, parentes próximos, renda, escolaridade e raça/cor.", dataset = "forest", sourceId = "elsi_baseline", layout = "half", defaultSort = list(field = "estimate", direction = "desc"), columns = list(list(field = "label", label = "Grupo"), list(field = "estimate", label = "Odds ratio", format = "number"), list(field = "ci_low", label = "IC95% inferior", format = "number"), list(field = "ci_high", label = "IC95% superior", format = "number"), list(field = "p_value", label = "p-valor", format = "number")))
  ),
  sources = sources,
  blocks = list(
    list(id = "hero_metrics", type = "metric-strip", cardIds = list("prevalence", "sample", "coverage", "hypertension")),
    list(id = "age_block", type = "chart", chartId = "age_chart"),
    list(id = "condition_block", type = "chart", chartId = "condition_chart"),
    list(id = "region_block", type = "chart", chartId = "region_chart"),
    list(id = "association_block", type = "chart", chartId = "association_chart"),
    list(id = "age_table_block", type = "table", tableId = "age_table"),
    list(id = "association_table_block", type = "table", tableId = "association_table"),
    list(id = "caveat", type = "markdown", body = "### Leitura responsável\n\nEste painel descreve associações em dados transversais e não estima causalidade. As prevalências e os intervalos respeitam o desenho amostral complexo. Respostas ausentes ou ‘não sabe/não respondeu’ não foram classificadas como ausência de doença; por isso, o desfecho possui cobertura de 96,7%."),
    list(id = "method", type = "markdown", body = "### Método e uso no portfólio\n\nConstruído a partir da linha de base do ELSI-Brasil, com pipeline reproduzível em R. O painel demonstra definição de métricas, tratamento de qualidade, análise ponderada, modelagem ajustada e tradução de evidência de saúde pública para priorização executiva.")
  )
)

artifact <- list(
  surface = "dashboard",
  manifest = manifest,
  snapshot = list(version = 1, generatedAt = gsub(" ", "T", d$meta$generated_at, fixed = TRUE), status = "ready", datasets = list(overview = overview, age = d$age, sex = d$sex, marital = d$marital, region = d$region, conditions = d$conditions, forest = d$forest, quality = d$quality)),
  sources = sources
)

write_json(artifact, args[[2]], auto_unbox = TRUE, pretty = TRUE, na = "null")
