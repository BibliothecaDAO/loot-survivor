import { NextRequest, NextResponse } from "next/server";

export async function POST(request: NextRequest) {
  // Clone the request body before reading it
  const clonedRequest = request.clone();

  // Get the API selection from query parameters
  const { searchParams } = new URL(request.url);
  const apiSelection = searchParams.get("api") || "katana";

  // Choose the appropriate API key and URL based on the selection
  let apiKey, apiUrl;

  if (apiSelection === "katana") {
    apiKey = process.env.KATANA_GRAPHQL_API_KEY;
    apiUrl = process.env.KATANA_GRAPHQL_API_URL;
  } else {
    apiKey = process.env.GRAPHQL_API_KEY;
    apiUrl = process.env.GRAPHQL_API_URL;
  }

  const isDevelopment = process.env.NEXT_PUBLIC_NETWORK === "development";

  if (!apiUrl) {
    return NextResponse.json(
      { error: "API URL not configured" },
      { status: 500 }
    );
  }

  const body = await clonedRequest.json();

  const headers: HeadersInit = {
    "Content-Type": "application/json",
  };

  // Only add the API key if it exists and we're not in development mode
  if (apiKey && !isDevelopment) {
    headers["X-API-Key"] = apiKey;
    // Add a cache-busting parameter to the body
    body.variables = {
      ...body.variables,
      _cacheBuster: Date.now(),
    };
  }

  // console.log({
  //   ...headers,
  //   "Cache-Control": "no-cache, no-store, must-revalidate",
  // });

  const response = await fetch(apiUrl, {
    method: "POST",
    headers: {
      ...headers,
    },
    body: JSON.stringify(body),
  });

  const data = await response.json();

  console.log(JSON.stringify(data, null, 2));

  return NextResponse.json(data);
}
