setwd("/home/pawel/projects/tramwaje-warszawskie/analysis/")
print("Started script")

# TODO
# - czy ze wzgledu na losowanie punktu w circle on moze zle policzyc kierunek?
# - moving marker: im blizej wierzcholka, tym wolniej animuje

source('analysis.R')

lineSchemePath = "../data/line_scheme_26.geojson"
previousDataPath = "../data/previousData.csv"
resultsRunning = "../data/vehicles-running.json"
resultsHalted = "../data/vehicles-halted.json"

lineShape = readOGR(lineSchemePath, "OGRGeoJSON", verbose = F)

if (file.exists(previousDataPath)) {
  prevData = read.csv(previousDataPath)
  print("Loaded previous observations")
} else {
  prevData = getLineStatus(26, lineShape)
  print("Get current data as previous observations")
}

data = getLineStatus(26, lineShape, prevData)
print("Calculated current data")
# showMap(data, lineShape)

sl = getMovementSpatialDF(data)
sp = getHaltSpatialDF(data)
print("Calculated spatial data frames")

write.csv(data %>% dplyr::select(-circle, -split, -movement, -position), previousDataPath)

if (file.exists(resultsRunning)) { file.remove(resultsRunning) }
if (file.exists(resultsHalted)) { file.remove(resultsHalted) }

if (!is.null(sl)) { rgdal::writeOGR(sl, resultsRunning, "OGRGeoJSON", driver = "GeoJSON") }
if (!is.null(sp)) { rgdal::writeOGR(sp, resultsHalted, "OGRGeoJSON", driver = "GeoJSON") }

print("Saved results")

