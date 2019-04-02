from dataclasses import dataclass
from enum import Enum, unique
from json import loads
from typing import Iterable

from boto3 import resource


@unique
class MessageType(Enum):
    Bounce = "Bounce"
    Complaint = "Complaint"
    Delivery = "Delivery"


@dataclass(frozen=True)
class Message:
    email_address: str
    message_type: MessageType

    @classmethod
    def iter_from_record(cls, record) -> Iterable["Message"]:
        if record["Type"] != "Notification":
            return

        body = loads(record["Message"])

        message_type = MessageType(body["notificationType"])

        yield from (
            cls(
                email_address=email_address,
                message_type=message_type,
            )
            for email_address in body["delivery"]["recipients"]
        )


def ses_handler(event, context):
    dynamodb = resource("dynamodb")
    table = dynamodb.Table("ses")

    for record in event["Records"]:
        for message in Message.iter_from_record(loads(record["body"])):
            table.update_item(
                Key=dict(
                    email_address=message.email_address,
                ),
                UpdateExpression="SET " + ", ".join([
                    "bounces = if_not_exists(bounces, :bounces)",
                    "complaints = if_not_exists(compltaints, :complaints)",
                    "deliveries = if_not_exists(deliveries, :deliveries)",
                ]),
                ExpressionAttributeValues={
                    ":bounces": 0,
                    ":complaints": 0,
                    ":deliveries": 0,
                },
            )
            # XXX is there an ordering problem here?
            table.update_item(
                Key=dict(
                    email_address=message.email_address,
                ),
                # XXX pick term
                UpdateExpression="SET deliveries = deliveries + :increment",
                ExpressionAttributeValues={
                    ":increment": 1,
                },
            )
