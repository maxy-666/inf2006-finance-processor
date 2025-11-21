import boto3
import os
import time
import uuid
import mimetypes

# --- CONFIGURATION ---
# Your S3 Bucket Name (from your Terraform/AWS Console)
BUCKET_NAME = "inf2006-financial-docs-b0957fd1a4dafc2c" 
# The folder on your laptop containing the SROIE images
LOCAL_FOLDER = r"C:\Users\Yuno\Downloads\SROIE2019\test\img" 
# ---------------------

s3 = boto3.client('s3')

def bulk_upload():
    # 1. Find all images
    files = [f for f in os.listdir(LOCAL_FOLDER) if f.lower().endswith(('.jpg', '.jpeg', '.png'))]
    print(f"Found {len(files)} images. Starting bulk upload...")

    # Limit to 50 for a safe, quick demo (remove [:50] to upload all)
    files_to_upload = files[:50] 
    
    count = 0
    for filename in files_to_upload:
        local_path = os.path.join(LOCAL_FOLDER, filename)
        
        # Generate a unique S3 key. 
        # CRITICAL: Must start with 'uploads/' to trigger EventBridge!
        s3_key = f"uploads/{uuid.uuid4()}-{filename}"
        
        print(f"Uploading {count+1}/{len(files_to_upload)}: {filename}...")
        
        try:
            # Determine content type automatically
            content_type, _ = mimetypes.guess_type(local_path)
            if not content_type: content_type = 'image/jpeg'

            with open(local_path, "rb") as f:
                s3.put_object(
                    Bucket=BUCKET_NAME,
                    Key=s3_key,
                    Body=f,
                    ContentType=content_type
                )
            count += 1
            
            # Small sleep to simulate realistic traffic (optional)
            time.sleep(0.5) 
            
        except Exception as e:
            print(f"Failed to upload {filename}: {e}")

    print(f"\n✅ Success! Uploaded {count} files.")
    print("Go check your Step Functions console to see the parallel processing!")

if __name__ == "__main__":
    bulk_upload()