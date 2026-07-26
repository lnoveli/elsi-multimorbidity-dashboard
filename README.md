# Multimorbidity in Brazil 50+

An interactive public-health dashboard that translates complex survey data into an accessible view of multimorbidity among Brazilians aged 50 and over.

**Live dashboard:** [Open the interactive dashboard](https://lnoveli.github.io/elsi-multimorbidity-dashboard/).

## Research problem

Population ageing increases the need to understand multimorbidity: the coexistence of two or more chronic conditions in the same person. This project asks:

> How does multimorbidity vary by age, Brazilian region, and selected sociodemographic characteristics among people aged 50 and over?

The goal is not to make causal claims or predict individual disease. It is to organize evidence so that researchers, managers, and policy stakeholders can identify patterns, assess inequities, and prioritize further investigation.

## Why this dashboard matters

Survey-based health research often produces many tables and model outputs that are difficult to read together. The dashboard consolidates the analysis into one decision-oriented view:

- **Scale of the challenge:** weighted prevalence of multimorbidity and the most prevalent chronic conditions.
- **Population patterns:** comparisons by age group and Brazilian region.
- **Adjusted associations:** odds ratios for selected marital-status and sex groups, controlling for relevant covariates.
- **Methodological transparency:** confidence intervals, survey design, outcome coverage, and clear interpretation limits.

In a portfolio context, it demonstrates how analytical work can move from raw statistical output to a professional, stakeholder-ready data product.

## Dashboard contents

1. Headline indicators: multimorbidity prevalence, analytic sample, outcome coverage, and hypertension prevalence.
2. Multimorbidity prevalence by age group.
3. Prevalence of chronic conditions included in the outcome definition.
4. Multimorbidity prevalence by Brazilian region.
5. Adjusted odds of multimorbidity by marital status and sex.
6. Supporting tables with 95% confidence intervals.

## Methods

- **Source:** baseline wave of the Brazilian Longitudinal Study of Ageing (ELSI-Brasil).
- **Population:** adults aged 50 years and over.
- **Outcome:** multimorbidity, defined as two or more self-reported chronic conditions among 12 selected conditions.
- **Survey analysis:** calibrated weights, strata, and primary sampling units are incorporated in estimates.
- **Uncertainty:** prevalence estimates include 95% confidence intervals.
- **Adjusted model:** survey-weighted logistic regression adjusted for age, sex, close relatives, income, education, and race/colour.
- **Missing data rule:** missing, “don’t know”, and non-response values were not treated as absence of disease; the dashboard reports outcome coverage.

## Responsible interpretation

This is a cross-sectional analysis. The findings describe associations and disparities in the baseline data; they do not establish causation. Odds ratios should be interpreted together with their 95% confidence intervals and the study context.

## Repository structure

```text
.
├── index.html                 # Published interactive dashboard
├── scripts/
│   ├── build_elsi_dashboard.R # Reproducible data transformation and analysis
│   ├── package_elsi_dashboard.R
│   └── force_dark_dashboard.R
└── .gitignore                 # Prevents source microdata and local files from being published
```

## Data availability and ethics

The raw microdata are deliberately **not included** in this repository. The dashboard contains only aggregated, non-identifiable results. Use of the original ELSI-Brasil data must follow its applicable access, citation, and ethical requirements.

## Technology stack

`R` · `survey` · `dplyr` · `readstata13` · `HTML` · `GitHub Pages`

## Author

Leonardo Noveli

---

Built as a public-health analytics and Business Analytics portfolio project.
