from pyspark.sql import SparkSession
import sys

print("--- DEBUG JOB STARTING ---")

try:
    # Initialize Spark
    spark = SparkSession.builder.appName("DebugJob").getOrCreate()
    print("--- SPARK SESSION CREATED ---")

    # Define path
    input_path = "s3://inf2006-analytics-datalake/processed_data/"
    print(f"--- READING PATH: {input_path} ---")

    # Read Data
    df = spark.read.json(input_path)
    
    # Basic Count
    count = df.count()
    print(f"--- DATA READ SUCCESS. COUNT: {count} ---")
    
    # Print Schema
    df.printSchema()

except Exception as e:
    print("--- CRITICAL ERROR ---")
    print(e)
    sys.exit(1)

print("--- DEBUG JOB FINISHED ---")
spark.stop()