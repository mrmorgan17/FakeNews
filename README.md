# FakeNews

This repository includes exploratory analysis and predictive modeling for the [Fake News Kaggle](https://www.kaggle.com/c/fake-news) competition. All code was done using the R programming language.

The .R file `MM_FakeNewsCleaning.R` includes my code and output for the methodology of feature selection, model building, and model tuning for the competiton.

A notebook was created on Kaggle for this competition as well and can be found [here](https://www.kaggle.com/matt4byu/fake-news-analysis-with-wactor-xgboost).

The goal of this competition was to use two datasets, a training dataset with information on 20,800 articles and a testing dataset, and a test dataset with information on 5,200 articles (26,000 articles total). Each of the 20,800 articles in the training dataset is labeled as either reliable or unreliable (fake news). The goal of this competition is to use the training data to build a model that can accurately label all 5,200 articles in the testing dataset as reliable or unreliable.

The best model that was fit to the data was an xgboost model. Models were fit using the [xgboost](https://www.rdocumentation.org/packages/xgboost/versions/1.2.0.1) R package. Term Frequency–Inverse Document Frequency matrices were also used in this analysis. This competiton used accuracy as the defining metric to compare submissions to each other. While the competition closed approximately 3 years ago, privately, the best logloss score achieved from an xgboost model was .98571 which would place 2nd on the Kaggle leaderboard for this competition.

I'd especially like to acknowledge [Michael W. Kearney](https://www.kaggle.com/mkearney) whose notebook, [Opinion/news classifier for predicting fake news](https://www.kaggle.com/mkearney/opinion-news-classifier-for-predicting-fake-news), was used as a reference and template for the much of my code. He is one of the creators of the [wactor](https://github.com/mkearney/wactor) package that I used for this analysis and he does great work with many text-based analyses.

