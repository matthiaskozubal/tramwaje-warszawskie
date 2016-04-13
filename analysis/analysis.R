setwd("/home/pawel/projects/tramwaje-warszawskie/analysis/")

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
proj4string = CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")

getTimetable = function(lineNum, stopId, stopNum) {
  # Example: stopNum = "04", stopId = "5002", lineNum = "26"
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
  result[!duplicated(result$Brigade),]
}

showMap <- function(positions, lineShape) {
  positions = applyColors(positions)
  leaflet(data = positions) %>% addTiles %>% 
    # addProviderTiles("CartoDB.Positron") %>% 
    setView(lng = 21.035, lat = 52.231765, zoom = 12) %>% 
    addCircles(~Lon, ~Lat, popup = ~Time, color = ~color) %>%
    addPolylines(data = lineShape, color = "#555", fillOpacity = 0, weight = 3) %>%
    addMarkers(~adjustedLon, ~adjustedLat)
}

applyColors <- function(data) {
  colors = list(
    split1 = "#0f0",
    split2 = "#00f",
    terminated = "#000",
    notMoving = "#f00",
    unknown = "#555"
  )
  data$color = lapply(data$direction, function (x) { colors[[x]] })
  data
}

getPointOnLine <- function(line) {
  spsample(line, 1, "regular")
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
  SpatialPolygons(list(Polygons(list(Polygon(my.pol)), ID="1")), proj4string=proj4string)
}

getPositionCircles <- function(lineData) {
  radius = 0.0002
  lineData$circle = apply(lineData[,c('Lon','Lat')], 1, 
                          function(x) createCircle(x[1], x[2], radius))
  lineData
}

getEstimatedPosition <- function(circle, origLon, origLat) {
  line = gIntersection(lineShape, circle)
  if (is.null(line)) {
    SpatialPoints(list(x = origLon, y = origLat), proj4string=proj4string)        
  } else {
    getPointOnLine(line)
  }
}

getCoordsFromSP <- function(spatialPoint) {
  list(lon = spatialPoint@coords[1,1][['x']], lat = spatialPoint@coords[1,2][['y']])
}

getLineSplit <- function(lineData, lineShape) {
  lineData$split = lapply(lineData$circle, function(x) gDifference(lineShape, x))
  estimatedPositions = mapply(getEstimatedPosition, lineData$circle, lineData$Lon, lineData$Lat)
  lineData$adjustedLon = lapply(estimatedPositions, function(x) { getCoordsFromSP(x)$lon }) %>% unlist
  lineData$adjustedLat = lapply(estimatedPositions, function(x) { getCoordsFromSP(x)$lat }) %>% unlist
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
  for (i in data$Brigade) {
    direction = "unknown"
    data[data$Brigade == i, 'direction'] = direction
    len1 = data[data$Brigade == i, 'split1Length']
    len2 = data[data$Brigade == i, 'split2Length']
    if (sum(prevData$Brigade == i) == 1) {
      len1prev = previousData[previousData$Brigade == i, 'split1Length']
      len2prev = previousData[previousData$Brigade == i, 'split2Length']
    } else {
      len1prev = 0
      len2prev = 0
    }
    if (len1 > 0 & len2 > 0 & len1prev > 0 & len2prev > 0) {
      diff1 = len1 - len1prev
      diff2 = len2 - len2prev
      if (diff1 > 0 & diff2 < 0) {
        direction = "split2"
      } else if (diff1 < 0 & diff2 > 0) {
        direction = "split1"
      } else {
        direction = "notMoving"
      }
    } else {
      direction = "terminated"
    }
    data[data$Brigade == i, 'direction'] = direction
  }
  data
}

getSplit <- function(split, num) {
  line = split@lines[[1]]@Lines[[num]]
  if (num == 1) {
    # Uwaga: zaprojektowane pod MVP z linia 26, nalezy to zgeneralizowac dla przypadku ogolnego
    line@coords = apply(line@coords, 2, rev)
  }
  line
} 

getDirectionSplit <- function(split, decision) {
  if (decision == "split1") {
    getSplit(split, 1)
  } else if (decision == "split2") {
    getSplit(split, 2)
  } else {
    NULL
  }
}

getHaltPosition <- function(decision, lon, lat) {
  if (decision == "terminated" | decision == "notMoving") {
    SpatialPoints(list(x = lon, y = lat), proj4string=proj4string)
  } else {
    NULL
  }
}

addMovementData <- function(data) {
  data$movement = mapply(getDirectionSplit, data$split, data$direction)
  data$position = mapply(getHaltPosition, data$direction, data$adjustedLon, data$adjustedLat)
  data
}

getLineStatus <- function(lineNumber, lineShape, previousData = data.frame()) {
  data <- getLinePositions(lineNumber) %>%
    getPositionCircles %>%
    getLineSplit(lineShape) %>%
    measureSplitLengths
  if (nrow(previousData) > 0) {
    data <- calculateDirections(data, previousData) %>%
      addMovementData
  }
  data
}

getMovementSpatialDF <- function(data) {
  movingVehicles = data[lapply(data$movement, function(x) { !is.null(x) }) %>% unlist,]
  ids = as.character(movingVehicles$Brigade)
  rownames(movingVehicles) = ids
  linesList = mapply(function(line, id) { Lines(line, id) }, movingVehicles$movement, ids)
  if (length(linesList) > 0) {
    movingVehicles %>% 
      dplyr::select(-movement, -circle, -split, -position) %>%
      SpatialLinesDataFrame(SpatialLines(linesList, proj4string), .)
  } else {
    NULL
  }
}

getHaltSpatialDF <- function(data) {
  haltedVehicles = data[lapply(data$position, function(x) { !is.null(x) }) %>% unlist,]
  ids = as.character(haltedVehicles$Brigade)
  rownames(haltedVehicles) = ids
  pointsList = do.call(rbind, haltedVehicles$position)
  if (length(pointsList) > 0) {
    haltedVehicles %>% 
      dplyr::select(-movement, -circle, -split, -position) %>%
      SpatialPointsDataFrame(pointsList, ., proj4string=proj4string)
  } else {
    NULL
  }
}


