import { describe, expect, test, vi, beforeEach, afterEach } from "vitest";
import { OpenProjectApi } from "../../src/extensions/openProjectApi";
import { onAuthenticatePayload, onLoadDocumentPayload, onStoreDocumentPayload } from "@hocuspocus/server";
import * as Y from "yjs";

describe("OpenProjectApi", () => {
  let fetchMock: any;
  let originalAllowedDomains: string | undefined;

  beforeEach(() => {
    fetchMock = vi.fn();
    vi.stubGlobal('fetch', fetchMock);
    originalAllowedDomains = process.env.ALLOWED_DOMAINS;
    process.env.ALLOWED_DOMAINS = 'test.api,example.com';
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    process.env.ALLOWED_DOMAINS = originalAllowedDomains;
  });

  describe("onAuthenticate", () => {
    test("when the token is not present throw an error", async () => {
      await expect(() =>
        new OpenProjectApi().onAuthenticate({
          token: null,
          requestParameters: new URLSearchParams({ documentId: "121", returnUrl: "https://test.api" }),
        } as unknown as onAuthenticatePayload)
      ).rejects.toThrowError("Unauthorized: Token missing.");
    });

    test("when the returnUrl is not present throw an error", async () => {
      await expect(() =>
        new OpenProjectApi().onAuthenticate({
          token: "validToken",
          requestParameters: new URLSearchParams({ documentId: "121" }),
        } as unknown as onAuthenticatePayload)
      ).rejects.toThrowError("Unauthorized: Return URL missing.");
    });

    test("when ALLOWED_DOMAINS is not configured throw an error", async () => {
      delete process.env.ALLOWED_DOMAINS;

      await expect(() =>
        new OpenProjectApi().onAuthenticate({
          token: "validToken",
          requestParameters: new URLSearchParams({ documentId: "121", returnUrl: "https://test.api" }),
        } as unknown as onAuthenticatePayload)
      ).rejects.toThrowError("Unauthorized: No allowed domains configured.");
    });

    test("when returnUrl has invalid format throw an error", async () => {
      await expect(() =>
        new OpenProjectApi().onAuthenticate({
          token: "validToken",
          requestParameters: new URLSearchParams({ documentId: "121", returnUrl: "not-a-valid-url" }),
        } as unknown as onAuthenticatePayload)
      ).rejects.toThrowError("Unauthorized: Invalid return URL format.");
    });

    test("when returnUrl domain is not in ALLOWED_DOMAINS throw an error", async () => {
      await expect(() =>
        new OpenProjectApi().onAuthenticate({
          token: "validToken",
          requestParameters: new URLSearchParams({ documentId: "121", returnUrl: "https://malicious.com" }),
        } as unknown as onAuthenticatePayload)
      ).rejects.toThrowError("Unauthorized: Invalid return URL domain.");
    });

    test("when returnUrl subdomain matches ALLOWED_DOMAINS it should be accepted", async () => {
      fetchMock.mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: () => Promise.resolve({
          title: "TheDocName"
        }),
      });

      const data = {
        context: {},
        token: "validToken",
        documentName: "TheDocName",
        requestParameters: new URLSearchParams({ documentId: "121", returnUrl: "https://subdomain.test.api" }),
      } as unknown as onAuthenticatePayload;

      await new OpenProjectApi().onAuthenticate(data);

      expect(data.context.returnUrl).toEqual("https://subdomain.test.api");
    });

    test("when the token is invalid throw an error", async () => {
      fetchMock.mockResolvedValueOnce({
        ok: false,
        status: 401,
      });

      await expect(() =>
        new OpenProjectApi().onAuthenticate({
          token: "invalidToken",
          documentName: "TheDocName",
          requestParameters: new URLSearchParams({ documentId: "121", returnUrl: "https://test.api" }),
        } as unknown as onAuthenticatePayload)
      ).rejects.toThrowError("Unauthorized: Invalid token.");

      expect(fetchMock).toHaveBeenCalledWith(
        "https://test.api/api/v3/documents/121",
        {
          method: "GET",
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer invalidToken",
          },
        }
      );
    });

    test("when the document title does not match the requested documentName, throw an error", async () => {
      fetchMock.mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: () => Promise.resolve({
          title: "DifferentDocName"
        }),
      });

      await expect(() =>
        new OpenProjectApi().onAuthenticate({
          token: "validToken",
          documentName: "TheDocName",
          requestParameters: new URLSearchParams({ documentId: "121", returnUrl: "https://test.api" }),
        } as unknown as onAuthenticatePayload)
      ).rejects.toThrowError("Unauthorized: Document access denied.");
    });

    test("when the token is valid and document title matches, set the documentId, token and returnUrl on the context", async () => {
      fetchMock.mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: () => Promise.resolve({
          title: "TheDocName"
        }),
      });

      const data = {
        context: {},
        token: "validToken",
        documentName: "TheDocName",
        requestParameters: new URLSearchParams({ documentId: "121", returnUrl: "https://test.api" }),
      } as unknown as onAuthenticatePayload;

      await new OpenProjectApi().onAuthenticate(data);

      expect(data.context.documentId).toEqual("121");
      expect(data.context.token).toEqual("validToken");
      expect(data.context.returnUrl).toEqual("https://test.api");
      expect(data.documentName).toEqual("TheDocName");
    });
  });

  describe("onLoadDocument", () => {
    test("should fetch document content and apply update to YDoc", async () => {
      // Create a valid YJS update by encoding state from a document with content
      const sourceDoc = new Y.Doc();
      const text = sourceDoc.getText('content');
      text.insert(0, 'test content');
      const base64Update = Buffer.from(Y.encodeStateAsUpdate(sourceDoc)).toString('base64');

      fetchMock.mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: () => Promise.resolve({
          contentBinary: base64Update
        }),
      });

      const targetDoc = new Y.Doc();
      const data = {
        context: { documentId: "121", token: "testToken", returnUrl: "https://test.api" },
        document: targetDoc,
      } as onLoadDocumentPayload;

      const api = new OpenProjectApi();
      await api.onLoadDocument(data);

      expect(fetchMock).toHaveBeenCalledWith(
        "https://test.api/api/v3/documents/121",
        {
          method: "GET",
          headers: {
            "Content-Type": "application/json",
            "Authorization": expect.stringContaining("Bearer"),
          },
        }
      );

      // Verify the document was updated with the content
      const updatedContent = targetDoc.getText('content').toString();
      expect(updatedContent).toBe('test content');
    });

    test("should return early when response is not successful", async () => {
      fetchMock.mockResolvedValueOnce({
        ok: false,
        status: 404,
      });

      const data = {
        context: { documentId: "121", token: "testToken", returnUrl: "https://test.api" },
        document: new Y.Doc(),
      } as onLoadDocumentPayload;

      const initialContent = data.document.getText('content').toString();

      const api = new OpenProjectApi();
      await api.onLoadDocument(data);

      expect(fetchMock).toHaveBeenCalled();

      const updatedContent = data.document.getText('content').toString();
      expect(updatedContent).toBe(initialContent);
    });
  });

  describe("onStoreDocument", () => {
    test("should store document content successfully", async () => {
      fetchMock.mockResolvedValueOnce({
        ok: true,
        status: 200,
      });

      const document = new Y.Doc();
      const text = document.getText('content');
      text.insert(0, 'test document content');

      const data = {
        context: { documentId: "121", token: "testToken", returnUrl: "https://test.api" },
        document,
      } as onStoreDocumentPayload;

      const api = new OpenProjectApi();
      await api.onStoreDocument(data);

      expect(fetchMock).toHaveBeenCalledWith(
        "https://test.api/api/v3/documents/121",
        {
          method: "PATCH",
          headers: {
            "Content-Type": "application/json",
            "Authorization": expect.stringContaining("Bearer"),
          },
          body: JSON.stringify({
            content_binary: Buffer.from(Y.encodeStateAsUpdate(data.document)).toString("base64")
          }),
        }
      );
    });
  });
});
