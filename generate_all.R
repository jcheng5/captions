source("generate.R")
source("duration_table.R")

durations <- readr::read_csv("data/000-durations.csv", col_types = "cc")
input_files <- list.files("data", pattern = "*.srt", full.names = TRUE)

if (any(!input_files %in% file.path("data", durations$filename)) || any(!grepl("[1-9]", durations$duration))) {
  stop("durations table is not up-to-date")
}

count <- 0
for (file in input_files) {
  count <- count + 1
  message("[", count, "/", length(input_files), "] ", file)
  dur <- durations %>% filter(filename == basename(file)) %>% magrittr::extract2("duration")
  if (!generate_video(file, dur)) {
    message("  ...skipped")
  }
}
