from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from database import (
    tests_col,
    centers_col,
    prices_col,
    bookings_col,
    admins_col,
    center_users_col,
    admins_col,
    center_users_col,
    categories_col,
    notices_col,
    agents_col
)

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

# ---------------- GET NOTICE ----------------
@app.get("/get_notice")
def get_notice():
    notice = notices_col.find_one({"id": "home_notice"}, {"_id": 0})
    if not notice:
        return {"text": "", "enabled": False}
    return notice

# ---------------- UPDATE NOTICE ----------------
@app.post("/admin/update_notice")
def update_notice(data: dict):
    notices_col.update_one(
        {"id": "home_notice"},
        {
            "$set": {
                "text": data.get("text", ""),
                "enabled": bool(data.get("enabled", False))
            }
        },
        upsert=True
    )
    return {"status": "updated"}

# ---------------- GET TESTS ----------------
@app.get("/get_tests")
def get_tests(category_id: int):
    return list(
        tests_col.find(
            {"category_id": category_id},
            {"_id": 0}
        )
    )


# ---------------- GET CENTERS ----------------
@app.get("/get_centers")
def get_centers(test_id: int):
    prices = list(
        prices_col.find(
            {"test_id": test_id, "enabled": True},
            {"_id": 0}
        )
    )

    result = []

    for p in prices:
        center = centers_col.find_one(
            {"id": p["center_id"], "enabled": True},
            {"_id": 0}
        )

        if center:
            result.append({
                "center_id": center["id"],
                "center_name": center["center_name"],
                "address": center["address"],
                "lat": center.get("lat"),
                "lng": center.get("lng"),
                "timings": center.get("timings", []),
                "price": p["price"],
                "enabled": True  # ✅ SEND THIS
            })

    return result



# ---------------- ADD BOOKING ----------------
@app.post("/add_booking")
def add_booking(data: dict):
    booking_id = f"BKG{int(time.time())}"
    current_time = int(time.time())
    
    booked_by = data.get("booked_by", "Customer")
    price = float(data["price"])
    
    # Amount paid at booking time
    paid_amount = float(data.get("paid_amount", 0))
    
    # Validation: If legacy 'payment_status'='Paid', assume full price
    if data.get("payment_status") == "Paid" and paid_amount == 0:
        paid_amount = price

    agent_collected = 0.0
    center_collected = 0.0

    # Attribution
    if booked_by not in ["Customer", "Center"]: 
        agent_collected = paid_amount
    elif booked_by == "Center":
        center_collected = paid_amount
    
    # Calculate Status
    total_paid = agent_collected + center_collected
    balance_due = price - total_paid
    
    input_status = data.get("payment_status", "Unpaid")
    
    if "Pending" in input_status:
        payment_status = input_status
    elif balance_due <= 0:
        payment_status = "Paid"
    elif total_paid > 0:
        payment_status = "Partial"
    else:
        payment_status = "Unpaid"

    booking = {
        "booking_id": booking_id,
        "patient_name": data["name"],
        "mobile": data["mobile"],
        "center_id": data["center_id"],
        "test_id": data["test_id"],
        "price": price,
        "status": "Pending",
        "created_at": current_time,
        "booked_by": booked_by,
        
        # Payment Breakdown
        "agent_collected": agent_collected,
        "center_collected": center_collected,
        "payment_status": payment_status,
        "payment_updated_by": booked_by if total_paid > 0 else None,
        "payment_updated_at": current_time if total_paid > 0 else None
    }

    bookings_col.insert_one(booking)
    return {"booking_id": booking_id}


# ---------------- UPDATE PAYMENT DETAILS (New Generic) ----------------
# ---------------- UPDATE PAYMENT DETAILS (New Generic) ----------------
@app.post("/update_payment_details")
def update_payment_details(data: dict):
    booking_id = data.get("booking_id")
    booking = bookings_col.find_one({"booking_id": booking_id})
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    price = float(booking.get("price", 0))
    
    # Update provided fields only
    agent_collected = float(data.get("agent_collected", booking.get("agent_collected", 0)))
    center_collected = float(data.get("center_collected", booking.get("center_collected", 0)))
    admin_collected = float(data.get("admin_collected", booking.get("admin_collected", 0)))

    total_paid = agent_collected + center_collected + admin_collected
    balance_due = price - total_paid
    
    if balance_due <= 0:
        new_status = "Paid"
    elif total_paid > 0:
        new_status = "Partial"
    else:
        new_status = "Unpaid"

    updated_by = data.get("updated_by_name", "Admin")

    bookings_col.update_one(
        {"booking_id": booking_id},
        {"$set": {
            "agent_collected": agent_collected,
            "center_collected": center_collected,
            "admin_collected": admin_collected,
            "payment_status": new_status,
            "payment_updated_by": updated_by,
            "payment_updated_at": int(time.time())
        }}
    )
    return {"status": "updated", "payment_status": new_status}


