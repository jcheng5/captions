# HH:MM:SS,sss
parse_time <- function(timestr) {
  res <- rep_len(NA, length(timestr))
  is_na <- is.na(timestr)
  res[!is_na] <- lubridate::period_to_seconds(lubridate::hms(timestr[!is_na]))
  res
}

# 00:00:01,868 --> 00:00:04,203
parse_times <- function(timespanstr) {
  timepat <- "(\\d{2}:\\d{2}:\\d{2},\\d{3})"
  mat <- do.call(rbind, str_extract_all(timespanstr, timepat))
  cbind(
    parse_time(mat[,1]),
    parse_time(mat[,2])
  )
}

read_srt <- function(file) {
  lines <- readLines(file, encoding = "UTF-8")

  separators <- which(lines == "")
  starts <- c(0, separators)
  ends <- c(separators, length(lines) + 1)
  df <- mapply(starts, ends, FUN = function(start, end) {
    n <- as.integer(lines[start+1])
    times <- lines[start+2]
    text <- paste(collapse = "\n", lines[(start+3):(end-1)])
    tibble(n, times = times, text = text)
  }, SIMPLIFY = FALSE) %>% bind_rows()

  times_parsed <- parse_times(df$times)
  df %>%
    mutate(start = times_parsed[,1], end = times_parsed[,2], .after = times) %>%
    select(-times) %>%
    filter(!is.na(n))
}

# df <- read_srt("captions.srt")
