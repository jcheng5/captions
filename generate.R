library(dplyr, warn.conflicts = FALSE)
library(stringr)
library(progress)
library(lubridate, warn.conflicts = FALSE)

source("_parse.R")
source("_frame.R")

generate_video <- function(srt_file, duration = "00:00", overwrite = "auto") {

  # The output path is the input path with .srt => .mp4
  output_file <- paste0(tools::file_path_sans_ext(srt_file), ".mp4")

  # If the output file exists, we bail if ovewrite=FALSE
  if (file.exists(output_file)) {
    if (isFALSE(overwrite)) {
      return(FALSE)
    } else if (overwrite == "auto") {
      # Only bail if output is up-to-date
      srt_mtime <- file.info(srt_file)$mtime
      out_mtime <- file.info(output_file)$mtime
      if (out_mtime >= srt_mtime) {
        return(FALSE)
      }
    }
  }

  # Data frame with `n` (int), `start`/`end` (in secs), and `text`
  df <- read_srt(srt_file)

  if (identical(duration, "00:00")) {
    # Auto-detect duration; set it to last caption + 1 second
    duration <- max(df$end) + 1
  } else {
    # Convert "mm:ss" to seconds
    duration <- period_to_seconds(ms(duration))
  }

  # The overall strategy is to create one .png for each caption (dozens), plus
  # one blank .png, inside captions_dir.
  #
  # Then populate frames_dir with one softlink per output frame (thousands), and
  # use ffmpeg to convert frames_dir to a video.

  # Create these dirs using tempfile so we can simultaneously run multiple jobs
  # if we want to
  captions_dir <- tempfile("caption_images")
  frames_dir <- tempfile("frames")

  dir.create(captions_dir)
  dir.create(frames_dir)
  # Don't on.exit(unlink) in case the files are needed for debugging

  message("  Generating frames")
  text_to_frame("", file.path(captions_dir, "blank.png"))
  for (i in seq_len(nrow(df))) {
    text_to_frame(df$text[i], file.path(captions_dir, paste0(df$n[i], ".png")))
  }

  fps <- 1

  message("  Linking")
  for (sec in 0:(duration - 1)) {
    for (frame in 0:(fps - 1)) {
      abs_frame <- sec * fps + frame
      secs <- abs_frame / fps

      dest <- file.path(frames_dir, sprintf("frame%08d.png", abs_frame))

      # Determine which caption png should be used for this frame
      row <- which(df$start <= secs & df$end >= secs)
      if (length(row) == 0) {
        # No caption matched, use blank
        src <- file.path(captions_dir, "blank.png")
      } else  {
        # One or more captions matched, use the first result
        src <- file.path(captions_dir, paste0(df$n[[row[1]]], ".png"))
      }

      file.link(src, dest)
    }
  }

  message("  Rendering")

  tryCatch({
    av::av_encode_video(
      input = dir(frames_dir, full.names = TRUE),
      output = output_file,
      framerate = fps,
      verbose = FALSE
    )
    message("Wrote ", output_file)
  }, interrupt = function(e) {
    message("Interrupted, deleting output")
    unlink(output_file)
    stop(e)
  }, error = function(e) {
    message("Errored, deleting output")
    unlink(output_file)
    stop(e)
  })

  unlink(captions_dir, recursive = TRUE)
  unlink(frames_dir, recursive = TRUE)

  invisible(TRUE)
}

# args <- commandArgs(TRUE)
# if (length(args) < 1) {
#   message("Usage: Rscript generate.R [input-file.srt] [mm:ss]")
# }
# input_file <- args[[1]]
# duration <- if (length(args) > 1) args[[2]] else "00:00"
# generate_video(input_file, duration)
