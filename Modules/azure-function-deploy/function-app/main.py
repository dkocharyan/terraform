import azure.functions as func
import os
import sendgrid
from sendgrid.helpers.mail import Mail
from azure.storage.blob import BlobServiceClient, BlobClient

def main(msg: func.QueueMessage, blobinput: func.InputStream) -> None:

    message_content = msg.get_body().decode('utf-8')
    blob_content = blobinput.read()

    processed_data = process_message(message_content, blob_content)

    results_container_name = "results"
    results_blob_name = "result.txt"
    blob_service_client = BlobServiceClient.from_connection_string(os.environ["AzureWebJobsStorage"])
    container_client = blob_service_client.get_container_client(results_container_name)
    blob_client = container_client.get_blob_client(results_blob_name)
    blob_client.upload_blob(processed_data, overwrite=True)

    send_email(processed_data)

def process_message(message_content, blob_content):
    processed_data = "Processed message: " + message_content + "\n"
    processed_data += "Blob content: " + blob_content.decode('utf-8')
    return processed_data

def send_email(processed_data):
    sendgrid_api_key = os.environ["SendGridApiKey"]
    from_email = os.environ["SENDER"]
    to_email = os.environ["RECIPIENT"]
    subject = "Processing Result"

    sg = sendgrid.SendGridAPIClient(api_key=sendgrid_api_key)
    content = Mail(
        from_email,
        to_email,
        subject,
        plain_text_content=processed_data
    )

    response = sg.client.mail.send.post(request_body=content.get())
