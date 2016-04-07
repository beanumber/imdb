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
#' @param all.tables a logical indicating whether you want to download all of 
#' the tables. Default is \code{FALSE}.
#' 
#' @import etl
#' @export
#' @examples
#' # Connect using default RSQLite database
#' imdb <- etl("imdb")
#' 
#' # Connect using pre-configured PostgreSQL database
#' \dontrun{
#'  if (require(RPostgreSQL)) {
#'    # must have pre-existing database "imdb"
#'    db <- src_postgres(host = "localhost", user="postgres", password="postgres", dbname = "imdb")
#'   }
#'   imdb <- etl("imdb", db = db, dir = "~/dumps/imdb/")
#'   imdb %>%
#'     etl_extract(tables = "movies") %>%
#'     etl_load()
#' }
#' \dontrun{
#'  if (require(RMySQL)) {
#'    # must have pre-existing database "imdb"
#'    db <- src_mysql(default.file = path.expand("~/.my.cnf"), 
#'                    group = "scidb", user = NULL, password = NULL, dbname = "imdb")
#'   }
#'   imdb <- etl("imdb", db = db, dir = "~/dumps/imdb/")
#'   imdb %>%
#'     etl_extract(tables = "movies") %>%
#'     etl_load()
#'     
#'   movies <- imdb %>%
#'     tbl("title") 
#'   movies %>%
#'     filter(title == 'star wars')
#'     
#'   people <- imdb %>%
#'     tbl("name") 
#'   roles <- imdb %>%
#'     tbl("cast_info") 
#'   movies %>%
#'     inner_join(cast_info, by = c("id" = "movie_id")) %>%
#'     inner_join(people, by = c("person_id" = "id")) %>%
#'     filter(title == 'star wars') %>%
#'     filter(production_year == 1977) %>%
#'     arrange(nr_order)
#'   
#' }
#' @source IMDB: \url{ftp://ftp.fu-berlin.de/pub/misc/movies/database/}
#' @source IMDbPy: \url{http://imdbpy.sourceforge.net/}
#' 


etl_extract.etl_imdb <- function(obj, tables = 
                                   c("movies", "actors", "actresses", "directors"), 
                                 all.tables = FALSE, ...) {
  
  src <- "ftp://ftp.fu-berlin.de/pub/misc/movies/database/"
  
  file_list <- read.csv(paste0(src, "filesizes"), sep = " ", header = FALSE)
  files <- paste0(as.character(file_list$V1), ".gz")
  
  if (all.tables) {
    tables <- gsub("\\.list\\.gz", "", files)
  }
  
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
#' @param password Must re-enter password unless your password is blank. The real
#' password will not be shown in messages.
#' @details 
#' For best performance, set the MySQL default collation to \code{utf8_unicode_ci}.
#' See the IMDbPy2sql documentation at 
#' \url{http://imdbpy.sourceforge.net/docs/README.sqldb.txt} for more details. 
#' 
#' Please be aware that IMDB contains information about *all* types of movies.
#' @export
#' @importFrom DBI dbGetInfo
#' @importFrom dplyr tbl


etl_load.etl_imdb <- function(obj, schema = TRUE, path_to_imdbpy2sql = NULL, password = "", ...) {
  
  db_info <- DBI::dbGetInfo(obj$con)
  
  if ("src_postgres" %in% class(obj)) {
    db_type <- "postgres"
    args <- " "
  } else if ("src_mysql" %in% class(obj)) {
    db_type <- "mysql"
    args <- " --mysql-force-myisam"
  } else {
    db_type <- "sqlite"
    args <- " --sqlite-transactions"
  }
  
  dsn <- paste0(db_type, "://", db_info$user, ":", password, "@", db_info$host, "/", db_info$dbname)
  
  if (is.null(path_to_imdbpy2sql)) {
    path_to_imdbpy2sql <- findimdbpy2sql(attr(obj, "dir"))
  }
  # needed python modules: sqlalchemy, sqlojbect, psycopg2, mysqldb
  cmd <- paste0(path_to_imdbpy2sql, args, " -d ", 
                attr(obj, "raw_dir"), " -u '", dsn, "'",
                " -c ", attr(obj, "raw_dir"))
  message(paste("Running", gsub(password, "<password>", cmd)))
  system(cmd)
  message(paste("Ran", gsub(password, "<password>", cmd)))
  
  # check to see if the import worked. If not, try a workaround
  n <- nrow(dplyr::tbl(obj, "title"))
  if (n < 1) {
   etl_load_data(obj, ...) 
  }
  invisible(obj)
}

#' @rdname etl_extract.etl_imdb
#' @export
#' 

etl_load_data <- function(obj, ...) UseMethod("etl_load_data")

#' @rdname etl_extract.etl_imdb
#' @export
#' @importFrom DBI dbWriteTable
#' 
etl_load_data.src_mysql <- function(obj, ...) {
  load_dir <- attr(obj, "load_dir")
  file_names <- list.files(load_dir, pattern = "\\.csv")
  table_names <- gsub("\\.csv", "", file_names)
  message(paste("Writing", table_names, "to the database..."))
  mapply(FUN = DBI::dbWriteTable, table_names, paste0(load_dir, "/", file_names), 
         MoreArgs = list(conn = obj$con, append = TRUE, header = FALSE, ...))
  invisible(obj)
}



