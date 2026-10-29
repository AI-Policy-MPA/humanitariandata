# Week 6 (optional): topic model of the 2022 ReliefWeb reports on Ukraine.
#
# LDA (latent Dirichlet allocation; topicmodels package, VEM) on every English
# 2022 report with at least 50 words of page text: a much larger set than the
# 20 hand-coded reports, to see what the collection is about and where reports
# on health care sit in it.
#
# Text: title and page text in lower case, with web links, email addresses,
# numbers and punctuation removed, and English stop words removed (tm list).
# A term is kept if it appears in at least 10 reports and in no more than half
# of them, which drops words such as "ukraine" that appear almost everywhere.
#
# Settings: 12 topics, seed 20261028. The number of topics is a choice, not a
# result; other numbers were not tested. Topics are listed by their top words
# and are not named.
#
# Writes:
#   output/topics_lda.csv                topic, top 10 words, mean share of the collection,
#                                        and the number of reports where it is the main topic
#   output/topics_lda_sample20.csv       main topic of each of the 20 hand-coded reports, with the hand code
#   data/processed/topics_lda_docs.csv   ReliefWeb id, main topic and its share, for every report modelled
#
# Run from the week-06/ folder:
#   Rscript R/05_topic_model.R

suppressPackageStartupMessages(library(dplyr))
library(readr)
library(readxl)
library(stringr)
suppressPackageStartupMessages({
  library(tm)
  library(topicmodels)
  library(slam)
})

# ---- Settings ---------------------------------------------------------------

reports_file <- "../project/data/raw/reliefweb/ukr_2022/reports.rds"
k <- 12
seed <- 20261028
min_docs <- 10      # a term must appear in at least this many reports
max_share <- 0.5    # and in no more than this share of them
n_terms <- 10       # top words listed per topic

# ---- Text -------------------------------------------------------------------

docs <- readRDS(reports_file) |>
  filter(str_detect(language, "\\ben\\b"), n_words_body >= 50) |>
  mutate(text = paste(title, coalesce(body, "")) |>
           str_to_lower() |>
           str_remove_all("https?://\\S+|www\\.\\S+|\\S+@\\S+") |>
           str_replace_all("[^a-z]+", " "))

corpus <- VCorpus(VectorSource(docs$text))
dtm <- DocumentTermMatrix(corpus, control = list(
  stopwords = TRUE,
  wordLengths = c(3, Inf),
  bounds = list(global = c(min_docs, floor(max_share * nrow(docs))))
))

# Reports left with no terms cannot be modelled
keep <- row_sums(dtm) > 0
dtm <- dtm[keep, ]
docs <- docs[keep, ]
message(nrow(docs), " reports, ", ncol(dtm), " terms")

# ---- Model ------------------------------------------------------------------

lda <- LDA(dtm, k = k, method = "VEM", control = list(seed = seed))
post <- posterior(lda)
beta <- post$terms     # topics x terms
gamma <- post$topics   # reports x topics

top_terms <- apply(beta, 1, \(b) paste(names(sort(b, decreasing = TRUE))[seq_len(n_terms)], collapse = ", "))
main <- max.col(gamma, ties.method = "first")

topics <- tibble(
  topic = seq_len(k),
  top_terms = top_terms,
  share = colMeans(gamma),
  main_reports = tabulate(main, nbins = k)
) |>
  arrange(desc(share))

doc_topics <- tibble(rw_id = docs$rw_id, main_topic = main,
                     main_share = gamma[cbind(seq_len(nrow(gamma)), main)])

# ---- The 20 hand-coded reports ----------------------------------------------

hand <- read_excel("data/processed/hand_codes_20.xlsx", sheet = "Codes", col_types = "text") |>
  select(id, rw_id, title, code_hand)
sample_topics <- hand |>
  left_join(doc_topics, by = "rw_id") |>
  left_join(select(topics, topic, top_terms), by = c("main_topic" = "topic")) |>
  mutate(id = as.integer(id)) |>
  arrange(id)

# ---- Save -------------------------------------------------------------------

dir.create("output", showWarnings = FALSE)
write_csv(topics, "output/topics_lda.csv")
write_csv(select(sample_topics, id, rw_id, code_hand, main_topic, main_share, top_terms),
          "output/topics_lda_sample20.csv")
write_csv(doc_topics, "data/processed/topics_lda_docs.csv")

options(width = 160)
print(mutate(topics, share = round(share, 3)), n = k)
message("\nMain topic of the 20 hand-coded reports:")
print(count(sample_topics, main_topic, code_hand) |> tidyr::pivot_wider(names_from = code_hand, values_from = n, values_fill = 0))
