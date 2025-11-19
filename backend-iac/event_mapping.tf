resource "aws_lambda_event_source_mapping" "dynamo_stream_mapping" {
  event_source_arn  = aws_dynamodb_table.processed_documents.stream_arn
  function_name     = aws_lambda_function.etl_stream_to_s3.arn
  starting_position = "LATEST"
}