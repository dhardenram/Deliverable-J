library(sf)
library(dplyr)

taxlot_file <- "data/raw/taxlots_hrfa_2026-09-29.gpkg"
tract_file  <- "data/raw/tiger_tracts_2020_2026-09-29.gpkg" 

taxlots <- st_read(taxlot_file, quiet = TRUE) |> st_transform(2913)
tracts  <- st_read(tract_file,  quiet = TRUE) |> st_transform(2913)

# Assign each lot to one tract, using a point inside the lot
pts <- st_join(st_point_on_surface(taxlots), tracts["GEOID"], join = st_within)
stopifnot(nrow(pts) == nrow(taxlots))   # extra rows would misalign GEOIDs
taxlots$GEOID <- pts$GEOID

taxlots <- filter(taxlots, !is.na(GEOID))   # drops lots outside all 22 tracts
message(nrow(taxlots), " lots assigned")

st_write(taxlots, "data/interim/taxlots_hrfa_2913.gpkg", delete_dsn = TRUE)