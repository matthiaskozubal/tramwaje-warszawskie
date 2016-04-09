setwd("/home/pawel/projects/tramwaje-warszawskie/")

library(jsonlite)
library(magrittr)
library(dplyr)
library(leaflet)
library(rgdal)
library(stringr)
library(rgeos)
library(sp)
library(sampSurf)
library(pgirmess)
library(mosaic)

apiKey = "f10fec28-bf17-4abd-94d7-7b42ac4ab33e"
stopNum = "04"
stopId = "5002"
lineNum = "26"
lineScheme = read.csv('line_scheme_26.csv')

getTimetable = function(lineNum, stopId, stopNum) {
  timetableUrl = paste("https://api.um.warszawa.pl/api/action/dbtimetable_get/?id=e923fa0e-d96c-43f9-ae6e-60518c9f3238&busstopId=", stopId, "&busstopNr=", stopNum, "&line=", lineNum, "&apikey=", apiKey, sep="")
  dataJson = fromJSON(timetableUrl)
}

getAllPositions = function() {
  apiUrl = paste("https://api.um.warszawa.pl/api/action/wsstore_get/?id=c7238cfe-8b1f-4c38-bb4a-de386db7e776&apikey=", apiKey, sep="")
  dataJson = fromJSON(apiUrl)
  dataJson$result$FirstLine = dataJson$result$FirstLine %>% as.numeric
  dataJson$result
}

getLinePositions = function(lineNum) {
  result = getAllPositions() %>% filter(FirstLine == lineNum)
  result$readTime = Sys.time()
  result$Brigade = as.numeric(result$Brigade)
  result
}

showMap <- function(positions, lineShape) {
  positions = applyColors(positions)
  leaflet(data = positions) %>% addTiles %>% 
    addProviderTiles("CartoDB.Positron") %>% 
    setView(lng = 21.035, lat = 52.231765, zoom = 12) %>% 
    addCircles(~Lon, ~Lat, popup = ~Time, color = ~color) %>%
    addPolylines(data = lineShape, color = "#555", fillOpacity = 0, weight = 3)
}

applyColors <- function(data) {
  colors = list(
    split1 = "#0f0",
    split2 = "#00f",
    terminated = "#000",
    error = "#f00",
    unknown = "#555"
  )
  data$color = lapply(data$direction, function (x) { colors[[x]] })
  data
}

getPointOnLine <- function(line) {
  s = spsample(line, 1, "regular")
  list(lon = s@coords[1,1], lat = s@coords[1,2])
}

lineLength <- function(spatialLines) {
  # distance in meters
  # distTot(spatialLines@lines[[1]]@Lines[[1]]@coords, decdeg = T)
  distTot(spatialLines@coords, decdeg = T)
}

