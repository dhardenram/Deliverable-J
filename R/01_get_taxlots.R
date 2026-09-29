library(sf)
library(dplyr)
library(arcgislayers)

taxlot_url <- "https://services2.arcgis.com/McQ0OlIABe29rJJy/arcgis/rest/services/Taxlots_(Public)/FeatureServer/3"
taxlot_layer <- arc_open(taxlot_url)

tracts <- st_read("data/raw/hrfa_tracts.gpkg") |>    #22 HRFA tracts
  st_transform(st_crs(taxlot_layer))

# One request per tract, using that tract's bounding box
taxlots <- lapply(seq_len(nrow(tracts)), function(i) {
  arc_select(taxlot_layer,
             where = "COUNTY = 'M'",
             filter_geom = st_bbox(tracts[i, ]))
}) |>
  bind_rows() |>
  distinct(TLID, .keep_all = TRUE)    # neighboring boxes overlap

# Assign each lot to exactly one tract, using a point inside the lot
taxlots <- st_transform(taxlots, 2913)
tracts  <- st_transform(tracts, 2913)
pts <- st_join(st_point_on_surface(taxlots), tracts["GEOID"], join = st_within)
taxlots$GEOID <- pts$GEOID
taxlots <- filter(taxlots, !is.na(GEOID))

st_write(taxlots, "data/raw/taxlots_hrfa_2026-09-24.gpkg")