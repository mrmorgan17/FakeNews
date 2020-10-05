##
##  Data Cleaning for the Fake News Data
##

## Libraries
library(tidyverse)
library(tidytext)
library(stopwords)

## Read in the Data
fakeNews.train <- read_csv("./train.csv")
fakeNews.test <- read_csv("./test.csv")
fakeNews <- bind_rows(train = fakeNews.train, test = fakeNews.test,
                      .id = "Set")

################################
## Create a language variable ##
################################

## Determine which language each article is in
fakeNews <- fakeNews %>%
  mutate(language = cld2::detect_language(text = text, plain_text = FALSE))
fakeNews %>% count(language) %>%
  arrange(desc(n)) %>%
  print(n = Inf)

## Lump together other languages
fakeNews <- fakeNews %>% 
  mutate(language = fct_explicit_na(language, na_level = "Missing")) %>%
  mutate(language = fct_lump(language, n = 6))
fakeNews %>% count(language) %>%
  arrange(desc(n)) %>%
  print(n = Inf)

############################################
## Calculate df-idf for most common words ##
## not including stop words               ##
############################################

## Create a set of stop words
sw <- bind_rows(get_stopwords(language = "en"), #English
                get_stopwords(language = "ru"), #Russian
                get_stopwords(language = "es"), #Spanish
                get_stopwords(language = "de"), #German
                get_stopwords(language = "fr")) #French
sw <- sw %>%
  bind_rows(., data.frame(word = "это", lexicon = "snowball"))

## tidytext format
tidyNews <- fakeNews %>%
  unnest_tokens(tbl = ., output = word, input = text)

## Count of words in each article
news.wc <-  tidyNews %>%
  anti_join(sw) %>% 
  count(id, word, sort = TRUE)

## Number of non-stop words per article
all.wc <- news.wc %>% 
  group_by(id) %>% 
  summarize(total = sum(n))

## Join back to original df and calculate term frequency
news.wc <- left_join(news.wc, all.wc) %>%
  left_join(x = ., y = fakeNews %>% select(id, title))
news.wc <- news.wc %>% mutate(tf = n/total)
a.doc <- sample(news.wc$title,1)
ggplot(data = (news.wc %>% filter(title == a.doc)), aes(tf)) +
  geom_histogram() + ggtitle(label = a.doc)

## Find the tf-idf for the most common p% of words
word.count <- news.wc %>%
  count(word, sort=TRUE) %>%
  mutate(cumpct=cumsum(n)/sum(n))
ggplot(data=word.count, aes(x=1:nrow(word.count), y=cumpct)) + 
  geom_line()
top.words <- word.count %>%
  filter(cumpct<0.75)

news.wc.top <- news.wc %>% filter(word%in%top.words$word) %>%
  bind_tf_idf(word, id, n)
true.doc <- sample(fakeNews %>% filter(label==0) %>% pull(title),1)
news.wc.top %>% filter(title==true.doc) %>%
  slice_max(order_by=tf_idf, n=20) %>%
  ggplot(data=., aes(x=reorder(word, tf_idf), y=tf_idf)) + 
  geom_bar(stat="identity") +
  coord_flip() + ggtitle(label=true.doc)
fake.doc <- sample(fakeNews %>% filter(label==1) %>% pull(title),1)
news.wc.top %>% filter(title==fake.doc) %>%
  slice_max(order_by=tf_idf, n=20) %>%
  ggplot(data=., aes(x=reorder(word, tf_idf), y=tf_idf)) + 
  geom_bar(stat="identity") +
  coord_flip() + ggtitle(label=fake.doc)

############################################
## Merge back with original fakeNews data ##
############################################

## Convert from "long" data format to "wide" data format
## so that word tfidf become explanatory variables
names(news.wc.top)[1] <- "Id"
news.tfidf <- news.wc.top %>%
  pivot_wider(id_cols=Id,
              names_from=word,
              values_from=tf_idf)

## Fix NA's to zero
news.tfidf <- news.tfidf %>%
  replace(is.na(.), 0)

## Merge back with fakeNews data
names(fakeNews)[c(2,6)] <- c("Id", "isFake")
fakeNews.tfidf <- left_join(fakeNews, news.tfidf, by="Id")

## Remaining articles with NAs all have missing text so should get 0 tfidf
fakeNews.clean <- fakeNews.tfidf %>%
  select(-isFake, -title.x, -author.x, -text.x) %>% 
  replace(is.na(.), 0) %>% 
  left_join(fakeNews.tfidf %>% select(Id, isFake, title.x, author.x, text.x),., by="Id")

## Compare distributions of tfidf for different words
a.word <- sample(names(fakeNews.clean)[-c(1:7)], 1)
sub.df <- fakeNews.clean %>% select(as.name(a.word), isFake)
names(sub.df) <- c("x", "isFake")
ggplot(data=sub.df %>% filter(x>0), mapping=aes(x=x, color=as.factor(isFake))) +
  geom_density() + ggtitle(label=a.word)

## Write out clean dataset
write_csv(x=fakeNews.clean %>% select(-author.x, -title.x, -text.x),
          path="./CleanFakeNews.csv")