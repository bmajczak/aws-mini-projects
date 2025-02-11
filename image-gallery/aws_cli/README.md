# AWS Setup Script

This script automates the setup of AWS resources for an image gallery application. It performs the following tasks:

1. **Creates S3 Buckets**:
   - `static-image-gallery-654`: For serving static website content.
   - `image-storage-6552`: For storing images.

2. **Configures S3 Buckets**:
   - Applies bucket policies, blocks public access, and sets CORS configurations.
   - Enables static website hosting on the `static-image-gallery-654` bucket.

3. **Sets Up Lambda Function**:
   - Creates an IAM role for the Lambda function with appropriate permissions.
   - Deploys the Lambda function for image processing.

4. **Creates and Configures API Gateway**:
   - Sets up an HTTP API.
   - Integrates the API with the Lambda function.
   - Configures routes and CORS for the API.

5. **Uploads Static Content**:
   - Uploads `index.html` to the static website bucket.

## Prerequisites

- AWS CLI installed and configured with appropriate permissions.
- JSON configuration files:
  - `block-public-access.json`: Defines public access block settings for S3 buckets.
  - `policy-storage.json`: Bucket policy for `image-storage-6552`.
  - `policy-gallery.json`: Bucket policy for `static-image-gallery-654`.
  - `cors.json`: CORS configuration for `image-storage-6552`.
  - `website-configuration.json`: Configuration for static website hosting on `static-image-gallery-654`.
  - `trust-policy.json`: Trust policy document for the Lambda role.
  - `lambda-policy.json`: Policy document for the Lambda role.
  - `api-cors.json`: CORS configuration for API Gateway.
- Lambda function code named `lambda_function.py`, packaged as `lambda-function.zip`.

## How to Use

1. **Update Variables**: Modify the script to update the region, bucket names, role names, and ARNs as needed. If you change bucket names, remember to update them in other files (e.g., `lambda_function.py` and `.json` files).

2. **Prepare Configuration Files**: Ensure all required configuration files are present and correctly defined in the same directory as the script.

3. **Execute Script**: Run the script using a bash shell:
    ```bash
    chmod +x setup.sh
    ./setup.sh
    ```
   **Note:** During execution, some AWS CLI commands will output JSON responses. You may need to press "Enter" multiple times or press "q" to quit. Follow the prompts to proceed.

   After running the script, update the API URL in `index.html`. Replace the placeholder `$image_gallery` with the name of the bucket hosting the website, or create an environment variable. Then upload `index.html` to the S3 bucket:
    ```bash
    aws s3api put-object --bucket "$image_gallery" --key index.html --body index.html --content-type "text/html"
    ```

4. **Clean Up**: If you are done, use the `clean_up.sh` script to release resources. Make sure to update `clean_up.sh` with your API ID:
    ```bash
    chmod +x clean_up.sh
    ./clean_up.sh
    ```
