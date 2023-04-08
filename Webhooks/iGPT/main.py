import uvicorn, os, requests, json
from typing import Union
from fastapi import FastAPI
from pydantic import BaseModel
from dotenv import load_dotenv
from GPTController import GPTController

app = FastAPI()
load_dotenv()

class Message(BaseModel):
    body: dict
    sendStyle: str
    attachments: list
    recipient: dict
    sender: dict
    date: str
    guid: str
    
    class Config:
        extra = "allow"

class OutgoingMessage(BaseModel):
    body: dict
    recipient: dict


@app.get("/")
async def read_root():
    return {"Hello": "World"}


@app.post("/messages/")
async def post_message(msg: Message):
    controller = GPTController()
    qst: str = msg.body['message'][5:] 
    outgoing = OutgoingMessage(body={"message": controller.getResponse(question=qst)}, recipient={"handle": msg.recipient['handle']})
    requests.post(url=os.getenv('JaredEndpoint'), json=outgoing.dict())

    #Delete the object
    del outgoing
    return {"success": True}