library(dplyr)
library(tidyr)
library(sp)
library(raster)
library(rgeos)
library(rgbif)
library(viridis)
library(gridExtra)
library(rasterVis)
require(spatialEco)

set.seed(1)

# Retrieved with thanks from http://strimas.com/spatial/hexagonal-grids/
make_grid <- function(x, cell_diameter, cell_area, clip = FALSE) {
  if (missing(cell_diameter)) {
    if (missing(cell_area)) {
      stop("Must provide cell_diameter or cell_area")
    } else {
      cell_diameter <- sqrt(2 * cell_area / sqrt(3))
    }
  }
  ext <- as(extent(x) + cell_diameter, "SpatialPolygons")
  projection(ext) <- projection(x)
  # generate array of hexagon centers
  g <- spsample(ext, type = "hexagonal", cellsize = cell_diameter, 
                offset = c(0.5, 0.5))
  # convert center points to hexagons
  g <- HexPoints2SpatialPolygons(g, dx = cell_diameter)
  # clip to boundary of study area
  if (clip) {
    g <- gIntersection(g, x, byid = TRUE)
  } else {
    g <- g[x, ]
  }
  # clean up feature IDs
  row.names(g) <- as.character(1:length(g))
  return(g)
}

# read in files
tweets <- read_csv("emoji_trunc.csv")
shape <- readOGR(dsn = 'sg-shape', layer ='sg-all')
shape <- gBuffer(shape, byid=TRUE, width=0) # clean up polygons

# convert to sp points and polygon
tweets <- drop_na(tweets)
# p <- SpatialPointsDataFrame(tweets, data.frame(id=1:728138))
tweets.sf <- st_as_sf(tweets, coords = c('lon','lat'), crs=4326)

shape_utm <- spTransform(shape, CRS(proj4string(shape)))
hex_grid <- make_grid(shape_utm, cell_area = 0.0001, clip = T)
hex.sf <- st_as_sf(hex_grid, crs=4326)
hex.sf <- tibble::rowid_to_column(hex.sf, "hexID")

# points in polygon
join <- st_join(tweets.sf, hex.sf, join = st_within)
join.df <- as.data.frame(join)
join.summary <- join.df %>% group_by(hexID) %>% summarise(count = n(), pos = sum(pos), neg = sum(neg), neu = sum(neu)) 
join.summary <- join.summary %>% select('count', 'pos', 'neg', 'neu', 'hexID') %>% drop_na()

kml.data <- merge(join.summary, hex.sf, by = "hexID") %>% st_as_sf()
kml.data <- st_as_sf(kml.data)
kml.data <- kml.data %>% mutate(norm = (pos-neg)/count)

p <- ggplot() +
  geom_sf(data = kml.data, aes(fill = (pos-neg)/count, geometry = geometry, text = paste0("Sentiment: ", norm)), lwd = 0) + 
  theme_void() +
  coord_sf() +
  scale_fill_viridis(
    breaks=c(0,0.25,0.3,0.35,0.4,0.45), 
    name="Normalized Sentiment", 
    guide=guide_legend( 
      keyheight = unit(3, units = "mm"),
      keywidth=unit(12, units = "mm"), 
      label.position = "bottom", 
      title.position = 'top', 
      nrow=1)) +
  labs(
    title = "Sentiments of Singaporeans in Singapore",
    subtitle = "Normalized Sentiment score = (Positive - Negative)/Total Count",
    caption = "Data: Ate Poorthuis | Creation: Dragon Minions"
  ) +
  theme(
    text = element_text(color = "#22211d"), 
    plot.background = element_rect(fill = "#f5f5f2", color = NA), 
    panel.background = element_rect(fill = "#f5f5f2", color = NA), 
    legend.background = element_rect(fill = "#f5f5f2", color = NA),
    plot.title = element_text(size= 22, hjust=0.01, color = "#4e4d47", margin = margin(b = -0.1, t = 0.4, l = 2, unit = "cm")),
    plot.subtitle = element_text(size= 17, hjust=0.01, color = "#4e4d47", margin = margin(b = -0.1, t = 0.43, l = 2, unit = "cm")),
    plot.caption = element_text( size=12, color = "#4e4d47", margin = margin(b = 0.3, r=-99, unit = "cm") ),
    legend.position = c(0.7, 0.09),
    panel.grid.major = element_line(colour = 'transparent'), 
    panel.grid.minor = element_line(colour = 'transparent')
  )

ggplotly(p, tooltip = "text") %>%
  highlight(
    "plotly_hover",
    opacityDim = 1
  )

st_write(kml.data, "tweet_hex_sentiment.kml")