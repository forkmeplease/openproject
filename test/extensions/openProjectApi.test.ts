import { Document, onAuthenticatePayload, onLoadDocumentPayload, onStoreDocumentPayload, onTokenSyncPayload } from "@hocuspocus/server";
import { afterEach, beforeEach, describe, expect, test, vi } from "vitest";
import * as Y from "yjs";
import { OpenProjectApi, createEditor } from "../../src/extensions/openProjectApi";

describe("OpenProjectApi", () => {
  let fetchMock: any;

  beforeEach(() => {
    fetchMock = vi.fn();
    vi.stubGlobal('fetch', fetchMock);
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  describe("onAuthenticate", () => {
    test("when the token is not present throw an error", async () => {
      await expect(() =>
        new OpenProjectApi().onAuthenticate({
          token: null,
        } as unknown as onAuthenticatePayload)
      ).rejects.toThrowError("Unauthorized: Missing auth params");
    });

    test("when the oauth_token is invalid throw an error", async () => {
      await expect(() =>
        new OpenProjectApi().onAuthenticate({
          // invalid token generated with a different secret
          token: "mXPMUDJ41lbo0xc0qjgeUrk0nYfuCKMxPZa+/euNNM8jVpeZI5uU/YQQa60WnLoYo7gkCKlOCcdY5BVS2MqkpnSf5RWQPhNjm0czkiZ6hK4G6Y3EJOZkE67MPyVmyYFGgxnoGajwMAI=--gyIqET3MOf8a+HDk--DW5I6ZOWaGHRgiJ6FjOcZQ==",
          documentName: "https://test.api/api/v3/documents/1",
        } as unknown as onAuthenticatePayload)
      ).rejects.toThrowError("Unsupported state or unable to authenticate data");
    });

    test("when the origin does not match the one in the token", async () => {
      await expect(() =>
        new OpenProjectApi().onAuthenticate({
          token: "Yjo1x80JGIjrK8J6IDOuRn5kIOGvaAUw8C1so+dJJq7cgkllf3dQnw6d8bgiKbHXw8ZaMYE4IyOI1KQgX2ZRmx1mKBkxtb/fc7eCpGyTKGTA2Y1r/q7VJYiJZlpX7gx3nu569joEl/k=--mUkLaPiK0E82vGT9--gj1ZnTNlydL9j+Xw8+YFAA==",
          documentName: "https://test.api/api/v3/documents/1",
          request: {
            headers: {
              origin: "https://different.origin",
            },
          },
        } as unknown as onAuthenticatePayload)
      ).rejects.toThrowError("Unauthorized: Token origin does not match request origin.");
    });

    test("when the resourceUrl does not match the one in the token", async () => {
      fetchMock.mockResolvedValueOnce({ throws: new TypeError("is not a valid URL") });

      await expect(() =>
        new OpenProjectApi().onAuthenticate({
          token: "Yjo1x80JGIjrK8J6IDOuRn5kIOGvaAUw8C1so+dJJq7cgkllf3dQnw6d8bgiKbHXw8ZaMYE4IyOI1KQgX2ZRmx1mKBkxtb/fc7eCpGyTKGTA2Y1r/q7VJYiJZlpX7gx3nu569joEl/k=--mUkLaPiK0E82vGT9--gj1ZnTNlydL9j+Xw8+YFAA==",
          documentName: "https://indemiddle/api/v3/documents/1",
        } as unknown as onAuthenticatePayload)
      ).rejects.toThrowError("Unauthorized: Token resource URL does not match document.");
    });

    test("when the auth server does not authorize the request throw an error", async () => {
      fetchMock.mockResolvedValueOnce({
        ok: false,
        status: 401,
      });

      await expect(() =>
        new OpenProjectApi().onAuthenticate({
          token: "Yjo1x80JGIjrK8J6IDOuRn5kIOGvaAUw8C1so+dJJq7cgkllf3dQnw6d8bgiKbHXw8ZaMYE4IyOI1KQgX2ZRmx1mKBkxtb/fc7eCpGyTKGTA2Y1r/q7VJYiJZlpX7gx3nu569joEl/k=--mUkLaPiK0E82vGT9--gj1ZnTNlydL9j+Xw8+YFAA==",
          documentName: "https://test.api/api/v3/documents/1",
        } as unknown as onAuthenticatePayload)
      ).rejects.toThrowError("Unauthorized: Invalid token or document access denied.");

      expect(fetchMock).toHaveBeenCalledWith(
        "https://test.api/api/v3/documents/1",
        {
          method: "GET",
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer some_token_value",
          },
        }
      );
    });

    test("when the token is valid set the context", async () => {
      fetchMock.mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: () => Promise.resolve({}),
      });

      const data = {
        context: {},
        connectionConfig: {},
        token: "Yjo1x80JGIjrK8J6IDOuRn5kIOGvaAUw8C1so+dJJq7cgkllf3dQnw6d8bgiKbHXw8ZaMYE4IyOI1KQgX2ZRmx1mKBkxtb/fc7eCpGyTKGTA2Y1r/q7VJYiJZlpX7gx3nu569joEl/k=--mUkLaPiK0E82vGT9--gj1ZnTNlydL9j+Xw8+YFAA==",
        documentName: "https://test.api/api/v3/documents/1",
      } as unknown as onAuthenticatePayload;

      await new OpenProjectApi().onAuthenticate(data);

      expect(data.context.resourceUrl).toEqual("https://test.api/api/v3/documents/1");
      expect(data.context.token).toEqual("some_token_value");
      expect(data.documentName).toEqual("https://test.api/api/v3/documents/1");
    });

    test("when there is no update link, setup the connection as readonly", async () => {
      fetchMock.mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: () => Promise.resolve({
          _links: {
            self: { href: "/api/v3/documents/1" }
          }
        }),
      });

      const data = {
        context: {},
        connectionConfig: {},
        token: "Yjo1x80JGIjrK8J6IDOuRn5kIOGvaAUw8C1so+dJJq7cgkllf3dQnw6d8bgiKbHXw8ZaMYE4IyOI1KQgX2ZRmx1mKBkxtb/fc7eCpGyTKGTA2Y1r/q7VJYiJZlpX7gx3nu569joEl/k=--mUkLaPiK0E82vGT9--gj1ZnTNlydL9j+Xw8+YFAA==",
        documentName: "https://test.api/api/v3/documents/1",
      } as unknown as onAuthenticatePayload;

      await new OpenProjectApi().onAuthenticate(data);

      expect(data.connectionConfig.readOnly).toBe(true);
      expect(data.context.readonly).toBe(true);
    });

    test("when there is an update link, setup the connection as writable", async () => {
      fetchMock.mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: () => Promise.resolve({
          title: "TheDocName",
          _links: {
            self: { href: "/api/v3/documents/1" },
            update: { href: "/api/v3/documents/1" }
          }
        }),
      });

      const data = {
        context: {},
        connectionConfig: {},
        token: "Yjo1x80JGIjrK8J6IDOuRn5kIOGvaAUw8C1so+dJJq7cgkllf3dQnw6d8bgiKbHXw8ZaMYE4IyOI1KQgX2ZRmx1mKBkxtb/fc7eCpGyTKGTA2Y1r/q7VJYiJZlpX7gx3nu569joEl/k=--mUkLaPiK0E82vGT9--gj1ZnTNlydL9j+Xw8+YFAA==",
        documentName: "https://test.api/api/v3/documents/1",
      } as unknown as onAuthenticatePayload;

      await new OpenProjectApi().onAuthenticate(data);

      expect(data.connectionConfig.readOnly).toBeUndefined();
      expect(data.context.readonly).toBeUndefined();
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
        json: () => Promise.resolve({ contentBinary: base64Update }),
      });

      const targetDoc = new Y.Doc();
      const data = {
        context: { token: "superValidToken", resourceUrl: "https://test.api/api/v3/documents/121" },
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
            "Authorization": "Bearer superValidToken",
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
        context: { token: "superValidToken", resourceUrl: "https://test.api/api/v3/documents/121" },
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


      const editor = createEditor();
      const blocks = [
        {
          type: "paragraph",
          content: "test document content"
        }
      ];

      const document = new Y.Doc();
      const fragment = document.getXmlFragment('document-store');

      // @ts-expect-error BlockNote types are complicated
      editor.blocksToYXmlFragment(blocks, fragment);

      const data = {
        context: {
          token: "superValidToken",
          resourceUrl: "https://test.api/api/v3/documents/121",
          readonly: false,
        },
        document: { ...document, connections: [] } as unknown as Document,
      } as onStoreDocumentPayload;

      const api = new OpenProjectApi();
      await api.onStoreDocument(data);

      expect(fetchMock).toHaveBeenCalledWith(
        "https://test.api/api/v3/documents/121",
        expect.objectContaining({
          method: "PATCH",
          headers: {
            "Content-Type": "application/json",
            "Authorization": expect.stringContaining("Bearer"),
          },
          body: expect.stringContaining("content_binary"),
        })
      );
    });
  });

  describe("onTokenSync", () => {
    // Valid packed params token: { resource_url: "https://test.api/api/v3/documents/1", oauth_token: "some_token_value", readonly: false }
    const validPackedParamsToken = "Yjo1x80JGIjrK8J6IDOuRn5kIOGvaAUw8C1so+dJJq7cgkllf3dQnw6d8bgiKbHXw8ZaMYE4IyOI1KQgX2ZRmx1mKBkxtb/fc7eCpGyTKGTA2Y1r/q7VJYiJZlpX7gx3nu569joEl/k=--mUkLaPiK0E82vGT9--gj1ZnTNlydL9j+Xw8+YFAA==";

    test("should return early if token is missing", async () => {
      const data = {
        token: "",
        connection: {
          readOnly: false,
          context: { resourceUrl: "https://test.api/api/v3/documents/1" },
        },
        document: {},
      } as unknown as onTokenSyncPayload;

      const api = new OpenProjectApi();
      await api.onTokenSync(data);

      expect(fetchMock).not.toHaveBeenCalled();
    });

    test("should return early if resourceUrl is missing", async () => {
      const data = {
        token: validPackedParamsToken,
        connection: {
          readOnly: false,
          context: {},
        },
        document: {},
      } as unknown as onTokenSyncPayload;

      const api = new OpenProjectApi();
      await api.onTokenSync(data);

      expect(fetchMock).not.toHaveBeenCalled();
    });

    test("should validate and update token on successful sync", async () => {
      fetchMock.mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: () => Promise.resolve({
          _links: {
            self: { href: "/api/v3/documents/1" },
            update: { href: "/api/v3/documents/1" }
          }
        }),
      });

      const data = {
        token: validPackedParamsToken,
        connection: {
          readOnly: false,
          context: {
            resourceUrl: "https://test.api/api/v3/documents/1",
            token: "old_token",
            readonly: false,
          },
        },
        document: {},
      } as unknown as onTokenSyncPayload;

      const api = new OpenProjectApi();
      await api.onTokenSync(data);

      expect(fetchMock).toHaveBeenCalledWith(
        "https://test.api/api/v3/documents/1",
        expect.objectContaining({
          method: "GET",
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer some_token_value",
          },
        })
      );

      expect(data.connection.context.token).toBe("some_token_value");
    });

    test("should update readonly status when permissions change from writable to readonly", async () => {
      fetchMock.mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: () => Promise.resolve({
          _links: {
            self: { href: "/api/v3/documents/1" }
            // No update link = readonly
          }
        }),
      });

      const data = {
        token: validPackedParamsToken,
        connection: {
          readOnly: false,
          context: {
            resourceUrl: "https://test.api/api/v3/documents/1",
            token: "old_token",
            readonly: false,
          },
        },
        document: {},
      } as unknown as onTokenSyncPayload;

      const api = new OpenProjectApi();
      await api.onTokenSync(data);

      expect(data.connection.context.readonly).toBe(true);
      expect(data.connection.readOnly).toBe(true);
    });

    test("should not update context if token validation fails", async () => {
      fetchMock.mockResolvedValueOnce({
        ok: false,
        status: 401,
        statusText: "Unauthorized",
      });

      const data = {
        token: validPackedParamsToken,
        connection: {
          readOnly: false,
          context: {
            resourceUrl: "https://test.api/api/v3/documents/1",
            token: "old_token",
            readonly: false,
          },
        },
        document: {},
      } as unknown as onTokenSyncPayload;

      const api = new OpenProjectApi();
      await api.onTokenSync(data);

      expect(data.connection.context.token).toBe("old_token");
    });

    test("should handle decryption errors gracefully", async () => {
      const data = {
        token: "invalid_encrypted_token",
        connection: {
          readOnly: false,
          context: {
            resourceUrl: "https://test.api/api/v3/documents/1",
            token: "old_token",
          },
        },
        document: {},
      } as unknown as onTokenSyncPayload;

      const api = new OpenProjectApi();
      // Should not throw, just log and return
      await expect(api.onTokenSync(data)).resolves.toBeUndefined();

      expect(data.connection.context.token).toBe("old_token");
    });
  });
});
