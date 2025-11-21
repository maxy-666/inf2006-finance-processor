import sys
import boto3
from pyspark.sql import SparkSession

# --- CRITICAL: Force prints to show in the stderr log ---
sys.stdout = sys.stderr

print("==============================================")
print(">>> STARTING DIAGNOSTIC JOB")
print("==============================================")

BUCKET = "inf2006-analytics-datalake"
PREFIX = "processed_data/"

# TEST 1: Check S3 Access directly (Bypass Spark)
print(f">>> TEST 1: Checking S3 access to s3://{BUCKET}/{PREFIX} ...")
try:
    s3 = boto3.client('s3')
    response = s3.list_objects_v2(Bucket=BUCKET, Prefix=PREFIX)
    
    if 'Contents' in response:
        count = len(response['Contents'])
        print(f">>> SUCCESS: Found {count} files in S3.")
        # Print the first file to ensure it looks right
        print(f">>> First file: {response['Contents'][0]['Key']}")
        print(f">>> Size: {response['Contents'][0]['Size']} bytes")
    else:
        print(">>> WARNING: S3 Bucket is accessible but appears EMPTY.")
except Exception as e:
    print(f">>> FAILURE: Could not list S3 objects. Error: {e}")

print("----------------------------------------------")

# TEST 2: Spark Read
print(f">>> TEST 2: Attempting to read with Spark...")
try:
    spark = SparkSession.builder.appName("DebugVerify").getOrCreate()
    path = f"s3://{BUCKET}/{PREFIX}"
    
    df = spark.read.json(path)
    
    print(">>> SUCCESS: Spark read the schema!")
    df.printSchema()
    
    print(">>> Attempting to count rows...")
    row_count = df.count()
    print(f">>> SUCCESS: Spark dataframe has {row_count} rows.")
    
    print(">>> Showing top 5 rows:")
    df.show(5)
    
except Exception as e:
    print(">>> FAILURE: Spark crashed.")
    print(f">>> ERROR DETAILS: {e}")

print("==============================================")
print(">>> DIAGNOSTIC FINISHED")
print("==============================================")