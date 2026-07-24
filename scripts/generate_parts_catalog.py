#!/usr/bin/env python3
"""Generate parts_catalog.json and reorganize assets/sub/ images."""

from __future__ import annotations

import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SUB_DIR = ROOT / "assets" / "sub"
OUT_JSON = ROOT / "assets" / "data" / "parts_catalog.json"

# Existing image files -> (category_folder, slug, display name)
IMAGE_MAP = {
    "file_000000000d158820bb5be0500eb79a006.png": (
        "transmission",
        "parallel_hybrid_transmission",
        "Parallel Hybrid Transmission",
    ),
    "file_00000000b454820b8bf39ba917052c11.png": (
        "transmission",
        "parallel_hybrid_transmission_alt",
        "Parallel Hybrid Transmission",
    ),
    "file_0000000006ea0820bade761cb5fed2ee8.png": (
        "transmission",
        "series_hybrid_transmission",
        "Series Hybrid Transmission",
    ),
    "file_0000000065ec82099f0df3b51ff16f50.png": (
        "transmission",
        "hybrid_dct",
        "Hybrid DCT (Dual-Clutch Hybrid)",
    ),
    "file_00000000b8c8820b9d95a252fdaaafb3.png": (
        "transmission",
        "hybrid_dct_alt",
        "Hybrid DCT",
    ),
    "file_000000000c99481fa8dd0cf4d285355f3.png": (
        "transmission",
        "hybrid_at",
        "Hybrid AT",
    ),
    "file_000000002b5871f795a24175b4615c1f.png": (
        "transmission",
        "p2_hybrid_transmission",
        "P2 Hybrid Transmission",
    ),
    "file_00000000620c722f9a8930dbc977dc31.png": (
        "transmission",
        "multi_mode_hybrid_transmission",
        "Multi-Mode Hybrid Transmission",
    ),
    "file_000000007e58720cbbb5e5fb885d5ae8.png": (
        "transmission",
        "in_wheel_motor_drive",
        "In-Wheel Motor Drive",
    ),
    "file_0000000026a871f587a4a4915c96ec2d.png": (
        "transmission",
        "hub_motor_drive",
        "Hub Motor Drive",
    ),
    "file_000000006f5471f5b80318eeab2946ee.png": (
        "transmission",
        "direct_drive_ev_transmission",
        "Direct Drive EV Transmission (Gearless)",
    ),
    "file_0000000005c471f5819c780c70edccd1.png": (
        "transmission",
        "power_split_ev_drive_system",
        "Power-Split EV Drive System",
    ),
    "file_00000000b0288206baf5140331f49a3e.png": (
        "transmission",
        "torque_vectoring_ev_drive_system",
        "Torque Vectoring EV Drive System",
    ),
    "file_00000000cdd0820badb6ca703489f942.png": (
        "transmission",
        "e_cvt_power_split_hybrid",
        "E-CVT (Power Split Hybrid Transmission)",
    ),
    "file_000000003b3471f5b86c02cba1fa4d84.png": (
        "transmission",
        "parallel_axis_axle",
        "Parallel-Axis e-Axle",
    ),
    "file_0000000059d0720c97abfa7f4bab9340.png": (
        "transmission",
        "planetary_gear_ev_transmission",
        "Planetary Gear EV Transmission",
    ),
    "file_000000000e52c720cb24ef4472cda80e3.png": (
        "transmission",
        "dual_motor_ev_transmission",
        "Dual Motor EV Transmission",
    ),
    "file_00000000c294720d94034f761822cc10.png": (
        "transmission",
        "tri_motor_ev_transmission",
        "Tri-Motor EV Transmission",
    ),
    "file_000000005c20722f8dddefde225f3cb2.png": (
        "transmission",
        "quad_motor_ev_transmission",
        "Quad-Motor EV Transmission",
    ),
    "file_00000000882c71f794330a898f4180c8.png": (
        "transmission",
        "integrated_e_axle_drive_unit",
        "Integrated e-Axle Drive Unit",
    ),
    "file_0000000006c871f6be7624e8a999a41a.png": (
        "transmission",
        "multi_speed_ev_transmission",
        "Multi-Speed EV Transmission",
    ),
    "1784285330175.png": (
        "transmission",
        "multi_speed_ev_transmission_alt",
        "Multi-Speed EV Transmission",
    ),
    "file_00000000cb5471f79c7bcdbad702bde9.png": (
        "transmission",
        "single_speed_reduction_gear",
        "Single-Speed Reduction Gear",
    ),
    "1784284694983.png": (
        "transmission",
        "single_speed_reduction_gear_alt",
        "Single-Speed Reduction Gear",
    ),
}

# slug -> image path after rename (primary images only, alt duplicates skipped in catalog)
PRIMARY_IMAGE_BY_SLUG: dict[str, str] = {}


def slugify(text: str) -> str:
    return (
        text.lower()
        .replace("&", "and")
        .replace("/", "_")
        .replace("-", "_")
        .replace("(", "")
        .replace(")", "")
        .replace(".", "")
        .replace(",", "")
        .replace("'", "")
        .replace(" ", "_")
        .replace("__", "_")
        .strip("_")
    )


def sub(name: str, group: str, image_slug: str | None = None) -> dict:
    sid = slugify(name)
    image = PRIMARY_IMAGE_BY_SLUG.get(image_slug or sid)
    entry = {"id": sid, "name": name, "group": group}
    if image:
        entry["image"] = image
    return entry


