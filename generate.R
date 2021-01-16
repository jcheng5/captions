library(dplyr)
library(stringr)
library(progress)
library(lubridate)

source("_parse.R")
source("_frame.R")

generate_video <- function(srt_file, duration = "00:00", overwrite = "auto") {
  output_file <- paste0(tools::file_path_sans_ext(srt_file), ".mp4")
  if (file.exists(output_file)) {
    if (isFALSE(overwrite)) {
      return(FALSE)
    } else if (overwrite == "auto") {
      srt_mtime <- file.info(srt_file)$mtime
      out_mtime <- file.info(output_file)$mtime
      if (out_mtime >= srt_mtime) {
        return(FALSE)
      }
    }
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

  message("  Generating frames")
  text_to_frame("", file.path(captions_dir, "blank.png"))
  # pb <- progress_bar$new(total = nrow(df))
  for (i in seq_len(nrow(df))) {
    # pb$tick()
    text_to_frame(df$text[i], file.path(captions_dir, paste0(df$n[i], ".png")))
  }

  fps <- 24

  message("  Linking")
  # pb <- progress_bar$new(total = duration)
  for (sec in 0:(duration - 1)) {
    # pb$tick()
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

  message("  Rendering")
  tryCatch({
    # system(paste0("ffmpeg -hide_banner -loglevel warning -nostats ",
    #   " -y -r 24 -s 1920x360 -i ",
    #   shQuote(file.path(frames_dir, "frame%08d.png"), "sh"), " ",
    #   "-vcodec libx264 -crf 25 -pix_fmt yuv420p ",
    #   shQuote(output_file, "sh")))
    res <- processx::run("ffmpeg", c(
      "-hide_banner",
      "-loglevel", "warning",
      "-nostats",
      "-y",
      "-r", "24",
      "-s", "1920x360",
      "-i", file.path(frames_dir, "frame%08d.png"),
      "-vcodec", "libx264",
      "-crf", "25",
      "-pix_fmt", "yuv420p",
      output_file
    ), echo_cmd = FALSE, echo = TRUE)
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
