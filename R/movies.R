#' movies
#' 
#' @description Download the raw data files from IMDB
#' 
#' @param tables a character vector of files from IMDB to download. The default is
#' movies, actors, actresses, and directors. There are 49 total files available on IMDB.
#' @param temp.dir a directory where you want to store the download files. 
#' 
#' @return An integer indicating the number of files present in \code{temp.dir} whose
#' filenames match those on IMDB. 
#' 
#' @export
#' @examples
#' 
#' if (require(RPostgreSQL) & require(dplyr)) {
#'  # must have pre-existing database "airlines"
#'  db <- src_postgres(host = "localhost", user="postgres", password="postgres", dbname = "imdb")
#' }
#' \dontrun{
#'   getMovies(temp.dir = "~/dumps/imdb")
#' }
#' 
#' 


getMovies <- function (tables = c("movies.list.gz", "actors.list.gz", "actresses.list.gz", "directors.list.gz"), temp.dir = tempdir()) {
  
  src <- "ftp://ftp.fu-berlin.de/pub/misc/movies/database/"
  
  file.list <- read.csv(paste0(src, "filesizes"), sep = " ", header=FALSE)
  files <- paste0(as.character(file.list$V1), ".gz")
  
  if (!is.null(tables)) {
    files <- intersect(tables, files)
  }
  
  for (file in files) {
    remote <- paste0(src, file)
    local <- paste0(temp.dir, "/", file)
    download.file(remote, destfile = local)
  }
  files
  numFiles <- length(intersect(files, list.files(temp.dir)))
  return(numFiles)
}
