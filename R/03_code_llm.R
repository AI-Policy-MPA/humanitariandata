# Week 6: code the 20 ReliefWeb reports with a language model through the Claude API.
#
# Sends the screening codebook and one report at a time to a Claude model and
# saves the code it returns (yes / no) with a one-sentence reason. Zero-shot:
# the codebook only, no coded examples.
#
# The model reads what the hand coder read: the title, type, source, date and page text of
# each report, as in output/local/reading_sheet_20.md (without the bold). It must
# answer in JSON with `yes` or `no` and a reason (structured outputs), so every
# answer is a valid code.
#
# Adapted from ../week-05/R/07_code_llm.R. Same API settings:
#   - Anthropic Messages API, API version 2026-10-21; needs ANTHROPIC_API_KEY in ~/.Renviron.
#   - Temperature cannot be set on this API version, so two runs can differ.
#     Run it twice to see how many codes change.
#   - The model always thinks briefly before answering; `effort` sets how much.
#     Thinking tokens are billed as output tokens.
#   - No fallback model. If the model declines a report, its code is left empty
#     and stop_reason is "refusal", so every code comes from one model.
#
# The hand codes must be complete first (data/processed/hand_codes_20.xlsx),
# so no model output exists before them. --estimate works at any time.
#
# Usage, from the week-06/ folder:
#   Rscript R/03_code_llm.R --estimate   cost estimate only; sends nothing
#   Rscript R/03_code_llm.R              code the 20 reports
#
# Writes, for each run (run id = date and time):
#   data/processed/llm_runs/sample20_<run id>.csv          one row per report: code, reason, tokens
#   data/processed/llm_runs/sample20_<run id>_prompt.txt   the exact system prompt sent
# and lists the codes that changed since the previous run.

suppressPackageStartupMessages(library(dplyr))
library(readr)
library(readxl)
library(httr2)
suppressPackageStartupMessages(library(jsonlite))

# ---- Settings ---------------------------------------------------------------

model <- "claude-opus-5-5"   # the API also reports which model answered (model_used)
effort <- "medium"           # low / medium / high; medium is this model's default
codebook_file <- "../project/docs/codebook_screen_v1.md"
reports_file <- "../project/data/raw/reliefweb/ukr_2022/reports.rds"
sample_file <- "data/processed/sample_20.csv"
hand_file <- "data/processed/hand_codes_20.xlsx"
codes_allowed <- c("yes", "no")
max_tokens <- 4000           # room for the model's thinking plus a short answer
api_version <- "2026-10-21"

# US dollars per million tokens. Anthropic list prices as given in Claude Code's
# API reference (cached 2026-10-06); check https://docs.anthropic.com/ before relying on them.
prices <- tribble(
  ~model,              ~input, ~output,
  "claude-opus-5-5",     4.00,   20.00,
  "claude-sonnet-5-5",   2.00,   10.00,
  "claude-haiku-5-5",    0.10,    0.50
)

# For --estimate only. Thinking length varies, so output is a guess per call;
# a real run prints the actual token counts and cost.
assumed_output_tokens <- 800

# ---- Arguments --------------------------------------------------------------

args <- commandArgs(trailingOnly = TRUE)
estimate_only <- "--estimate" %in% args

price <- filter(prices, .data$model == .env$model)
if (nrow(price) != 1) stop("No price for ", model, ". Add it to `prices`.")

# ---- Hand codes first -------------------------------------------------------

hand <- read_excel(hand_file, sheet = "Codes", col_types = "text")
hand_done <- nrow(hand) == 20 && all(trimws(tolower(hand$code_hand)) %in% codes_allowed)
if (!estimate_only && !hand_done) {
  stop("Finish all 20 hand codes in ", hand_file, " (yes or no in code_hand) before running the model.")
}

# ---- Read the reports and the codebook --------------------------------------

sample_ids <- read_csv(sample_file, show_col_types = FALSE,
                       col_types = cols(.default = col_character())) |>
  select(id, rw_id)

# Only the text the hand coder saw is sent: no sampling part, no hand codes
docs <- readRDS(reports_file) |>
  select(rw_id, title, format, source, date_original, body) |>
  inner_join(sample_ids, by = "rw_id") |>
  mutate(id = as.integer(id), title = gsub("\\s+", " ", title)) |>
  arrange(id)
stopifnot(nrow(docs) == 20)

codebook <- paste(readLines(codebook_file, warn = FALSE), collapse = "\n")

doc_text <- function(d) {
  paste0("Title: ", d$title, "\n",
         "Type: ", d$format, "\n",
         "Source: ", d$source, "\n",
         "Date: ", d$date_original, "\n\n",
         "Page text:\n", coalesce(d$body, ""))
}

# ---- Build the prompt -------------------------------------------------------

system_prompt <- paste0(
  "You screen ReliefWeb reports for a research project on attacks on health care. ",
  "Apply the codebook below to the report the user sends. Use only the text given. ",
  "Answer `yes` or `no` to the codebook question. ",
  "Give a one-sentence reason that points to the sentence in the report, or the codebook rule, that decided it.",
  "\n\n<codebook>\n", codebook, "\n</codebook>"
)

# Every answer must be JSON with a code from the list and a reason
schema <- list(
  type = "object",
  properties = list(
    code = list(type = "string", enum = as.list(codes_allowed)),
    reason = list(type = "string")
  ),
  required = list("code", "reason"),
  additionalProperties = FALSE
)

# ---- Cost estimate ----------------------------------------------------------

