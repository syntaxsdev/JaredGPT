import openai, json, os, pandas as pd, tiktoken
from dotenv import load_dotenv

class GPT:
    def __init__(self):
        self.MaxTokens = 4096
        load_dotenv()

    def connectOpenAI(self):
        # Set the API key again.
        openai.api_key = os.getenv("API_KEY")

    def generateMessage(self, prompt: str, text: str, temp: int = 0) -> list:
        messages=[{"role": "system", "content": prompt},
                    {"role": "user", "content": text}]
        return messages


    def runModel(self, msg_history: list, temp: int = 0):
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=msg_history,
            temperature=temp
        )
        return response

    def request(self, text: str, prompt: str):
        self.connectOpenAI()
        msg = self.generateMessage(prompt=prompt, text=text)
        msg_list = self.truncate_message_parts(msg)

        response = []
        for msg_part in msg_list:
            data = self.runModel(msg_history=msg_part)
            response.append(data.choices[0].message.content)
        return ' '.join(response)

        
    def num_tokens_from_messages(self, messages, model="gpt-3.5-turbo-0301"):
        """Returns the number of tokens used by a list of messages.
            Code from OpenAI developer website
            https://platform.openai.com/docs/guides/chat/introduction"""
        try:
            encoding = tiktoken.encoding_for_model(model)
        except KeyError:
            encoding = tiktoken.get_encoding("cl100k_base")
        if model == "gpt-3.5-turbo-0301":  # note: future models may deviate from this
            num_tokens = 0
            for message in messages:
                num_tokens += 4  # every message follows <im_start>{role/name}\n{content}<im_end>\n
                for key, value in message.items():
                    num_tokens += len(encoding.encode(value))
                    if key == "name":  # if there's a name, the role is omitted
                        num_tokens += -1  # role is always required and always 1 token
            num_tokens += 2  # every reply is primed with <im_start>assistant
            return num_tokens
        else:
            raise NotImplementedError(f"""num_tokens_from_messages() is not presently implemented for model {model}.
        See https://github.com/openai/openai-python/blob/main/chatml.md for information on how messages are converted to tokens.""")


    def truncate_message_parts(self, message, max_tokens=2078):
        truncated_messages = []
        
        content = message[1]['content']

        while content:
            scan = self.generateMessage(prompt=message[0]['content'], text=content)

            if self.num_tokens_from_messages(scan) <= max_tokens:
                truncated_messages.append(scan)
                break

            truncated_content = content
            while self.num_tokens_from_messages(scan) > max_tokens:
                print(self.num_tokens_from_messages(scan))
                offset = int(len(truncated_content) * 0.05)
                half_size = len(truncated_content) // 2
                truncate_at = max(half_size + offset, 1)
                last_period = truncated_content[:truncate_at].rfind(".")
                last_doublespace = truncated_content[:truncate_at].rfind("  ")

                print(half_size + offset, last_period, last_doublespace)
                if last_period != -1 and (half_size + offset) >= last_period:
                    print("in lp")
                    truncated_content = truncated_content[:last_period + 1]
                elif last_doublespace != 1 and (half_size + offset) >= last_doublespace:
                    print("in lds")
                    truncated_content = truncated_content[:last_doublespace + 1]
                else:
                    truncated_content = truncated_content[:truncate_at]

                sub_message = self.generateMessage(prompt=message[0]['content'], text=truncated_content)
                scan = sub_message
                

            
            content = content[len(truncated_content):].lstrip()
            truncated_messages.append(sub_message)

        return truncated_messages
