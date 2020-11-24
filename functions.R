
terra_extract_part <- function(raster, polygon, n) {
  x <- ceiling(nlyr(terra_s) / n)
  
  for (j in 1:n){
    cat(sprintf("%d/%d\n", j, n))
    terra_part <- terra::subset(terra_s, (x * (j - 1) + 1):min((x * j), nlyr(terra_s)))
    terra_sub <- terra::extract(terra_part, terraUganda[i,], fun=sum)
    if (j == 1){
      terra_all <- terra_sub
    } else {
      terra_all <- cbind(terra_all, terra_sub)
    }
  }
  return(terra_all)
}

extract_polygon <- function(rasters, polygons, i, n) {
  terra_all <- terra_extract_part(rasters, polygons[i,], n)
  
  total_amount <- terra::extract(fullraster, polygons[i,], fun=sum)
  perc_all <- as.data.frame(t(terra_all / total_amount[1,2] * 100))
  colnames(perc_all) <- polygons$ADM1_EN[i]
  perc_all$date <- as.Date(substr(rownames(perc_all),13,20), format = "%Y%m%d")
  return(perc_all)
}
plot_district <- function(datalist, n = NULL, name = NULL)
{
  if (is.null(n) & is.null(name)) {
    cat("either n or name has to be given\n")
    return()
  } else if (!is.null(n)) {
    ggplot(datalist[[n]], aes_string(y = names(datalist[[n]])[1], x = "date")) + geom_line()
  }
}