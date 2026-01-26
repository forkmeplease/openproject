import { describe, expect, test } from "vitest";
import { replaceWithExplicitHost } from "../../src/services/explicitHostService";

describe("replaceWithExplicitHost", () => {
  test("returns the host if a direct host is not defined", () => {
    const resourceUrl = "https://example.com/path/to/resource";
    const result = replaceWithExplicitHost(resourceUrl);
    expect(result).toBe(resourceUrl);
  });
});
