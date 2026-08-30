from fastapi import FastAPI

app = FastAPI(title="WeatherGPT API")


@app.get("/")
def read_root():
    return {"message": "WeatherGPT Backend is running"}


@app.get("/health")
def health_check():
    return {"status": "healthy"}