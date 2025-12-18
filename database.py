from pymongo import MongoClient
import os

MONGO_URL = os.getenv("MONGO_URL")

if not MONGO_URL:
    raise Exception("MONGO_URL not set")

client = MongoClient(MONGO_URL)
db = client["se_booking"]

# USER SIDE
tests_col = db["tests"]
centers_col = db["centers"]
prices_col = db["prices"]
bookings_col = db["bookings"]

# ADMIN & CENTER AUTH
admins_col = db["admins"]            # ✅ REQUIRED
center_users_col = db["center_users"] # ✅ REQUIRED
