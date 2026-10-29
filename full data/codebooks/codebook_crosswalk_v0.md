# Codebook crosswalk (draft v0): project, SHCC and WHO SSA, Ukraine

How the project's screening codebook and planned extraction fields line up with the two systems that record attacks on health care in Ukraine. The aim is a codebook whose `yes` means what the coded records count, and whose extracted fields can be matched to the SHCC record and compared with WHO counts.

## Sources

| Short name | What it is | Read from |
|---|---|---|
| Project v1 | Screening codebook, `codebook_screen_v1.md` (Part A from SHCC 2019, Part B rules for whole reports) | This repository |
| SHCC 2019 | SHCC and Insecurity Insight, *Attacks Data Codebook*, version May 2019, for the 2018 data | `project/2018-SHCC-Attacks-Data-Codebook-v-May-2019.pdf`, pp. 2–3 |
| SHCC UKR | Insecurity Insight, "2016-2026 UKR Attacks on Health Care Incident Data", HDX, CC BY-SA; 43 columns; 3,130 incidents from 2022 to 28 Sep 2026 | The file itself, downloaded 28 Oct 2026 (`R/03_download_shcc_ukraine.R`); counts below are for 2022 to 2026 |
| WHO SSA | WHO Surveillance System for Attacks on Health Care: Methodology v1.0 (Dec 2018 / Apr 2019) and the public dashboard's export fields and option lists | Source check of 30 Sep 2026 (methodology page numbers as given there); no WHO data downloaded |

## 1. What counts as an attack

| | Definition | Who must have done it |
|---|---|---|
| SHCC 2019 (p. 2) | Verbal or physical violence, obstruction, or threat of violence that interferes with the availability of, access to and delivery of curative or preventive health services, in a country in conflict | An actor in the conflict. Strikes, protests, and attacks by criminals, patients and other civilians are excluded |
| SHCC UKR | No definition in the file. Flags per incident: conflict-related, political, COVID-19, vaccination, polio, Ebola | 35 of 3,130 incidents are flagged not conflict-related. Their perpetrators include patients or family (6), employees (7), criminals (3), police (2) and no information (14) |
| WHO SSA (methodology p. 7) | Verbal or physical violence, threats or other psychological violence, or obstruction that gets in the way of curative or preventive health services being available, reached or delivered | No actor condition in the definition. Each attack carries a certainty level (rumour, possible, probable, confirmed); rumours are not published |
| Project v1 | SHCC 2019 definition and event criteria | Conflict actor, or not named (B4); non-conflict actors excluded |

## 2. What was hit

Counts are SHCC UKR incidents from 2022 to 2026 with the field above zero, or flagged.

| Target or harm | Project v1 | SHCC 2019 column | SHCC UKR column (incidents) | WHO SSA public field |
|---|---|---|---|---|
| Facility destroyed | Part A | K | Number of Attacks on Health Facilities Reporting Destruction (121) | HC Facilities; type of facility |
| Facility damaged | Part A | L | ...Reporting Damaged (1,690) | HC Facilities |
| Armed entry | Part A | M | Forceful Entry into Health Facility (107) | Attack type: armed or violent search |
| Occupation | Part A | O | Occupation of Health Facility (106) | Attack type: militarization |
| Vicinity of a facility | Not covered | None | Vicinity of Health Facility Affected (57) | Annex 1: direct and indirect impact (p. 21) |
| Utilities of a facility | B6: `no` | None | Hospital Utilities Affected: energy supplies (241) | Annex 1: direct and indirect impact |
| Ambulance or health transport | Part A | P, Q, R | Health Transportation Destroyed (35), Damaged (340), Stolen/Hijacked (20); Attacks on Emergency Medical Services (454) | HC Transport |
| Medical supplies | Part A (looting) | N (looting) | No looting column; Affects Access to Medicines, Vaccines and Other Health Products (145) | Attack type: removal of assets; HC Supplies Assets; HC Warehouse Storage |
| Obstruction | B7 (medical only) | In the definition | No column (the 2024 global file has "Obstruction to Health Care") | Attack type: obstruction |
| Health workers killed, injured | Stage 3 plan | E, F | Killed (449), Injured (337) | Total Death, Total Injured; HC Personnel |
| Health workers kidnapped, arrested | Stage 3 plan | G, I | Kidnapped (0), Arrested (47); Known Kidnapping or Arrest Outcome | HW Abduction, Arrest, Detention |
| Health workers threatened, assaulted | Part A (threat) | None | Threatened (25), Assaulted (3), Sexually Assaulted (0) | Attack types: psychological violence or threat; assault without weapons; sexual assault |
| Patients | B3, B6 | None | No patient column | HC Patients; Patient Abduction, Arrest, Detention |
| Services for children, women | Not covered | None | Children's Health Services Affected (144), Attacks on Children's Hospitals (62), Women's Health Services Affected (113) | Type of facility only |
| Criminalization of health care | Not covered | I (arrest includes charges, fines, expulsion) | Arrested | Attack type: criminalization of health care |

## 3. Who, how, where, when

