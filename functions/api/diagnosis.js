export async function onRequest(context) {
  const { request, env } = context;

  if (request.method === "OPTIONS") {
    return cors(new Response(null, { status: 204 }));
  }

  if (request.method !== "POST") {
    return cors(Response.json({ error: { message: "Method not allowed" } }, { status: 405 }));
  }

  const apiKey = env.OPENAI_API_KEY;
  if (!apiKey) {
    return cors(
      Response.json({ error: { message: "Server AI token is not configured" } }, { status: 500 }),
    );
  }

  const upstreamEndpoint = env.AI_DIAGNOSIS_ENDPOINT || "https://unifyapi.xyz/v1/responses";
  const model = env.AI_DIAGNOSIS_MODEL || "gpt-5.4";

  try {
    const body = await request.json();
    const payload = {
      ...body,
      // 前端只负责传诊断内容，真正的模型由服务端环境变量统一控制。
      model,
    };

    const upstreamResponse = await fetch(upstreamEndpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify(payload),
    });

    const text = await upstreamResponse.text();
    return cors(
      new Response(text, {
        status: upstreamResponse.status,
        headers: {
          "Content-Type":
            upstreamResponse.headers.get("content-type") || "application/json; charset=utf-8",
        },
      }),
    );
  } catch (error) {
    return cors(
      Response.json(
        {
          error: {
            message: error?.name === "SyntaxError" ? "Invalid JSON body" : "AI proxy request failed",
          },
        },
        { status: error?.name === "SyntaxError" ? 400 : 502 },
      ),
    );
  }
}

function cors(response) {
  response.headers.set("Access-Control-Allow-Origin", "*");
  response.headers.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  response.headers.set("Access-Control-Allow-Headers", "Content-Type");
  response.headers.set("Cache-Control", "no-store");
  return response;
}
