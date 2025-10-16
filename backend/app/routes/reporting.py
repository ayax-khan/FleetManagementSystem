"""
Fleet Management System - Reporting API Routes
Summary Detail report combining trips, vehicles, drivers
"""

from fastapi import APIRouter, HTTPException, Depends, Request, Query
from typing import List, Optional
from datetime import datetime

from app.database.hive_manager import HiveManager

router = APIRouter()

def get_hive_manager(request: Request) -> HiveManager:
    return request.app.state.hive_manager

@router.get("/summary-detail")
async def summary_detail_report(
    start_date: Optional[str] = Query(None, description="ISO date or datetime start filter"),
    end_date: Optional[str] = Query(None, description="ISO date or datetime end filter"),
    vehicle_id: Optional[str] = None,
    driver_id: Optional[str] = None,
    hive: HiveManager = Depends(get_hive_manager)
):
    """Return rows for the Summary Detail report.

    Headings:
    Sr.No, Date, Vehic Reg No, Officer/Staff, Destination, Time Out, Meter Out,
    Time IN, Meter IN, KMs, Ave, Ltrs, Driver Name, CoEs, Duty Detail
    """
    try:
        trips = await hive.find_all("trips")
        vehicles = {v["id"]: v for v in await hive.find_all("vehicles")}
        drivers = {d["id"]: d for d in await hive.find_all("drivers")}

        def parse_dt(v):
            try:
                return datetime.fromisoformat(v) if isinstance(v, str) else None
            except Exception:
                return None

        # Filters
        if vehicle_id:
            trips = [t for t in trips if t.get("vehicle_id") == vehicle_id]
        if driver_id:
            trips = [t for t in trips if t.get("driver_id") == driver_id]
        if start_date:
            sd = parse_dt(start_date)
            if sd:
                trips = [t for t in trips if (parse_dt(t.get("start_time")) or sd) >= sd]
        if end_date:
            ed = parse_dt(end_date)
            if ed:
                trips = [t for t in trips if (parse_dt(t.get("end_time")) or ed) <= ed]

        # Sort by start_time
        trips.sort(key=lambda t: t.get("start_time", ""))

        rows: List[dict] = []
        for idx, trip in enumerate(trips, start=1):
            veh = vehicles.get(trip.get("vehicle_id"), {})
            drv = drivers.get(trip.get("driver_id"), {})

            start_km = trip.get("start_km") or 0
            end_km = trip.get("end_km") or 0
            kms = max(0, (end_km - start_km) if end_km is not None else 0)
            ltrs = trip.get("fuel_used") or 0
            ave = (kms / ltrs) if ltrs else 0

            row = {
                "Sr.No": idx,
                "Date": (trip.get("start_time") or "").split("T")[0],
                "Vehic Reg No": veh.get("registration_number") or "",
                "Officer/Staff": trip.get("officer_staff") or "",
                "Destination": trip.get("destination") or (trip.get("route") or ""),
                "Time Out": trip.get("start_time") or "",
                "Meter Out": start_km,
                "Time IN": trip.get("end_time") or "",
                "Meter IN": end_km if end_km is not None else "",
                "KMs": kms,
                "Ave": round(ave, 2),
                "Ltrs": ltrs,
                "Driver Name": drv.get("name") or "",
                "CoEs": trip.get("coes") or "",
                "Duty Detail": trip.get("duty_detail") or "",
            }
            rows.append(row)

        return {
            "success": True,
            "message": f"Generated {len(rows)} rows",
            "headings": [
                "Sr.No","Date","Vehic Reg No","Officer/Staff","Destination","Time Out",
                "Meter Out","Time IN","Meter IN","KMs","Ave","Ltrs","Driver Name",
                "CoEs","Duty Detail"
            ],
            "rows": rows,
            "total": len(rows)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/fuel-pol")
async def fuel_pol_report(
    vehicle_id: Optional[str] = None,
    month: Optional[str] = Query(None, description="YYYY-MM"),
    fuel_type: Optional[str] = None,
    station: Optional[str] = None,
    hive: HiveManager = Depends(get_hive_manager)
):
    """Fuel/POL report with per-vehicle consumption and cost analysis."""
    try:
        fuels = await hive.find_all("fuel_entries")
        vehicles = {v["id"]: v for v in await hive.find_all("vehicles")}
        trips = await hive.find_all("trips")

        def yyyymm(dstr: str) -> str:
            try:
                return (datetime.fromisoformat(dstr) if 'T' in dstr else datetime.fromisoformat(dstr + 'T00:00:00')).strftime('%Y-%m')
            except Exception:
                try:
                    return datetime.fromisoformat(dstr).strftime('%Y-%m')
                except Exception:
                    return ''

        # Apply filters
        if vehicle_id:
            fuels = [f for f in fuels if f.get("vehicle_id") == vehicle_id]
        if fuel_type:
            fuels = [f for f in fuels if (f.get("fuel_type") or '').lower() == fuel_type.lower()]
        if station:
            fuels = [f for f in fuels if (f.get("station") or '').lower() == station.lower()]
        if month:
            fuels = [f for f in fuels if yyyymm(f.get("date", "")) == month]

        # Sort by vehicle then date
        fuels.sort(key=lambda f: (f.get("vehicle_id", ''), f.get("date", '')))

        # Pre-index trips by vehicle for linked_job_id (best-effort)
        trips_by_vehicle = {}
        for t in trips:
            trips_by_vehicle.setdefault(t.get("vehicle_id"), []).append(t)
        for v in trips_by_vehicle:
            trips_by_vehicle[v].sort(key=lambda t: t.get("start_time", ''))

        def find_linked_trip_id(vid: str, fdate: str) -> Optional[str]:
            lst = trips_by_vehicle.get(vid, [])
            if not lst:
                return None
            try:
                fd = datetime.fromisoformat(fdate) if 'T' in fdate else datetime.fromisoformat(fdate + 'T00:00:00')
            except Exception:
                return None
            # choose nearest by time same day
            same_day = [t for t in lst if (t.get("start_time") or '').split('T')[0] == fd.strftime('%Y-%m-%d')]
            if not same_day:
                return None
            same_day.sort(key=lambda t: abs((datetime.fromisoformat(t.get("start_time")) - fd).total_seconds()) if t.get("start_time") else 1e18)
            return same_day[0].get("id")

        # Compute km_used per fuel entry using odometer deltas per vehicle
        rows = []
        monthly = {}
        vehicle_eff = {}

        # Group by vehicle
        from itertools import groupby
        for vid, group in groupby(fuels, key=lambda f: f.get("vehicle_id")):
            veh_rows = list(group)
            prev_odo = None
            for f in veh_rows:
                liters = float(f.get("liters", 0) or 0)
                cost = float(f.get("cost", 0) or 0)
                odo = float(f.get("odometer", 0) or 0)
                rate = (cost / liters) if liters else 0
                km_used = max(0.0, (odo - prev_odo)) if (prev_odo is not None) else 0.0
                prev_odo = odo

                reg = vehicles.get(vid, {}).get("registration_number") or ''
                d = f.get("date", '')
                link_id = find_linked_trip_id(vid, d)

                rows.append({
                    "vehicle_reg": reg,
                    "date": d,
                    "fuel_type": f.get("fuel_type") or '',
                    "litres": round(liters, 2),
                    "rate": round(rate, 2),
                    "amount": round(cost, 2),
                    "odometer": odo,
                    "linked_job_id": link_id or '',
                    "km_used": round(km_used, 2),
                    "vehicle_id": vid,
                })

                mm = yyyymm(d)
                mrec = monthly.setdefault(mm, {"litres": 0.0, "amount": 0.0, "km_used": 0.0})
                mrec["litres"] += liters
                mrec["amount"] += cost
                mrec["km_used"] += km_used

                ve = vehicle_eff.setdefault(vid, {"km_used": 0.0, "litres": 0.0, "reg": reg})
                ve["km_used"] += km_used
                ve["litres"] += liters

        # Aggregates and charts
        monthly_list = []
        for mm, rec in sorted(monthly.items()):
            litres = rec["litres"]
            amount = rec["amount"]
            kmu = rec["km_used"]
            avg_rate = (amount / litres) if litres else 0
            km_per_litre = (kmu / litres) if litres else 0
            cost_per_km = (amount / kmu) if kmu else 0
            monthly_list.append({
                "month": mm,
                "litres": round(litres, 2),
                "amount": round(amount, 2),
                "avg_rate": round(avg_rate, 2),
                "km_per_litre": round(km_per_litre, 2),
                "cost_per_km": round(cost_per_km, 2),
            })

        totals = {
            "litres": round(sum(r.get("litres", 0) for r in rows), 2),
            "amount": round(sum(r.get("amount", 0) for r in rows), 2),
        }
        totals_l = sum(r.get("litres", 0) for r in rows)
        totals_km = sum(r.get("km_used", 0) for r in rows)
        totals["avg_rate"] = round((totals["amount"] / totals_l) if totals_l else 0, 2)
        totals["km_per_litre"] = round((totals_km / totals_l) if totals_l else 0, 2)
        totals["cost_per_km"] = round((totals["amount"] / totals_km) if totals_km else 0, 2)

        efficiency_scatter = []
        for vid, rec in vehicle_eff.items():
            litres = rec["litres"]
            kmu = rec["km_used"]
            efficiency_scatter.append({
                "vehicle_id": vid,
                "vehicle_reg": rec["reg"],
                "km_per_litre": round((kmu / litres) if litres else 0, 2)
            })

        return {
            "success": True,
            "message": f"Generated {len(rows)} fuel rows",
            "headings": ["vehicle_reg","date","fuel_type","litres","rate","amount","odometer","linked_job_id"],
            "rows": rows,
            "aggregates": {
                "monthly": monthly_list,
                "totals": totals
            },
            "charts": {
                "monthly_litres": [{"x": m["month"], "y": m["litres"]} for m in monthly_list],
                "monthly_cost_per_km": [{"x": m["month"], "y": m["cost_per_km"]} for m in monthly_list],
                "efficiency_scatter": efficiency_scatter
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
