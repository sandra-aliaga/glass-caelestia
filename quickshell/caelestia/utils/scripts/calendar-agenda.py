#!/usr/bin/env python3
"""Fetch a (secret) ICS calendar URL and print upcoming events as JSON.

The URL is resolved from, in order:
  1. the CAELESTIA_CALENDAR_URL environment variable
  2. a CAELESTIA_CALENDAR_URL=... line in the repo-root .env file

The .env file is gitignored, so the secret never gets committed while the
code stays in the repo. Recurrences are expanded with recurring-ical-events.
Output is a JSON list sorted by start time:

    [{"summary", "location", "start", "end", "allDay"}]

Times are ISO 8601 in the local timezone. On any error a JSON object with
an "error" key is printed instead, so the QML side can surface it.
"""

import json
import os
import sys
import urllib.request
from datetime import datetime, timedelta
from pathlib import Path

import icalendar
import recurring_ical_events

ENV_VAR = "CAELESTIA_CALENDAR_URL"
# script is at <repo>/quickshell/caelestia/utils/scripts/calendar-agenda.py
ENV_FILE = Path(__file__).resolve().parents[4] / ".env"
DAYS_AHEAD = 7


def resolve_url() -> str:
    env = os.environ.get(ENV_VAR, "").strip()
    if env:
        return env
    if ENV_FILE.exists():
        for line in ENV_FILE.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line.startswith("#") or "=" not in line:
                continue
            key, _, value = line.partition("=")
            if key.strip() == ENV_VAR:
                return value.strip().strip('"').strip("'")
    return ""


def fail(message: str) -> None:
    print(json.dumps({"error": message}))
    sys.exit(0)


def main() -> None:
    url = resolve_url()
    if not url:
        fail("no calendar url configured")

    try:
        req = urllib.request.Request(url, headers={"User-Agent": "caelestia-calendar"})
        with urllib.request.urlopen(req, timeout=20) as resp:
            raw = resp.read()
    except Exception as exc:  # noqa: BLE001 - surface any fetch problem
        fail(f"fetch failed: {exc}")

    try:
        cal = icalendar.Calendar.from_ical(raw)
    except Exception as exc:  # noqa: BLE001
        fail(f"parse failed: {exc}")

    now = datetime.now().astimezone()
    start = now - timedelta(hours=12)  # keep events already in progress today
    end = now + timedelta(days=DAYS_AHEAD)

    try:
        occurrences = recurring_ical_events.of(cal).between(start, end)
    except Exception as exc:  # noqa: BLE001
        fail(f"recurrence expansion failed: {exc}")

    events = []
    for ev in occurrences:
        dtstart = ev.get("DTSTART")
        if dtstart is None:
            continue
        sdt = dtstart.dt
        edt = ev.get("DTEND").dt if ev.get("DTEND") else sdt

        # date (not datetime) means an all-day event
        all_day = not isinstance(sdt, datetime)

        def iso(value):
            if isinstance(value, datetime):
                return value.astimezone().isoformat()
            return datetime(value.year, value.month, value.day).astimezone().isoformat()

        events.append({
            "summary": str(ev.get("SUMMARY", "(sin título)")),
            "location": str(ev.get("LOCATION", "")),
            "start": iso(sdt),
            "end": iso(edt),
            "allDay": all_day,
        })

    events.sort(key=lambda e: e["start"])
    print(json.dumps(events, ensure_ascii=False))


if __name__ == "__main__":
    main()
