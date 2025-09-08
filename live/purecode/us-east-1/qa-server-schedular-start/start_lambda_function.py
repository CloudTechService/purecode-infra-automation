import boto3
import os
import json
from botocore.exceptions import ClientError

def lambda_handler(event, context):
    """
    Lambda function to start EC2 instances
    """
    # Initialize EC2 client
    ec2_client = boto3.client('ec2')
    
    # Get instance IDs from environment variable (comma-separated)
    instance_ids = os.environ.get('INSTANCE_IDS', '').split(',')
    instance_ids = [id.strip() for id in instance_ids if id.strip()]
    
    try:
        if not instance_ids:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'No instance IDs provided in INSTANCE_IDS environment variable'
                })
            }
        
        # Get current instance states
        describe_response = ec2_client.describe_instances(InstanceIds=instance_ids)
        instance_states = {}
        for reservation in describe_response['Reservations']:
            for instance in reservation['Instances']:
                instance_states[instance['InstanceId']] = instance['State']['Name']
        
        # Find instances that can be started (stopped state)
        instances_to_start = [id for id in instance_ids if instance_states.get(id) == 'stopped']
        
        results = {
            'action': 'start',
            'successful': [],
            'skipped': [],
            'errors': []
        }
        
        if instances_to_start:
            try:
                response = ec2_client.start_instances(InstanceIds=instances_to_start)
                results['successful'] = [instance['InstanceId'] for instance in response['StartingInstances']]
                print(f"Successfully started instances: {results['successful']}")
            except ClientError as e:
                error_msg = f"Failed to start instances: {str(e)}"
                results['errors'].append(error_msg)
                print(f"ERROR: {error_msg}")
        
        # Track instances that were skipped
        for id in instance_ids:
            if id not in instances_to_start:
                skip_msg = f"{id} (current state: {instance_states.get(id, 'unknown')})"
                results['skipped'].append(skip_msg)
                print(f"Skipped: {skip_msg}")
        
        # Determine response status code
        status_code = 200
        if results['errors']:
            status_code = 207 if results['successful'] else 500
        
        return {
            'statusCode': status_code,
            'body': json.dumps(results)
        }
    
    except ClientError as e:
        error_msg = f'AWS API Error: {str(e)}'
        print(f"ERROR: {error_msg}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': error_msg})
        }
    except Exception as e:
        error_msg = f'Unexpected error: {str(e)}'
        print(f"ERROR: {error_msg}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': error_msg})
        }