# ---------------- ADMIN STATS (CENTER WISE) ----------------
@app.get("/admin/center_stats")
def get_center_stats(start_ts: int = None, end_ts: int = None):
    pipeline = []
    
    # 1. Match Stage (Filter by Date if provided)
    if start_ts is not None and end_ts is not None:
        pipeline.append({
            "$match": {
                "created_at": {"$gte": start_ts, "$lte": end_ts}
            }
        })

    # 2. Group Stage
    pipeline.append({
            "$group": {
                "_id": "$center_id",
                "total_bookings": {"$sum": 1},
                "total_revenue": {"$sum": "$price"},
                "paid_count": {
                    "$sum": { "$cond": [ {"$eq": ["$payment_status", "Paid"]}, 1, 0 ] }
                },
                "unpaid_count": {
                    "$sum": { "$cond": [ {"$eq": ["$payment_status", "Unpaid"]}, 1, 0 ] }
                },
                "partial_count": {
                    "$sum": { "$cond": [ {"$eq": ["$payment_status", "Partial"]}, 1, 0 ] }
                },
                # Use $ifNull to handle old documents without these fields
                "total_agent_collected": {"$sum": { "$ifNull": ["$agent_collected", 0] }},
                "total_center_collected": {"$sum": { "$ifNull": ["$center_collected", 0] }},
                "total_admin_collected": {"$sum": { "$ifNull": ["$admin_collected", 0] }}
            }
    })
    
    stats = list(bookings_col.aggregate(pipeline))
    result = []
    
    for s in stats:
        # Resolve Center Name
        c_id = s["_id"]
        center = None
        if isinstance(c_id, int) or (isinstance(c_id, str) and c_id.isdigit()):
            center = centers_col.find_one({"id": int(c_id)})
        
        c_name = center["center_name"] if center else f"ID: {c_id}"
        
        total_collected = (s.get("total_agent_collected", 0) + 
                           s.get("total_center_collected", 0) + 
                           s.get("total_admin_collected", 0))

        result.append({
            "center_name": c_name,
            "total_bookings": s["total_bookings"],
            "total_revenue": s["total_revenue"],
            "paid_count": s["paid_count"],
            "unpaid_count": s["unpaid_count"] + s["partial_count"], 
            "agent_collected": s.get("total_agent_collected", 0),
            "center_collected": s.get("total_center_collected", 0),
            "admin_collected": s.get("total_admin_collected", 0),
            "total_due": s["total_revenue"] - total_collected
        })
    
    return result

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
            "date": b["created_at"],
            "payment_status": b.get("payment_status", "Unpaid"),
            "agent_collected": b.get("agent_collected", 0),
            "center_collected": b.get("center_collected", 0)
        })

    return result
# ================= ADMIN LOGIN =================
@app.post("/admin/login")
def admin_login(data: dict):
    admin = admins_col.find_one({
        "username": data.get("username"),
        "password": data.get("password")
    })

    if not admin:
        raise HTTPException(status_code=401, detail="Invalid credentials")

    return {"status": "success"}
# ================= ADD TEST =================
@app.post("/admin/add_test")
def add_test(data: dict):
    if tests_col.find_one({"test_name": data["test_name"]}):
        raise HTTPException(status_code=400, detail="Test already exists")

    tests_col.insert_one({
        "id": int(time.time()),
        "category_id": data["category_id"],
        "test_name": data["test_name"]
    })
    return {"status": "test added"}

# ================= ADD CENTER =================
@app.post("/admin/add_center")
def add_center(data: dict):
    if centers_col.find_one({"id": data["id"]}):
        raise HTTPException(status_code=400, detail="Center exists")

    centers_col.insert_one({
        "id": data["id"],
        "center_name": data["center_name"],
        "address": data["address"],
        "lat": data.get("lat"),
        "lng": data.get("lng"),
        "timings": data.get("timings", []),
        "enabled": True
    })

    return {"status": "center added"}

# ================= SET PRICE (ASSIGN TEST TO CENTER) =================
@app.post("/admin/set_price")
def set_price(data: dict):
    prices_col.update_one(
        {
            "center_id": int(data["center_id"]),
            "test_id": int(data["test_id"])
        },
        {
            "$set": {
                "price": float(data["price"]),
                "enabled": bool(data.get("enabled", True))
            }
        },
        upsert=True
    )
    return {"status": "price updated"}

