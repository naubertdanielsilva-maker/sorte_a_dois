import os
from uuid import uuid4

from fastapi import APIRouter, File, HTTPException, UploadFile

router = APIRouter(prefix="/api/uploads", tags=["Uploads"])

UPLOAD_DIR = "app/uploads"

ALLOWED_EXTENSIONS = {
    "jpg",
    "jpeg",
    "png",
    "webp",
    "heic",
    "heif",
}


@router.post("/photo")
async def upload_photo(file: UploadFile = File(...)):
    os.makedirs(UPLOAD_DIR, exist_ok=True)

    original_name = file.filename or "foto.jpg"

    extension = (
        original_name.rsplit(".", 1)[-1].lower()
        if "." in original_name
        else "jpg"
    )

    if extension not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail="Formato de imagem não permitido.",
        )

    content = await file.read()

    if not content:
        raise HTTPException(
            status_code=400,
            detail="A imagem está vazia.",
        )

    filename = f"{uuid4()}.{extension}"
    filepath = os.path.join(UPLOAD_DIR, filename)

    with open(filepath, "wb") as buffer:
        buffer.write(content)

    return {
        "filename": filename,
        "url": f"/uploads/{filename}",
    }