| Field | SHCC 2019 | SHCC UKR (values seen, 2022 to 2026) | WHO SSA public |
|---|---|---|---|
| Perpetrator | Non-state forces, State forces, Multiple, Unknown, with subtypes (pp. 2–3) | Reported Perpetrator, 14 values: Foreign Forces: Military (2,721), No Information (310), Government: Military (35), NSA (16), Donor Government (11), Police (8), Employee (7), Patient or Family (7), Other (6), Criminal (4), Multiple (2), Civilian, Government/Self-Declared Government, Vigilante (1 each). Reported Perpetrator Name: Armed Forces of the Russian Federation (2,721), Unidentified Armed Actor (233), Armed Forces of Ukraine (28), and others | None |
| Weapon | None | Weapon Carried/Used, 26 values; most common: Aerial Bomb: Drone (745), Unspecified Explosive (495), Shelling (427), Firearms (405), Aerial Bomb: Plane (247), Missile (213), Artillery (188), Rocket (181), Not Applicable: No Direct Violence (84) | Attack types: heavy weapons, individual weapons, setting fire, chemical agent |
| Place type | None | Location of Incident, 16 values; most common: Health Building (2,184), Road (227), Other (220), No Information (210) | Type of facility |
| Place | Country | Admin 1 (oblast; 26% "No Information" in 2022); coordinates censored | Country; city and town in the single-report view |
| Intent | SHCC attack type: Intentional, Indiscriminate, No Information (p. 2) | None | Annex 1: targeted and non-targeted (p. 21) |
| Incident date | Attack date | Date | Attack Date, Attack Time |
| Entry date | None | Date Event Entered, Date Event Modified | Created, Last Modified |
| Identifier | Event code | SiND Event ID | Attack ID, with versions |
| Text | None | Event Description column present but empty | Description withheld (methodology p. 12) |

## 4. Unit and counting rules

| | Unit | Rules |
|---|---|---|
| SHCC | One incident: a unique place and time | An unspecified number of health workers, facilities or ambulances counts as one. A facility attacked before counts as 0 facilities (2019 codebook, column J) |
| WHO SSA | One attack record | Reports from several partners about one attack are merged into one record (methodology pp. 10, 22); records can be revised or withdrawn |
| Project | Stage 2: one report (`yes` / `no`). Stage 3: one incident per event described | One report can describe several incidents, and one incident can appear in many reports, so incidents from different reports must be de-duplicated before matching |

## 5. Where project v1 and the coded records differ

- **Actors.** Project v1 and SHCC 2019 exclude non-conflict actors. The current SHCC Ukraine file includes 35 incidents flagged not conflict-related, and WHO's definition names no actor.
- **Indirect harm.** Project rule B6 codes damage to power or utilities that affects a hospital as `no`. The SHCC Ukraine file records hospital energy supplies as affected in 241 incidents, and a facility's vicinity in 57.
- **Totals.** Project rule B2 codes a report that gives only totals as `no`. Both systems record single incidents or attacks, so a total cannot be matched to either record.
- **Patients.** Project v1 counts harm to patients in care. WHO records patients; the SHCC Ukraine file has no patient field.
- **Supplies and obstruction.** The SHCC Ukraine file has no looting or obstruction column; it records reduced access to medicines instead. WHO records removal of assets and obstruction as attack types.
- **The 2019 codebook is older than the file.** 27 of the 43 columns in the current Ukraine file are not in the 2019 codebook, among them vicinity, utilities, access to medicines, emergency medical services, children's and women's services, threats and assaults, weapon, place type and entry dates. Three 2019 columns are not in the file: intent (SHCC attack type), total facilities affected, and looting.

## 6. Stage 3 extraction fields that map onto the SHCC Ukraine file

For each incident in a `yes` report. Values follow the SHCC Ukraine file where it has a column, so extracted incidents can be matched to it.

| Field | Values | SHCC UKR column | WHO SSA |
|---|---|---|---|
| `incident_date` | Date, or month if only the month is given | Date | Attack Date |
| `oblast` | Oblast name as in SHCC, or No Information | Admin 1 | City or town (not public at oblast level) |
| `place_name` | Town or facility name as written in the report | None (used for de-duplication only) | Not public |
| `location_type` | SHCC Location of Incident values | Location of Incident | Type of facility |
| `facility_destroyed`, `facility_damaged` | Count | ...Reporting Destruction, ...Reporting Damaged | HC Facilities |
| `forceful_entry`, `occupation`, `vicinity` | Count | Forceful Entry..., Occupation..., Vicinity... | Armed search, militarization |
| `transport_destroyed`, `transport_damaged`, `transport_stolen` | Count | Health Transportation... | HC Transport |
| `ems_attack` | yes / no | Attacks on Emergency Medical Services | HC Transport, HC Personnel |
| `utilities_affected` | yes / no | Hospital Utilities Affected | None |
| `medicines_access` | yes / no | Affects Access to Medicines... | HC Supplies Assets |
| `hw_killed`, `hw_injured`, `hw_arrested`, `hw_threatened`, `hw_assaulted` | Count | Health Workers... | HC Personnel; HW Arrest, Detention |
| `patients_harmed` | yes / no | None | HC Patients |
| `perpetrator` | SHCC Reported Perpetrator values | Reported Perpetrator | None |
| `weapon` | SHCC Weapon Carried/Used values | Weapon Carried/Used | Attack type |
| `conflict_related` | yes / no / unclear | Conflict-Related Violence | None |
| `report_id`, `report_date` | ReliefWeb id and date | None (for timeliness: report date against Date Event Entered) | None |

## Version

- v0, 28 Oct 2026: first draft, from the three sources above. Not yet used for coding.
