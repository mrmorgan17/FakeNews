import pandas as py
import numpy as np
import re
import os
from operator import add
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("DataFramExample").getOrCreate()
sc = spark.sparkContext
sc.setLogLevel('WARN')

newsDF = spark.read.option("header", "true").csv("train.csv")
newsDF.show(5)

authors = newsDF.groupBy('author').count().sort('count', ascending = False)
authors.show(20)

label = newsDF.groupby('label').count().sort('count', ascending = False)
label.show(20)

text = newsDF.groupby('label').count().sort('count', ascending = False)

