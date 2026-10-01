# Surveillance of Attacks on Health Care

Applied AI for Public Policy, Fall 2026 (Prof. Han Zhang).
Shwetha Mangalesh

## Summary

| | |
|---|---|
| **Policy question** | How can the UN Office for the Coordination of Humanitarian Affairs (OCHA) obtain complete and current data on attacks on health care to guide humanitarian response decisions? |
| **Audience** | UN OCHA, in particular its Centre for Humanitarian Data |
| **Data** | Incident data on attacks on health care from the Safeguarding Health in Conflict Coalition (SHCC) and the WHO Surveillance System for Attacks on Health Care (SSA), ACLED and the Aid Worker Security Database |
| **End Goal** | A web page for OCHA, and this repository with open-source code, and data where licenses allow, to re-run the analysis and simulations |

## Problem Statement

Attacks on health care are increasing faster than the surveillance systems can record them. Across 36 countries affected by conflict, the Safeguarding Health in Conflict Coalition recorded 3,623 incidents of violence against or obstruction of health care in 2024, an average of nearly ten per day and a 62% increase since 2022. More than 900 health workers were killed. Each incident report is still read and coded manually by analysts at a small number of surveillance organizations, and the volume of reports now exceeds their capacity to process them. As a result, incidents enter the record with delay or not at all, and the data used to direct the humanitarian medical response and to support accountability are incomplete and out of date at the point of use.

Source: Safeguarding Health in Conflict Coalition and Insecurity Insight (2025), [*Epidemic of violence: Violence against health care in conflict 2024*](https://www.insecurityinsight.org/wp-content/uploads/2025/04/2024-SHCC-Annual-Report.pdf).

## Why UN OCHA

OCHA coordinates the humanitarian response that these data are meant to inform. Its Centre for Humanitarian Data runs the [Humanitarian Data Exchange](https://data.humdata.org/), where the SHCC incident data are published. OCHA does not collect these data. It depends on SHCC, WHO, and others to record attacks, and it uses what they record to make decisions.

## Data Sources and Evidence

| Source | What it contains | Utility |
|---|---|---|
| [Insecurity Insight, SHCC attacks on health care data](https://data.humdata.org/dataset/shcchealthcare-dataset) | Incident records of attacks on health care in conflict-affected countries, coded by analysts | Main dataset; the analysts' coding is the reference standard |
| WHO SSA [dashboard](https://extranet.who.int/ssa/) and [methodology](https://www.who.int/publications/i/item/surveillance-system-for-attacks-on-health-care-(-ssa)) | Attacks recorded and verified by WHO | Second main source; compared with SHCC |
| [ACLED](https://acleddata.com) | Armed conflict event data | Cross-check |
| [Aid Worker Security Database](https://humanitarianoutcomes.org/AWSD-codebook) | Major incidents of violence against aid workers | Cross-check for incidents involving health workers |


**The sources record different attacks.** Parada and colleagues compared WHO's records of attacks on health care in 2017 with Insecurity Insight's Security in Numbers Database. Of 254 unique events, only 33 appeared in both datasets (12.9%), and 22 of 31 countries had no overlap at all. The authors conclude that the minimal overlap suggests significant under-reporting of attacks on health care. 

> Parada, V., Fast, L., Briody, C., Wille, C., & Coninx, R. (2023). Underestimating attacks: Comparing two sources of publicly-available data about attacks on health care in 2017. *Conflict and Health, 17*, Article 3. https://doi.org/10.1186/s13031-023-00498-w

**Language models can code text as accurately as expert coders on some tasks.** Törnberg tested GPT-4 on identifying the political affiliation of politicians from single posts on X (Twitter) across 11 countries. GPT-4 was more accurate than expert coders, crowd workers, and supervised classifiers in every country studied. The task is different from coding incident reports of attacks on health care, which is what this project tests. 

> Törnberg, P. (2025). Large language models outperform expert coders and supervised classifiers at annotating political social media messages. *Social Science Computer Review, 43*(6), 1181–1195. https://doi.org/10.1177/08944393241286471

## Alternatives

Each alternative is an action OCHA could potentially take. Alternative A is the baseline against which the others are compared.

| | Alternative | Action Item | Addresses |
|---|---|---|---|
| A | Let present trends continue | No change. OCHA continues to use SHCC and WHO SSA data as each organization publishes them. | Baseline |
| B | More analysts | OCHA funds, or mobilizes donor funding for, additional coding staff at Insecurity Insight (SHCC) and WHO SSA. | Timeliness |
| C | Two-speed release | OCHA sets a standard on HDX for publishing a short core record of each incident (date, location, type of attack) soon after it is reported, with the full coding released later. | Timeliness |
| D | Pool the sources | OCHA convenes SHCC, WHO SSA, ACLED, and the Aid Worker Security Database to adopt a shared codebook and publish one merged, de-duplicated dataset on HDX. | Completeness |
| E | AI-assisted coding to support analysts | OCHA's Centre for Humanitarian Data pilots a shared tool in which a language model drafts the codes for each incident report and analysts review and correct them. | Timeliness |


## Use of AI

**Week 3, problem definition.** AI did not help me define the problem; however, it did help me rethink and refine the phrasing once I had it defined. Even that took multiple attempts and prompts. My first prompt returned with a response completely redefining my problem statement. Later drafts then reframed the problem as the untested accuracy of language models. Each response I noticed, embedded the solution, which is exactly what the eight-fold path asks that you not do. I rejected all of them and had to state the problem in my own words before Claude produced revisions that were usable. That took well over 6 prompts, and Claude kept drifting back towards including its own answer. Where it helped was the reframing. It helped me break up long sentences, replaced some casual phrasing, and also verified the 2024 figures against the published reports the links to which I had shared with it. I think AI for this has helped as an editing tool rather than with thinking process.

**Week 4, data sources & defining alternatives.** AI was really helpful this time to review additional data sources that I had not identified previously. I did review them to inclusion and credibility. With respect to defining alternatives, AI was not particularly helpful. I did run an experimental setup this time with subagents running in parallel to see what I could gain from splitting my task. 
