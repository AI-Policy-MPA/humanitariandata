# Week 6: Hand coding and automated coding of ReliefWeb reports

MPA 2479, text analysis exercise, due Oct 29, 2026. Shwetha Mangalesh.

This exercise is the first run of the screening and audit stages of the project's Analysis Plan (see the [project README](../README.md)). Twenty ReliefWeb reports on Ukraine from 2022 were coded by hand for one variable, then coded by a language model through the Claude API, and the two were compared. A topic model (LDA) was then fitted to all 3,458 English reports from 2022.

## Text source

Reports posted on [ReliefWeb](https://reliefweb.int), OCHA's humanitarian information service, collected through the ReliefWeb API (version 2) with an approved app name. ReliefWeb carries situation reports, press releases, analyses and statements from UN agencies, NGOs, governments and the media, so it holds report text, not coded incident data.

Reports whose primary country is Ukraine, by the report's own date (counted on 28 Oct 2026):

| Year | Reports |
|---|---|
| 2022 (pilot, downloaded) | 4,122 |
| 2023 | 2,196 |
| 2024 | 2,200 |
| 2025 | 1,525 |
| 2026 (to 28 Oct) | 1,019 |
| **2022 to 2026** | **11,062** |

The 2022 reports are mostly news and press releases (2,267) and situation reports (578). The text coded is what the ReliefWeb page shows. For many situation reports this is a summary, and the full report is an attached PDF, which was not read.

Report text belongs to its original sources, so this repository holds report identifiers, titles, links and codes, not the text itself.

## Variable

`attack_hc`: **Does the report describe at least one specific attack on health care?** (`yes` / `no`)

Codebook: [`project/docs/codebook_screen_v1.md`](../project/docs/codebook_screen_v1.md).

- **Part A** summarises the definitions and event criteria of the Safeguarding Health in Conflict Coalition (SHCC) *Attacks Data Codebook* (Insecurity Insight, May 2019, p. 2): what counts as an attack on health care, a health worker and a health facility, and which actors are included.
- **Part B** adds eight rules for coding a whole report, which the SHCC codebook does not cover because it codes incidents. The rule that mattered most here is B2: a `yes` needs an identifiable event (a place, a date, or a particular facility, worker or vehicle), and a total alone is `no`.

## Sample

| | Reports |
|---|---|
| Ukraine, dated 2022 | 4,122 |
| English | 4,066 |
| English, 50 to 3,000 words of page text | 3,382 |
| ...and mention health care at least once (the pool) | 1,524 |
| ......a health term in the same sentence as a harm word | 520 |
| ......a health term only | 1,004 |

Attacks are a minority of the pool, so a simple random draw of 20 could have held too few for precision and recall to mean anything. Ten reports were drawn at random from each of the last two groups (seed 20261028), and the 20 were shown in a random order without saying which group each came from. The results describe these 20 reports. They are not an estimate for the whole pool, because the "health term near a harm word" group is over-represented.

## Methods

1. **Hand coding.** All 20 reports were coded by hand from the reading sheet before any model output existed. The codebook and hand codes were committed at 22:24:44 on 28 Oct 2026 (local commit `3e39bf8`); the model run started at 22:24:45.
2. **Language model.** `claude-opus-5-5` through the Anthropic Messages API (API version 2026-10-21), effort `medium`, zero-shot: the full codebook as the system prompt, then one report at a time with the same title, type, source, date and page text the hand coder read. Structured output forced each answer to be `yes` or `no` with a one-sentence reason. No fallback model was used, so every code comes from one model. The exact prompt is saved with the run.
3. **Keyword rule.** A simple dictionary method for comparison: `yes` when a health term appears in the same sentence as a harm word, within 80 characters. This is the rule that split the sample.
4. **Comparison.** Hand codes are the reference. For each method: confusion matrix, accuracy, the majority-class baseline, and precision, recall and F1 for `yes`.
5. **Topic model (optional step).** LDA with 12 topics (R package `topicmodels`, VEM, seed 20261028) on all 3,458 English 2022 reports with at least 50 words of page text. Title and page text, with stop words removed; a term is kept if it appears in at least 10 reports and in no more than half of them. The number of topics was chosen, not tuned.

## Results

Hand codes: 4 `yes`, 16 `no`.

| | Model | Keyword rule |
|---|---|---|
| Accuracy | 0.85 (17 / 20) | 0.50 (10 / 20) |
| Baseline: always `no` | 0.80 | 0.80 |
| Precision for `yes` | 1.00 (1 / 1) | 0.20 (2 / 10) |
| Recall for `yes` | 0.25 (1 / 4) | 0.50 (2 / 4) |
| F1 for `yes` | 0.40 | 0.29 |

Confusion matrices (rows: hand codes; columns: method):

| Model | `yes` | `no` |
|---|---|---|
| **Hand `yes`** | 1 | 3 |
| **Hand `no`** | 0 | 16 |

| Keyword rule | `yes` | `no` |
|---|---|---|
| **Hand `yes`** | 2 | 2 |
| **Hand `no`** | 8 | 8 |

**Where the model and the hand codes disagree.** All three disagreements are reports coded `yes` by hand and `no` by the model. In each, the model's reason cites rule B2 (no specific event), along with B6 (indirect harm) and B8 (general statements). Every phrase the model quoted was checked against the report text.

| # | Report | Hand note | Model's reason, in short |
|---|---|---|---|
| 5 | ICRC, 12 Jan 2022, on the conflict in eastern Ukraine | attack on humanitarian forces | Mentions only general "disrupted access to medical care"; no facility, worker, vehicle or supply hit |
| 7 | UN human rights experts, 4 Mar 2022, on older people and persons with disabilities | alludes to attacks on health care facilities | Says only in general terms that explosive weapons are disrupting services such as health care |
| 9 | UN, Apr 2022, call for an Easter truce | attacks on hospitals | Gives a total (136 attacks on health care facilities since the start of hostilities) and a general reference to attacks on hospitals; no place, date or facility |

The one report both coded `yes` (#2, MSF, 6 Mar 2022) says hospitals in Mariupol were heavily damaged by attacks. The model counted the named place under B2, while noting that the mention is brief and names no particular hospital.

With only 4 `yes` codes, one report moves precision or recall by 0.25, and always answering `no` already scores 0.80 accuracy. Full output: [`output/eval_20.txt`](output/eval_20.txt).

**Cost and time.** The model run used 72,917 input and 2,963 output tokens and cost $0.35, about $17.55 per 1,000 reports of this length. At that rate the 11,062 Ukraine reports for 2022 to 2026 would cost roughly $190. That figure is rough, because the 20 were capped at 3,000 words and longer reports cost more. Hand coding the 20 reports meant reading about 16,000 words.

### Topic model

Twelve topics across 3,458 reports and 7,269 terms, listed by their ten most likely words. Share is the topic's average share of a report; "main topic" counts the reports where it has the largest share.

| Topic | Top words | Share | Main topic of |
|---|---|---|---|
| 5 | health, conflict, women, million, access, services, care, needs, children, violence | 13.2% | 499 |
| 12 | medical, aid, water, supplies, health, red, cross, relief, food, ukrainian | 12.9% | 472 |
| 8 | million, assistance, refugees, countries, ukrainian, european, protection, government, response, help | 11.8% | 416 |
| 6 | information, response, services, needs, protection, local, social, national, conflict, government | 11.7% | 418 |
| 4 | casualties, civilian, killed, injured, oblast, ohchr, march, reported, kyiv, government | 8.7% | 278 |
| 9 | food, million, wfp, data, grain, per, cent, damage, world, global | 7.9% | 258 |
| 10 | now, many, can, one, region, says, border, time, home, mission | 7.2% | 227 |
| 7 | children, education, unicef, families, child, schools, school, help, ukrainian, social | 6.2% | 215 |
| 3 | russian, said, federation, international, united, council, must, states, nations, security | 5.7% | 190 |
| 2 | nuclear, iaea, power, plant, safety, general, said, director, security, site | 5.6% | 180 |
| 11 | rights, human, russian, civilians, said, international, forces, crimes, law, ukrainian | 5.5% | 209 |
| 1 | russian, russia, forces, ukrainian, week, region, last, continued, violence, military | 3.6% | 96 |

- No topic's top ten words include "attack", "hospital", "clinic" or "ambulance". Health appears in the two largest topics: topic 5 (health needs and access to services) and topic 12 (medical aid and supplies).
- Of the 4 reports coded `yes` by hand, 2 have topic 5 as their main topic, 1 topic 10 and 1 topic 11. Topic 12 is the main topic of 4 of the 20 reports, all coded `no` by hand.
- At 12 topics, the model does not separate reports that describe attacks on health care from reports about health needs or medical aid.

Files: [`output/topics_lda.csv`](output/topics_lda.csv), [`output/topics_lda_sample20.csv`](output/topics_lda_sample20.csv).

## Discussion

I was able to acquire access to ReliefWeb's API. This was very helpful since it contains texts and reports from various sources and not just coded data. I picked Ukraine for my pilot analysis and the year 2022. My final data will be between 2022 to 2026, which contains 11,062 reports (as of 28 October 2026), just for Ukraine. I then had Claude randomly select 20 articles from 2022 to hand code (from the 1,524 English reports that mention health care; see Sample). My question for hand code was "Does the report describe at least one specific attack on health care?" (yes or no). Here's where Claude and I differed. While I considered attacks on healthcare facilities or even where a report alludes to attacks on health care or numbers as attacks on healthcare. While Claude specifically stuck to actual human toll. I was surprised by this but also think that unless I specify that this includes facilities, direct and indirect attacks it is still considered attacks on health care. While it was okay for me to skim through the summary for 20 articles, I don't think it is possible for me to do this for 11k+ articles, and that too restricted to Ukraine only and not even including other places. I think it would be critical for me to specify what this codebook should contain, how it's different from OCHA data, or WHO or SHCC data. I think AI has been extremely useful here to gather all of my data and also skim through everything. While I'm currently using a published codebook from SHCC. It might be worthwhile evaluating what the codebook misses, how much more information that I can add using AI and how this might impact the results for policy analysis. I was always looking to use AI for the project, particularly to help with data collection and synthesis. I think for this step it has been exceedingly useful. However, I'm curious to understand and see at what other steps of the eightfold path will I still find AI useful.

## Files

| File | What it is |
|---|---|
| [`../project/R/02_reliefweb_pull.R`](../project/R/02_reliefweb_pull.R) | Downloads every ReliefWeb report for a country and year |
| [`../project/data/processed/reliefweb_ukr_2022_reports.csv`](../project/data/processed/reliefweb_ukr_2022_reports.csv) | The 4,122 Ukraine 2022 reports: identifiers, dates, sources, titles, links (no text) |
| [`../project/docs/codebook_screen_v1.md`](../project/docs/codebook_screen_v1.md) | The codebook |
| [`R/01_sample_20.R`](R/01_sample_20.R) | Builds the pool and draws the 20 reports |
| [`R/02_coding_sheet.R`](R/02_coding_sheet.R) | Makes the hand-coding spreadsheet |
| [`R/03_code_llm.R`](R/03_code_llm.R) | Codes the 20 reports with the Claude API |
| [`R/04_evaluate.R`](R/04_evaluate.R) | Compares each method with the hand codes |
| [`data/processed/sample_20.csv`](data/processed/sample_20.csv) | The 20 reports (no text) |
| [`data/processed/sample_20_strata.csv`](data/processed/sample_20_strata.csv) | Which group each report was drawn from |
| [`data/processed/hand_codes_20.xlsx`](data/processed/hand_codes_20.xlsx) | Hand codes and notes |
| [`data/processed/llm_runs/`](data/processed/llm_runs/) | The model's codes and reasons, and the exact prompt |
| [`output/eval_20.txt`](output/eval_20.txt), [`output/metrics_20.csv`](output/metrics_20.csv) | Comparison results |
| [`output/sample_20_log.txt`](output/sample_20_log.txt) | Pool sizes and seed |
| [`R/05_topic_model.R`](R/05_topic_model.R) | LDA topic model of the 2022 reports |
| [`output/topics_lda.csv`](output/topics_lda.csv) | The 12 topics: top words, share, reports per main topic |
| [`output/topics_lda_sample20.csv`](output/topics_lda_sample20.csv) | Main topic of each of the 20 hand-coded reports |
| [`data/processed/topics_lda_docs.csv`](data/processed/topics_lda_docs.csv) | Main topic of every report modelled (ReliefWeb ids only) |

## Reproducibility

All scripts are in R and run in the order listed above, the project pull first. The pull uses a ReliefWeb app name and the model run uses an Anthropic API key, both read from environment variables. Report text is downloaded locally and is not part of this repository. The model cannot be run at a fixed temperature on this API version, so a second run may give different codes.
