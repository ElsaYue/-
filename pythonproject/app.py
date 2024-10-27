from fastapi import FastAPI, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from process_image import process_image as process_image_function
from process_text import process_text, process_keyword, process_text_meaning

app = FastAPI()

class ImageRequest(BaseModel):
    image_base64: str

class TextRequest(BaseModel):
    all_text: str

class TextMeaningRequest(BaseModel):
    text: str

@app.post("/process_image")
async def process_image_route(request: ImageRequest):
    try:
        async def generate():
            async for content in process_image_function(request):
                yield content.encode('utf-8')
        
        return StreamingResponse(generate(), media_type="text/plain")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/process_text")
async def process_text_route(request: TextRequest):
    try:
        async def generate():
            async for content in process_text(request):
                yield content.encode('utf-8')
        
        return StreamingResponse(generate(), media_type="text/plain")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/process_keyword")
async def process_keyword_route(request: TextRequest):
    try:
        result = await process_keyword(request)
        return {"result": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/process_text_meaning")
async def process_text_meaning_route(request: TextMeaningRequest):
    try:
        async def generate():
            async for content in process_text_meaning(request):
                yield content.encode('utf-8')
        
        return StreamingResponse(generate(), media_type="text/plain")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/")
async def root():
    return {"message": "欢迎使用photoPPT应用"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=4000)
