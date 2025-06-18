from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse
from pydantic import BaseModel

app = FastAPI()

class Word(BaseModel):
    text: str

@app.get("/", response_class=HTMLResponse)
def homepage():
    return """
    <html>
        <head>
            <title>Word Reverser</title>
        </head>
        <body>
            <h1>Reverse a Word</h1>
            <form id="reverse-form">
                <input type="text" id="word-input" placeholder="Enter a word" required>
                <button type="submit">Reverse</button>
            </form>
            <p id="result"></p>
            <script>
                const form = document.getElementById('reverse-form');
                form.addEventListener('submit', async (e) => {
                    e.preventDefault();
                    const word = document.getElementById('word-input').value;
                    const response = await fetch('/reverse', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify({ text: word })
                    });
                    const data = await response.json();
                    document.getElementById('result').innerText = 'Reversed: ' + data.reversed;
                });
            </script>
        </body>
    </html>
    """

@app.post("/reverse")
def reverse_word(word: Word):
    return {"reversed": word.text[::-1]}
