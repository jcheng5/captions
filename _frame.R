text_to_frame <- function(text, file, width = 1920, height = 360,
  bg = "#F8F8F8", fg = "#404040", ...) {

  par(..., bg = bg)
  png(file = file, width = width, height = height, bg = bg,
    pointsize = 12)
  par(mar = c(0,0,0,0))
  plot.new()

  par(cex = 6, family = "Source Sans Pro", col = fg)

  # Detect clipping
  if (strwidth(text, "figure") > 1 || strheight(text, "figure") > 1) {
    stop("The caption [", text, "] was clipped")
  }

  text(0.5, 0.5, text)
  dev.off()

  invisible()
}
