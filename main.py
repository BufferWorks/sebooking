from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from database import tests_col, centers_col, prices_col, bookings_col
import time

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def root():
    return {"status": "SE Booking API running"}

# -------- GET TESTS --------
@app.get("/get_tests")
def get_tests(category: str):
    return list(tests_col.find(
        {"category": category},
        {"_id": 0}
    ))

# -------- GET CENTERS --------
@app.get("/get_centers")
def get_centers(test_id: int):
    result = []
    for p in prices_col.find({"test_id": test_id}):
        center = centers_col.find_one(
            {"id": p["center_id"]},
            {"_id": 0}
        )
        if center:
            result.append({
                "id": center["id"],
                "center_name": center["center_name"],
                "price": p["price"]
            })
    return result

# -------- ADD BOOKING --------
class Booking(BaseModel):
    name: str
    mobile: str
    center_id: int
    test_id: int
    price: float

@app.post("/add_booking")
def add_booking(b: Booking):
    booking_id = "BKG" + str(int(time.time()))

    bookings_col.insert_one({
        "booking_id": booking_id,
        "patient_name": b.name,
        "mobile": b.mobile,
        "center_id": b.center_id,
        "test_id": b.test_id,
        "price": b.price,
        "status": "Pending",
        "created_at": int(time.time())
    })

    return {
        "booking_id": booking_id
    }
