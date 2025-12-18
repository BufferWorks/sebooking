from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from database import tests_col, centers_col, prices_col, bookings_col
import time

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------- HOME ----------------
@app.get("/")
def home():
    return {"status": "SE Booking API running"}

# ---------------- GET TESTS ----------------
@app.get("/get_tests")
def get_tests(category: str):
    tests = list(tests_col.find({"category": category}, {"_id": 0}))
    return tests

# ---------------- GET CENTERS ----------------
@app.get("/get_centers")
def get_centers(test_id: int):
    prices = list(prices_col.find({"test_id": test_id}, {"_id": 0}))

    result = []
    for p in prices:
        center = centers_col.find_one(
            {"id": p["center_id"]},
            {"_id": 0, "id": 1, "center_name": 1, "address": 1}
        )
        if center:
            result.append({
                "center_id": center["id"],
                "center_name": center["center_name"],
                "address": center["address"],
                "price": p["price"]
            })

    return result

# ---------------- ADD BOOKING ----------------
@app.post("/add_booking")
def add_booking(data: dict):
    booking_id = f"BKG{int(time.time())}"

    booking = {
        "booking_id": booking_id,
        "patient_name": data["name"],
        "mobile": data["mobile"],
        "center_id": data["center_id"],
        "test_id": data["test_id"],
        "price": data["price"],
        "status": "Pending",
        "created_at": int(time.time())
    }

    bookings_col.insert_one(booking)

    return {"booking_id": booking_id}

# ---------------- BOOKING HISTORY (NEW) ----------------
@app.get("/bookings_by_mobile")
def bookings_by_mobile(mobile: str):
    mobile = mobile.strip()

    # Search both string and number (handles old + new data)
    query = {
        "$or": [
            {"mobile": mobile},
            {"mobile": int(mobile)} if mobile.isdigit() else {}
        ]
    }

    bookings = list(bookings_col.find(
        query,
        {"_id": 0, "mobile": 0}
    ))

    result = []
    for b in bookings:
        test = tests_col.find_one({"id": b["test_id"]}, {"_id": 0})
        center = centers_col.find_one({"id": b["center_id"]}, {"_id": 0})

        result.append({
            "booking_id": b["booking_id"],
            "patient_name": b["patient_name"],
            "test_name": test["test_name"] if test else "",
            "center_name": center["center_name"] if center else "",
            "price": b["price"],
            "status": b["status"],
            "date": b["created_at"]
        })

    return result