# Rough rule: about 4 characters per token for English text
input_chars <- nchar(system_prompt) * nrow(docs) +
  sum(sapply(seq_len(nrow(docs)), \(i) nchar(doc_text(docs[i, ]))))
est_input <- input_chars / 4
est_output <- nrow(docs) * assumed_output_tokens
est_cost <- est_input / 1e6 * price$input + est_output / 1e6 * price$output

message(sprintf(
  "Estimate: %d calls, about %s input tokens and up to %s output tokens. Cost about $%.2f with %s.",
  nrow(docs), format(round(est_input), big.mark = ","), format(est_output, big.mark = ","),
  est_cost, model
))
if (estimate_only) {
  if (!hand_done) message("Hand codes not complete yet, so a real run would stop here.")
  quit(save = "no")
}

# ---- Call the API -----------------------------------------------------------

api_key <- Sys.getenv("ANTHROPIC_API_KEY")
if (api_key == "") stop("ANTHROPIC_API_KEY is not set. Add it to ~/.Renviron (Week 5 README, Step 4).")

code_one <- function(d) {
  resp <- request("https://api.anthropic.com/v1/messages") |>
    req_headers(`x-api-key` = api_key, `anthropic-version` = api_version,
                .redact = "x-api-key") |>
    req_body_json(list(
      model = model,
      max_tokens = max_tokens,
      system = system_prompt,
      output_config = list(effort = effort,
                           format = list(type = "json_schema", schema = schema)),
      messages = list(list(role = "user", content = doc_text(d)))
    )) |>
    req_retry(max_tries = 4,
              is_transient = \(r) resp_status(r) %in% c(429, 500, 502, 503, 529)) |>
    req_error(body = \(r) tryCatch(resp_body_json(r)$error$message, error = \(e) NULL)) |>
    req_perform() |>
    resp_body_json()

  # The answer is the text block; thinking blocks come before it
  text <- Filter(\(b) b$type == "text", resp$content)
  answer <- if (resp$stop_reason == "end_turn" && length(text) > 0) {
    fromJSON(text[[1]]$text)
  } else {
    list()
  }

  tibble(
    code_llm = answer$code %||% NA_character_,
    reason = answer$reason %||% NA_character_,
    model_used = resp$model,
    stop_reason = resp$stop_reason,
    input_tokens = resp$usage$input_tokens,
    output_tokens = resp$usage$output_tokens
  )
}

run_id <- format(Sys.time(), "%Y%m%d_%H%M%S")

results <- lapply(seq_len(nrow(docs)), function(i) {
  d <- docs[i, ]
  message(sprintf("%2d/%d  ReliefWeb %s", i, nrow(docs), d$rw_id))
  # An error on one report is recorded and the run goes on
  tryCatch(
    code_one(d),
    error = \(e) tibble(code_llm = NA_character_, reason = NA_character_,
                        model_used = NA_character_,
                        stop_reason = paste("error:", conditionMessage(e)),
                        input_tokens = 0L, output_tokens = 0L)
  )
})

codes <- docs |>
  select(id, rw_id) |>
  bind_cols(bind_rows(results)) |>
  mutate(
    run_id = run_id,
    model_requested = model,
    effort = effort,
    api_version = api_version,
    codebook_file = codebook_file,
    codebook_md5 = unname(tools::md5sum(codebook_file))
  )

# ---- Save -------------------------------------------------------------------

run_dir <- "data/processed/llm_runs"
dir.create(run_dir, recursive = TRUE, showWarnings = FALSE)
run_file <- file.path(run_dir, paste0("sample20_", run_id, ".csv"))
write_csv(codes, run_file, na = "")
writeLines(system_prompt, file.path(run_dir, paste0("sample20_", run_id, "_prompt.txt")))
message("Saved ", run_file)

# ---- Report -----------------------------------------------------------------

print(count(codes, code_llm))

problems <- filter(codes, stop_reason != "end_turn")
if (nrow(problems) > 0) {
  message(nrow(problems), " report(s) without a code:")
  print(select(problems, id, rw_id, stop_reason))
}

cost <- sum(codes$input_tokens) / 1e6 * price$input +
  sum(codes$output_tokens) / 1e6 * price$output
message(sprintf(
  "Actual: %s input and %s output tokens, $%.3f. About $%.2f per 1,000 reports.",
  format(sum(codes$input_tokens), big.mark = ","),
  format(sum(codes$output_tokens), big.mark = ","),
  cost, cost / nrow(codes) * 1000
))
message("Model that answered: ", paste(unique(na.omit(codes$model_used)), collapse = ", "))

# ---- Compare with the previous run ------------------------------------------

earlier <- setdiff(
  list.files(run_dir, pattern = "^sample20_\\d{8}_\\d{6}\\.csv$", full.names = TRUE),
  run_file
)
if (length(earlier) > 0) {
  prev_file <- max(earlier)  # file names sort by date and time
  prev <- read_csv(prev_file, show_col_types = FALSE,
                   col_types = cols(.default = col_character()))
  same_codebook <- all(prev$codebook_md5 == codes$codebook_md5[1])

  changed <- codes |>
    mutate(rw_id = as.character(rw_id)) |>
    select(id, rw_id, code_llm) |>
    inner_join(select(prev, rw_id, code_previous = code_llm), by = "rw_id") |>
    filter(!coalesce(code_llm == code_previous, is.na(code_llm) & is.na(code_previous)))

  message(sprintf("Compared with %s (%s codebook): %d of %d codes changed.",
                  basename(prev_file), if (same_codebook) "same" else "a different",
                  nrow(changed), nrow(codes)))
  if (nrow(changed) > 0) print(changed)
}
