library(dplyr)
library(stringr)
library(progress)
library(lubridate)

source("_parse.R")
source("_frame.R")

generate_video <- function(srt_file, duration = "00:00", overwrite = TRUE) {
  output_file <- paste0(tools::file_path_sans_ext(srt_file), ".ogv")
  if (!overwrite && file.exists(output_file)) {
    message(output_file, " exists, skipping")
    return()
  }

  df <- read_srt(srt_file)

  if (identical(duration, "00:00")) {
    # Last caption + 1 second
    duration <- max(df$end) + 1
  } else {
    duration <- period_to_seconds(ms(duration))
  }

  captions_dir <- tempfile("caption_images")
  frames_dir <- tempfile("frames")

  unlink(captions_dir, recursive = TRUE)
  dir.create(captions_dir)
  unlink(frames_dir, recursive = TRUE)
  dir.create(frames_dir)

  text_to_frame("", file.path(captions_dir, "blank.png"))
  pb <- progress_bar$new(total = nrow(df))
  for (i in seq_len(nrow(df))) {
    pb$tick()
    text_to_frame(df$text[i], file.path(captions_dir, paste0(df$n[i], ".png")))
  }

  fps <- 24

  pb <- progress_bar$new(total = duration)
  for (sec in 0:(duration - 1)) {
    pb$tick()
    for (frame in 0:(fps - 1)) {
      abs_frame <- sec * fps + frame
      secs <- abs_frame / fps

      dest <- file.path(frames_dir, sprintf("frame%08d.png", abs_frame))

      row <- which(df$start <= secs & df$end >= secs)
      if (length(row) == 0) {
        src <- file.path(captions_dir, "blank.png")
      } else  {
        src <- file.path(captions_dir, paste0(df$n[[row[1]]], ".png"))
      }

      file.link(src, dest)
    }
  }

  system(paste0("ffmpeg -y -r 24 -s 1920x360 -i ",
    shQuote(file.path(frames_dir, "frame%08d.png"), "sh"), " ",
  #   "-vcodec libx264 -crf 25 -pix_fmt yuv420p ",
    "-c:v libtheora -qscale:v 7 ",
    shQuote(output_file, "sh")))
  message("Wrote ", output_file)

  unlink(captions_dir, recursive = TRUE)
  unlink(frames_dir, recursive = TRUE)
  invisible()
}

# args <- commandArgs(TRUE)
# if (length(args) < 1) {
#   message("Usage: Rscript generate.R [input-file.srt] [mm:ss]")
# }
# input_file <- args[[1]]
# duration <- if (length(args) > 1) args[[2]] else "00:00"
# generate_video(input_file, duration)
