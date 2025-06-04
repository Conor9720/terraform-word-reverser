from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "Hello from FastAPI!"}

@app.get("/reverse")
def reverse_word(word: str):
    return {"reversed": word[::-1]}
