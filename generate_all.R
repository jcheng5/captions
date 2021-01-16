source("generate.R")

library(future)
plan(multisession, workers = 8)

durations <- readr::read_csv("data/000-durations.csv", col_types = "cc")
input_files <- list.files("data", pattern = "*.srt", full.names = TRUE)

if (any(!input_files %in% file.path("data", durations$filename))) {
  stop("durations table is not up-to-date")
}

futures <- lapply(input_files, function(file) {
  dur <- durations %>% filter(filename == basename(file)) %>% magrittr::extract2("duration")
  future(generate_video(file, dur, overwrite = FALSE))
})

lapply(futures, value)
