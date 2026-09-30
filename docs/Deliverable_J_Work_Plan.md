# Deliverable J — Work Plan and Scaffolding

Last updated: September 27, 2026. Companion to `HRFA_Dashboard_Decisions.md`.

## How to use this plan

- **Work in order.** Each stage sets up the next. Don't start data pulls before the environment is set up, and don't start analysis before the data is in.
- **One task at a time.** Each task has a "done when" line. Confirm it before moving on.
- **Park, don't solve.** A question that doesn't block the current task goes in the "Parked questions" section of `docs/assumptions_log.md`, to be answered at the stage where it matters.
- **New ideas go on the v2 list** in the decisions log.

## Folder structure

Names ending in `/` are folders. Everything lives inside `Deliverable-J/`.

| Location | Type | What goes in it | Created by |
|---|---|---|---|
| `Deliverable-J.Rproj` | File | RStudio project file | RStudio (done) |
| `renv/`, `renv.lock`, `.Rprofile` | Folder + files | renv's package records; never edit by hand | renv (done) |
| `.gitignore` | File | List of files Git should never upload | You, stage A |
| `README.md` | File | Repo front page: scope, findings, screenshots, app link | You, week 4 |
| `docs/` | Folder | `HRFA_Dashboard_Decisions.md`, `Deliverable_J_Work_Plan.md`, `assumptions_log.md`, `data_manifest.csv`, `findings_draft.md` | You, stage A |
| `data/raw/` | Folder | Untouched downloads, one file per source, dated | Scripts `01`–`09` |
| `data/interim/` | Folder | Cleaned, reprojected (EPSG 2913), joined data | Scripts `10`+ |
| `data/processed/` | Folder | Final small files the app reads | Scripts `40`+ |
| `R/` | Folder | Numbered scripts (list below) | You |
| `qgis/` | Folder | QGIS project files for visual checks | You |
| `outputs/` | Folder | Figures and tables for README and LinkedIn | Scripts |
| `app/` | Folder | `app.R`; `app/data/` (copies of processed files); `app/www/` (images) | You, week 4 |

### Scripts in `R/`

| Script | Purpose |
|---|---|
| `00_setup.R` | Loads every package the project uses (this is how renv knows what to record) |
| `01_get_taxlots.R` | RLIS taxlots (done; move here from `data/raw/`) |
| `02_get_rlis_layers.R` | Other RLIS layers |
| `03_get_portland_open_data.R` | BLI, TSP, max height, special height corridors |
| `04_get_acs.R` | ACS, tract and county |
| `05_get_places_county.R` | PLACES county values |
| `06_get_lodes.R` | LODES inflow/outflow |
| `07_get_lead.R` | Energy burden |
| `08_get_trimet.R` | GTFS and transit centers |
| `09_get_tif.R` | TIF districts |
| `10_`–`19_` | Week 2: capacity analysis |
| `20_`–`29_` | Week 3: site and tract context |
| `30_findings_tables.R` | Week 3: findings numbers |
| `40_export_app_data.R` | Week 4: small files for the app |

## Week 1

### Stage A: Environment and repo (day 1)

**A1. Tidy what exists.**
- Move `01_get_taxlots.R` from `data/raw/` to `R/`.
- In the script, add `taxlots <- rename(taxlots, rlis_fid = FID)` before `st_write()`, add `delete_dsn = TRUE` to `st_write()`, and build the file name from `Sys.Date()` so it records the real download date.
- Rename the existing taxlot file to the date it was actually pulled.
- Done when: the script runs start to finish without errors.

**A2. Install every package now.**
- Install the full list below in one command.
- Write `R/00_setup.R` containing one `library()` line per package.
- Run `renv::snapshot()`.
- Done when: `renv::status()` reports no problems.

**A3. Census API key.**
- Request a key at https://api.census.gov/data/key_signup.html.
- Store it with `tidycensus::census_api_key("KEY", install = TRUE)`. This saves it outside the project, so it never reaches GitHub.
- Done when: `Sys.getenv("CENSUS_API_KEY")` returns the key after restarting R.

**A4. Git and GitHub.**
- In Terminal, run `git --version` (a Mac may prompt you to install developer tools).
- Write `.gitignore` before the first commit. Include `.Rhistory`, `.RData`, `.Rproj.user/`, `data/raw/`, `data/interim/`, and `rsconnect/`.
- Run `usethis::use_git()`.
- Create a GitHub token with `usethis::create_github_token()`, store it with `gitcreds::gitcreds_set()`, then run `usethis::use_github()`.
- Done when: the repo appears on GitHub with no data files in it.

