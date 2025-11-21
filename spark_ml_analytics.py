from pyspark.sql import SparkSession
from pyspark.sql.functions import col, expr, when, lit
from pyspark.sql.types import FloatType
from pyspark.ml.feature import StringIndexer, Tokenizer, HashingTF, VectorAssembler
from pyspark.ml.classification import RandomForestClassifier
from pyspark.ml.evaluation import MulticlassClassificationEvaluator
from pyspark.ml import Pipeline

# Initialize Spark
spark = SparkSession.builder.appName("ExpensePatternRecognition").getOrCreate()

print("--- STARTED SPARK ML JOB ---")

# 1. Read Data from Data Lake
input_path = "s3://inf2006-analytics-datalake/processed_data/"
df = spark.read.json(input_path)

# 2. Data Cleaning (Same safe extraction as before)
try:
    # Extract Vendor Name (string) and Total Amount (float)
    clean_df = df.withColumn("vendor_raw", expr("entities.company.L[0].S")) \
                 .withColumn("vendor", 
                    when(col("vendor_raw").isNotNull(), col("vendor_raw"))
                    .otherwise(lit("Unknown"))
                 ) \
                 .withColumn("amount_raw", expr("entities.total.L[0].S")) \
                 .withColumn("amount", 
                    when(col("amount_raw").isNotNull(), col("amount_raw").cast(FloatType()))
                    .otherwise(lit(0.0))
                 ) \
                 .select("vendor", "amount", "category")
                 
    # Filter out 'Uncategorized' or invalid rows for training
    clean_df = clean_df.filter((col("category") != "Uncategorized") & (col("category").isNotNull()))

except Exception as e:
    print(f"CRITICAL ERROR parsing data: {e}")
    spark.stop()
    exit(1)

print(f"Training data count: {clean_df.count()}")
clean_df.show(5)

# 3. Feature Engineering Pipeline
# Machine Learning models need numbers, not text. We convert text to numbers.

# A. Convert Category string to a Label Index (0, 1, 2...)
labelIndexer = StringIndexer(inputCol="category", outputCol="label")

# B. Process Vendor Name: Tokenize -> Hash -> Term Frequency
tokenizer = Tokenizer(inputCol="vendor", outputCol="words")
hashingTF = HashingTF(inputCol="words", outputCol="textFeatures", numFeatures=100)

# C. Assemble all features (Text Features + Amount) into one vector
# Add handleInvalid="skip" to drop rows with missing data instead of crashing
assembler = VectorAssembler(inputCols=["textFeatures", "amount"], outputCol="features", handleInvalid="skip")

# 4. Define the Random Forest Model
rf = RandomForestClassifier(labelCol="label", featuresCol="features", numTrees=20)

# 5. Build and Run the Pipeline
pipeline = Pipeline(stages=[labelIndexer, tokenizer, hashingTF, assembler, rf])

# Split data into Training (80%) and Test (20%) sets
(trainingData, testData) = clean_df.randomSplit([0.8, 0.2])

print("Training Random Forest Model...")
model = pipeline.fit(trainingData)

# 6. Make Predictions on Test Data
predictions = model.transform(testData)

# Show results
print("--- PREDICTION RESULTS ---")
predictions.select("vendor", "amount", "category", "label", "prediction").show(10)

# 7. Evaluate Accuracy
evaluator = MulticlassClassificationEvaluator(
    labelCol="label", predictionCol="prediction", metricName="accuracy")
accuracy = evaluator.evaluate(predictions)

print(f"--- MODEL ACCURACY: {accuracy:.2f} ---")
print(f"Insight: The model can predict expense categories with {accuracy*100:.1f}% accuracy based on Vendor and Amount.")

# 8. Save the Insights Report
output_path = "s3://inf2006-analytics-datalake/batch_reports/ml_insights"
# Create a simple dataframe of the metrics to save
metrics_df = spark.createDataFrame([(accuracy,)], ["accuracy"])
metrics_df.write.mode("overwrite").parquet(output_path)

spark.stop()