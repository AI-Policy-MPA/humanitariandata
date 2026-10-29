# Week 6: compare the automated codes with the hand codes (assignment step 5).
#
# Reference: the hand codes, data/processed/hand_codes_20.xlsx.
# Methods compared:
#   model         newest data/processed/llm_runs/sample20_*.csv   (R/03_code_llm.R)
#   keyword rule  `yes` when a health term is in the same sentence as a harm word,
#                 the rule that split the pool in R/01_sample_20.R
#                 (data/processed/sample_20_strata.csv)
#
# For each method it prints a confusion matrix (hand codes as rows, the method
# as columns), accuracy, the majority-class baseline, and precision, recall and
# F1 for `yes`, with each calculation written out. Then it lists every report
# where the model and the hand codes disagree, with the hand note and the model's reason, and
# the results for each half of the sample.
#
# Ten reports came from each half of the pool, so "health term near a harm word"
# reports are over-represented. The numbers describe these 20 reports, not the
# whole pool. With so few `yes` codes, one report moves precision or recall a lot.
#
# Usage, from the week-06/ folder:
#   Rscript R/04_evaluate.R
#   Rscript R/04_evaluate.R --run=data/processed/llm_runs/sample20_<run id>.csv   a given run
#
# Writes:
#   output/eval_20.txt      everything printed below
#   output/metrics_20.csv   accuracy, precision, recall and F1 for each method

suppressPackageStartupMessages(library(dplyr))
library(readr)
library(readxl)
library(tidyr)

options(width = 150)  # keep tables on one line in the terminal
codes_allowed <- c("yes", "no")

# ---- Arguments --------------------------------------------------------------

args <- commandArgs(trailingOnly = TRUE)
run_arg <- grep("^--run=", args, value = TRUE)
run_dir <- "data/processed/llm_runs"
run_file <- if (length(run_arg) == 1) {
  sub("^--run=", "", run_arg)
} else {
  runs <- list.files(run_dir, pattern = "^sample20_\\d{8}_\\d{6}\\.csv$", full.names = TRUE)
  if (length(runs) == 0) stop("No model run in ", run_dir, ". Run R/03_code_llm.R first.")
  max(runs)  # file names sort by date and time
}

read_chr <- function(f) read_csv(f, show_col_types = FALSE, col_types = cols(.default = col_character()))

# ---- Read every code --------------------------------------------------------

hand <- read_excel("data/processed/hand_codes_20.xlsx", sheet = "Codes", col_types = "text") |>
  transmute(id, rw_id, title, hand = trimws(tolower(code_hand)), hand_note = note)
if (nrow(hand) != 20 || !all(hand$hand %in% codes_allowed)) {
  stop("hand_codes_20.xlsx needs yes or no in code_hand for all 20 reports.")
}

model <- read_chr(run_file) |> select(rw_id, model = code_llm, model_reason = reason)
strata <- read_chr("data/processed/sample_20_strata.csv") |> select(rw_id, part)

codes <- hand |>
  left_join(model, by = "rw_id") |>
  left_join(strata, by = "rw_id") |>
  mutate(keyword_rule = if_else(part == "health_near_harm", "yes", "no"),
         id = as.integer(id)) |>
  arrange(id)

# ---- Measures ---------------------------------------------------------------

# A missing model code counts as wrong in accuracy and is shown as "none"
evaluate <- function(ref, pred, method) {
  pred <- coalesce(pred, "none")
  tp <- sum(ref == "yes" & pred == "yes")
  fp <- sum(ref == "no" & pred == "yes")
  fn <- sum(ref == "yes" & pred != "yes")
  tn <- sum(ref == "no" & pred == "no")
  n <- length(ref)

  correct <- sum(ref == pred)
  majority <- names(sort(table(ref), decreasing = TRUE))[1]
  baseline <- mean(ref == majority)
  precision <- if (tp + fp > 0) tp / (tp + fp) else NA_real_
  recall <- if (tp + fn > 0) tp / (tp + fn) else NA_real_
  f1 <- if (!is.na(precision) && !is.na(recall) && precision + recall > 0) {
    2 * precision * recall / (precision + recall)
  } else NA_real_

  cat("\n==== ", method, " ====\n\n", sep = "")
  cat("Confusion matrix (rows: hand codes; columns: ", method, ")\n", sep = "")
  tab <- table(hand = factor(ref, levels = codes_allowed),
               method = factor(pred, levels = c(codes_allowed, if (any(pred == "none")) "none")))
  print(tab)

  fmt <- function(x) if (is.na(x)) "undefined" else sprintf("%.2f", x)
  cat(sprintf("\nAccuracy   = correct / all = %d / %d = %s\n", correct, n, fmt(correct / n)))
  cat(sprintf("Baseline   = always \"%s\" (the most common hand code) = %s\n", majority, fmt(baseline)))
  cat(sprintf("Precision  = TP / (TP + FP) = %d / (%d + %d) = %s   of the reports it called yes, the share coded yes by hand\n",
              tp, tp, fp, fmt(precision)))
  cat(sprintf("Recall     = TP / (TP + FN) = %d / (%d + %d) = %s   of the reports coded yes by hand, the share it found\n",
              tp, tp, fn, fmt(recall)))
  cat(sprintf("F1         = 2 x P x R / (P + R) = %s\n", fmt(f1)))
  cat(sprintf("(TP = both yes: %d; FP = it said yes, hand said no: %d; FN = hand said yes, it did not: %d; TN = both no: %d)\n",
              tp, fp, fn, tn))

  tibble(method, n, tp, fp, fn, tn, accuracy = correct / n, baseline,
         precision, recall, f1)
}

# ---- Report -----------------------------------------------------------------

dir.create("output", showWarnings = FALSE)
out_file <- "output/eval_20.txt"
sink(out_file, split = TRUE)

cat("Week 6 evaluation: 20 ReliefWeb reports, Ukraine 2022\n")
cat("Question: does the report describe at least one specific attack on health care?\n")
cat("Reference: hand codes (data/processed/hand_codes_20.xlsx)\n")
cat("Model run:", run_file, "\n")
cat(sprintf("Hand codes: %d yes, %d no\n", sum(codes$hand == "yes"), sum(codes$hand == "no")))

metrics <- bind_rows(
  evaluate(codes$hand, codes$model, "model"),
  evaluate(codes$hand, codes$keyword_rule, "keyword rule")
)

cat("\n==== Reports where the model and the hand codes disagree ====\n")
disagree <- filter(codes, coalesce(model, "none") != hand)
if (nrow(disagree) == 0) cat("\nNone.\n")
for (i in seq_len(nrow(disagree))) {
  d <- disagree[i, ]
  cat(sprintf("\n#%d  ReliefWeb %s  (%s)\n  %s\n  Hand: %s   %s\n  Model: %s   %s\n",
              d$id, d$rw_id, d$part, d$title,
              d$hand, coalesce(d$hand_note, ""),
              coalesce(d$model, "none"), coalesce(d$model_reason, "")))
}

cat("\n==== By half of the sample ====\n\n")
codes |>
  group_by(part) |>
  summarise(reports = n(), hand_yes = sum(hand == "yes"),
            model_yes = sum(model == "yes", na.rm = TRUE),
            model_agrees = sum(coalesce(model, "none") == hand), .groups = "drop") |>
  print()

cat("\n==== All 20 ====\n\n")
codes |>
  transmute(id, rw_id, part, hand, model, keyword_rule,
            title = substr(title, 1, 70)) |>
  print(n = 20)

sink()

write_csv(metrics, "output/metrics_20.csv")
message("\nSaved ", out_file, " and output/metrics_20.csv")
