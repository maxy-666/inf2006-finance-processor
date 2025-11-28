from pyspark.sql import SparkSession
from pyspark.sql.functions import col, avg, count, lit
from pyspark.sql.types import FloatType
import matplotlib.pyplot as plt
import io
import boto3

# Initialize Spark
spark = SparkSession.builder.appName("ExpenseBatchAnalytics").getOrCreate()

# 1. Read Data
BUCKET_NAME = "inf2006-analytics-datalake"
input_path = f"s3://{BUCKET_NAME}/processed_data/"

print(f"Reading data from: {input_path}")
df = spark.read.json(input_path)

print("Raw Data Schema:")
df.printSchema()

# 2. Deep Extraction (The Fix)
try:
    clean_df = df.withColumn(
        "total_amount_str", 
        col("entities.total.L").getItem(0).getField("S")
    ).withColumn(
        "total_amount_float", 
        col("total_amount_str").cast(FloatType())
    )
    
    clean_df = clean_df.na.fill(0.0, subset=["total_amount_float"])

except Exception as e:
    print(f"WARNING: Schema mismatch processing 'total'. Using 0.0. Details: {e}")
    # Fallback for schema mismatch
    clean_df = df.withColumn("total_amount_float", lit(0.0))

# 3. Perform Analytics (Aggregations)
analytics_df = clean_df.groupBy("category") \
    .agg(
        count("document_id").alias("transaction_count"),
        avg("total_amount_float").alias("average_spend") 
    ) \
    .orderBy(col("average_spend").desc())

# 4. Show results (Console Output)
print("Batch Analytics Results:")
analytics_df.show()

# 5. Save results to S3 (Parquet Format)
output_path = f"s3://{BUCKET_NAME}/batch_reports/category_summary_v3"
analytics_df.write.mode("overwrite").parquet(output_path)
print(f"Data report saved to {output_path}")

# 6. Visualization (The New Addition)
try:
    print("Starting Visualization...")
    
    # A. Convert the aggregated Spark DataFrame to a local Pandas DataFrame
    pdf = analytics_df.toPandas()

    # B. Create a Bar Chart using Matplotlib
    plt.figure(figsize=(10, 6))
    plt.bar(pdf['category'], pdf['average_spend'], color='skyblue')
    
    plt.xlabel('Expense Category')
    plt.ylabel('Average Spend ($)')
    plt.title('Average Spend by Category')
    plt.xticks(rotation=45) 
    plt.tight_layout()      

    # C. Save the plot to an in-memory buffer
    img_data = io.BytesIO()
    plt.savefig(img_data, format='png')
    img_data.seek(0) 

    # D. Upload the image directly to S3 using boto3
    s3_client = boto3.client('s3')
    image_key = "reports/spend_chart.png"
    
    s3_client.put_object(
        Bucket=BUCKET_NAME,
        Key=image_key,
        Body=img_data,
        ContentType='image/png'
    )
    
    print(f"Visualization saved successfully to s3://{BUCKET_NAME}/{image_key}")

except Exception as e:
    print(f"Error during visualization: {e}")

# Stop the Spark Session
spark.stop()