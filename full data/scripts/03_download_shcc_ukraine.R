# 03_download_shcc_ukraine.R
#
# Downloads Insecurity Insight's Ukraine attacks on health care incident file
# from HDX, the comparison record for the Ukraine pilot (Stage 4, Match).
#
# Source: Insecurity Insight, "Ukraine (UKR): Attacks on Aid Operations, Education,
#   Food and Water Systems and Health Care, and Conflict-Related and Explosive
#   Weapons Incident Data",
#   https://data.humdata.org/dataset/ukraine-data-on-attacks-on-aid-operations-education-health-and-protection
#   File: "2016-2026 UKR Attacks on Health Care Incident Data.xlsx"
#   (HDX resource 03db9083-4f16-4337-b20b-26aae4fe59dc). HDX describes it as
#   covering 1 January 2016 to 28 September 2026.
#   License on HDX: CC BY-SA. Cite the dataset name, period covered and retrieval date.
#
# The file is updated in place, so the script asks HDX for the current download
# link and records the date retrieved next to the file.
#
# Writes (not pushed to GitHub):
#   data/raw/hdx_ukr/2016-2026-ukr-attacks-on-health-care-incident-data.xlsx
#   data/raw/hdx_ukr/2016-2026-ukr-attacks-on-health-care-incident-data_retrieved.txt
#
# Run from the project/ folder:
#   Rscript R/03_download_shcc_ukraine.R

library(httr2)

resource_id <- "03db9083-4f16-4337-b20b-26aae4fe59dc"
dest_dir <- "data/raw/hdx_ukr"
dest <- file.path(dest_dir, "2016-2026-ukr-attacks-on-health-care-incident-data.xlsx")

dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)

# ---- Look up the current download link --------------------------------------

resource <- request("https://data.humdata.org/api/3/action/resource_show") |>
  req_url_query(id = resource_id) |>
  req_user_agent("MPA 2479 class project (Brown University)") |>
  req_retry(max_tries = 3) |>
  req_perform() |>
  resp_body_json()

url <- resource$result$url
message("File: ", resource$result$name, " (last modified on HDX ", resource$result$last_modified, ")")

# ---- Download ---------------------------------------------------------------

retrieved_at <- Sys.time()
invisible(request(url) |>
  req_user_agent("MPA 2479 class project (Brown University)") |>
  req_retry(max_tries = 3) |>
  req_perform(path = dest))

# Record where and when the file came from, next to the file
writeLines(c(
  paste("dataset: Insecurity Insight, Ukraine (UKR) attacks on health care incident data (HDX)"),
  paste("file:", resource$result$name),
  paste("hdx_last_modified:", resource$result$last_modified),
  paste("url:", url),
  paste("retrieved:", format(retrieved_at, "%Y-%m-%d %H:%M:%S %Z")),
  paste("bytes:", file.size(dest))
), sub("\\.xlsx$", "_retrieved.txt", dest))

message("Saved ", dest, " (", file.size(dest), " bytes)")
