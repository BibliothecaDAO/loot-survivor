import { NextRequest, NextResponse } from "next/server";

export async function POST(request: NextRequest) {
  try {
    const rpcKey = process.env.RPC_API_KEY;
    const rpcUrl = process.env.RPC_API_URL;

    if (!rpcUrl) {
      return NextResponse.json(
        { error: "API URL not configured" },
        { status: 500 }
      );
    }

    const body = await request.json();

    const response = await fetch(`${rpcUrl}/${rpcKey}`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      console.error("RPC API responded with status:", response.status);
      return NextResponse.json(
        { error: "RPC API request failed" },
        { status: response.status }
      );
    }

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error) {
    console.error("Error in rpc-proxy:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
