import os


class UndefinedValueError(Exception):
    """Raised when a required environment variable is missing."""


class Csv:
    """Simple CSV caster similar to python-decouple's Csv."""

    def __init__(self, separator=','):
        self.separator = separator

    def __call__(self, value):
        if value is None:
            return []
        return [item.strip() for item in str(value).split(self.separator) if item.strip()]


def _cast_value(value, cast):
    if cast in (str, None):
        return value
    if cast is bool:
        return str(value).strip().lower() in ('1', 'true', 'yes', 'on')
    if cast is int:
        return int(value)
    if cast is float:
        return float(value)
    if callable(cast):
        return cast(value)
    return value


def config(name, default=None, cast=str):
    """Minimal replacement for python-decouple's config helper."""
    value = os.getenv(name)
    if value is None:
        if default is None:
            raise UndefinedValueError(f'{name} not found. Declare it first.')
        if cast and cast is not str:
            return _cast_value(default, cast)
        return default
    return _cast_value(value, cast)
