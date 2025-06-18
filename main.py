from fastapi import FastAPI, Request, Form
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates

app = FastAPI()

templates = Jinja2Templates(directory="templates")

@app.get("/", response_class=HTMLResponse)
def read_form(request: Request):
    return templates.TemplateResponse("form.html", {"request": request, "reversed": None})

@app.post("/", response_class=HTMLResponse)
def reverse_word(request: Request, word: str = Form(...)):
    reversed_word = word[::-1]
    return templates.TemplateResponse("form.html", {"request": request, "reversed": reversed_word})

