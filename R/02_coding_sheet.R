# Week 6: make the spreadsheet for the hand codes.
#
# Input: data/processed/sample_20.csv   (R/01_sample_20.R)
#
# Writes data/processed/hand_codes_20.xlsx, sheet "Codes": one row per report
# (id, ReliefWeb id, date, source, type, words, title and link) and three columns
# for the hand coder (yellow): code_hand (yes / no, from a drop-down), note, and
# minutes (optional).
#
# The sheet has titles and links only. The report text is in
# output/local/reading_sheet_20.md, which is kept locally.
#
# An existing sheet is never overwritten, so hand codes cannot be lost by
# running this again.
#
# Run from the week-06/ folder:
#   Rscript R/02_coding_sheet.R

suppressPackageStartupMessages(library(dplyr))
library(readr)
library(openxlsx)

sample_file <- "data/processed/sample_20.csv"
sheet_file <- "data/processed/hand_codes_20.xlsx"

if (file.exists(sheet_file)) {
  stop(sheet_file, " already exists and may hold hand codes; it is not overwritten.")
}

# ---- The 20 reports, with empty columns to fill in --------------------------

codes <- read_csv(sample_file, show_col_types = FALSE,
                  col_types = cols(.default = col_character())) |>
  transmute(id = as.integer(id), rw_id, date = date_original, source, type = format,
            words = as.integer(n_words_body), title, link = url,
            code_hand = NA_character_, note = NA_character_, minutes = NA_real_)

class(codes$link) <- "hyperlink"   # clickable in Excel and Numbers

fill_cols <- which(names(codes) %in% c("code_hand", "note", "minutes"))
rows <- seq_len(nrow(codes)) + 1   # data rows, below the header

# ---- Codes sheet ------------------------------------------------------------

wb <- createWorkbook()
addWorksheet(wb, "Codes")
writeData(wb, "Codes", codes)

addStyle(wb, "Codes", createStyle(textDecoration = "bold", fgFill = "#D9E1F2", border = "bottom"),
         rows = 1, cols = seq_along(codes), gridExpand = TRUE)
addStyle(wb, "Codes", createStyle(wrapText = TRUE, valign = "top"),
         rows = rows, cols = seq_along(codes), gridExpand = TRUE)
addStyle(wb, "Codes", createStyle(fgFill = "#FFF2CC", wrapText = TRUE, valign = "top"),
         rows = rows, cols = fill_cols, gridExpand = TRUE)

# Only yes or no can be entered as a code
dataValidation(wb, "Codes", cols = which(names(codes) == "code_hand"), rows = rows,
               type = "list", value = '"yes,no"')

setColWidths(wb, "Codes", cols = seq_along(codes),
             widths = c(4, 10, 11, 14, 14, 7, 55, 30, 11, 45, 9))
freezePane(wb, "Codes", firstRow = TRUE)

saveWorkbook(wb, sheet_file)
message("Saved ", sheet_file)
