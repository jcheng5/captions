library(dplyr, warn.conflicts = FALSE)
library(tibble)

dir <- "data"
srt_files <- list.files(dir, pattern = "*.srt")

table <- file.path(dir, "000-durations.csv")

if (file.exists(table)) {
  df <- readr::read_csv(table, col_types = "cc")
} else {
  df <- tibble(filename = character(0), duration = character(0))
}

df <- df %>%
  bind_rows(tibble(filename = srt_files, duration = "00:00")) %>%
  filter(!duplicated(filename)) %>%
  arrange(filename)

readr::write_csv(df, table)
