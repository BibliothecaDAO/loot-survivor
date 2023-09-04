// Taken from github:EkuboProtocol/indexer

export type Felt = `0x${string}`;

export interface Parser<T> {
  (data: Felt[], startingFrom: number): {
    value: T;
    next: number;
  };
}

export const parseU128: Parser<string> = (data, startingFrom) => {
  return {
    value: BigInt(data[startingFrom]).toString(),
    next: startingFrom + 1,
  };
};

export const parseU64 = parseU128;

export const parseU256: Parser<string> = (data, startingFrom) => {
  const value =
    BigInt(data[startingFrom]) + BigInt(data[startingFrom + 1]) * 2n ** 128n;
  return {
    value: value.toString(),
    next: startingFrom + 2,
  };
};

export const parseI129: Parser<string> = (data, startingFrom) => {
  const value =
    BigInt(data[startingFrom]) *
    (BigInt(data[startingFrom + 1]) !== 0n ? -1n : 1n);
  return {
    value: value.toString(),
    next: startingFrom + 2,
  };
};

export type GetParserType<T extends Parser<any>> = T extends Parser<infer U>
  ? U
  : never;

export const parseU8: Parser<number> = (data, startingFrom) => {
  return {
    value: Number(BigInt(data[startingFrom])),
    next: startingFrom + 1,
  };
};

export const parseU16 = parseU8;

export const parseFelt252: Parser<string> = (data, startingFrom) => {
  return {
    value: BigInt(data[startingFrom]).toString(),
    next: startingFrom + 1,
  };
};

export const parseBoolean: Parser<boolean> = (data, startingFrom) => {
  const num = BigInt(data[startingFrom]);
  let value: boolean;
  if (num === 0n) {
    value = false;
  } else {
    if (num === 1n) {
      value = true;
    } else {
      throw new Error("Invalid boolean value");
    }
  }
  return {
    value,
    next: startingFrom + 1,
  };
};

export function combineParsers<
  T extends {
    [key: string]: unknown;
  }
>(parsers: {
  [K in keyof T]: { index: number; parser: Parser<T[K]> };
}): Parser<T> {
  return (data, startingFrom) =>
    Object.entries(parsers)
      .sort(([, { index: index0 }], [, { index: index1 }]) => {
        return index0 - index1;
      })
      .reduce(
        (memo, fieldParser) => {
          const { value: parsedValue, next } = fieldParser[1].parser(
            data,
            memo.next
          );
          memo.value[fieldParser[0] as keyof T] = parsedValue;
          memo.next = next;
          return memo;
        },
        {
          value: {} as Partial<T>,
          next: startingFrom,
        }
      ) as {
      value: T;
      next: number;
    };
}

export function parseArray<T>(elementParser: Parser<T>): Parser<T[]> {
  return (data, startingFrom) => {
    const length = Number(BigInt(data[startingFrom])); // or just keep it as BigInt if needed
    let next = startingFrom + 1;
    const value: T[] = [];

    for (let i = 0; i < length; i++) {
      const result = elementParser(data, next);
      value.push(result.value);
      next = result.next;
    }

    return { value, next };
  };
}
