# 02_reliefweb_pull.R
#
# Stage 1 (Collect): downloads every ReliefWeb report whose primary country is
# the chosen country and whose own date (date.original) falls in the chosen year.
#
# API: ReliefWeb API v2 (https://apidoc.reliefweb.int/). Version 1 was
# decommissioned (it answers "410 Gone"). Every request needs an approved app
# name, read here from RELIEFWEB_APPNAME in ~/.Renviron. Limits: 1,000 reports
# per call and 1,000 calls per day; a full country-year takes a few calls.
#
# The page text is the "body" field: what the ReliefWeb page shows. For many
# situation reports this is only a summary and the full report is an attached
# PDF; attachments are listed (file_urls) but not downloaded.
#
# Writes:
#   data/raw/reliefweb/<iso3>_<year>/page_NNN.json   API responses, as returned
#   data/raw/reliefweb/<iso3>_<year>/request.json    query, date retrieved, total count
#   data/raw/reliefweb/<iso3>_<year>/reports.rds     the same records in one table, with body text
#   data/processed/reliefweb_<iso3>_<year>_reports.csv  metadata only, no body text
#
# Report text belongs to its original sources, so it stays in data/raw/, which
# is not pushed to GitHub (see .gitignore). The processed CSV has links,
# identifiers and titles only.
#
# Run from the project/ folder:
#   Rscript R/02_reliefweb_pull.R            Ukraine, 2022 (the defaults)
#   Rscript R/02_reliefweb_pull.R sdn 2023   any ISO3 code and year

suppressPackageStartupMessages(library(dplyr))
library(readr)
library(purrr)
library(httr2)
suppressPackageStartupMessages(library(jsonlite))

# ---- Settings ---------------------------------------------------------------

args <- commandArgs(trailingOnly = TRUE)
iso3 <- tolower(if (length(args) >= 1) args[1] else "ukr")
year <- as.integer(if (length(args) >= 2) args[2] else 2022)

endpoint <- "https://api.reliefweb.int/v2/reports"
page_size <- 1000   # the API maximum

appname <- Sys.getenv("RELIEFWEB_APPNAME")
if (!nzchar(appname)) {
  stop("RELIEFWEB_APPNAME is not set. Add the line RELIEFWEB_APPNAME=<your app name> ",
       "to ~/.Renviron and restart R.")
}

raw_dir <- file.path("data/raw/reliefweb", paste0(iso3, "_", year))
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
dir.create("data/processed", showWarnings = FALSE)

# ---- Query ------------------------------------------------------------------

fields <- c("title", "body", "date.original", "date.created",
            "source.name", "source.shortname", "format.name", "language.code",
            "theme.name", "country.iso3", "primary_country.iso3",
            "url", "origin", "file.url")

query <- list(
  fields = list(include = fields),
  filter = list(
    operator = "AND",
    conditions = list(
      list(field = "primary_country.iso3", value = iso3),
      list(field = "date.original",
           value = list(from = sprintf("%d-01-01T00:00:00+00:00", year),
                        to   = sprintf("%d-12-31T23:59:59+00:00", year)))
    )
  ),
  sort = list("id:asc"),   # fixed order, so pages do not overlap
  limit = page_size
)

fetch_page <- function(offset) {
  request(endpoint) |>
    req_url_query(appname = appname) |>
    req_body_json(c(query, list(offset = offset)), auto_unbox = TRUE) |>
    req_retry(max_tries = 3) |>
    req_perform() |>
    resp_body_string()
}

# ---- Download every page ----------------------------------------------------

pages <- list()
offset <- 0
total <- NA_integer_

repeat {
  txt <- fetch_page(offset)
  page_no <- length(pages) + 1
  writeLines(txt, file.path(raw_dir, sprintf("page_%03d.json", page_no)))

  page <- fromJSON(txt, simplifyVector = FALSE)
  total <- page$totalCount
  pages[[page_no]] <- page$data
  offset <- offset + page$count
  message("Page ", page_no, ": ", offset, " of ", total, " reports")

  if (page$count == 0 || offset >= total) break
  Sys.sleep(1)   # be polite to the API
}

write_json(
  list(endpoint = endpoint,
       query = query,
       retrieved_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
       total_count = total,
       n_pages = length(pages)),
  file.path(raw_dir, "request.json"), auto_unbox = TRUE, pretty = TRUE
)

# ---- Flatten into one table -------------------------------------------------

# Join one sub-field of a list field (e.g. every source's shortname) with "; "
collapse_field <- function(x, key) {
  if (is.null(x) || length(x) == 0) return(NA_character_)
  vals <- map_chr(x, \(e) e[[key]] %||% NA_character_)
  paste(vals[!is.na(vals)], collapse = "; ")
}

flatten_report <- function(r) {
  f <- r$fields
  tibble(
    rw_id = r$id,
    date_original = substr(f$date$original %||% NA_character_, 1, 10),
    date_created = substr(f$date$created %||% NA_character_, 1, 10),
    title = f$title %||% NA_character_,
    source = collapse_field(f$source, "shortname"),
    source_name = collapse_field(f$source, "name"),
    format = collapse_field(f$format, "name"),
    language = collapse_field(f$language, "code"),
    theme = collapse_field(f$theme, "name"),
    countries = collapse_field(f$country, "iso3"),
    url = f$url %||% NA_character_,
    origin = f$origin %||% NA_character_,
    file_urls = collapse_field(f$file, "url"),
    body = f$body %||% NA_character_
  )
}

reports <- pages |>
  list_flatten() |>
  map(flatten_report) |>
  list_rbind() |>
  mutate(
    n_words_body = lengths(strsplit(coalesce(body, ""), "\\s+")) * (nzchar(trimws(coalesce(body, "")))),
    n_files = if_else(is.na(file_urls), 0L, lengths(strsplit(file_urls, "; ")))
  )

# Every report once, and as many as the API said there were
stopifnot(!anyDuplicated(reports$rw_id), nrow(reports) == total)

saveRDS(reports, file.path(raw_dir, "reports.rds"))

processed_file <- sprintf("data/processed/reliefweb_%s_%d_reports.csv", iso3, year)
reports |>
  select(-body) |>
  write_csv(processed_file, na = "")

# ---- Summary ----------------------------------------------------------------

message("\n", nrow(reports), " reports saved to ", raw_dir, "/reports.rds")
message("Metadata (no text) saved to ", processed_file, "\n")
message("By format:")
print(count(reports, format, sort = TRUE), n = 20)
message("\nEnglish reports: ", sum(grepl("\\ben\\b", reports$language)))
message("Reports with fewer than 50 words of page text: ", sum(reports$n_words_body < 50))
