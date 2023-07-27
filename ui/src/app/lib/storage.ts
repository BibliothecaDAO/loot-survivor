import Cookies from "js-cookie";

const isSafari =
  typeof navigator !== "undefined" &&
  /^((?!chrome|android).)*safari/i.test(navigator.userAgent);

const Storage = {
  keys: (): string[] => {
    if (!isSafari && typeof window != "undefined") {
      return Object.keys(window.localStorage);
    }

    return Object.keys(Cookies.get());
  },
  get: (key: string): any => {
    if (!isSafari && typeof window != "undefined") {
      const value = window.localStorage.getItem(key);
      if (!value) {
        return null;
      }

      return JSON.parse(value);
    }

    const existing = Cookies.get(key);

    if (typeof existing === "undefined") {
      return undefined;
    }

    return JSON.parse(existing);
  },
  set: (key: string, value: any) => {
    if (!isSafari && typeof window != "undefined") {
      window.localStorage.setItem(key, JSON.stringify(value));
      return;
    }

    Cookies.set(key, JSON.stringify(value), {
      secure: true,
      sameSite: "strict",
    });
  },
  remove: (key: string) => {
    if (!isSafari && typeof window != "undefined") {
      window.localStorage.removeItem(key);
      return;
    }

    Cookies.remove(key);
  },
  clear: () => {
    if (!isSafari && typeof window != "undefined") {
      window.localStorage.clear();
      return;
    }

    const cookies = Cookies.get();
    Object.keys(cookies).forEach((key) => Cookies.remove(key));
  },
};

export default Storage;