# ================= CENTER LOGIN =================
@app.post("/center/login")
def center_login(data: dict):
    user = center_users_col.find_one({
        "username": data.get("username"),
        "password": data.get("password")
    })

    if not user:
        raise HTTPException(status_code=401, detail="Invalid credentials")

    center = centers_col.find_one({"id": user["center_id"]}, {"_id": 0})

    return {
        "center_id": user["center_id"],
        "center_name": center["center_name"] if center else ""
    }

@app.get("/center/bookings")
def center_bookings(center_id: int):
    query = {
        "$or": [
            {"center_id": center_id},
            {"center_id": str(center_id)}
        ]
    }

    # Sort DESC
    bookings = list(bookings_col.find(
        query,
        {"_id": 0, "mobile": 0}
    ).sort("created_at", -1))

    result = []
    for b in bookings:
        test = tests_col.find_one({"id": b.get("test_id")}, {"_id": 0})

        result.append({
            "booking_id": b.get("booking_id"),
            "patient_name": b.get("patient_name"),
            "test_name": test["test_name"] if test else "",
            "price": b.get("price"),
            "status": b.get("status"),
            "created_at": b.get("created_at"),
            "booked_by": b.get("booked_by", "Customer"),
            "payment_status": b.get("payment_status", "Unpaid"),
            "payment_updated_by": b.get("payment_updated_by"),
            "agent_collected": b.get("agent_collected", 0),
            "center_collected": b.get("center_collected", 0)
        })

    return result

@app.get("/agent/bookings")
def agent_bookings(agent_name: str):
    # Sort DESC
    bookings = list(bookings_col.find(
        {"booked_by": agent_name},
        {"_id": 0}
    ).sort("created_at", -1))

    result = []
    for b in bookings:
        test = tests_col.find_one({"id": b.get("test_id")}, {"_id": 0})
        center = centers_col.find_one({"id": b.get("center_id")}, {"_id": 0})

        result.append({
            "booking_id": b.get("booking_id"),
            "patient_name": b.get("patient_name"),
            "mobile": b.get("mobile"),
            "test_name": test["test_name"] if test else "",
            "center_name": center["center_name"] if center else "",
            "price": b.get("price"),
            "status": b.get("status"),
            "created_at": b.get("created_at"),
            "payment_status": b.get("payment_status", "Unpaid"),
            "payment_updated_by": b.get("payment_updated_by"),
            "agent_collected": b.get("agent_collected", 0),
            "center_collected": b.get("center_collected", 0)
        })

    return result

# ================= MARK BOOKING DONE =================
@app.post("/center/mark_done")
def mark_done(data: dict):
    result = bookings_col.update_one(
        {"booking_id": data.get("booking_id")},
        {"$set": {"status": "Done"}}
    )

    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Booking not found")

    return {"status": "updated"}
@app.get("/admin/centers")
def admin_get_centers():
    return list(centers_col.find({}, {"_id": 0}))

@app.get("/admin/tests")
def admin_get_tests():
    return list(tests_col.find({}, {"_id": 0}))

@app.get("/admin/pricing")
def admin_pricing(center_id: int):
    result = []

    tests = list(tests_col.find({}, {"_id": 0}))

    for t in tests:
        price_row = prices_col.find_one(
            {
                "$or": [
                    {"center_id": center_id, "test_id": t.get("id")},
                    {"center_id": str(center_id), "test_id": t.get("id")}
                ]
            },
            {"_id": 0}
        )

        result.append({
            "test_id": t.get("id"),
            "test_name": t.get("test_name", ""),
            "category_id": t.get("category_id"),
            "price": price_row.get("price") if price_row else "",
            "enabled": price_row.get("enabled", False) if price_row else False
        })

    return result



@app.get("/admin/center_users")
def get_center_users():
    return list(center_users_col.find({}, {"_id": 0}))
@app.post("/admin/create_center_user")
def create_center_user(data: dict):
    if center_users_col.find_one({"username": data["username"]}):
        raise HTTPException(status_code=400, detail="Username already exists")

    center_users_col.insert_one({
        "center_id": int(data["center_id"]),
        "username": data["username"],
        "password": data["password"]
    })

    return {"status": "center user created"}

# ================= ADD CATEGORY =================
@app.post("/admin/add_category")
def add_category(data: dict):
    if categories_col.find_one({"name": data["name"]}):
        raise HTTPException(status_code=400, detail="Category exists")

    categories_col.insert_one({
        "id": int(time.time()),
        "name": data["name"]
    })
    return {"status": "category added"}


# ================= GET CATEGORIES =================
@app.get("/admin/categories")
def get_categories():
    return list(categories_col.find({}, {"_id": 0}))

