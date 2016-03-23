#' Find the path to the imdbpy2sql.py script
#' 
#' @description A utility function to locate the \code{imdbpy2sql} Python script
#' 
#' @param temp_dir directory where you want the IMDBPy script to reside
#' 
#' @return a path to the unzipped, executable script
#' 
#' @importFrom R.utils gunzip
#' 
#' @export
#' @examples 
#' script <- findimdbpy2sql()


findimdbpy2sql <- function(temp_dir = tempdir()) {
  
  local <- paste0(temp_dir, "/imdbpy2sql.py.gz")
  script <- gsub(".gz", "", local)
  
  if (!file.exists(script)) {
    # http://imdbpy.sourceforge.net/downloads.html
    # for Ubuntu
    remote <- "/usr/share/doc/python-imdbpy/examples/imdbpy2sql.py.gz"
    file.copy(remote, local)
    # could this be used instead??
    # untar(local, compressed = "gzip")
    R.utils::gunzip(local)
    if (file.exists(script) & file.exists(local)) {
      file.remove(local)
    }
  }
  if (!file.exists(script)) {
    stop(paste0("Sorry, I can't find the script at: ", script))
  }
  
  if (file.access(script, mode = 1) < 0) {
    # make the file executable
    Sys.chmod(script, mode = "755")
  }
  return(script)
}
