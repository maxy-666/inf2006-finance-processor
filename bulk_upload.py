import boto3
import os
import time
import uuid

# --- CONFIGURATION ---
BUCKET_NAME = "inf2006-financial-docs-b0957fd1a4dafc2c" 

LOCAL_FOLDER = r"C:\Users\Yuno\Downloads\SROIE2019\test\img" 

s3 = boto3.client('s3')

def upload_files():
    files = [f for f in os.listdir(LOCAL_FOLDER) if f.endswith('.jpg') or f.endswith('.png')]
    print(f"Found {len(files)} images. Starting upload...")

    count = 0
    for filename in files:
        local_path = os.path.join(LOCAL_FOLDER, filename)
        


        s3_key = f"uploads/{uuid.uuid4()}.jpg"
        
        print(f"Uploading {filename} -> s3://{BUCKET_NAME}/{s3_key}")
        
        try:
            with open(local_path, "rb") as f:
                s3.put_object(
                    Bucket=BUCKET_NAME,
                    Key=s3_key,
                    Body=f,
                    ContentType='image/jpeg'
                )
            count += 1
            

            time.sleep(0.5) 
            
        except Exception as e:
            print(f"Failed to upload {filename}: {e}")

    print(f"\nSuccessfully uploaded {count} files.")
    print("Check your Step Functions console! You should see hundreds of executions starting.")

if __name__ == "__main__":
    upload_files()