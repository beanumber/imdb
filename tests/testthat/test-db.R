context("db")

## TODO: Add more tests

test_that("instantiation works", {
  imdb <- etl("imdb")
  expect_true("etl_imdb" %in% class(imdb))
  expect_true("etl" %in% class(imdb))
  expect_true("src" %in% class(imdb))
  expect_true("src_sqlite" %in% class(imdb))
})

# test_that("mysql connects", {
#   db <- src_mysql(default.file = path.expand("~/.my.cnf"), group = "client", user = NULL, password = NULL, dbname = "imdb")
#   imdb <- etl("imdb", db = db, dir = "~/dumps/imdb/")
#   expect_true("etl_imdb" %in% class(imdb))
#   expect_true("etl" %in% class(imdb))
#   expect_true("src" %in% class(imdb))
#   expect_true("src_mysql" %in% class(imdb))
#   expect_gt(length(DBI::dbListTables(imdb$con)), 0)
# })
