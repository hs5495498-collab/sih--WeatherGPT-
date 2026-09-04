from datetime import date, timedelta


def get_target_date(time_reference: str) -> str:
    """
    Convert NLU time reference into an actual date.
    """

    today = date.today()

    if time_reference == "today":
        target_date = today

    elif time_reference == "tomorrow":
        target_date = today + timedelta(days=1)

    elif time_reference == "day_after_tomorrow":
        target_date = today + timedelta(days=2)

    else:
        target_date = today

    return target_date.isoformat()