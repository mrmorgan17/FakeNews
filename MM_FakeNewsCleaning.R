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

#
# mod.imp %>%
#  mutate(rank = seq_len(nrow(mod.imp))) %>%
#  select(rank, Feature, Gain, Cover, Frequency) %>%
#  slice(seq_len(grep("opinion_classifier", mod.imp$Feature) + 5)) ->
#  plot_data

## create plot
# the_plot <- plot_data %>%
#  mutate(Feature = factor(Feature, levels = rev(Feature))) %>%
#  ggplot(aes(x = Feature, y = Gain, fill = Feature)) +
#  geom_col(width = 0.6) +
#  geom_point(shape = 21, size = 3.25) +
#  labs(title = "Model importance – gain",
#       subtitle = "Estimates from extreme gradient boosted {xgboost} model",
#       x = "Feature",
#       y = "Gain") +
#  coord_flip() +
#  theme_minimal() +
#  theme(legend.position = "none")

fn.test$text <- with(fn.test, paste(title, text))

fn.test.data <- tfidf(accuracy_v, fn.test$text)

fn.test.xgb.data <- xgb_mat(fn.test.data)

fn.test$label <- as.integer(predict(fn.xgb.model, fn.test.xgb.data) >= 0.5)

readr::write_csv(dplyr::select(fn.test, id, label), sprintf("kaggle-upload-%d.csv", as.integer(Sys.time())))
