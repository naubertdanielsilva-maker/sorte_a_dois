import os
from uuid import uuid4

from fastapi import APIRouter, File, HTTPException, UploadFile

router = APIRouter(prefix="/api/uploads", tags=["Uploads"])

UPLOAD_DIR = "app/uploads"
ALLOWED_CONTENT_TYPES = {
    "image/jpeg",
    "image/png",
    "image/webp",
    "image/heic",
    "image/heif",
}


@router.post("/photo")
async def upload_photo(file: UploadFile = File(...)):
    os.makedirs(UPLOAD_DIR, exist_ok=True)

    if file.content_type and file.content_type not in ALLOWED_CONTENT_TYPES:
        raise HTTPException(
            status_code=400,
            detail="Formato de imagem nÃ£o permitido.",
        )

    original_name = file.filename or "foto.jpg"
    extension = original_name.rsplit(".", 1)[-1].lower() if "." in original_name else "jpg"
    filename = f"{uuid4()}.{extension}"
    filepath = os.path.join(UPLOAD_DIR, filename)

    content = await file.read()

    if not content:
        raise HTTPException(status_code=400, detail="A imagem estÃ¡ vazia.")

    with open(filepath, "wb") as buffer:
        buffer.write(content)

    return {
        "filename": filename,
        "url": f"/uploads/{filename}",
    }