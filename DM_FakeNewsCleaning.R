library(dplyr)
library(tidytext)
library(tibble)
library(ggplot2)
library(scales)

data(stop_words)

test = read.csv("../test.csv", header = TRUE)
train = read.csv("../train.csv", header = TRUE)

test$label = NA

complete = rbind(test,train)

train <- complete %>% 
  filter(complete$label == 1)

test <- complete %>% 
  filter(complete$label != 1)


#Unnest tokens to get each word
text_df <- tibble(line = 1:10413, text = train)
text_df <- mutate(text_df, text = as.character(train$text))

text_df <- text_df %>% 
  unnest_tokens(word, text)

#take out the stopwords
text_df <- text_df %>% 
  anti_join(stop_words)

text_df %>% 
  count(word, sort = TRUE)


#graph it out
text_df %>%
  count(word, sort = TRUE) %>%
  filter(n > 5000) %>%
  mutate(word = reorder(word, n)) %>%
  ggplot(aes(word, n)) +
  geom_col() +
  xlab(NULL) +
  coord_flip()


