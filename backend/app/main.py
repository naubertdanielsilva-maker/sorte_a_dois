from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from app.database import create_db_and_tables
from app import models
from app.routers import users, couples, raffles, items, draws, stats, auth, memories, achievements, uploads, wishes

app = FastAPI(
    title="Sorte a Dois",
    description="Aplicativo de sorteios e experiências para Amanda e Naubert.",
    version="1.0.0"
)


@app.on_event("startup")
def on_startup():
    create_db_and_tables()


app.mount("/static", StaticFiles(directory="app/static"), name="static")
app.mount("/uploads", StaticFiles(directory="app/uploads"), name="uploads")
templates = Jinja2Templates(directory="app/templates")

app.include_router(users.router)
app.include_router(couples.router)
app.include_router(raffles.router)
app.include_router(items.router)
app.include_router(draws.router)
app.include_router(stats.router)
app.include_router(auth.router)
app.include_router(memories.router)
app.include_router(achievements.router)
app.include_router(uploads.router)
app.include_router(wishes.router)


@app.get("/", response_class=HTMLResponse)
def home(request: Request):
    return templates.TemplateResponse(
        request=request,
        name="index.html",
        context={}
    )
