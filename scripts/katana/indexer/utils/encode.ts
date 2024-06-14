export function encodeIntAsBytes(n: bigint): string {
  const arr = new Uint8Array(32);
  let bigIntValue: bigint = n;

  for (let i = 31; i >= 0; i--) {
    const byteValue: BigInt = bigIntValue & BigInt("0xFF");
    arr[i] = Number(byteValue);
    bigIntValue >>= BigInt(8);
  }

  return arrayBufferToBase64(arr.buffer);
}

export function checkExistsInt(val: bigint): string | null {
  if (val === BigInt(0)) {
    return null;
  } else {
    return encodeIntAsBytes(val);
  }
}

function arrayBufferToBase64(buffer: ArrayBuffer): string {
  let binary = "";
  const bytes = new Uint8Array(buffer);
  const len = bytes.byteLength;
  for (let i = 0; i < len; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary);
}