**A5. Documentation files.**
- Move the decisions log and this plan into `docs/`.
- Create `assumptions_log.md` with two sections: "Assumptions" and "Parked questions".
- Create `data_manifest.csv` with these columns: `dataset, source, access_method, url, date_pulled, vintage, crs, terms, script, output_file, notes`. Add the taxlot row.
- Create an empty `findings_draft.md`.
- Done when: all four files exist and are committed.

**A6. Finish the tract layer.**
- Confirm the per-tract taxlot count: `count(st_drop_geometry(taxlots), GEOID)` should list 22 tracts, none unusually low.
- Add `is_efa` to `data/interim/hrfa_tracts_2913.gpkg` (21 TRUE, 1 FALSE).
- Done when: both are confirmed and the assumption that lots are assigned to tracts by an interior point is recorded.

### Stage B: Data acquisition (days 2–5)

One script per source. Every script saves to `data/raw/` with a date in the file name and adds a row to the data manifest.

**B1. `02_get_rlis_layers.R`.**
- Find each layer's service URL on RLIS Discovery.
- Pull with `arc_select()`, using the bounding box of all 22 tracts as `filter_geom`. A single rectangle avoids the multi-part issue.
- Rename `FID` if present.
- Fall back to download for any layer without a service.
- Layers: zoning, sidewalks, high-injury corridors, high-injury intersections, ORCA, FEMA flood hazard, Title 3, Title 13, wetlands, publicly owned parcels.
- Check whether the taxlot `PUBLIC_OWN` field makes the separate parcels layer unnecessary.

**B2. `03_get_portland_open_data.R`.**
- Same method, for BLI Model Development Capacity, TSP classifications, maximum height, and special building height corridors.

**B3. `04_get_acs.R`.**
- Pull every table in the ACS list below, at tract and county level, in one vintage. Keep margins of error.
- Filter tracts to the 22 GEOIDs.
- Verify every table ID with `tidycensus::load_variables()` before pulling.

**B4. `05_get_places_county.R`.**
- Identify the PLACES release used in `hrfa_tracts` from the county's documentation.
- Download Multnomah County values for CHD, DIABETES, and PHLTH from that same release.

**B5. `06_get_lodes.R`.**
- Use `lehdr::grab_lodes()`: 2023, origin-destination, all jobs, tract aggregation.
- Pull Oregon `main`, Oregon `aux`, and Washington `aux`.

**B6. `07_get_lead.R`.**
- Download the LEAD 2022 Oregon tract file.
- Record the exact URL used.

**B7. `08_get_trimet.R`.**
- Download `gtfs.zip`, read it with `tidytransit::read_gtfs()`, and record the feed dates.
- Download and unzip the Transit Centers shapefile.

**B8. `09_get_tif.R`.**
- Find GIS files for the Prosper Portland TIF districts and Gresham's Rockwood urban renewal area.
- If none are available, request them and log the request.

Done when (all of stage B): every source has a raw file and a manifest row, or a logged request.

### Stage C: Week 1 checks (day 5)

**C1. Read the BPS BLI metadata.** Record which constraints are applied, the units, the join key, and the zoning date.

**C2. Check zoning coverage for the 4 non-Portland tracts.** Record gaps and each zone's allowed FAR or units, per the local code.

**C3. Overlay checks in QGIS.** For each constraint layer and the special height corridors, record whether it touches any tract.

**C4. `hrfa_tracts` data dictionary.** Confirm `hdens`, `elp_per`, the vegetation fields, and the PLACES release. The HVI field meanings only matter for the context line.

**C5. Ask the county team** whether the land cover fields and `pmtemp23` can be published with credit.

Done when: each item's answer is in the assumptions log.

### In parallel: learning Shiny

Work through Mastering Shiny chapters 1–4, then build a toy app that shows the 22 tracts on a leaflet map. Spend about 30–45 minutes a day.

## Packages (install all in stage A2)

| Package | Purpose |
|---|---|
| sf, dplyr, tidyr, readr, stringr, purrr, janitor, units | Core data and spatial work |
| arcgislayers | RLIS and Portland Open Data services |
| tidycensus, tigris | ACS; county land area for density |
| lehdr | LODES |
| tidytransit | GTFS |
| ggplot2, ggiraph, gt | Charts and tables |
| shiny, bslib, leaflet, reactable, rsconnect | App and deployment |
| usethis, gitcreds | Git and GitHub setup |

```r
install.packages(c("sf", "dplyr", "tidyr", "readr", "stringr", "purrr", "janitor", "units",
                   "arcgislayers", "tidycensus", "tigris", "lehdr", "tidytransit",
                   "ggplot2", "ggiraph", "gt",
                   "shiny", "bslib", "leaflet", "reactable", "rsconnect",
                   "usethis", "gitcreds"))
```

