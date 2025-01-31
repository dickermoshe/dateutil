# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "pydantic",
#     "python-dateutil",
# ]
# ///

from dateutil.tz.win import tzwin
from json import dumps

print(dumps(tzwin.list()), end="")
