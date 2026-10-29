# Week 6: draw the 20 ReliefWeb reports to code by hand.
#
# Input: every ReliefWeb report on Ukraine dated 2022, from the project pull
#   ../project/data/raw/reliefweb/ukr_2022/reports.rds   (project/R/02_reliefweb_pull.R)
#
# Pool: English reports with at least 50 and at most 3,000 words of page text
# that mention health care at least once (health_terms below). Reports that never
# mention health care cannot describe an attack on it, and 3,000 words keeps
# each report readable by hand.
#
# Sample: attacks are a minority of the pool, so a simple random 20 could hold
# only two or three, too few for precision and recall. The pool is split in two
# by whether a health term appears within 80 characters of a harm word
# (harm_terms), and 10 reports are drawn at random from each part. The split
# is a sampling device, not a code. The reading sheet mixes the two parts in a
# random order and does not say which report came from which.
#
# Writes:
#   data/processed/sample_20.csv          the 20 reports: id, ReliefWeb id, date, source, title, link (no text)
#   data/processed/sample_20_strata.csv   which part each report came from (hidden from the coder)
#   output/sample_20_log.txt              pool sizes, seed and date drawn
#   output/local/reading_sheet_20.md      the 20 reports with full page text (kept locally, not uploaded)
#
# The hand-coding spreadsheet is made by R/02_coding_sheet.R.
#
# Run from the week-06/ folder:
#   Rscript R/01_sample_20.R

suppressPackageStartupMessages(library(dplyr))
library(readr)
library(stringr)

# ---- Settings ---------------------------------------------------------------

input_file <- "../project/data/raw/reliefweb/ukr_2022/reports.rds"
seed <- 20261028   # date drawn, so the draw can be repeated
n_per_part <- 10
min_words <- 50
max_words <- 3000

# Word starts, matched case-insensitively in the title and page text
health_terms <- c("hospital", "clinic", "ambulanc", "medic", "health ?care", "health facilit",
                  "health cent", "health work", "health personnel", "doctor", "nurse",
                  "paramedic", "pharmac", "maternity", "polyclinic")
harm_terms <- c("attack", "shell", "strike", "struck", "bomb", "missile", "rocket", "destroy",
                "damag", "hit", "shot", "shoot", "kill", "injur", "loot", "occup", "seiz")

# ---- Build the pool ---------------------------------------------------------

health_re <- paste0("\\b(", paste(health_terms, collapse = "|"), ")")
harm_re <- paste0("\\b(", paste(harm_terms, collapse = "|"), ")")
# Same sentence (no full stop between them), at most 80 characters apart
near_re <- paste0(health_re, "[^.]{0,80}", harm_re, "|", harm_re, "[^.]{0,80}", health_re)

reports <- readRDS(input_file) |>
  mutate(text = str_to_lower(paste(title, coalesce(body, ""))),
         english = str_detect(language, "\\ben\\b"))

pool <- reports |>
  filter(english, n_words_body >= min_words, n_words_body <= max_words,
         str_detect(text, health_re)) |>
  mutate(part = if_else(str_detect(text, near_re), "health_near_harm", "health_only"))

# ---- Draw 10 from each part, then shuffle -----------------------------------

set.seed(seed)
drawn <- pool |>
  group_by(part) |>
  slice_sample(n = n_per_part) |>
  ungroup() |>
  slice_sample(prop = 1) |>   # random reading order, so the parts are mixed
  mutate(id = row_number(),
         title = str_squish(title))   # some titles carry line breaks

stopifnot(nrow(drawn) == 2 * n_per_part, !anyDuplicated(drawn$rw_id))

dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
dir.create("output/local", recursive = TRUE, showWarnings = FALSE)

drawn |>
  select(id, rw_id, date_original, source, format, title, n_words_body, url) |>
  write_csv("data/processed/sample_20.csv", na = "")

drawn |>
  select(id, rw_id, part) |>
  write_csv("data/processed/sample_20_strata.csv")

# ---- Log --------------------------------------------------------------------

log_lines <- c(
  paste0("Drawn: ", Sys.Date(), "   seed: ", seed),
  paste0("Input: ", input_file),
  paste0("Ukraine reports dated 2022: ", nrow(reports)),
  paste0("  English: ", sum(reports$english)),
  paste0("  English, ", min_words, " to ", max_words, " words of page text: ",
         sum(reports$english & reports$n_words_body >= min_words & reports$n_words_body <= max_words)),
  paste0("  ...and mention health care (the pool): ", nrow(pool)),
  paste0("      health term near a harm word: ", sum(pool$part == "health_near_harm")),
  paste0("      health term only:             ", sum(pool$part == "health_only")),
  paste0("Sample: ", n_per_part, " from each part, ", 2 * n_per_part, " in all")
)
writeLines(log_lines, "output/sample_20_log.txt")
message(paste(log_lines, collapse = "\n"))

# ---- Reading sheet ----------------------------------------------------------

# Health terms in bold, as a finding aid for the hand coder (the model gets
# plain text). The report's own bold is removed first so the two never nest,
# and web links are left alone so they still work.
url_re <- "https?://[^\\s)\\]]+"
bold_health <- function(x) {
  words_re <- regex(paste0(health_re, "\\w*"), ignore_case = TRUE)
  text_parts <- str_split(x, url_re)[[1]]
  urls <- c(str_extract_all(x, url_re)[[1]], "")
  text_parts <- str_replace_all(text_parts, words_re, "**\\0**") |>
    str_replace_all(regex("\\*\\*(nurser\\w*)\\*\\*", ignore_case = TRUE), "\\1")  # "nurse" also matches "nursery"
  paste0(text_parts, urls, collapse = "")
}

# Headings inside a report become level-4 headings, below the sheet's own
tidy_body <- function(x) {
  x <- coalesce(x, "") |>
    str_remove_all(fixed("**")) |>
    str_replace_all(regex("^#+\\s*(.+?)\\s*#*$", multiline = TRUE), "#### \\1")
  bold_health(x)
}

md <- c(
  "# Ukraine 2022: 20 ReliefWeb reports for hand coding",
  "",
  "Codebook: `../project/docs/codebook_screen_v1.md`. Question: does the report describe at least one specific attack on health care? (`yes` / `no`)",
  "",
  "Health-care words are in **bold**. Hand codes: `data/processed/hand_codes_20.xlsx`.",
  "",
  "This file holds full report text and is kept locally (`output/local/` is not uploaded).",
  "",
  unlist(lapply(seq_len(nrow(drawn)), function(i) {
    r <- drawn[i, ]
    c(
      "---",
      "",
      paste0("## ", r$id, ". ", r$title),
      "",
      paste0("*", r$format, " · ", r$source, " · ", r$date_original, " · ",
             r$n_words_body, " words · ReliefWeb ", r$rw_id, "* · [link](", r$url, ")"),
      "",
      tidy_body(r$body),
      ""
    )
  }))
)
writeLines(md, "output/local/reading_sheet_20.md")
message("\nReading sheet: output/local/reading_sheet_20.md")
