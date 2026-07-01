import re

from rest_framework import serializers

LIBYAN_PHONE_REGEX = re.compile(r"^09[1-5]\d{7}$")


ARABIC_DIGITS_MAP = str.maketrans("٠١٢٣٤٥٦٧٨٩", "0123456789")


def normalize_phone(value: str) -> str:
    normalized = (value or "").strip().translate(ARABIC_DIGITS_MAP)
    normalized = normalized.replace(" ", "")
    return normalized


def validate_libyan_phone(value: str) -> str:
    phone = normalize_phone(value)
    if not LIBYAN_PHONE_REGEX.match(phone):
        raise serializers.ValidationError("رقم هاتف ليبي غير صالح. يجب أن يكون بالشكل 09XXXXXXXX ويبدأ بـ 091 أو 092 أو 093 أو 094 أو 095")
    return phone
