#' movies
#' 
#' @description Download the raw data files from IMDB
#' 
#' @inheritParams etl::etl_extract
#' @param tables a character vector of files from IMDB to download. The default is
#' movies, actors, actresses, and directors. These four files alone will occupy
#' more than 500 MB of disk space. There are 49 total files available 
#' on IMDB. See \url{ftp://ftp.fu-berlin.de/pub/misc/movies/database/} for the
#' complete list. 
#' 
#' @import etl
#' @export
#' @examples
#' #' 
#' if (require(RPostgreSQL)) {
#'  # must have pre-existing database "airlines"
#'  db <- src_postgres(host = "localhost", user="postgres", password="postgres", dbname = "imdb")
#' }
#' 
#' imdb <- etl("imdb")
#' 
#' \dontrun{
#'   imdb <- etl("imdb", db = db, dir = "~/dumps/imdb/")
#'   imdb %>%
#'     etl_extract(tables = "movies") %>%
#'     etl_load()
#' }
#' @source IMDB: \url{ftp://ftp.fu-berlin.de/pub/misc/movies/database/}
#' @source IMDbPy: \url{http://imdbpy.sourceforge.net/}
#' 


etl_extract.etl_imdb <- function(obj, tables = 
                                   c("movies", "actors", "actresses", "directors"), ...) {
  
  src <- "ftp://ftp.fu-berlin.de/pub/misc/movies/database/"
  
  file_list <- read.csv(paste0(src, "filesizes"), sep = " ", header = FALSE)
  files <- paste0(as.character(file_list$V1), ".gz")
  
  if (!is.null(tables)) {
    files <- intersect(paste0(tables, ".list.gz"), files)
  }
  
  remotes <- paste0(src, files)
  locals <- paste0(attr(obj, "raw_dir"), "/", files)
  mapply(download.file, remotes, locals)
  
  invisible(obj)
}

#' @rdname etl_extract.etl_imdb
#' @param path_to_imdbpy2sql a path to the IMDB2SQL Python script provided by
#' IMDBPy. If NULL -- the default -- will attempt to find it using \code{\link{findimdbpy2sql}}.
#' @export
#' @importFrom DBI dbGetInfo


etl_load.etl_imdb <- function(obj, path_to_imdbpy2sql = NULL, ...) {
  
  db_info <- DBI::dbGetInfo(obj$con)
  
  if ("src_postgres" %in% class(obj)) {
    db_type <- "postgres"
  } else if ("src_mysql" %in% class(obj)) {
    db_type <- "mysql"
  } else {
    db_type <- "sqlite"
  }
  
  dsn <- paste0(db_type, "://", db_info$user, ":@", db_info$host, "/", db_info$dbname)
  
  if (is.null(path_to_imdbpy2sql)) {
    path_to_imdbpy2sql <- findimdbpy2sql(attr(obj, "dir"))
  }
  # needed python modules: sqlalchemy, sqlojbect, psycog2
  cmd <- paste0(path_to_imdbpy2sql, " -d ", attr(obj, "raw_dir"), " -u '", dsn, "'")
  message(paste("Running", cmd))
  system(cmd)
  invisible(obj)
}


