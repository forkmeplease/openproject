import { onAuthenticatePayload, onLoadDocumentPayload, onStoreDocumentPayload } from "@hocuspocus/server";
import { afterEach, beforeEach, describe, expect, test, vi } from "vitest";
import * as Y from "yjs";
import { OpenProjectApi, createEditor } from "../../src/extensions/openProjectApi";

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
          requestParameters: new URLSearchParams({ document_id: "121", openproject_base_path: "https://test.api" }),
        } as unknown as onAuthenticatePayload)
      ).rejects.toThrowError("Unauthorized: Token missing.");
    });

    test("when the opBasePath is not present throw an error", async () => {
      await expect(() =>
        new OpenProjectApi().onAuthenticate({
          token: "7u+b+QRJN7qANls=--URNw83hIWBq3MMIA--jtl+UPdtbniQVFNOs2EcAw==",
          requestParameters: new URLSearchParams({ document_id: "121" }),
        } as unknown as onAuthenticatePayload)
      ).rejects.toThrowError("Unauthorized: Base URL missing.");
    });

    test("when ALLOWED_DOMAINS is not configured throw an error", async () => {
      delete process.env.ALLOWED_DOMAINS;

      await expect(() =>
        new OpenProjectApi().onAuthenticate({
          token: "7u+b+QRJN7qANls=--URNw83hIWBq3MMIA--jtl+UPdtbniQVFNOs2EcAw==",
          requestParameters: new URLSearchParams({ document_id: "121", openproject_base_path: "https://test.api" }),
        } as unknown as onAuthenticatePayload)
      ).rejects.toThrowError("Unauthorized: No allowed domains configured.");
    });

    test("when opBasePath has invalid format throw an error", async () => {
      await expect(() =>
        new OpenProjectApi().onAuthenticate({
          token: "7u+b+QRJN7qANls=--URNw83hIWBq3MMIA--jtl+UPdtbniQVFNOs2EcAw==",
          requestParameters: new URLSearchParams({ document_id: "121", openproject_base_path: "not-a-valid-url" }),
        } as unknown as onAuthenticatePayload)
      ).rejects.toThrowError("Unauthorized: Invalid base URL format.");
    });

    test("when opBasePath domain is not in ALLOWED_DOMAINS throw an error", async () => {
      await expect(() =>
        new OpenProjectApi().onAuthenticate({
          token: "7u+b+QRJN7qANls=--URNw83hIWBq3MMIA--jtl+UPdtbniQVFNOs2EcAw==",
          requestParameters: new URLSearchParams({ document_id: "121", openproject_base_path: "https://malicious.com" }),
        } as unknown as onAuthenticatePayload)
      ).rejects.toThrowError("Unauthorized: Invalid base URL domain.");
    });

    test("when opBasePath subdomain matches ALLOWED_DOMAINS it should be accepted", async () => {
      fetchMock.mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: () => Promise.resolve({ title: "TheDocName" }),
      });

      const data = {
        context: {},
        connectionConfig: {},
        token: "7u+b+QRJN7qANls=--URNw83hIWBq3MMIA--jtl+UPdtbniQVFNOs2EcAw==",
        documentName: "TheDocName",
        requestParameters: new URLSearchParams({ document_id: "121", openproject_base_path: "https://subdomain.test.api" }),
      } as unknown as onAuthenticatePayload;

      await new OpenProjectApi().onAuthenticate(data);

      expect(data.context.opBasePath).toEqual("https://subdomain.test.api");
    });

    test("when the token is invalid", async () => {
      await expect(() =>
        new OpenProjectApi().onAuthenticate({
          // Invalid token, generated with a different secret
          token: "5Sm4blMLhP8PFS67xw==--br8L/7YDX3rbTLpT--HHEi+SnNdmHmH90N3mHY9A==",
          documentName: "TheDocName",
          requestParameters: new URLSearchParams({ document_id: "121", openproject_base_path: "https://test.api" }),
        } as unknown as onAuthenticatePayload)
      ).rejects.toThrowError("Unsupported state or unable to authenticate data");
    });

    test("when the server does not authorize the request throw an error", async () => {
      fetchMock.mockResolvedValueOnce({
        ok: false,
        status: 401,
      });

      await expect(() =>
        new OpenProjectApi().onAuthenticate({
          token: "7u+b+QRJN7qANls=--URNw83hIWBq3MMIA--jtl+UPdtbniQVFNOs2EcAw==",
          documentName: "TheDocName",
          requestParameters: new URLSearchParams({ document_id: "121", openproject_base_path: "https://test.api" }),
        } as unknown as onAuthenticatePayload)
      ).rejects.toThrowError("Unauthorized: Invalid token.");

      expect(fetchMock).toHaveBeenCalledWith(
        "https://test.api/api/v3/documents/121",
        {
          method: "GET",
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer valid_token",
          },
        }
      );
    });

    test("when the document title does not match the requested documentName, throw an error", async () => {
      fetchMock.mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: () => Promise.resolve({ title: "DifferentDocName" }),
      });

      await expect(() =>
        new OpenProjectApi().onAuthenticate({
          token: "7u+b+QRJN7qANls=--URNw83hIWBq3MMIA--jtl+UPdtbniQVFNOs2EcAw==",
          documentName: "TheDocName",
          requestParameters: new URLSearchParams({ document_id: "121", openproject_base_path: "https://test.api" }),
        } as unknown as onAuthenticatePayload)
      ).rejects.toThrowError("Unauthorized: Document access denied.");
    });

    test("when the token is valid and document title matches, set the document_id, token and opBasePath on the context", async () => {
      fetchMock.mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: () => Promise.resolve({ title: "TheDocName" }),
      });

      const data = {
        context: {},
        connectionConfig: {},
        token: "7u+b+QRJN7qANls=--URNw83hIWBq3MMIA--jtl+UPdtbniQVFNOs2EcAw==",
        documentName: "TheDocName",
        requestParameters: new URLSearchParams({ document_id: "121", openproject_base_path: "https://test.api" }),
      } as unknown as onAuthenticatePayload;

      await new OpenProjectApi().onAuthenticate(data);

      expect(data.context.documentId).toEqual("121");
      expect(data.context.token).toEqual("valid_token");
      expect(data.context.opBasePath).toEqual("https://test.api");
      expect(data.documentName).toEqual("TheDocName");
    });

    test("when there is no update link, setup the connection as readonly", async () => {
      fetchMock.mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: () => Promise.resolve({
          title: "TheDocName",
          _links: {
            self: { href: "/api/v3/documents/121" }
          }
        }),
      });

      const data = {
        context: {},
        connectionConfig: {},
        token: "7u+b+QRJN7qANls=--URNw83hIWBq3MMIA--jtl+UPdtbniQVFNOs2EcAw==",
        documentName: "TheDocName",
        requestParameters: new URLSearchParams({ document_id: "121", openproject_base_path: "https://test.api" }),
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
            self: { href: "/api/v3/documents/121" },
            update: { href: "/api/v3/documents/121" }
          }
        }),
      });

      const data = {
        context: {},
        connectionConfig: {},
        token: "7u+b+QRJN7qANls=--URNw83hIWBq3MMIA--jtl+UPdtbniQVFNOs2EcAw==",
        documentName: "TheDocName",
        requestParameters: new URLSearchParams({ document_id: "121", openproject_base_path: "https://test.api" }),
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
        json: () => Promise.resolve({
          contentBinary: base64Update
        }),
      });

      const targetDoc = new Y.Doc();
      const data = {
        context: { documentId: "121", token: "testToken", opBasePath: "https://test.api" },
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
        context: { documentId: "121", token: "testToken", opBasePath: "https://test.api" },
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
          documentId: "121",
          token: "testToken",
          opBasePath: "https://test.api",
          readonly: false
        },
        document,
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
});
