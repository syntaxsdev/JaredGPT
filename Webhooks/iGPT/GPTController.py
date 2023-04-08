import os
from GPT import GPT
from dotenv import load_dotenv

class GPTController:
    def __init__(self):
        load_dotenv()
        self.gpt: GPT = GPT()
        self.prompt = os.getenv("prompt")


    def getResponse(self, question: str):
        response: str = self.gpt.request(text=question, prompt=self.prompt)
        return response
