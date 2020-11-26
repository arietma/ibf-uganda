library(ggplot2)
library(maptools)
library(raster)
library(sf)
library(rgeos)
library(rgdal)
library(terra)

dir <- "c:/Users/BOttow/OneDrive - Rode Kruis/Documenten/IBF/floodscan/Uganda_1998-2019"
dir_script <- "c:/Users/BOttow/Documents/ibf-uganda-main"
admin <- "c:/Users/BOttow/OneDrive - Rode Kruis/Documenten/IBF/From_Agathe/Admin/uga_admbnda_adm1_UBOS_v2.shp"
# admin <- "C:/Users/ariet/Documents/510RedCross/uga_adminboundaries_1.shp"
# dir <- C:/Users/ariet/Documents/510RedCross/Uganda_1998_2019/1998"
source(sprintf("%s/functions.R", dir_script))

# files
grids <- list.files(dir, pattern = "*.tif$", full.names = T, recursive = T) # rasters year 1998

# load raster and polygon for terra package
terrasterflood <- terra::rast(sprintf("%s/1998/aer_sfed_3s_19980513_v05r00.tif", dir)) # stack
terra_s <- terra::rast(grids) # 20 years raster
terraNgora <- vect(sprintf("%s/data/NgoraSHP.shp", dir_script)) # 1 district
terraUganda <- vect(admin) # whole Uganda

fullraster <- terrasterflood
fullraster[fullraster == 0] <- 1

# processing
file <- sprintf("%s/data/floodscan_parsed_data.RDS", dir_script)
if (file.exists(file)) {
  floodscan_parsed_data <- readRDS(file)
} else {
  floodscan_parsed_data <- list()
}
n = 10 # number of parts to split the whole time period (to not ask too much of our RAM)
for (i in 121:123){ # for all the districts, change i depending on where you left off
  cat(sprintf("%d. %s\n", i, terraUganda$ADM1_EN[i]))
  floodscan_parsed_data[[i]] <- extract_polygon(terra_s, terraUganda, i, n)
}
saveRDS(floodscan_parsed_data, sprintf("%s/data/floodscan_parsed_data.RDS", dir_script))

plot_district(floodscan_parsed_data, n = 100)

# post processing to put all data in 1 data.frame
library(dplyr)
test <- bind_cols(floodscan_parsed_data[1:27])
test2 <- bind_cols(floodscan_parsed_data[28:122])
tes <- test[,c(2,seq(1,ncol(test), 2))]
names(tes)[1] <- "date"
tes2 <- test2[,c(2,seq(1,ncol(test2), 2))]
names(tes2)[1] <- "date"

floodscan_df <- full_join(tes, tes2, by = "date") %>% filter(!is.na(date)) %>% mutate(date = as.Date(date))
saveRDS(floodscan_df, sprintf("%s/data/floodscan_df.RDS", dir_script))


if (FALSE){
  floodscan_df <- readRDS(sprintf("%s/data/floodscan_df.RDS", dir_script))
  n = 111
  ggplot(floodscan_df, aes_string(y = names(floodscan_df[n]), x = "date")) + geom_line()
}