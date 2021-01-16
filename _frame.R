text_to_frame <- function(text, file, width = 1920, height = 360,
  bg = "#F8F8F8", fg = "#404040", ...) {

  par(..., bg = bg)
  png(file = file, width = width, height = height, bg = bg,
    pointsize = 12)
  plot.new()
  text(0.5, 0.5, text, cex = 6, family = "Source Sans Pro", col = fg)
  dev.off()

  invisible()
}
