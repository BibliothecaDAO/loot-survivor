from datetime import datetime
import hashlib


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


def decode_bytes_as_int(n):
    return int.from_bytes(n, "big")


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


def create_uid(num1, num2, num3):
    # Convert the numbers to strings
    str1 = str(num1)
    str2 = str(num2)
    str3 = str(num3)

    # Concatenate the strings
    concat_str = str1 + str2 + str3

    # Create a hash object
    hash_object = hashlib.sha256(concat_str.encode())

    # Get the hexadecimal representation of the hash
    hex_dig = hash_object.hexdigest()

    return hex_dig