createCircle <- function(x,y,r,start=0,end=2*pi,nsteps=100){
  rs <- seq(start,end,len=nsteps)
  xc <- x+r*cos(rs)
  yc <- y+r*sin(rs)
  my.pol<-cbind(xc,yc)
  my.pol <- rbind(my.pol, my.pol[1,])
  SpatialPolygons(list(Polygons(list(Polygon(my.pol)), ID="1")), 
                  proj4string=CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"))
}

getPositionCircles <- function(lineData) {
  radius = 0.0002
  lineData$circle = apply(lineData[,c('Lon','Lat')], 1, 
                          function(x) createCircle(x[1], x[2], radius))
  lineData
}

getLineSplit <- function(lineData, lineShape) {
  lineData$split = lapply(lineData$circle, function(x) gDifference(lineShape, x))
  lineData
}

measureSplitLengths <- function(lineData) {
  lineData$split1Length = 0
  lineData$split2Length = 0
  for (i in 1:nrow(lineData)) {
    split = lineData[i, 'split'][[1]]@lines[[1]]@Lines
    if (length(split) == 2) {
      lineData[i, 'split1Length'] = distTot(split[[1]]@coords, decdeg=T)
      lineData[i, 'split2Length'] = distTot(split[[2]]@coords, decdeg=T)
    }
  }
  lineData
}

calculateDirections <- function(data, previousData) {
  direction = "unknown"
  data$direction = direction
  for (i in data$Brigade) {
    len1 = data[data$Brigade == i, 'split1Length']
    len2 = data[data$Brigade == i, 'split2Length']
    len1prev = previousData[previousData$Brigade == i, 'split1Length']
    len2prev = previousData[previousData$Brigade == i, 'split2Length']
    if (len1 > 0 & len2 > 0 & len1prev > 0 & len2prev > 0) {
      diff1 = len1 - len1prev
      diff2 = len2 - len2prev
      if (diff1 > 0 & diff2 < 0) {
        direction = "split2"
      } else if (diff1 < 0 & diff2 > 0) {
        direction = "split1"
      } else {
        direction = "error"
      }
    } else {
      direction = "terminated"
    }
    data[data$Brigade == i, 'direction'] = direction
  }
  data
}

getLineStatus <- function(lineNumber, previousData = data.frame()) {
  lineShape = readOGR(paste('line_scheme_', lineNumber, '.geojson', sep=""), "OGRGeoJSON", verbose = F)
  data <- getLinePositions(lineNumber) %>%
    getPositionCircles %>%
    getLineSplit(lineShape) %>%
    measureSplitLengths
  if (nrow(previousData) > 0) {
    data <- calculateDirections(data, previousData)
  }
  data
}


line26 = line26n
line26 = getLineStatus(26)
line26n = getLineStatus(26, line26)

lineShape = readOGR(paste('line_scheme_26.geojson', sep=""), "OGRGeoJSON", verbose = F)
showMap(line26n, lineShape)

# Do zapisu split --> geojson
rgdal::writeOGR(shape, filepath, "OGRGeoJSON", driver="GeoJSON")


t = line26$Time %>% str_replace("T", " ") %>% strptime(format="%Y-%m-%d %H:%M:%S")
t <- getLinePositions(26) %>% select(Brigade, Time, readTime) %>% {.[order(.$Brigade),]}
t <- rbind(t, getLinePositions(26) %>% select(Brigade, Time, readTime) %>% {.[order(.$Brigade),]})




# TODO
# - mail: skąd aktualny czas ZTM
# - animacja w JS
# 
# OBSERWACJE
# - unikalny tramwaj można rozpoznawać po parametrze `Brigade`
# - odświeżone pozycje co ~30s.
# - wyzwanie: kalibracja czasu, zdobycie czasu jaki ma ZTM: 
#   1) poprosić w mailu 
#   2) brać najświeższy czas z API
#   3) porównywać pozycje z rozkładem jazdy
#
# MVP
# - płynny ruch tramwaju (musi już być w JS - Leaflet.AnimatedMarker lub Mapbox)
#
# Chcesz zrobić prototyp na jednej linii + art na bloga data-science.pl + akcja na wykop 
# "czy chcecie to też dla nocnych i wiecej?". "dla jakich miast byście chcieli?" ankieta-wyniki tajne tylko dla ciebie (tam jest wartość)
# Napisz caly art o akcji
#
# Jak czesto zmieniaja api? Jak sie dostosowac zeby aplikacja nie miala naglych przerw?
# Bedziesz musiał o to zadbać podczas wypuszczania artykulu
# To sie bedzie mocno rozwijać: "Obecnie pracujemy nad rozszerzeniem ilości parametrów udostępnianych danych w tym zakresie."
#
# Istniejace projekty:
# http://tramwaje.kloch.net/
# http://tramway.cloudapp.net/testapp/map/ (MIMUW)
#
# Prezka
# - pokazac linie tramwajowe
# - jakies ogolne statsy (ile tramwajow)
# - fajnie, mamy dane co 30s. ale to nie wystarcza! w 30s tramwaj moze przejechać kilkaset metrów

