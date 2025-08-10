import os
import json
import sys

import pytest


# Configure the database to use a temporary SQLite file for testing. This
# needs to happen before importing the application modules so that the
# SQLAlchemy engine picks up the correct URL.
os.environ["DATABASE_URL"] = "sqlite:///./test.db"

# Ensure the backend package can be imported when tests are executed from
# the repository root.
sys.path.append(os.path.dirname(os.path.dirname(__file__)))

from database import create_tables, SessionLocal  # noqa: E402
from models import (
    DPRCreate,
    DPRUpdate,
    HouseholdMember,
    MPRCreate,
    MPRUpdate,
    PurchaseItem,
)
import crud  # noqa: E402


@pytest.fixture(scope="module", autouse=True)
def setup_database():
    """Prepare the SQLite database for all tests in this module."""

    # Ensure a clean database before any tests run. The file is left in
    # place afterwards to keep the SQLite connection valid throughout the
    # test module.
    if os.path.exists("test.db"):
        os.remove("test.db")

    create_tables()
    yield


def test_update_dpr_accepts_plain_dicts():
    db = SessionLocal()

    member = HouseholdMember(
        name="Alice",
        relationship_with_head="self",
        gender="F",
        age=30,
        education="College",
        occupation="Engineer",
        annual_income_job=50000,
        annual_income_other=0,
        other_income_source="None",
        total_income=50000,
    )

    dpr_create = DPRCreate(
        name_and_address="123 Street",
        district="District",
        state="State",
        family_size=4,
        income_group="Middle",
        centre_code="C001",
        return_no="R001",
        month_and_year="2024-01",
        household_members=[member],
        latitude=12.0,
        longitude=77.0,
        otp_code="1234",
    )

    dpr = crud.create_dpr(db, dpr_create)

    update_model = DPRUpdate(**dpr_create.dict())
    update_dict = update_model.dict()
    update_dict["family_size"] = 5
    updated = crud.update_dpr(db, dpr.id, update_dict)

    stored_members = json.loads(updated.household_members)
    assert stored_members[0]["name"] == "Alice"
    assert updated.family_size == 5

    db.close()


def test_update_mpr_accepts_plain_dicts():
    db = SessionLocal()

    item = PurchaseItem(
        item_name="Shirt",
        item_code="S001",
        month_of_purchase="2024-01",
        fibre_code="F001",
        sector_of_manufacture_code="SMC",
        colour_design_code="CDC",
        person_age_gender="30M",
        type_of_shop_code="TSC",
        purchase_type_code="PTC",
        dress_intended_code="DIC",
        length_in_meters=1.0,
        price_per_meter=10.0,
        total_amount_paid=10.0,
        brand_mill_name="Brand",
        is_imported=False,
    )

    mpr_create = MPRCreate(
        name_and_address="123 Street",
        district_state_tel="District, State, 1234567890",
        panel_centre="Centre",
        centre_code="C001",
        return_no="R001",
        family_size=4,
        income_group="Middle",
        month_and_year="2024-01",
        occupation_of_head="Engineer",
        items=[item],
        latitude=12.0,
        longitude=77.0,
        otp_code="1234",
    )

    mpr = crud.create_mpr(db, mpr_create)

    update_model = MPRUpdate(**mpr_create.dict())
    update_dict = update_model.dict()
    update_dict["income_group"] = "High"
    updated = crud.update_mpr(db, mpr.id, update_dict)

    stored_items = json.loads(updated.items)
    assert stored_items[0]["item_name"] == "Shirt"
    assert updated.income_group == "High"

    db.close()

