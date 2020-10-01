library(tidyverse)
library(wactor)
library(xgboost)

fn.train <- read_csv('train.csv')
fn.test <- read_csv('test.csv')

# Combining the title and text variables into the text variable
fn.train$text <- with(fn.train, paste(title, text))

fn.data <- split_test_train(fn.train, .p = 0.85)

# Create wactor
accuracy_v <- wactor(fn.data$train$text,
                     tokenizer = function(x) tokenizers::tokenize_words(x, strip_numeric = TRUE), max_words = 10000)

##Generate tfidf for train and test data
fn.data.train <- tfidf(accuracy_v, fn.data$train$text)
fn.data.test  <- tfidf(accuracy_v, fn.data$test$text)

# rm(fn.data.train, fn.data.test) => HUGE FILES...

fn.xgb.data <- list(train = xgb_mat(fn.data.train, y = fn.data$train$label),
                    test = xgb_mat(fn.data.test, y = fn.data$test$label)
                    )

param <- list(max_depth = 2,
              eta = 0.4,
              nthread = 60,
              objective = 'binary:logistic'
              )

fn.xgb.model <- xgb.train(param,
                          fn.xgb.data$train,
                          nrounds = 100,
                          print_every_n = 50,
                          watchlist = fn.xgb.data
                          )

fn.xgb.model <- xgb.train(param,
                          fn.xgb.data$train,
                          xgb_model = fn.xgb.model,
                          nrounds = 500,
                          print_every_n = 50,
                          watchlist = fn.xgb.data
                          )

table(predict = predict(fn.xgb.model, fn.xgb.data$test) >= 0.5,
      actual = fn.data$test$label)

## get influence metrics
mod.imp <- xgb.importance(model = fn.xgb.model)

fn.test$text <- with(fn.test, paste(title, text))

fn.test.data  <- wactor::tfidf(accuracy_v, fn.test$text)

fn.test.xgb.data <- xgb_mat(fn.test.data)

fn.test$label <- as.integer(predict(fn.xgb.model, fn.test.xgb.data) >= 0.5)

readr::write_csv(dplyr::select(fn.test, id, label), sprintf("kaggle-upload-%d.csv", as.integer(Sys.time())))