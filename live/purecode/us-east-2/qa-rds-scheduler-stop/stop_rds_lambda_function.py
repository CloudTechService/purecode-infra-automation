import boto3
import os
import json
from botocore.exceptions import ClientError

def lambda_handler(event, context):
    """
    Lambda function to stop RDS instances
    """
    # Initialize RDS client
    rds_client = boto3.client('rds')
    
    # Get DB instance identifiers from environment variable (comma-separated)
    db_identifiers = os.environ.get('DB_IDENTIFIERS', '').split(',')
    db_identifiers = [id.strip() for id in db_identifiers if id.strip()]
    
    try:
        if not db_identifiers:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'No DB identifiers provided in DB_IDENTIFIERS environment variable'
                })
            }
        
        results = {
            'action': 'stop',
            'successful': [],
            'skipped': [],
            'errors': []
        }
        
        # Process each DB instance
        for db_id in db_identifiers:
            try:
                # Get current DB instance status
                describe_response = rds_client.describe_db_instances(
                    DBInstanceIdentifier=db_id
                )
                
                if not describe_response['DBInstances']:
                    error_msg = f"DB instance {db_id} not found"
                    results['errors'].append(error_msg)
                    print(f"ERROR: {error_msg}")
                    continue
                
                db_instance = describe_response['DBInstances'][0]
                current_status = db_instance['DBInstanceStatus']
                
                # Check if instance can be stopped
                if current_status == 'available':
                    try:
                        rds_client.stop_db_instance(DBInstanceIdentifier=db_id)
                        results['successful'].append(db_id)
                        print(f"Successfully initiated stop for DB instance: {db_id}")
                    except ClientError as e:
                        error_code = e.response['Error']['Code']
                        if error_code == 'InvalidDBInstanceState':
                            skip_msg = f"{db_id} (cannot be stopped in current state)"
                            results['skipped'].append(skip_msg)
                            print(f"Skipped: {skip_msg}")
                        else:
                            error_msg = f"Failed to stop {db_id}: {str(e)}"
                            results['errors'].append(error_msg)
                            print(f"ERROR: {error_msg}")
                elif current_status in ['stopped', 'stopping']:
                    skip_msg = f"{db_id} (current status: {current_status})"
                    results['skipped'].append(skip_msg)
                    print(f"Skipped: {skip_msg}")
                else:
                    skip_msg = f"{db_id} (current status: {current_status}, cannot be stopped)"
                    results['skipped'].append(skip_msg)
                    print(f"Skipped: {skip_msg}")
                    
            except ClientError as e:
                error_msg = f"Error processing {db_id}: {str(e)}"
                results['errors'].append(error_msg)
                print(f"ERROR: {error_msg}")
        
        # Determine response status code
        status_code = 200
        if results['errors']:
            status_code = 207 if results['successful'] else 500
        
        return {
            'statusCode': status_code,
            'body': json.dumps(results)
        }
    
    except Exception as e:
        error_msg = f'Unexpected error: {str(e)}'
        print(f"ERROR: {error_msg}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': error_msg})
        }