def build_catalog() -> dict:
    categories = []

    def cat(name: str, cid: str, groups: list[tuple[str, list[dict]]]) -> dict:
        subs: list[dict] = []
        for group_name, items in groups:
            subs.extend(items)
        return {"id": cid, "name": name, "subcategories": subs}

    categories.append(
        cat(
            "Engine",
            "engine",
            [
                (
                    "Engine Block Components",
                    [
                        sub("Engine Block", "Engine Block Components"),
                        sub("Cylinder Head", "Engine Block Components"),
                        sub("Head Gasket", "Engine Block Components"),
                        sub("Oil Pan (Sump)", "Engine Block Components"),
                        sub("Engine Mount", "Engine Block Components"),
                        sub("Engine Cover", "Engine Block Components"),
                    ],
                ),
                (
                    "Crankshaft Assembly",
                    [
                        sub("Crankshaft", "Crankshaft Assembly"),
                        sub("Main Bearings", "Crankshaft Assembly"),
                        sub("Connecting Rod", "Crankshaft Assembly"),
                        sub("Connecting Rod Bearings", "Crankshaft Assembly"),
                        sub("Pistons", "Crankshaft Assembly"),
                        sub("Piston Rings", "Crankshaft Assembly"),
                        sub("Piston Pin", "Crankshaft Assembly"),
                        sub("Flywheel / Flexplate", "Crankshaft Assembly"),
                        sub("Harmonic Balancer", "Crankshaft Assembly"),
                    ],
                ),
                (
                    "Valve Train",
                    [
                        sub("Camshaft", "Valve Train"),
                        sub("Cam Gear", "Valve Train"),
                        sub("Rocker Arm", "Valve Train"),
                        sub("Valve", "Valve Train"),
                        sub("Valve Spring", "Valve Train"),
                        sub("Valve Guide", "Valve Train"),
                        sub("Valve Seat", "Valve Train"),
                        sub("Hydraulic Lifter / Tappet", "Valve Train"),
                        sub("Push Rod", "Valve Train"),
                    ],
                ),
                (
                    "Timing System",
                    [
                        sub("Timing Chain", "Timing System"),
                        sub("Timing Belt", "Timing System"),
                        sub("Timing Gears", "Timing System"),
                        sub("Timing Tensioner", "Timing System"),
                        sub("Timing Guide", "Timing System"),
                        sub("Idler Pulley", "Timing System"),
                    ],
                ),
                (
                    "Lubrication System",
                    [
                        sub("Oil Pump", "Lubrication System"),
                        sub("Oil Pickup", "Lubrication System"),
                        sub("Oil Filter Housing", "Lubrication System"),
                        sub("Oil Cooler", "Lubrication System"),
                        sub("Oil Pressure Sensor", "Lubrication System"),
                        sub("Dipstick", "Lubrication System"),
                        sub("PCV Valve", "Lubrication System"),
                        sub("Oil Filter", "Lubrication System"),
                    ],
                ),
                (
                    "Cooling System",
                    [
                        sub("Water Pump", "Cooling System"),
                        sub("Thermostat", "Cooling System"),
                        sub("Radiator", "Cooling System"),
                        sub("Cooling Fan", "Cooling System"),
                        sub("Fan Clutch", "Cooling System"),
                        sub("Expansion Tank", "Cooling System"),
                        sub("Coolant Pipes & Hoses", "Cooling System"),
                    ],
                ),
                (
                    "Air Intake System",
                    [
                        sub("Air Filter", "Air Intake System"),
                        sub("Air Filter Box", "Air Intake System"),
                        sub("Intake Manifold", "Air Intake System"),
                        sub("Throttle Body (Petrol)", "Air Intake System"),
                        sub("Intercooler (Turbo)", "Air Intake System"),
                        sub("Turbo Hose", "Air Intake System"),
                    ],
                ),
                (
                    "Fuel System (Petrol)",
                    [
                        sub("Fuel Pump", "Fuel System (Petrol)"),
                        sub("Fuel Filter", "Fuel System (Petrol)"),
                        sub("Fuel Rail", "Fuel System (Petrol)"),
                        sub("Petrol Injectors", "Fuel System (Petrol)"),
                        sub("Pressure Regulator", "Fuel System (Petrol)"),
                        sub("EVAP Canister", "Fuel System (Petrol)"),
                        sub("Purge Valve", "Fuel System (Petrol)"),
                    ],
                ),
                (
                    "Fuel System (Diesel)",
                    [
                        sub("High Pressure Pump", "Fuel System (Diesel)"),
                        sub("Common Rail", "Fuel System (Diesel)"),
                        sub("Diesel Injectors", "Fuel System (Diesel)"),
                        sub("SCV Valve", "Fuel System (Diesel)"),
                        sub("DRV Valve", "Fuel System (Diesel)"),
                        sub("Fuel Filter", "Fuel System (Diesel)"),
                        sub("Primer Pump", "Fuel System (Diesel)"),
                        sub("Water Separator", "Fuel System (Diesel)"),
                    ],
                ),
                (
                    "Ignition System (Petrol)",
                    [
                        sub("Spark Plug", "Ignition System (Petrol)"),
                        sub("Ignition Coil", "Ignition System (Petrol)"),
                        sub("HT Lead", "Ignition System (Petrol)"),
                        sub("Distributor (Old Models)", "Ignition System (Petrol)"),
                    ],
                ),
                (
                    "Diesel Combustion",
                    [
                        sub("Glow Plug", "Diesel Combustion"),
                        sub("Glow Plug Relay", "Diesel Combustion"),
                    ],
                ),
                (
                    "Turbo System",
                    [
                        sub("Turbocharger", "Turbo System"),
                        sub("Wastegate", "Turbo System"),
                        sub("VGT Actuator", "Turbo System"),
                        sub("Boost Pipe", "Turbo System"),
                        sub("Intercooler", "Turbo System"),
                        sub("Turbo Hose", "Turbo System"),
                    ],
                ),
                (
                    "Exhaust & Emission",
                    [
                        sub("Exhaust Manifold", "Exhaust & Emission"),
                        sub("Catalytic Converter", "Exhaust & Emission"),
                        sub("DPF (Diesel Particulate Filter)", "Exhaust & Emission"),
                        sub("EGR Valve", "Exhaust & Emission"),
                        sub("EGR Cooler", "Exhaust & Emission"),
                        sub("SCR (Selective Catalytic Reduction)", "Exhaust & Emission"),
                        sub("AdBlue Injector", "Exhaust & Emission"),
                        sub("Oxygen Sensor", "Exhaust & Emission"),
                        sub("NOx Sensor", "Exhaust & Emission"),
                    ],
                ),
                (
                    "Engine Sensors",
                    [
                        sub("Crankshaft Position Sensor", "Engine Sensors"),
                        sub("Camshaft Position Sensor", "Engine Sensors"),
                        sub("MAP Sensor", "Engine Sensors"),
                        sub("MAF Sensor", "Engine Sensors"),
                        sub("Knock Sensor", "Engine Sensors"),
                        sub("Coolant Temp. Sensor", "Engine Sensors"),
                        sub("Intake Air Temp. Sensor", "Engine Sensors"),
                        sub("Oil Pressure Sensor", "Engine Sensors"),
                        sub("Oil Level Sensor", "Engine Sensors"),
                        sub("Fuel Rail Pressure Sensor", "Engine Sensors"),
                        sub("Boost Pressure Sensor", "Engine Sensors"),
                        sub("Exhaust Temp. Sensor", "Engine Sensors"),
                    ],
                ),
                (
                    "Engine Electrical",
                    [
                        sub("ECU (Engine Control Unit)", "Engine Electrical"),
                        sub("Engine Wiring Harness", "Engine Electrical"),
                        sub("Relays", "Engine Electrical"),
                        sub("Fuses", "Engine Electrical"),
                        sub("Connectors", "Engine Electrical"),
                    ],
                ),
                (
                    "Gaskets & Seals",
                    [
                        sub("Full Gasket Kit", "Gaskets & Seals"),
                        sub("Oil Seals", "Gaskets & Seals"),
                        sub("O-Rings", "Gaskets & Seals"),
                        sub("Crankshaft Seal", "Gaskets & Seals"),
                        sub("Camshaft Seal", "Gaskets & Seals"),
                        sub("Valve Cover Gasket", "Gaskets & Seals"),
                        sub("Intake Gasket", "Gaskets & Seals"),
                        sub("Exhaust Gasket", "Gaskets & Seals"),
                    ],
                ),
                (
                    "Repair Kits",
                    [
                        sub("Engine Overhaul Kit", "Repair Kits"),
                        sub("Engine Rebuild Kit", "Repair Kits"),
                        sub("Bearing Kit", "Repair Kits"),
                        sub("Piston Kit", "Repair Kits"),
                        sub("Timing Kit", "Repair Kits"),
                        sub("Seal Kit", "Repair Kits"),
                    ],
                ),
            ],
        )
    )

    categories.append(
        cat(
            "Transmission",
            "transmission",
            [
                (
                    "Manual Transmission (MT)",
                    [
                        sub("Clutch Kit", "Manual Transmission (MT)"),
                        sub("Flywheel", "Manual Transmission (MT)"),
                        sub("Gearbox Housing", "Manual Transmission (MT)"),
                        sub("Input Shaft", "Manual Transmission (MT)"),
                        sub("Output Shaft", "Manual Transmission (MT)"),
                        sub("Counter Shaft", "Manual Transmission (MT)"),
                        sub("Gears", "Manual Transmission (MT)"),
                        sub("Synchronizer Assembly", "Manual Transmission (MT)"),
                        sub("Shift Fork", "Manual Transmission (MT)"),
                        sub("Shift Rail", "Manual Transmission (MT)"),
                        sub("Gear Lever", "Manual Transmission (MT)"),
                        sub("Extension Housing", "Manual Transmission (MT)"),
                    ],
                ),
                (
                    "Automatic Transmission (AT)",
                    [
                        sub("Torque Converter", "Automatic Transmission (AT)"),
                        sub("Transmission Case", "Automatic Transmission (AT)"),
                        sub("Planetary Gear Set", "Automatic Transmission (AT)"),
                        sub("Valve Body", "Automatic Transmission (AT)"),
                        sub("Solenoid Pack", "Automatic Transmission (AT)"),
                        sub("Clutch Pack", "Automatic Transmission (AT)"),
                        sub("Brake Band", "Automatic Transmission (AT)"),
                        sub("Overrunning Clutch", "Automatic Transmission (AT)"),
                        sub("Transmission Filter", "Automatic Transmission (AT)"),
                        sub("Transmission Oil Pan", "Automatic Transmission (AT)"),
                        sub("Transmission Cooler", "Automatic Transmission (AT)"),
                        sub("Speed Sensor", "Automatic Transmission (AT)"),
                    ],
                ),
                (
                    "Dual Clutch Transmission (DCT)",
                    [
                        sub("Dual Clutch Pack", "Dual Clutch Transmission (DCT)"),
                        sub("Mechatronic Unit", "Dual Clutch Transmission (DCT)"),
                        sub("DCT Housing", "Dual Clutch Transmission (DCT)"),
                        sub("DCT Actuator", "Dual Clutch Transmission (DCT)"),
                        sub("DCT Control Module", "Dual Clutch Transmission (DCT)"),
                    ],
                ),
                (
                    "Continuously Variable Transmission (CVT)",
                    [
                        sub("Drive Pulley", "Continuously Variable Transmission (CVT)"),
                        sub("Driven Pulley", "Continuously Variable Transmission (CVT)"),
                        sub("V-Belt / Chain", "Continuously Variable Transmission (CVT)"),
                        sub("CVT Step Motor", "Continuously Variable Transmission (CVT)"),
                        sub("CVT Valve Body", "Continuously Variable Transmission (CVT)"),
                    ],
                ),
                (
                    "Automated Manual Transmission (AMT)",
                    [
                        sub("Clutch Actuator", "Automated Manual Transmission (AMT)"),
                        sub("Gear Actuator", "Automated Manual Transmission (AMT)"),
                        sub("AMT Control Module", "Automated Manual Transmission (AMT)"),
                        sub("Position Sensor", "Automated Manual Transmission (AMT)"),
                    ],
                ),
                (
                    "Hybrid Transmissions",
                    [
                        sub(
                            "Parallel Hybrid Transmission",
                            "Hybrid Transmissions",
                            "parallel_hybrid_transmission",
                        ),
                        sub(
                            "Series Hybrid Transmission",
                            "Hybrid Transmissions",
                            "series_hybrid_transmission",
                        ),
                        sub(
                            "P2 Hybrid Transmission",
                            "Hybrid Transmissions",
                            "p2_hybrid_transmission",
                        ),
                        sub(
                            "Hybrid DCT (Dual-Clutch Hybrid)",
                            "Hybrid Transmissions",
                            "hybrid_dct",
                        ),
                        sub("Hybrid AT", "Hybrid Transmissions", "hybrid_at"),
                        sub(
                            "Multi-Mode Hybrid Transmission",
                            "Hybrid Transmissions",
                            "multi_mode_hybrid_transmission",
                        ),
                        sub(
                            "E-CVT (Power Split Hybrid Transmission)",
                            "Hybrid Transmissions",
                            "e_cvt_power_split_hybrid",
                        ),
                        sub(
                            "Hybrid Transmission (e-CVT / Power Split)",
                            "Hybrid Transmissions",
                        ),
                    ],
                ),
                (
                    "Electric Vehicle Drive Systems",
                    [
                        sub(
                            "Single-Speed Reduction Gear",
                            "Electric Vehicle Drive Systems",
                            "single_speed_reduction_gear",
                        ),
                        sub(
                            "Multi-Speed EV Transmission",
                            "Electric Vehicle Drive Systems",
                            "multi_speed_ev_transmission",
                        ),
                        sub(
                            "Two-Speed EV Transmission",
                            "Electric Vehicle Drive Systems",
                        ),
                        sub(
                            "Direct Drive EV Transmission (Gearless)",
                            "Electric Vehicle Drive Systems",
                            "direct_drive_ev_transmission",
                        ),
                        sub(
                            "Planetary Gear EV Transmission",
                            "Electric Vehicle Drive Systems",
                            "planetary_gear_ev_transmission",
                        ),
                        sub(
                            "Integrated e-Axle Drive Unit",
                            "Electric Vehicle Drive Systems",
                            "integrated_e_axle_drive_unit",
                        ),
                        sub(
                            "Coaxial e-Axle",
                            "Electric Vehicle Drive Systems",
                        ),
                        sub(
                            "Parallel-Axis e-Axle",
                            "Electric Vehicle Drive Systems",
                            "parallel_axis_axle",
                        ),
                        sub(
                            "Dual Motor EV Transmission",
                            "Electric Vehicle Drive Systems",
                            "dual_motor_ev_transmission",
                        ),
                        sub(
                            "Tri-Motor EV Transmission",
                            "Electric Vehicle Drive Systems",
                            "tri_motor_ev_transmission",
                        ),
                        sub(
                            "Quad-Motor EV Transmission",
                            "Electric Vehicle Drive Systems",
                            "quad_motor_ev_transmission",
                        ),
                        sub(
                            "In-Wheel Motor Drive",
                            "Electric Vehicle Drive Systems",
                            "in_wheel_motor_drive",
                        ),
                        sub(
                            "Hub Motor Drive",
                            "Electric Vehicle Drive Systems",
                            "hub_motor_drive",
                        ),
                        sub(
                            "Power-Split EV Drive System",
                            "Electric Vehicle Drive Systems",
                            "power_split_ev_drive_system",
                        ),
                        sub(
                            "Torque Vectoring EV Drive System",
                            "Electric Vehicle Drive Systems",
                            "torque_vectoring_ev_drive_system",
                        ),
                        sub("Electric Drive Motor", "Electric Vehicle Drive Systems"),
                        sub("Reduction Gear Set", "Electric Vehicle Drive Systems"),
                        sub("Inverter", "Electric Vehicle Drive Systems"),
                        sub("Differential Gear", "Electric Vehicle Drive Systems"),
                    ],
                ),
                (
                    "Other Transmission Types",
                    [
                        sub("Intelligent Variable Transmission (IVT)", "Other Transmission Types"),
                        sub("Hydrostatic Transmission (HST)", "Other Transmission Types"),
                        sub("Powershift Transmission (PST)", "Other Transmission Types"),
                        sub("Synchromesh Transmission", "Other Transmission Types"),
                        sub("Dog Clutch Transmission", "Other Transmission Types"),
                        sub("Sequential Transmission (Dog Box)", "Other Transmission Types"),
                        sub("Direct Drive Transmission", "Other Transmission Types"),
                    ],
                ),
                (
                    "Common Transmission Components",
                    [
                        sub("Bearings", "Common Transmission Components"),
                        sub("Bushings", "Common Transmission Components"),
                        sub("Oil Pump", "Common Transmission Components"),
                        sub("Oil Cooler", "Common Transmission Components"),
                        sub("Shafts", "Common Transmission Components"),
                        sub("Seals & Gaskets", "Common Transmission Components"),
                        sub("Transmission Mount", "Common Transmission Components"),
                        sub("Wiring Harness", "Common Transmission Components"),
                        sub("Control Module", "Common Transmission Components"),
                    ],
                ),
            ],
        )
    )

    categories.append(
        cat(
            "AC System",
            "ac_system",
            [
                (
                    "Major A/C System Components",
                    [
                        sub("Compressor", "Major A/C System Components"),
                        sub("Condenser", "Major A/C System Components"),
                        sub("Evaporator", "Major A/C System Components"),
                        sub("Receiver Drier / Accumulator", "Major A/C System Components"),
                        sub("Expansion Valve (TXV)", "Major A/C System Components"),
                        sub("Orifice Tube", "Major A/C System Components"),
                        sub("A/C Hoses & Pipes", "Major A/C System Components"),
                    ],
                ),
                (
                    "Compressor Parts",
                    [
                        sub("Compressor Clutch", "Compressor Parts"),
                        sub("Pulley", "Compressor Parts"),
                        sub("Clutch Coil", "Compressor Parts"),
                        sub("Compressor Shaft", "Compressor Parts"),
                        sub("Swash Plate", "Compressor Parts"),
                        sub("Valve Plate", "Compressor Parts"),
                    ],
                ),
                (
                    "Condenser Components",
                    [
                        sub("Condenser Coil", "Condenser Components"),
                        sub("Condenser Fan", "Condenser Components"),
                        sub("Fan Motor", "Condenser Components"),
                        sub("Condenser Bracket", "Condenser Components"),
                        sub("Pressure Switch", "Condenser Components"),
                    ],
                ),
                (
                    "Evaporator Components",
                    [
                        sub("Evaporator Core", "Evaporator Components"),
                        sub("Evaporator Housing", "Evaporator Components"),
                        sub("Blower Motor", "Evaporator Components"),
                        sub("Blower Fan", "Evaporator Components"),
                        sub("Blower Resistor / Regulator", "Evaporator Components"),
                        sub("Drain Pan", "Evaporator Components"),
                    ],
                ),
                (
                    "Expansion Devices",
                    [
                        sub("TXV (Thermal Expansion Valve)", "Expansion Devices"),
                        sub("Electronic Expansion Valve", "Expansion Devices"),
                        sub("Capillary Tube", "Expansion Devices"),
                    ],
                ),
                (
                    "Filters & Strainers",
                    [
                        sub("Cabin Air Filter", "Filters & Strainers"),
                        sub("Suction Strainer", "Filters & Strainers"),
                        sub("In-line Filter", "Filters & Strainers"),
                        sub("Condenser Filter", "Filters & Strainers"),
                    ],
                ),
                (
                    "Pressure & Temperature Controls",
                    [
                        sub("High Pressure Switch", "Pressure & Temperature Controls"),
                        sub("Low Pressure Switch", "Pressure & Temperature Controls"),
                        sub("Pressure Transducer", "Pressure & Temperature Controls"),
                        sub("Temperature Sensor", "Pressure & Temperature Controls"),
                        sub("Cycling Switch", "Pressure & Temperature Controls"),
                        sub("Dual Pressure Switch", "Pressure & Temperature Controls"),
                    ],
                ),
                (
                    "Air Flow & Duct Components",
                    [
                        sub("Dashboard Vents", "Air Flow & Duct Components"),
                        sub("Center Vents", "Air Flow & Duct Components"),
                        sub("Side Vents", "Air Flow & Duct Components"),
                        sub("Air Ducts", "Air Flow & Duct Components"),
                        sub("Vent Grilles", "Air Flow & Duct Components"),
                        sub("Mode Actuator", "Air Flow & Duct Components"),
                        sub("Blend Door Actuator", "Air Flow & Duct Components"),
                    ],
                ),
                (
                    "A/C Electrical Components",
                    [
                        sub("A/C Control Panel", "A/C Electrical Components"),
                        sub("A/C Control Module", "A/C Electrical Components"),
                        sub("A/C Switch", "A/C Electrical Components"),
                        sub("Temperature Control Unit", "A/C Electrical Components"),
                        sub("A/C Relay", "A/C Electrical Components"),
                        sub("A/C Wiring Harness", "A/C Electrical Components"),
                    ],
                ),
                (
                    "Specialized A/C Systems",
                    [
                        sub("Rear A/C System", "Specialized A/C Systems"),
                        sub("Roof Top A/C System", "Specialized A/C Systems"),
                        sub("Standby / Parking A/C", "Specialized A/C Systems"),
                        sub("Automatic Climate Control", "Specialized A/C Systems"),
                        sub("Dual / Tri Zone A/C", "Specialized A/C Systems"),
                        sub("Electric A/C Compressor", "Specialized A/C Systems"),
                        sub("Heat Pump System", "Specialized A/C Systems"),
                    ],
                ),
            ],
        )
    )

    categories.append(
        cat(
            "Body Parts",
            "body_parts",
            [
                (
                    "Front Body",
                    [
                        sub("Bonnet / Hood", "Front Body"),
                        sub("Front Bumper", "Front Body"),
                        sub("Grille", "Front Body"),
                        sub("Headlight", "Front Body"),
                        sub("Bumper Reinforcement", "Front Body"),
                        sub("Bumper Bracket", "Front Body"),
                        sub("Slam Panel", "Front Body"),
                        sub("Tow Hook Cover", "Front Body"),
                        sub("Radiator Support Panel", "Front Body"),
                        sub("Front Lip", "Front Body"),
                        sub("Front Air Dam", "Front Body"),
                        sub("Washer Nozzle", "Front Body"),
                    ],
                ),
                (
                    "Rear Body",
                    [
                        sub("Rear Bumper", "Rear Body"),
                        sub("Tailgate / Boot Lid", "Rear Body"),
                        sub("Tail Lamp", "Rear Body"),
                        sub("Rear Bumper Reinforcement", "Rear Body"),
                        sub("Spoiler", "Rear Body"),
                        sub("Rear Garnish", "Rear Body"),
                        sub("Number Plate Garnish", "Rear Body"),
                        sub("Rear Diffuser", "Rear Body"),
                        sub("High Mount Stop Lamp", "Rear Body"),
                        sub("Boot Lock", "Rear Body"),
                        sub("Boot Hinge", "Rear Body"),
                        sub("Reflector", "Rear Body"),
                    ],
                ),
                (
                    "Side Body",
                    [
                        sub("Front Door", "Side Body"),
                        sub("Rear Door", "Side Body"),
                        sub("Fender", "Side Body"),
                        sub("Quarter Panel", "Side Body"),
                        sub("Door Shell", "Side Body"),
                        sub("Door Hinges", "Side Body"),
                        sub("Door Check Strap", "Side Body"),
                        sub("Side Mirror (ORVM)", "Side Body"),
                        sub("Side Skirt", "Side Body"),
                        sub("Rocker Panel", "Side Body"),
                        sub("Wheel Arch", "Side Body"),
                        sub("Body Side Moulding", "Side Body"),
                    ],
                ),
                (
                    "Glass & Mirrors",
                    [
                        sub("Windshield", "Glass & Mirrors"),
                        sub("Rear Windshield", "Glass & Mirrors"),
                        sub("Front Door Glass", "Glass & Mirrors"),
                        sub("Rear Door Glass", "Glass & Mirrors"),
                        sub("Quarter Glass", "Glass & Mirrors"),
                        sub("Sunroof Glass", "Glass & Mirrors"),
                        sub("Mirror Cover", "Glass & Mirrors"),
                        sub("Mirror Glass", "Glass & Mirrors"),
                        sub("Mirror Indicator", "Glass & Mirrors"),
                        sub("Mirror Base", "Glass & Mirrors"),
                        sub("Glass Seal / Moulding", "Glass & Mirrors"),
                    ],
                ),
                (
                    "Exterior Trim & Accessories",
                    [
                        sub("Chrome Garnish", "Exterior Trim & Accessories"),
                        sub("Body Cladding", "Exterior Trim & Accessories"),
                        sub("Door Moulding", "Exterior Trim & Accessories"),
                        sub("Fender Garnish", "Exterior Trim & Accessories"),
                        sub("Roof Rail", "Exterior Trim & Accessories"),
                        sub("Rain Visor", "Exterior Trim & Accessories"),
                        sub("Mud Flap", "Exterior Trim & Accessories"),
                        sub("Emblem / Badge", "Exterior Trim & Accessories"),
                        sub("Decal / Sticker", "Exterior Trim & Accessories"),
                        sub("Fuel Lid Cover", "Exterior Trim & Accessories"),
                        sub("Side Step", "Exterior Trim & Accessories"),
                        sub("Antenna / Shark Fin", "Exterior Trim & Accessories"),
                    ],
                ),
                (
                    "Wiper System",
                    [
                        sub("Wiper Arm", "Wiper System"),
                        sub("Wiper Blade", "Wiper System"),
                        sub("Wiper Linkage", "Wiper System"),
                        sub("Washer Tank", "Wiper System"),
                        sub("Washer Motor", "Wiper System"),
                        sub("Washer Pump", "Wiper System"),
                        sub("Rear Wiper Arm", "Wiper System"),
                    ],
                ),
                (
                    "Lock & Handle",
                    [
                        sub("Door Handle", "Lock & Handle"),
                        sub("Tailgate Handle", "Lock & Handle"),
                        sub("Bonnet Lock", "Lock & Handle"),
                        sub("Door Lock", "Lock & Handle"),
                        sub("Lock Actuator", "Lock & Handle"),
                        sub("Central Locking Kit", "Lock & Handle"),
                        sub("Key Cylinder", "Lock & Handle"),
                        sub("Fuel Lid", "Lock & Handle"),
                    ],
                ),
                (
                    "Interior Body Trim",
                    [
                        sub("Dashboard", "Interior Body Trim"),
                        sub("Door Trim Panel", "Interior Body Trim"),
                        sub("Pillar Trim", "Interior Body Trim"),
                        sub("Headliner", "Interior Body Trim"),
                        sub("Carpet", "Interior Body Trim"),
                        sub("Sun Visor", "Interior Body Trim"),
                        sub("Interior Garnish", "Interior Body Trim"),
                        sub("Boot / Trunk Trim", "Interior Body Trim"),
                    ],
                ),
                (
                    "Under Body Parts",
                    [
                        sub("Chassis Cross Member", "Under Body Parts"),
                        sub("Floor Panel", "Under Body Parts"),
                        sub("Engine Splash Shield", "Under Body Parts"),
                        sub("Wheel Well Liner", "Under Body Parts"),
                        sub("Under Cover", "Under Body Parts"),
                        sub("Side Under Cover", "Under Body Parts"),
                        sub("Fuel Tank Shield", "Under Body Parts"),
                        sub("Heat Shield", "Under Body Parts"),
                    ],
                ),
                (
                    "Weather Seals",
                    [
                        sub("Door Rubber Beading", "Weather Seals"),
                        sub("Windshield Seal", "Weather Seals"),
                        sub("Boot Seal", "Weather Seals"),
                        sub("Sunroof Seal", "Weather Seals"),
                        sub("Glass Run Channel", "Weather Seals"),
                        sub("Belt Weather Strip", "Weather Seals"),
                        sub("Corner Seal", "Weather Seals"),
                        sub("Duster Seal", "Weather Seals"),
                    ],
                ),
                (
                    "Mounting & Fasteners",
                    [
                        sub("Clips", "Mounting & Fasteners"),
                        sub("Retainers", "Mounting & Fasteners"),
                        sub("Fasteners", "Mounting & Fasteners"),
                        sub("Brackets", "Mounting & Fasteners"),
                        sub("Body Bolts", "Mounting & Fasteners"),
                        sub("Plastic Rivets", "Mounting & Fasteners"),
                        sub("Screws", "Mounting & Fasteners"),
                        sub("Nuts & Washers", "Mounting & Fasteners"),
                    ],
                ),
            ],
        )
    )

    # Additional categories with logical subcategories
    categories.extend(
        [
            cat(
                "Suspension",
                "suspension",
                [
                    (
                        "Front Suspension",
                        [
                            sub("Shock Absorber", "Front Suspension"),
                            sub("Strut Assembly", "Front Suspension"),
                            sub("Coil Spring", "Front Suspension"),
                            sub("Control Arm", "Front Suspension"),
                            sub("Ball Joint", "Front Suspension"),
                            sub("Stabilizer Link", "Front Suspension"),
                            sub("Sway Bar", "Front Suspension"),
                            sub("Strut Mount", "Front Suspension"),
                        ],
                    ),
                    (
                        "Rear Suspension",
                        [
                            sub("Rear Shock Absorber", "Rear Suspension"),
                            sub("Leaf Spring", "Rear Suspension"),
                            sub("Trailing Arm", "Rear Suspension"),
                            sub("Panhard Rod", "Rear Suspension"),
                            sub("Rear Coil Spring", "Rear Suspension"),
                        ],
                    ),
                    (
                        "Steering & Alignment",
                        [
                            sub("Tie Rod End", "Steering & Alignment"),
                            sub("Rack & Pinion", "Steering & Alignment"),
                            sub("Steering Knuckle", "Steering & Alignment"),
                            sub("Wheel Hub", "Steering & Alignment"),
                            sub("Wheel Bearing", "Steering & Alignment"),
                        ],
                    ),
                ],
            ),
            cat(
                "Brakes",
                "brakes",
                [
                    (
                        "Brake Components",
                        [
                            sub("Brake Pad", "Brake Components"),
                            sub("Brake Disc / Rotor", "Brake Components"),
                            sub("Brake Drum", "Brake Components"),
                            sub("Brake Caliper", "Brake Components"),
                            sub("Brake Shoe", "Brake Components"),
                            sub("Brake Line", "Brake Components"),
                            sub("Master Cylinder", "Brake Components"),
                            sub("Brake Booster", "Brake Components"),
                            sub("ABS Module", "Brake Components"),
                            sub("Wheel Speed Sensor", "Brake Components"),
                        ],
                    ),
                    (
                        "Parking Brake",
                        [
                            sub("Handbrake Cable", "Parking Brake"),
                            sub("Handbrake Lever", "Parking Brake"),
                            sub("Parking Brake Shoes", "Parking Brake"),
                        ],
                    ),
                ],
            ),
            cat(
                "Electrical",
                "electrical",
                [
                    (
                        "Starting & Charging",
                        [
                            sub("Alternator", "Starting & Charging"),
                            sub("Starter Motor", "Starting & Charging"),
                            sub("Battery", "Starting & Charging"),
                            sub("Voltage Regulator", "Starting & Charging"),
                        ],
                    ),
                    (
                        "Wiring & Connectors",
                        [
                            sub("Main Wiring Harness", "Wiring & Connectors"),
                            sub("Fuse Box", "Wiring & Connectors"),
                            sub("Relay Box", "Wiring & Connectors"),
                            sub("Connectors & Terminals", "Wiring & Connectors"),
                        ],
                    ),
                    (
                        "Switches & Controls",
                        [
                            sub("Ignition Switch", "Switches & Controls"),
                            sub("Window Switch", "Switches & Controls"),
                            sub("Combination Switch", "Switches & Controls"),
                            sub("Horn", "Switches & Controls"),
                        ],
                    ),
                ],
            ),
            cat(
                "Accessories",
                "accessories",
                [
                    (
                        "Exterior Accessories",
                        [
                            sub("Roof Box", "Exterior Accessories"),
                            sub("Bike Rack", "Exterior Accessories"),
                            sub("Tow Bar", "Exterior Accessories"),
                            sub("Bull Bar", "Exterior Accessories"),
                            sub("Car Cover", "Exterior Accessories"),
                        ],
                    ),
                    (
                        "Interior Accessories",
                        [
                            sub("Floor Mat", "Interior Accessories"),
                            sub("Seat Cover", "Interior Accessories"),
                            sub("Steering Cover", "Interior Accessories"),
                            sub("Phone Mount", "Interior Accessories"),
                            sub("Dash Cam", "Interior Accessories"),
                        ],
                    ),
                    (
                        "Electronics & Gadgets",
                        [
                            sub("Infotainment System", "Electronics & Gadgets"),
                            sub("Reverse Camera", "Electronics & Gadgets"),
                            sub("Parking Sensor Kit", "Electronics & Gadgets"),
                            sub("TPMS Kit", "Electronics & Gadgets"),
                        ],
                    ),
                ],
            ),
            cat(
                "Sensors & Modules",
                "sensors_and_modules",
                [
                    (
                        "Control Modules",
                        [
                            sub("ECU / ECM", "Control Modules"),
                            sub("TCU (Transmission Control Unit)", "Control Modules"),
                            sub("BCM (Body Control Module)", "Control Modules"),
                            sub("ABS Control Module", "Control Modules"),
                            sub("Airbag Control Module", "Control Modules"),
                        ],
                    ),
                    (
                        "Sensors",
                        [
                            sub("Oxygen Sensor", "Sensors"),
                            sub("Mass Air Flow Sensor", "Sensors"),
                            sub("Crankshaft Position Sensor", "Sensors"),
                            sub("Camshaft Position Sensor", "Sensors"),
                            sub("Parking Sensor", "Sensors"),
                            sub("Rain Sensor", "Sensors"),
                            sub("Tyre Pressure Sensor", "Sensors"),
                        ],
                    ),
                ],
            ),
            cat(
                "Interior",
                "interior",
                [
                    (
                        "Seats & Upholstery",
                        [
                            sub("Front Seat", "Seats & Upholstery"),
                            sub("Rear Seat", "Seats & Upholstery"),
                            sub("Seat Belt", "Seats & Upholstery"),
                            sub("Seat Motor", "Seats & Upholstery"),
                            sub("Seat Frame", "Seats & Upholstery"),
                        ],
                    ),
                    (
                        "Console & Storage",
                        [
                            sub("Center Console", "Console & Storage"),
                            sub("Glove Box", "Console & Storage"),
                            sub("Armrest", "Console & Storage"),
                            sub("Cup Holder", "Console & Storage"),
                        ],
                    ),
                    (
                        "Climate & Comfort",
                        [
                            sub("Heater Core", "Climate & Comfort"),
                            sub("Blower Motor", "Climate & Comfort"),
                            sub("Sunroof Mechanism", "Climate & Comfort"),
                        ],
                    ),
                ],
            ),
            cat(
                "Wheels",
                "wheels",
                [
                    (
                        "Wheels & Tyres",
                        [
                            sub("Alloy Wheel", "Wheels & Tyres"),
                            sub("Steel Wheel", "Wheels & Tyres"),
                            sub("Spare Wheel", "Wheels & Tyres"),
                            sub("Tyre", "Wheels & Tyres"),
                            sub("Wheel Cap", "Wheels & Tyres"),
                            sub("Lug Nut / Bolt", "Wheels & Tyres"),
                        ],
                    ),
                    (
                        "TPMS & Accessories",
                        [
                            sub("TPMS Sensor", "TPMS & Accessories"),
                            sub("Wheel Spacer", "TPMS & Accessories"),
                            sub("Wheel Hub", "TPMS & Accessories"),
                        ],
                    ),
                ],
            ),
            cat(
                "Lighting",
                "lighting",
                [
                    (
                        "Exterior Lighting",
                        [
                            sub("Headlamp", "Exterior Lighting"),
                            sub("Tail Lamp", "Exterior Lighting"),
                            sub("Fog Lamp", "Exterior Lighting"),
                            sub("DRL / Day Light", "Exterior Lighting"),
                            sub("Indicator Lamp", "Exterior Lighting"),
                            sub("Reverse Lamp", "Exterior Lighting"),
                            sub("Number Plate Lamp", "Exterior Lighting"),
                            sub("Cornering Lamp", "Exterior Lighting"),
                        ],
                    ),
                    (
                        "Interior Lighting",
                        [
                            sub("Interior Lamp", "Interior Lighting"),
                            sub("Welcome Light", "Interior Lighting"),
                            sub("Map Light", "Interior Lighting"),
                            sub("Boot Light", "Interior Lighting"),
                        ],
                    ),
                    (
                        "Bulbs & Ballasts",
                        [
                            sub("Halogen Bulb", "Bulbs & Ballasts"),
                            sub("LED Bulb", "Bulbs & Ballasts"),
                            sub("Xenon Bulb", "Bulbs & Ballasts"),
                            sub("Ballast", "Bulbs & Ballasts"),
                        ],
                    ),
                ],
            ),
            cat(
                "Bearing",
                "bearing",
                [
                    (
                        "Bearings",
                        [
                            sub("Wheel Bearing", "Bearings"),
                            sub("Hub Bearing", "Bearings"),
                            sub("Clutch Release Bearing", "Bearings"),
                            sub("Pilot Bearing", "Bearings"),
                            sub("Taper Roller Bearing", "Bearings"),
                            sub("Ball Bearing", "Bearings"),
                            sub("Needle Bearing", "Bearings"),
                        ],
                    ),
                ],
            ),
            cat(
                "Fuel System",
                "fuel_system",
                [
                    (
                        "Petrol Fuel System",
                        [
                            sub("Fuel Pump", "Petrol Fuel System"),
                            sub("Fuel Filter", "Petrol Fuel System"),
                            sub("Fuel Rail", "Petrol Fuel System"),
                            sub("Fuel Injector", "Petrol Fuel System"),
                            sub("Fuel Tank", "Petrol Fuel System"),
                            sub("Fuel Cap", "Petrol Fuel System"),
                            sub("Fuel Line", "Petrol Fuel System"),
                        ],
                    ),
                    (
                        "Diesel Fuel System",
                        [
                            sub("High Pressure Pump", "Diesel Fuel System"),
                            sub("Common Rail", "Diesel Fuel System"),
                            sub("Diesel Injector", "Diesel Fuel System"),
                            sub("Water Separator", "Diesel Fuel System"),
                            sub("Primer Pump", "Diesel Fuel System"),
                        ],
                    ),
                    (
                        "EV Charging & Storage",
                        [
                            sub("High Voltage Battery", "EV Charging & Storage"),
                            sub("Battery Management System", "EV Charging & Storage"),
                            sub("Onboard Charger", "EV Charging & Storage"),
                            sub("DC-DC Converter", "EV Charging & Storage"),
                        ],
                    ),
                ],
            ),
        ]
    )

    return {
        "version": 1,
        "generatedAt": "2026-07-25",
        "categories": categories,
    }


