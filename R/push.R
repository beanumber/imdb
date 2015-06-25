#' @title push
#' 
#' @description a utility function to push a data frame to a DB.
#' 
#' @param db a \code{dplyr} \code{src} or a \code{DBI} connection
#' @param temp.dir a directory containing the IMDB files you with to process
#' @param path.to.imdbpy2sql a path to the IMDB2SQL Python script provided by
#' IMDBPy. If NULL -- the default -- will attempt to find it using \code{\link{findimdbpy2sql}}.
#' 
#' @export
#' 
#' @examples
#' 
#' 
#' \dontrun{
#' if (require(RMySQL) & require(dplyr)) {
#'  # must have pre-existing database "imdb"
#'  db <- src_mysql(host = "localhost", user="bbaumer", password="fakepass", dbname = "imdb")
#' }
#' 
#' cache <- "~/dumps/imdb"
#'   getMovies(temp.dir = cache)
#'   push(db, temp.dir = cache)
#' }
#' 
#' 


push <- function(db, temp.dir, path.to.imdbpy2sql = NULL) {
  if ("src_postgres" %in% class(db)) {
    db.type <- "postgres"
  } else {
    db.type <- "sqlite"
  }
  dsn <- paste0(db.type, "://", db$info$user, ":@", db$info$host, "/", db$info$dbname)

  if (is.null(path.to.imdbpy2sql)) {
    path.to.imdbpy2sql <- findimdbpy2sql(temp.dir)
  }
  # needed python modules: sqlalchemy, sqlojbect, psycog2
  cmd <- paste0(path.to.imdbpy2sql, " -d ", temp.dir, " -u '", dsn, "'")
  system(cmd)
}


# dbBuildIndex()