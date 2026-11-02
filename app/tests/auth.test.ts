import { describe, expect, test } from "vitest";
import { getAPIKey } from "../src/api/auth.js";

describe("getAPIKey", () => {
  test("returns a valid API key", () => {
    const headers = {
      authorization: "ApiKey my-secret-key",
    };

    expect(getAPIKey(headers)).toBe("my-secret-key");
  });

  test("returns null when authorization is missing", () => {
    expect(getAPIKey({})).toBeNull();
  });

  test("returns null for the wrong authentication scheme", () => {
    const headers = {
      authorization: "Bearer my-token",
    };

    expect(getAPIKey(headers)).toBeNull();
  });

  test("returns null when the API key is empty", () => {
    const headers = {
      authorization: "ApiKey ",
    };

    expect(getAPIKey(headers)).toBeNull();
  });
});
