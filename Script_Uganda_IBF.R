# IBF Uganda script 
# 3-11-2020
# First, raster extraction is calculated using functions raster::extract, exactextractr::exact_extract, velox extraction and 
# terra::extract for:
# 1 day 1 district (Ngora district)
# 1 day whole Uganda
# 1 year (1998) 1 district
# 1 year whole Uganda

# Eventually we would calculate: sum/count for each raster layer. I could only find a working 'count' function in exactextractr.
# The results of 'sum' statistics in exactextractr differ slightly from the other methods because exactextractr uses the pixel 
# percentage coverage of the vector layer.

# Lastly I attempted raster aggregation by making the resolution 3 times coarser.


# load libraries and set working directory
library(maptools)
library(raster)
library(tictoc)
library(exactextractr)
library(sf)
library(rgeos)
library(rgdal)
library(velox)
library(terra)

setwd("C:/Users/ariet/Documents/510RedCross/Uganda_1998_2019/1998")

# load rasters and polygons for raster and exactextractr
grids <- list.files("C:/Users/ariet/Documents/510RedCross/Uganda_1998_2019/1998", pattern = "*.tif$") # rasters year 1998
x = lapply(grids, raster); s = raster::stack(x) # stack rasters
rasterwithflood = raster("C:/Users/ariet/Documents/510RedCross/Uganda_1998_2019/1998/aer_sfed_3s_19980513_v05r00.tif") # raster 1day
poly <- st_read("C:/Users/ariet/Documents/510RedCross/NgoraSHP.shp") # 1 district 
polyuga <- st_read("C:/Users/ariet/Documents/510RedCross/uga_adminboundaries_1.shp") # whole Uganda

# load raster and polygon for velox package
vxtest <- velox(rasterwithflood) # raster 1 day
polyvx <- readShapePoly("C:/Users/ariet/Documents/510RedCross/NgoraSHP.shp") # 1 district
polyvxuga <- readShapePoly("C:/Users/ariet/Documents/510RedCross/uga_adminboundaries_1.shp") # whole Uganda

# load raster and polygon for terra package
terrasterflood <- terra::rast("C:/Users/ariet/Documents/510RedCross/Uganda_1998_2019/1998/aer_sfed_3s_19980513_v05r00.tif") # stack
terra_s <- terra::rast(grids) # 1 day raster
terraNgora <- vect("C:/Users/ariet/Documents/510RedCross/NgoraSHP.shp") # 1 district
terraUganda <- vect("C:/Users/ariet/Documents/510RedCross/uga_adminboundaries_1.shp") # whole Uganda

#raster::extract####
# 1 day 1 district
tic(); extract(rasterwithflood, poly, fun=sum, na.rm=TRUE, df=TRUE); toc() 
# this is very slow, 8s for 1 day 1 district.

#exactextractr::exact_extract####
# 1 day 1 district
tic();exact_extract(rasterwithflood, poly,'sum');toc() 
# 0.3s, a lot faster than raster::extract 

# 1 day whole Uga
tic(); ex1998 <- exact_extract(rasterwithflood, polyuga,'count'); toc() # seconds
# 8s

# 1 year 1 district
tic(); ex1998 <- exact_extract(s, poly,'sum'); toc() 
# 88.52 s

# 1 year whole Uga
# tic();uga1998 <- exact_extract(s, polyuga,'count'); toc() # Error: cannot allocate vector of size x Gb

#velox package####
# 1 day 1 district
tic();vxtest$extract(polyvx, fun=sum, legacy = TRUE);toc() # legacy=TRUE is needed otherwise C++ code isn't used.
# 0.58 seconds

# 1 day whole Uga
tic(); vx1998 <- vxtest$extract(polyvxuga, fun=sum, legacy = TRUE); toc()
# 30s

# 1 year 1 district
# vx <- velox(s) # Error: cannot allocate vector of size x Mb
# vx1998 <- vx$extract(polyvx, fun=sum, legacy = TRUE) 

# 1 year whole Uga
# same problem as above

#terra::extract####
# 1 day 1 district
tic();terra::extract(terrasterflood, terraNgora, fun=sum);toc()
# 0.47s

# 1 day whole Uga
tic();terra::extract(terrasterflood, terraUganda, fun=sum);toc()
# 133s

# 1 year 1 district
tic(); terra::extract(terra_s, terraNgora, fun=sum);toc()
# 11s

# 1 year whole Uga
#tic(); terra::extract(s, SpatUganda, fun=sum);toc() # Error in x@ptr$extractVector(y@ptr, touches[1], method[1]) : 
#   std::bad_alloc 
# this means I'm out of RAM












#aggregation####
# raster::aggregate
# one day aggregation
tic(); raster3_oneday <- aggregate(rasterwithflood, fact=3, fun=mean, expand=TRUE); toc()
# this was very slow. it took 57 seconds
# one year aggregation
# tic(); raster_3_oneyear <- aggregate(s, fact=3, fun=mean, expand=TRUE); toc()
# this ran for 8 hours, took to long so I stopped the calculation

# velox
# one day aggregation
vxraster3_oneday <- velox(vxtest) # make velox raster, new raster saves into this one
tic(); vxraster3_oneday$aggregate(factor = 3, aggtype ='mean'); toc()
# 0.56s, very fast!
# one year aggregation
# velox raster stacking didn't work so this one won't either
#vx <- velox(s) # Error vector allocation
#vx$aggregate(factor = 3, aggtype = 'mean')

# terra:aggregate
# one day aggregation
tic();terra_raster3_oneday <- terra::aggregate(terrasterflood, fact = 3, fun='mean'); toc()
# 1.99 seconds elapsed!
# one year aggregation
#tic();terra_s3 <- terra::aggregate(terra_s, fact = 3, fun='mean'); toc()
#Error: [aggregate] insufficient disk space (perhaps from temporary file)

