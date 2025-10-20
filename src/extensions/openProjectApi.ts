import type { onAuthenticatePayload, onLoadDocumentPayload, onStoreDocumentPayload } from "@hocuspocus/server";
import { Extension } from "@hocuspocus/server";
import * as Y from "yjs";
import type { ApiResponseDocument } from "../types";

export class OpenProjectApi implements Extension {
  /**
    * Authenticate the user by validating the token and document access
    */
  async onAuthenticate(data: onAuthenticatePayload) {
    const { token, documentName, requestParameters } = data;
    const documentId = requestParameters.get("documentId");
    const returnUrl = requestParameters.get("returnUrl");

    if (!token) {
      throw new Error('Unauthorized: Token missing.');
    }

    if (!returnUrl) {
      throw new Error('Unauthorized: Return URL missing.');
    }

    // Validate returnUrl against allowed domains
    const allowedDomains = process.env.ALLOWED_DOMAINS?.split(',') || [];
    if (allowedDomains.length <= 0) {
      throw new Error('Unauthorized: No allowed domains configured.');
    }
    
    try {
      const url = new URL(returnUrl);
      const isAllowed = allowedDomains.some(domain =>
        url.hostname === domain.trim() || url.hostname.endsWith('.' + domain.trim())
      );

      if (!isAllowed) {
        throw new Error('Unauthorized: Invalid return URL domain.');
      }
    } catch (error) {
      if (error instanceof TypeError) {
        throw new Error('Unauthorized: Invalid return URL format.');
      }
      throw error;
    }

    const targetUrl = `${returnUrl}/api/v3/documents/${documentId}`;
    const response = await fetch(targetUrl, {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${token}`,
      },
    });

    if (!response.ok) {
      throw new Error('Unauthorized: Invalid token.');
    }
    const jsonData = await response.json() as ApiResponseDocument;

    if (!jsonData.title || jsonData.title !== documentName) {
      throw new Error('Unauthorized: Document access denied.');
    }

    data.documentName = jsonData.title;
    data.context.documentId = documentId;
    data.context.token = token;
    data.context.returnUrl = returnUrl;
  }

  /**
    * Retrieve data from the API. This should return the YDoc data
    */
  async onLoadDocument(data: onLoadDocumentPayload) {
    const { documentId, returnUrl } = data.context;

    const targetUrl = `${returnUrl}/api/v3/documents/${documentId}`;
    console.log(`GET ${targetUrl}`);

    const response = await fetch(targetUrl, {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${data.context.token}`,
      },
    });

    if (!response.ok) {
      console.warn(`Error fetching document: ${response.statusText}`);
      return;
    }

    const jsonData = await response.json() as ApiResponseDocument;
    if (jsonData.contentBinary) {
      const update = new Uint8Array(Buffer.from(jsonData.contentBinary, 'base64'));
      Y.applyUpdate(data.document, update);
    }
  }

  /**
    * Store data to the API. The data is a YDoc update
    */
  async onStoreDocument(data: onStoreDocumentPayload): Promise<void> {
    const { documentId, returnUrl } = data.context;

    const targetUrl = `${returnUrl}/api/v3/documents/${documentId}`;
    console.log(`PATCH ${targetUrl}`);

    const base64Data = Buffer.from(Y.encodeStateAsUpdate(data.document)).toString("base64");

    const response = await fetch(targetUrl, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${data.context.token}`,
      },
      body: JSON.stringify({
        content_binary: base64Data
      }),
    });

    if (!response.ok) {
      console.warn(`Error storing document: ${response.statusText}`);
    }
  }
}

