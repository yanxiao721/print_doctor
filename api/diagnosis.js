const DEFAULT_ENDPOINT = "https://unifyapi.xyz/v1/responses";
const DEFAULT_MODEL = "gpt-5.5";

function setCorsHeaders(response) {
  response.setHeader("Access-Control-Allow-Origin", "*");
  response.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  response.setHeader("Access-Control-Allow-Headers", "Content-Type");
  response.setHeader("Cache-Control", "no-store");
}

module.exports = async function diagnosisProxy(request, response) {
  setCorsHeaders(response);

  if (request.method === "OPTIONS") {
    return response.status(204).end();
  }

  if (request.method !== "POST") {
    return response.status(405).json({ error: { message: "Method not allowed" } });
  }

  const apiKey = process.env.OPENAI_API_KEY;
  const upstreamEndpoint = process.env.AI_DIAGNOSIS_ENDPOINT || DEFAULT_ENDPOINT;
  const model = process.env.AI_DIAGNOSIS_MODEL || DEFAULT_MODEL;

  if (!apiKey) {
    return response.status(500).json({
      error: { message: "Server AI token is not configured" },
    });
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 70000);

  try {
    const payload = {
      ...request.body,
      // 前端也会传 model，这里再覆盖一次，避免用户篡改请求刷其它模型。
      model,
    };

    const upstreamResponse = await fetch(upstreamEndpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify(payload),
      signal: controller.signal,
    });

    const text = await upstreamResponse.text();
    response.status(upstreamResponse.status);
    response.setHeader(
      "Content-Type",
      upstreamResponse.headers.get("content-type") || "application/json; charset=utf-8",
    );
    return response.send(text);
  } catch (error) {
    const isTimeout = error && error.name === "AbortError";
    return response.status(isTimeout ? 504 : 502).json({
      error: {
        message: isTimeout ? "AI request timed out" : "AI proxy request failed",
      },
    });
  } finally {
    clearTimeout(timeout);
  }
};
