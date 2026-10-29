# 05_reliefweb_combine.R
#
# Combines the yearly ReliefWeb pulls for Ukraine (R/02_reliefweb_pull.R, one
# run per year) into one table for 2022 to 2026, and flags the reports that
# could describe an attack on health care.
#
# Inputs:  data/raw/reliefweb/ukr_<year>/reports.rds, for 2022 to 2026
# Writes:
#   data/raw/reliefweb/ukr_2022_2026_reports.rds        all reports, with page text (not uploaded)
#   data/processed/reliefweb_ukr_2022_2026_reports.csv  metadata and flags, no text
#   output/reliefweb_ukr_2022_2026_summary.csv          counts by year
#
# Flags (same rules as the Week 6 pool, ../week-06/R/01_sample_20.R):
#   english          the report is tagged English
#   words_50         at least 50 words of page text
#   health_mention   the title or text mentions health care at least once
#   health_near_harm a health term in the same sentence as a harm word, within 80 characters
# A report can describe an attack on health care only if health_mention is TRUE.
#
# Run from the project/ folder:
#   Rscript R/05_reliefweb_combine.R

suppressPackageStartupMessages(library(dplyr))
library(readr)
library(stringr)
library(purrr)

years <- 2022:2026

# Word starts, as in ../week-06/R/01_sample_20.R
health_terms <- c("hospital", "clinic", "ambulanc", "medic", "health ?care", "health facilit",
                  "health cent", "health work", "health personnel", "doctor", "nurse",
                  "paramedic", "pharmac", "maternity", "polyclinic")
harm_terms <- c("attack", "shell", "strike", "struck", "bomb", "missile", "rocket", "destroy",
                "damag", "hit", "shot", "shoot", "kill", "injur", "loot", "occup", "seiz")
health_re <- paste0("\\b(", paste(health_terms, collapse = "|"), ")")
harm_re <- paste0("\\b(", paste(harm_terms, collapse = "|"), ")")
near_re <- paste0(health_re, "[^.]{0,80}", harm_re, "|", harm_re, "[^.]{0,80}", health_re)

# ---- Combine ----------------------------------------------------------------

files <- sprintf("data/raw/reliefweb/ukr_%d/reports.rds", years)
missing <- files[!file.exists(files)]
if (length(missing) > 0) stop("Missing pulls: ", paste(missing, collapse = ", "))

reports <- map(files, readRDS) |>
  list_rbind() |>
  mutate(year = as.integer(substr(date_original, 1, 4)))

# A report has one date, so it should be in one year only
stopifnot(!anyDuplicated(reports$rw_id))

text <- str_to_lower(paste(reports$title, coalesce(reports$body, "")))
reports <- reports |>
  mutate(english = str_detect(language, "\\ben\\b"),
         words_50 = n_words_body >= 50,
         health_mention = str_detect(text, health_re),
         health_near_harm = str_detect(text, near_re))

# Same title, source and date: likely the same report posted twice
reports <- reports |>
  group_by(title, source, date_original) |>
  mutate(same_title_source_date = n()) |>
  ungroup()

# ---- Save -------------------------------------------------------------------

saveRDS(reports, "data/raw/reliefweb/ukr_2022_2026_reports.rds")
reports |>
  select(-body) |>
  write_csv("data/processed/reliefweb_ukr_2022_2026_reports.csv", na = "")

summary <- reports |>
  group_by(year) |>
  summarise(reports = n(),
            english = sum(english),
            english_50_words = sum(english & words_50),
            health_mention = sum(english & words_50 & health_mention),
            health_near_harm = sum(english & words_50 & health_near_harm),
            .groups = "drop")
summary <- bind_rows(summary, summarise(summary, across(-year, sum)) |> mutate(year = NA_integer_))
write_csv(summary, "output/reliefweb_ukr_2022_2026_summary.csv", na = "total")

print(summary)
message(sum(reports$same_title_source_date > 1), " reports share their title, source and date with another report")
