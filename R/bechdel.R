#' Bechdel Test
#' @export

read_bechdel <- function() {
  # https://austinwehrwein.com/post/bechdel/
  movies <- jsonlite::read_json('http://bechdeltest.com/api/v1/getAllMovies',
                                 simplifyVector = TRUE) %>%
    mutate(year = readr::parse_number(year),
           id = readr::parse_number(id)) %>%
    tibble::as_tibble()
  return(movies)
}
