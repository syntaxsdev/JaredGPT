# Webhooks for Jared

There is currently one webhook, `iGPT`.

## iGPT

To configure, rename the `env` file to `.env` and put your API key in.
Set the prompt correctly.

Then, load `uvicorn`.

```sh 
uvicorn main:app --port 3003 --reload 
```