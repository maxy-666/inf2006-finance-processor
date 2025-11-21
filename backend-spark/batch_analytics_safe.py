from pyspark.sql import SparkSession
from pyspark.sql.functions import col, avg, count, lit
from pyspark.sql.types import FloatType

# Initialize Spark
spark = SparkSession.builder.appName("ExpenseBatchAnalytics").getOrCreate()

# 1. Read Data
input_path = "s3://inf2006-analytics-datalake/processed_data/"
df = spark.read.json(input_path)

print("Raw Data Schema:")
df.printSchema()

# 2. Deep Extraction (The Fix)
# Your data is in DynamoDB format: entities -> total -> L (list) -> [0] -> S (string)
# We navigate this structure to get the actual value.

try:
    clean_df = df.withColumn(
        "total_amount_str", 
        col("entities.total.L").getItem(0).getField("S")
    ).withColumn(
        "total_amount_float", 
        col("total_amount_str").cast(FloatType())
    )
    
    # Handle nulls (if total was missing) by filling with 0.0
    clean_df = clean_df.na.fill(0.0, subset=["total_amount_float"])

except Exception as e:
    print(f"WARNING: Schema mismatch processing 'total'. Using 0.0. Details: {e}")
    clean_df = df.withColumn("total_amount_float", lit(0.0))

# 3. Perform Analytics
analytics_df = clean_df.groupBy("category") \
    .agg(
        count("document_id").alias("transaction_count"),
        avg("total_amount_float").alias("average_spend") 
    ) \
    .orderBy(col("average_spend").desc())

# 4. Show results
print("Batch Analytics Results:")
analytics_df.show()

# 5. Save results
output_path = "s3://inf2006-analytics-datalake/batch_reports/category_summary_v3"
analytics_df.write.mode("overwrite").parquet(output_path)

print(f"Report saved to {output_path}")

spark.stop()