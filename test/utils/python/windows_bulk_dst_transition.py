from datetime import datetime
from json import dumps
from typing import Annotated, Any
import typer
from dateutil.tz.win import tzwin


def datetime_to_timestamp(dt: datetime, tz: tzwin) -> float:
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=tz)
    return dt.timestamp()


def main(year: int, timezones: Annotated[list[str], typer.Option()]):
    total_result = []

    for timezone in timezones:
        tz = tzwin(timezone)
        transitions: tuple[datetime, datetime] | None = tz.transitions(year)
        result: dict[str, Any] = {
            "std_offset": tz._std_offset.total_seconds(),
            "dst_offset": tz._dst_offset.total_seconds(),
        }
        if transitions:
            result["dst_on"] = datetime_to_timestamp(transitions[0], tz)
            result["dst_off"] = datetime_to_timestamp(transitions[1], tz)
        else:
            result["dst_on"] = None
            result["dst_off"] = None
        total_result.append(result)
    print(dumps(total_result), end="")


if __name__ == "__main__":
    typer.run(main)
