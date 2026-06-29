import os
from uuid import uuid4
from fastapi import APIRouter, UploadFile, File

router = APIRouter(prefix="/uploads", tags=["Uploads"])

UPLOAD_DIR = "app/uploads"


@router.post("/photo")
async def upload_photo(file: UploadFile = File(...)):
    extension = file.filename.split(".")[-1]
    filename = f"{uuid4()}.{extension}"
    filepath = os.path.join(UPLOAD_DIR, filename)

    with open(filepath, "wb") as buffer:
        buffer.write(await file.read())

    return {
        "filename": filename,
        "url": f"/uploads/{filename}"
    }
