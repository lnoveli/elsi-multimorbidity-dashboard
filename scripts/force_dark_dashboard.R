#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) stop("Usage: force_dark_dashboard.R <dashboard.html>")

html <- paste(readLines(args[[1]], warn = FALSE), collapse = "\n")
dark_css <- paste0(
  "<style id=\"portfolio-dark-theme\">",
  ":root{color-scheme:dark;--portable-canvas:#121416;--portable-surface:#1b1f23;--portable-surface-subtle:#242a30;--portable-ink:#eef2f4;--portable-muted:#b6c0c8;--portable-tertiary:#85919b;--portable-table-text:#c5ced5;--portable-border:rgba(255,255,255,.12);--portable-accent:#79b8ff;--portable-positive:#8ecf9c;--portable-positive-bg:rgba(91,164,108,.14);--portable-negative:#ff9898;--portable-negative-bg:rgba(214,82,82,.16);--portable-warning-bg:#332914;--portable-warning-border:#b08b3b}",
  ".portable-static-chart-light{display:none!important}.portable-static-chart-dark{display:block!important}",
  "</style>"
)
html <- sub("</head>", paste0(dark_css, "</head>"), html, fixed = TRUE)
writeLines(html, args[[1]], useBytes = TRUE)
