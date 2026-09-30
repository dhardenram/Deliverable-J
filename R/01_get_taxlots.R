library(sf)
library(dplyr)
library(arcgislayers)
library(tigris)

# --- Tracts: 2020 TIGER/Line, full resolution, for the 22 HRFA GEOIDs ---
hrfa_geoids <- st_read("data/raw/hrfa_tracts.gpkg", quiet = TRUE)$GEOID

tracts_tiger <- tigris::tracts(state = "OR", county = "Multnomah",
                               year = 2020, cb = FALSE) |>
  filter(GEOID %in% hrfa_geoids)
stopifnot(nrow(tracts_tiger) == 22)

st_write(tracts_tiger, paste0("data/raw/tiger_tracts_2020_", Sys.Date(), ".gpkg"),
         delete_dsn = TRUE)

# --- Taxlots: one request per tract bounding box ---
taxlot_url <- "https://services2.arcgis.com/McQ0OlIABe29rJJy/arcgis/rest/services/Taxlots_(Public)/FeatureServer/3"
taxlot_layer <- arc_open(taxlot_url)
tracts_svc <- st_transform(tracts_tiger, st_crs(taxlot_layer))

taxlots <- lapply(seq_len(nrow(tracts_svc)), function(i) {
  arc_select(taxlot_layer,
             where = "COUNTY = 'M'",
             filter_geom = st_bbox(tracts_svc[i, ]))
}) |>
  bind_rows() |>
  rename(rlis_fid = FID) |>
  distinct(rlis_fid, .keep_all = TRUE)   # neighboring boxes overlap

message(nrow(taxlots), " lots; ", n_distinct(taxlots$TLID), " distinct TLIDs")

st_write(taxlots, paste0("data/raw/taxlots_hrfa_", Sys.Date(), ".gpkg"),
         delete_dsn = TRUE)