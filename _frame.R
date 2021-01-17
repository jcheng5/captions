text_to_frame <- function(text, file, width = 1920, height = 360,
  bg = "#F8F8F8", fg = "#404040", ...) {

  ragg::agg_png(filename = file, width = width, height = height, bg = bg,
    pointsize = 12)
  on.exit(dev.off())

  par(bg = bg, mar = c(0,0,0,0), ...)
  plot.new()

  family <- "Source Sans Pro"
  if (grepl("darwin", R.version$os)) {
    if (is.na(iconv(text, to = "latin1"))) {
      family <- "PingFang SC"
    }
  }
  par(cex = 6, family = family, col = fg)

  # Detect clipping
  if (strwidth(text, "figure") > 1 || strheight(text, "figure") > 1) {
    stop("The caption [", text, "] was clipped")
  }

  text(0.5, 0.5, text)

  invisible()
}
