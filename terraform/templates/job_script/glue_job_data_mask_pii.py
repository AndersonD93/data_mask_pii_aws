__author__ = "Anderson"

import boto3
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.utils import getResolvedOptions
import time
import json
import sys

# Inicializar sesión de Glue
glueContext = GlueContext(SparkContext.getOrCreate())
spark = glueContext.spark_session

args = getResolvedOptions(
    sys.argv,
    [
        "table_name",
        "database_catalog_name",
        "redshiftTmpDir",
        "role_arn",
        "db_user",
        "cluster_id",
        "authorized_users_table",
        "lambda_function_name",
    ],
)

# Utilizar los parámetros recibidos desde Job Parameters o desde Lambda
table_name = args["table_name"]  # dinámico, desde Lambda
database_catalog_name = args["database_catalog_name"]
redshiftTmpDir = args["redshiftTmpDir"]
role_arn = args["role_arn"]
db_user = "admin_ajduran"
cluster_id = args["cluster_id"]
authorized_users_table = args["authorized_users_table"]
lambda_function_name = args["lambda_function_name"]

# Patrón de PII
pii_patterns = {
    "cedula_ciudadania": r"\b\d{7,15}\b",
    "cedula_ciudadania_con_prefijo": r"CC\d{8,10}",
    "direccion": r"\b(?:CL|CR|AV|TR|KM|CJRES|MZ|CS|PS)\s?\d+\s?(?:[A-Z]|\#)?\s?-?\s?\d*(?:\s?#\s?\d+)?(?:\s?AP\s?\d+)?(?:\s?BL\s?\d+)?(?:\s?OF\s?\d+)?\b",
}

def invoke_create_masked_view():
    try:
        create_masked_view(
            table_name,
            authorized_users_table,
            database_catalog_name,
            cluster_id,
            db_user,
            role_arn,
            pii_patterns,
        )
    except KeyError as e:
        print(f"Error de clave: {e}")
        raise
    except Exception as e:
        print(f"Error inesperado: {e}")
        raise


def create_masked_view(
    table_name,
    authorized_users_table,
    database_catalog_name,
    cluster_id,
    db_user,
    role_arn,
    pii_patterns,
):
    pii_columns = detect_pii_in_columns(pii_patterns, database_catalog_name, table_name)
    # Elimina duplicados de PII encontrados
    pii_columns_unique = list(set(pii_columns))
    print(f"Columnas PII encontradas: {pii_columns_unique}")
    parts = table_name.split("_", 4)
    table_name_redshift = parts[4]
    schema_name = parts[3]
    db_name = "_".join(parts[:3])
    # Verificar si la vista existe
    view_name = f"vw_masked_{table_name_redshift}"
    check_view_sql = f"""
    SELECT 1 FROM pg_views WHERE schemaname = '{schema_name}' AND viewname = '{view_name}';
    """
    print(f"Verificando si la vista {view_name} existe...")
    view_exists = execute_redshift_query(
        check_view_sql, db_name, role_arn, db_user, cluster_id
    )
    if view_exists:
        # Eliminar la vista si existe
        print(f"La vista {view_name} existe. Eliminando vista...")
        drop_view_sql = f"DROP VIEW IF EXISTS {schema_name}.{view_name};"
        execute_redshift_query(drop_view_sql, db_name, role_arn, db_user, cluster_id)
        print(f"Vista {view_name} eliminada.")
    # Inicio del SQL para crear la nueva vista
    sql = f"CREATE OR REPLACE VIEW {schema_name}.{view_name} AS SELECT "
    columns = []
    # Construir el SQL para cada columna
    for column in all_columns:
        if column in pii_columns_unique:
            # Enmascarar las columnas que contienen PII si el usuario no está autorizado
            columns.append(
                f"""
                CASE
                    WHEN CURRENT_USER IN (SELECT usename FROM {authorized_users_table} WHERE pii_access = true)
                    THEN {column}
                    ELSE '*****'
                END AS {column}
            """
            )
        else:
            # No enmascarar las demás columnas
            columns.append(f"{column}")
    # Finalizar la construcción del SQL
    sql += ", ".join(columns) + f" FROM {schema_name}.{table_name_redshift};"
    print(f"SQL a ejecutar es: {sql}")
    try:
        execute_redshift_query(sql, db_name, role_arn, db_user, cluster_id)
        # Obtener los roles existentes
        roles = get_roles_by_owner(db_name, role_arn, db_user, cluster_id)

        # Otorgar permisos a los roles
        grant_permissions_to_roles(
            roles, schema_name, view_name, db_name, role_arn, db_user, cluster_id
        )

        # Invocar notificación solo si la vista se creó correctamente
        print(
            f"Vista enmascarada {view_name} creada exitosamente. Enviando notificación..."
        )
        invoke_lambda_notification(lambda_function_name, schema_name, view_name)
    except ValueError as e:
        print(f"Error al crear la vista enmascarada {view_name}: {str(e)}")
    return f"Masked view created for {table_name_redshift}"