# UPDATE CENTER DETAILS
@app.post("/admin/update_center")
def update_center(data: dict):
    update_data = {
        "center_name": data["center_name"],
        "address": data["address"],
    }

    if "lat" in data and data["lat"] is not None:
        update_data["lat"] = float(data["lat"])

    if "lng" in data and data["lng"] is not None:
        update_data["lng"] = float(data["lng"])

    if "timings" in data:
        update_data["timings"] = data["timings"]

    result = centers_col.update_one(
        {"id": int(data["id"])},
        {"$set": update_data}
    )

    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Center not found")

    return {"status": "center updated"}


@app.post("/admin/update_center_user")
def update_center_user(data: dict):
    result = center_users_col.update_one(
        {"center_id": int(data["center_id"])},
        {"$set": {
            "username": data["username"],
            "password": data["password"]
        }}
    )

    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Center user not found")

    return {"status": "center user updated"}

@app.post("/admin/update_test")
def update_test(data: dict):
    result = tests_col.update_one(
        {"id": int(data["test_id"])},
        {"$set": {"test_name": data["test_name"]}}
    )
    return {"status": "updated"}

@app.post("/admin/toggle_center")
def toggle_center(data: dict):
    result = centers_col.update_one(
        {"id": int(data["center_id"])},
        {"$set": {"enabled": bool(data["enabled"])}}
    )

    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Center not found")

    return {"status": "updated"}


@app.get("/admin/bookings")
def admin_all_bookings():
    # Sort by created_at descending (-1)
    bookings = list(bookings_col.find({}, {"_id": 0}).sort("created_at", -1))

    result = []
    for b in bookings:
        test = tests_col.find_one({"id": b["test_id"]}, {"_id": 0})
        center = centers_col.find_one({"id": b["center_id"]}, {"_id": 0})

        result.append({
            "booking_id": b["booking_id"],
            "patient_name": b["patient_name"],
            "mobile": b["mobile"],
            "test_name": test["test_name"] if test else "",
            "center_name": center["center_name"] if center else "",
            "status": b["status"],
            "created_at": b["created_at"],
            "booked_by": b.get("booked_by", "Customer"),
            "payment_status": b.get("payment_status", "Unpaid"),
            "payment_updated_by": b.get("payment_updated_by"),
            "payment_updated_at": b.get("payment_updated_at"),
            "agent_collected": b.get("agent_collected", 0),
            "center_collected": b.get("center_collected", 0),
            "admin_collected": b.get("admin_collected", 0),
            "price": b.get("price", 0)
        })

    return result


# ================= AGENT SECTION =================

@app.post("/agent/login")
def agent_login(data: dict):
    agent = agents_col.find_one({
        "username": data.get("username"),
        "password": data.get("password")
    })

    if not agent:
        raise HTTPException(status_code=401, detail="Invalid credentials")

    return {
        "agent_id": str(agent["_id"]),
        "agent_name": agent["name"]
    }

@app.post("/center/update_payment_status")
def update_payment(data: dict):
    # This endpoint is used by Center AND Admin
    # Admin or Center can pass "updated_by_name"
    updater_name = data.get("updated_by_name", "Center")
    
    result = bookings_col.update_one(
        {"booking_id": data.get("booking_id")},
        {"$set": {
            "payment_status": data.get("payment_status"),
            "payment_updated_by": updater_name,
            "payment_updated_at": int(time.time())
        }}
    )
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Booking not found")
    return {"status": "updated"}

@app.post("/admin/update_agent")
def update_agent(data: dict):
    # Use username as key for now or pass _id if available
    # Assuming user sends old_username to find and update
    query = {}
    if "id" in data:
        from bson.objectid import ObjectId
        query = {"_id": ObjectId(data["id"])}
    else:
        query = {"username": data["username"]} # Fallback

    update_fields = {
        "name": data["name"],
        "username": data["username"],
        "password": data["password"]
    }
    
    result = agents_col.update_one(query, {"$set": update_fields})
    
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Agent not found")
        
    return {"status": "agent updated"}

@app.get("/admin/agents")
def get_agents():
    agents = list(agents_col.find({}, {"password": 0})) 
    for a in agents:
        a["id"] = str(a["_id"])
        del a["_id"]
    return agents
@app.post("/admin/add_agent")
def add_agent(data: dict):
    if agents_col.find_one({"username": data["username"]}):
        raise HTTPException(status_code=400, detail="Agent exists")

    agents_col.insert_one({
        "name": data["name"],
        "username": data["username"],
        "password": data["password"],
        "created_at": int(time.time())
    })
    return {"status": "agent added"}
