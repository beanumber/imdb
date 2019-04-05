[![Travis-CI Build Status](https://travis-ci.org/beanumber/imdb.svg?branch=master)](https://travis-ci.org/beanumber/imdb)

Getting Started
---------------

`imdb` is a light package that leverages the Python module [`IMDbPy`](https://github.com/alberanid/imdbpy) and the [`etl`](http://www.github.com/beanumber/etl) framework to make mirroring the IMDB in SQL painless, with user interaction taking place entirely within R.

### Prerequisities

You must install the Python module [`IMDbPy`](http://imdbpy.sourceforge.net/), which also has external dependencies. For Ubuntu, the following command should install everything you need. Binaries for Mac OS X and Windows are available from the project's [Download](http://imdbpy.sourceforge.net/downloads.html) page. \[You may want to consult the [.travis.yml](https://github.com/beanumber/imdb/blob/master/.travis.yml) file for a list of those dependencies.\]

``` bash
sudo apt-get install python-imdbpy python-sqlalchemy python-sqlobject python-psycopg2 python-mysqldb
```

You will also need to install the `etl` package from GitHub.

``` r
install.packages("etl")
```

### Installation

Similarly, `imdb` must be installed from GitHub.

``` r
devtools::install_github("beanumber/imdb")
```

``` r
library(imdb)
```

Instantiate an object
---------------------

Since the IMDB is very large (many gigabytes), it is best to store the data in a persistent SQL database. By default, `etl` will create an `RSQLite` for you in a temp directory -- but this is not a very safe place to store these data. Instead, we will connect to an existing (but empty) MySQL database using a [local option file](https://dev.mysql.com/doc/refman/5.7/en/option-files.html).

``` r
# must have pre-existing database "imdb"
db <- src_mysql_cnf(dbname = "imdb")
```

Since you will be downloading lots of data, you will probably want to specify a directory to store the raw data (which will take up several gigabytes on disk). Again, `etl` will create a directory for you if you don't, but that directory will be in a temp directory that is not safe.

``` r
imdb <- etl("imdb", db = db, dir = "~/dumps/imdb/")
```

Performing the ETL steps
------------------------

The first phase is to **E**xtract the data from IMDB. This may take a while. There are 47 files that take up approximately 2 GB on disk. By default, only the `movies`, `actors`, `actresses`, and `directors` files will be downloaded, but even these take up more then 500 MB of disk space.

``` r
imdb %>%
  etl_extract()
```

Mercifully, there is no **T**ransform phase for these data. However, the **L**oad phase can take a loooooong time.

The load phase leverages the Python module `IMDbPy`, which also has external dependencies. Please see the [.travis.yml](https://github.com/beanumber/imdb/blob/master/.travis.yml) file for a list of those dependencies (on Ubuntu -- your configuration may be different).

You may want to leave this running. To load the full set of files it took about 90 minutes and occupied about 9.5 gigabytes on disk.

``` r
imdb %>%
  etl_load()
```

    # TIME FINAL : 88min, 20sec (wall) 25min, 46sec (user) 0min, 11sec (system)

``` r
summary(imdb)
```

    ## files:
    ##    n     size                          path
    ## 1 47 1.915 GB  /home/bbaumer/dumps/imdb/raw
    ## 2 19 7.037 GB /home/bbaumer/dumps/imdb/load

    ##       Length Class           Mode       
    ## con   1      MySQLConnection S4         
    ## info  8      -none-          list       
    ## disco 3      -none-          environment

Query the database
------------------

Once everything is completed, you can query your fresh copy of the IMDB to find all of the *Star Wars* movies:

``` r
movies <- imdb %>%
  tbl("title")
movies %>%
  filter(title == "Star Wars" & kind_id == 1)
```

    ## Source:   query [?? x 12]
    ## Database: mysql 5.7.17-0ubuntu0.16.04.1 [bbaumer@localhost:/imdb]
    ## 
    ##        id     title imdb_index kind_id production_year imdb_id
    ##     <int>     <chr>      <chr>   <int>           <int>   <int>
    ## 1 3850123 Star Wars       <NA>       1            1977      NA
    ## # ... with 6 more variables: phonetic_code <chr>, episode_of_id <int>,
    ## #   season_nr <int>, episode_nr <int>, series_years <chr>, md5sum <chr>