## Data calls

| Script | Source | Method | Key settings | Output in `data/raw/` |
|---|---|---|---|---|
| `01` | RLIS Taxlots (Public), FeatureServer/3 | `arc_open()` + `arc_select()` per tract bounding box | `where = "COUNTY = 'M'"`; rename `FID` | `taxlots_hrfa_<date>.gpkg` (done) |
| `02` | RLIS layers (list in B1) | `arc_select()` with the 22-tract bounding box; download as fallback | Rename `FID` | `rlis_<layer>_<date>.gpkg` |
| `03` | Portland Open Data layers (list in B2) | Same as `02` | | `pdx_<layer>_<date>.gpkg` |
| `04` | ACS 5-year | `tidycensus::get_acs()` | `geography = "tract"` and `"county"`; `state = "OR"`; `county = "Multnomah"`; `survey = "acs5"`; latest year | `acs_tract_<year>.csv`, `acs_county_<year>.csv` |
| `05` | CDC PLACES county | CSV download from data.cdc.gov | Same release as `hrfa_tracts` | `places_county_<release>.csv` |
| `06` | LODES 8 | `lehdr::grab_lodes()` | `year = 2023`; `lodes_type = "od"`; `job_type = "JT00"`; `agg_geo = "tract"`; OR main, OR aux, WA aux | `lodes_od_2023_<part>.csv` |
| `07` | DOE LEAD 2022 | File download | Oregon, tract | `lead_2022_or.csv` |
| `08` | TriMet | `tidytransit::read_gtfs(url)`; `download.file()` + `unzip()` | GTFS: http://developer.trimet.org/schedule/gtfs.zip; transit centers: https://developer.trimet.org/gis/ | `trimet_gtfs_<date>.zip`, `trimet_transit_centers/` |
| `09` | Prosper Portland; City of Gresham | Service, download, or request | | `tif_<date>.gpkg` |

## ACS measures (verify every table ID before pulling)

| Measure | Table |
|---|---|
| Total population | B01003 |
| Male; under 18; 65+ | B01001 |
| Seniors living alone | B09021 (confirm) |
| BIPOC and race/ethnicity groups | B03002 |
| Foreign-born | B05002 |
| English proficiency | C16002 (households) or B16005 (persons); match the `hrfa_tracts` definition |
| Total disability | B18101 |
| Cognitive difficulty | B18104 |
| Less than bachelor's degree | B15003 |
| Median household income | B19013 |
| Renter share | B25003 |
| Rent burden | B25070 |
| Zero-vehicle households | B25044 |
| Commute mode | B08301 |
| Housing units (for housing density) | B25001 |

Densities are counts divided by land area (`ALAND` for tracts; `tigris` for the county).

## Weeks 2–4 (outline)

**Week 2: Capacity.**
- Join the BLI to taxlots for the 18 Portland tracts.
- Apply the same rule to the 4 non-Portland tracts.
- Apply exclusions, then classify lots (vacant, underutilized, public, committed).
- Compute FAR (item 1).
- QA checks:
  - row counts before and after joins;
  - duplicates;
  - built FAR above allowed FAR;
  - tract totals;
  - a 10-lot spot-check against aerials.

**Week 3: Context and findings.**
- Transit catchments and frequency.
- Sidewalk, high-injury network, and park proximity around sites.
- Join ACS, PLACES, LEAD, and LODES to tracts.
- Write `findings_draft.md`: 3–5 findings, what the 22 tracts share, and a scope statement.

**Week 4: App and launch.**
- Pages: findings, site explorer, tract profiles, methods.
- Export small processed files.
- Test from a clean session, snapshot, deploy.
- README, LinkedIn post, 3-minute interview walkthrough.

## Tutorials

| Stage | Resource |
|---|---|
| A | Happy Git with R (happygitwithr.com); renv (rstudio.github.io/renv) |
| B | arcgislayers (r.esri.com/arcgislayers); *Analyzing US Census Data* (walker-data.com/census-r); tidytransit (r-transit.github.io/tidytransit) |
| Week 2–3 | *Geocomputation with R* (r.geocompx.org) |
| Parallel and week 4 | Mastering Shiny (mastering-shiny.org); ggiraph book (ardata.fr/ggiraph-book); leaflet for R (rstudio.github.io/leaflet); bslib (rstudio.github.io/bslib) |
| Week 3–4 | *Fundamentals of Data Visualization* (clauswilke.com/dataviz) |
