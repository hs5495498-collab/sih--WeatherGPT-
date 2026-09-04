from datetime import datetime


def format_temperature(value: float | None):
    """Format temperature safely."""
    if value is None:
        return None

    return round(value, 1)


def format_datetime(dt: datetime):
    """Format datetime consistently."""
    return dt.strftime("%Y-%m-%d %H:%M:%S")