import boto3
import os
from botocore.exceptions import ClientError, NoCredentialsError, EndpointConnectionError


def handler(event, context):
    # Configuración de los parámetros del correo
    emailSource = os.environ["emailSource"]  # Dirección de correo del remitente
    emailTarget = os.environ["emailTarget"]  # Dirección de correo del destinatario
    print(event)
    # Parsear el payload recibido
    schema_name = event.get("schema_name", "Unknown schema")
    view_name = event.get("view_name", "Unknown view")
    try:
        # Inicializar el cliente de SES
        ses_client = boto3.client("ses")
        # Crear el cuerpo del mensaje
        email_subject = f"Notification: Masked View Created in {schema_name}"
        email_body = (
            f"The masked view '{view_name}' has been successfully created in the schema '{schema_name}'.\n\n"
            f"Best regards,\nYour Automated Notification System"
        )

        # Enviar el correo electrónico usando SES
        response = ses_client.send_email(
            Source=emailSource,
            Destination={"ToAddresses": [emailTarget]},
            Message={
                "Subject": {"Data": email_subject},
                "Body": {"Text": {"Data": email_body}},
            },
        )
        print("Email sent successfully:", response)
        return {"statusCode": 200, "body": "Email sent successfully"}
    except ClientError as e:
        # Manejo de errores específicos de SES
        error_message = e.response["Error"]["Message"]
        print(f"ClientError sending email: {error_message}")
        return {"statusCode": 500, "body": f"Error sending email: {error_message}"}
    except NoCredentialsError:
        print("No AWS credentials were provided.")
        return {"statusCode": 500, "body": "Server error: No AWS credentials provided"}
    except EndpointConnectionError:
        print("Connection to the SES endpoint failed.")
        return {
            "statusCode": 500,
            "body": "Server error: Connection to SES endpoint failed",
        }
    except ValueError as e:
        print(f"ValueError: {str(e)}")
        return {"statusCode": 400, "body": f"Bad Request: {str(e)}"}