def reorganize_assets() -> None:
    staging = SUB_DIR / "_staging"
    if staging.exists():
        shutil.rmtree(staging)
    staging.mkdir(parents=True)

    for src_name, (folder, slug, _label) in IMAGE_MAP.items():
        src = SUB_DIR / src_name
        if not src.exists():
            print(f"skip missing: {src_name}")
            continue
        dest_dir = staging / folder
        dest_dir.mkdir(parents=True, exist_ok=True)
        dest = dest_dir / f"{slug}.png"
        shutil.copy2(src, dest)
        if not slug.endswith("_alt") and slug not in PRIMARY_IMAGE_BY_SLUG:
            PRIMARY_IMAGE_BY_SLUG[slug] = f"assets/sub/{folder}/{slug}.png"

    # Remove old flat files and promote staging
    for item in SUB_DIR.iterdir():
        if item.name == "_staging":
            continue
        if item.is_file():
            item.unlink()
        elif item.is_dir():
            shutil.rmtree(item)

    for item in staging.iterdir():
        dest = SUB_DIR / item.name
        shutil.move(str(item), str(dest))
    staging.rmdir()


def main() -> None:
    reorganize_assets()
    catalog = build_catalog()
    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    total = sum(len(c["subcategories"]) for c in catalog["categories"])
    print(f"Wrote {OUT_JSON} with {len(catalog['categories'])} categories, {total} subcategories")
    print(f"Mapped {len(PRIMARY_IMAGE_BY_SLUG)} subcategory images")


if __name__ == "__main__":
    main()