def execute_redshift_query(sql, db_name, role_arn, db_user, cluster_id):
    print("Ingresando a execute_redshift_query")
    print(f"sql=>{sql} db_name=>{db_name} db_user=>{db_user} cluster_id=>{cluster_id}")
    redshift_client = boto3.client('redshift-data')

    try:
        # Intentamos ejecutar la consulta
        response = redshift_client.execute_statement(
            ClusterIdentifier=cluster_id,
            Database=db_name,
            DbUser=db_user,
            Sql=sql
        )
        if 'CreatedAt' in response:
            response['CreatedAt'] = response['CreatedAt'].isoformat()
            
        statement_id = response.get("Id", None)

        if not statement_id:
            print("Error: No se recibió un statement_id. Respuesta de execute_statement:")
            print(response)
            return {"statusCode": 500, "body": "Error ejecutando query"}

        print(f"Query enviada con statement_id: {statement_id}")

    except Exception as e:
        print(f"Error ejecutando la consulta en Redshift: {str(e)}")
        return {"statusCode": 500, "body": f"Error ejecutando query: {str(e)}"}

    status = None
    attempts = 0
    backoff_time = 10
    max_attempts = 7

    while status not in ("FINISHED", "FAILED", "ABORTED") and attempts < max_attempts:
        try:
            response = redshift_client.describe_statement(Id=statement_id)
            status = response["Status"]
            print(f"Intento {attempts + 1}: Estado de la consulta: {status}")

            if status in ("FAILED", "ABORTED"):
                print(f"Error: La consulta falló con estado: {status}")
                print(f"Detalles del error: {response}")
                return {"statusCode": 500, "body": f"Query failed: {response}"}

            if status == "FINISHED":
                result = redshift_client.get_statement_result(Id=statement_id)
                records = result.get("Records", [])
                print(f"Consulta finalizada. Registros obtenidos: {records}")

                return {
                    "statusCode": 200,
                    "body": json.dumps(records),
                }

        except redshift_client.exceptions.ResourceNotFoundException:
            print(f"Query con statement_id {statement_id} no encontrada. Reintentando en {backoff_time} segundos...")

        except Exception as e:
            print(f"Error al obtener estado de la consulta: {str(e)}")
            return {"statusCode": 500, "body": f"Error en describe_statement: {str(e)}"}

        time.sleep(backoff_time)
        backoff_time = min(backoff_time + 10, 60)
        attempts += 1

    print(f"Error: La consulta no finalizó después de {max_attempts} intentos.")
    return {"statusCode": 500, "body": "Query timeout"}


# Función para obtener el esquema de la tabla desde Glue Data Catalog
def get_table_schema(database, table):
    glue_client = boto3.client("glue")
    print(f"database= {database} tablename={table}")
    response = glue_client.get_table(DatabaseName=database, Name=table)
    columns = response["Table"]["StorageDescriptor"]["Columns"]
    schema = [(column["Name"], column["Type"]) for column in columns]
    return schema


# Función para cargar la tabla completa en un DataFrame
def load_table(database, table):
    df = glueContext.create_dynamic_frame.from_catalog(
        database=database, table_name=table, redshift_tmp_dir=redshiftTmpDir
    )
    return df.toDF()


# Función para detectar PII en las columnas
def detect_pii_in_columns(pii_patterns, database_catalog_name, table_name):
    df = load_table(database_catalog_name, table_name)
    pii_columns = set()
    for column in df.columns:
        for pattern_name, pattern in pii_patterns.items():
            # Aplicar patrón específico si es necesario
            if pattern_name == "cedula_ciudadania" and (
                "doc" not in column and "id" not in column
            ):
                continue
            # Comprobar si alguna columna contiene PII
            if df.filter(df[column].rlike(pattern)).count() > 0:
                pii_columns.add(column)
    return list(pii_columns)


def get_roles_by_owner(db_name, role_arn, db_user, cluster_id):
    # Consulta SQL para obtener los roles cuyo propietario es 'role_owner'
    sql = f"SELECT role_name FROM svv_roles WHERE role_owner = '{db_user}';"
    roles_data = execute_redshift_query(sql, db_name, role_arn, db_user, cluster_id)
    # Verifica si 'body' es un string y convierte a lista si es necesario
    body_data = (
        json.loads(roles_data["body"])
        if isinstance(roles_data["body"], str)
        else roles_data["body"]
    )
    # Extraer los nombres de los roles
    roles = (
        [record[0]["stringValue"] for record in body_data]
        if roles_data["statusCode"] == 200
        else []
    )
    print(f"Roles encontrados: {roles}")
    return roles


def grant_permissions_to_roles(
    roles, schema_name, view_name, db_name, role_arn, db_user, cluster_id
):
    # Otorgar permisos sobre el esquema y vista para cada rol
    for role in roles:
        # Permiso sobre el esquema
        schema_sql = f"GRANT USAGE ON SCHEMA {schema_name} TO ROLE {role};"
        execute_redshift_query(schema_sql, db_name, role_arn, db_user, cluster_id)
        # Permiso sobre la vista
        view_sql = f"GRANT SELECT ON {schema_name}.{view_name} TO ROLE {role};"
        execute_redshift_query(view_sql, db_name, role_arn, db_user, cluster_id)
        print(
            f"Permisos otorgados al rol {role} para el esquema {schema_name} y la vista {view_name}"
        )


def invoke_lambda_notification(lambda_function_name, schema_name, view_name):
    # Inicializar el cliente de Lambda
    lambda_client = boto3.client("lambda")
    # Preparar los datos del payload para enviar la notificación
    payload = {
        "message": f"Masked view {view_name} created successfully in schema {schema_name}.",
        "schema_name": schema_name,
        "view_name": view_name,
    }
    # Invocar la función Lambda para enviar la notificación
    try:
        response = lambda_client.invoke(
            FunctionName=lambda_function_name,
            InvocationType="Event",  # 'Event' para que no espere la respuesta
            Payload=json.dumps(payload),
        )
        print("Lambda function invoked successfully:", response)
    except ValueError as e:
        print("Error invoking Lambda function:", str(e))

               
if __name__ == "__main__":
    print("Ejecutando Glue Job")
    invoke_create_masked_view()