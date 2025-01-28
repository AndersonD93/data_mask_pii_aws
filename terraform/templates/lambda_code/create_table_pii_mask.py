import boto3
import json
import os
from botocore.exceptions import ClientError, EndpointConnectionError


def handler(event, context):
    glue_client = boto3.client("glue")
    # Extraer el nombre de la tabla y database catalog desde la invocación de Lambda (event)
    table_name = event["tableName"]
    database_catalog_name = event["databaseName"]
    # Validar que los parámetros necesarios están presentes
    if not table_name or not database_catalog_name:
        return {
            "statusCode": 400,
            "body": json.dumps(
                "Error: tableName y databaseName son obligatorios en el evento."
            ),
        }
    # Nombre del Glue Job (debe estar configurado previamente en Glue)
    glue_job_name = os.environ["glue_job_name"]
    try:
        # Iniciar el Glue Job con los parámetros
        response = glue_client.start_job_run(
            JobName=glue_job_name,
            Arguments={
                "--table_name": table_name,
                "--database_catalog_name": database_catalog_name,
            },
        )
        job_run_id = response["JobRunId"]
        return {
            "statusCode": 200,
            "body": json.dumps(
                f"Glue job iniciado exitosamente. JobRunId: {job_run_id}"
            ),
        }
    except EndpointConnectionError:
        # Manejo de error de conexión
        return {
            "statusCode": 503,
            "body": json.dumps(
                "Error de conexión con AWS Glue: verifica la red o configuración."
            ),
        }

    except ClientError as e:
        # Manejo de errores específicos de Glue (permiso denegado, recurso no encontrado, etc.)
        error_message = e.response["Error"]["Message"]
        return {
            "statusCode": 500,
            "body": json.dumps(
                f"Error del cliente al iniciar el Glue job: {error_message}"
            ),
        }
