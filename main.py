from fastapi import FastAPI, Request
from pydantic import BaseModel

app = FastAPI()

class Word(BaseModel):
    text: str

@app.get("/")
def health_check():
    return {"status": "ok"}

@app.post("/reverse")
def reverse_word(word: Word):
    return {"reversed": word.text[::-1]}
