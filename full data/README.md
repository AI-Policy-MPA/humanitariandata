# Full data: ReliefWeb reports on Ukraine, 2022 to 2026

Every report on [ReliefWeb](https://reliefweb.int) (OCHA) whose primary country is Ukraine, dated 1 January 2022 to 28 October 2026: 11,062 reports, downloaded through the ReliefWeb API (version 2) on 28 October 2026. One row per report, with identifiers, dates, sources, titles, links and screening flags.

The report text is not included. It belongs to the original sources, so this repository keeps links, identifiers and codes only.

## Counts

| Year | Reports | English | English, 50+ words of page text | ...mention health care | ...health term near a harm word |
|---|---|---|---|---|---|
| 2022 | 4,122 | 4,066 | 3,512 | 1,593 | 563 |
| 2023 | 2,196 | 2,170 | 1,986 | 763 | 294 |
| 2024 | 2,200 | 2,050 | 2,006 | 747 | 319 |
| 2025 | 1,525 | 1,402 | 1,256 | 423 | 169 |
| 2026 (to 28 Oct) | 1,019 | 940 | 771 | 307 | 106 |
| **Total** | **11,062** | **10,628** | **9,531** | **3,833** | **1,451** |

A report can describe an attack on health care only if it mentions health care, so the 3,833 reports in the second-to-last column are the candidates for screening.

## Files

| File | What it is |
|---|---|
| [`reliefweb_ukr_2022_2026_reports.csv`](reliefweb_ukr_2022_2026_reports.csv) | All 11,062 reports, one row each (columns below) |
| [`reliefweb_ukr_2022_2026_summary.csv`](reliefweb_ukr_2022_2026_summary.csv) | The counts above |
| [`codebooks/codebook_screen_v1.md`](codebooks/codebook_screen_v1.md) | Screening codebook: does the report describe at least one specific attack on health care? |
| [`codebooks/codebook_crosswalk_v0.md`](codebooks/codebook_crosswalk_v0.md) | Draft crosswalk of the codebook against the SHCC Ukraine incident file and WHO SSA |
| [`scripts/02_reliefweb_pull.R`](scripts/02_reliefweb_pull.R) | Downloads every ReliefWeb report for a country and year |
| [`scripts/03_download_shcc_ukraine.R`](scripts/03_download_shcc_ukraine.R) | Downloads the SHCC Ukraine incident file from HDX |
| [`scripts/05_reliefweb_combine.R`](scripts/05_reliefweb_combine.R) | Combines the yearly downloads and adds the flags |

## Columns of `reliefweb_ukr_2022_2026_reports.csv`

| Column | Meaning |
|---|---|
| `rw_id` | ReliefWeb report id |
| `date_original` | The report's own date |
| `date_created` | Date the report was posted on ReliefWeb |
| `title` | Report title |
| `source`, `source_name` | Publishing organisations, short and full names, separated by "; " |
| `format` | ReliefWeb content type, such as News and Press Release or Situation Report |
| `language` | Language codes, separated by "; " |
| `theme` | ReliefWeb themes, separated by "; " |
| `countries` | ISO3 codes of every country the report is tagged with |
| `url` | The report's ReliefWeb page |
| `origin` | The source's own page for the report, where given |
| `file_urls` | Attachments, usually PDFs, separated by "; " |
| `n_words_body` | Words of page text on ReliefWeb |
| `n_files` | Number of attachments |
| `year` | Year of `date_original` |
| `english` | Tagged English |
| `words_50` | At least 50 words of page text |
| `health_mention` | The title or page text mentions health care at least once (hospital, clinic, ambulance, medical, health care, health facility, health worker, doctor, nurse, paramedic, pharmacy, maternity and similar) |
| `health_near_harm` | A health term in the same sentence as a harm word (attack, shelling, strike, missile, destroyed, damaged, killed, injured, looted, occupied and similar), within 80 characters |
| `same_title_source_date` | Number of reports with the same title, source and date; above 1 for 6 reports, which may be the same report posted twice |

The exact word lists are in `scripts/05_reliefweb_combine.R`.

## Not included

- **Report text.** The scripts download it again from the ReliefWeb API, which requires an approved app name.
- **The SHCC Ukraine incident file.** Insecurity Insight, "2016-2026 UKR Attacks on Health Care Incident Data", on the [Humanitarian Data Exchange](https://data.humdata.org/dataset/ukraine-data-on-attacks-on-aid-operations-education-health-and-protection) (CC BY-SA), used as the comparison record. Insecurity Insight's terms for academic use are not yet confirmed, so the file is not copied here; `scripts/03_download_shcc_ukraine.R` downloads it.

## Reproducibility

The scripts are in R and were run from the project folder of the working repository, where they read and write `data/raw/`, `data/processed/` and `output/`. Run order: `02_reliefweb_pull.R` once for each year (for example `ukr 2023`), then `05_reliefweb_combine.R`; `03_download_shcc_ukraine.R` is independent. ReliefWeb keeps adding reports, so a new download can return more reports than these counts, especially for 2026.
