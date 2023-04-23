from datetime import datetime


def str_to_felt(text):
    b_text = bytes(text, "ascii")
    return int.from_bytes(b_text, "big")


def felt_to_str(int):
    b_int = int.to_bytes(32, "big")
    return str(b_int, "ascii")


def get_key_by_value(v, dict):
    for key, value in dict.items():
        if value == v:
            return key
    return None


def encode_int_as_bytes(n):
    return n.to_bytes(32, "big")


def check_exists_int(val):
    if val == 0:
        return None
    else:
        return encode_int_as_bytes(val)


def check_exists_timestamp(val):
    if val == 0:
        return None
    else:
        return datetime.fromtimestamp(val)
