// Follow along: https://github.com/supabase/supabase/tree/master/supabase/functions
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// CORS headers
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// AI Model configurations
const MODELS = {
  standard: {
    provider: "gemini",
    endpoint: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent",
    key: Deno.env.get("GEMINI_API_KEY"),
  },
  fallback: {
    provider: "openai",
    endpoint: "https://api.openai.com/v1/chat/completions",
    key: Deno.env.get("OPENAI_API_KEY"),
  },
  custom: {
    provider: "chinese_ai",
    endpoint: Deno.env.get("CHINESE_AI_ENDPOINT") || "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions",
    key: Deno.env.get("CHINESE_AI_API_KEY"),
  },
};

// System prompts for different action types
const SYSTEM_PROMPTS: Record<string, string> = {
  summarize: `You are a document summarization assistant. Summarize the provided document with:
1. A one-paragraph overview
2. Five key bullet points
3. Three key terms defined

Be concise and accurate.`,

  translate: `You are a professional translator. Translate the following document content to the target language.
Preserve the original formatting, structure, and tone.
Do not add any explanations or notes.`,

  extract_text: `You are a text extraction assistant. Extract all readable text content from the document.
Return only the clean text without any formatting or markup.`,

  extract_tables: `You are a data extraction specialist. Identify and extract all tables from the document.
Return each table in Markdown table format.
If no tables are found, return an empty response.`,

  chat: `You are a helpful document assistant. The user has provided a document and will ask questions about it.
Answer questions accurately based on the document content.
If you don't know the answer or it's not in the document, say so clearly.`,

  custom: `You are a document AI agent. The user has provided a document and will make a custom request.
Complete their request accurately and thoroughly.
Return structured, well-formatted output when appropriate.`,
};

interface AiRequest {
  action_type: string;
  doc_id?: string;
  user_id?: string;
  prompt?: string;
  file_url?: string;
  file_content?: string;
  language?: string;
}

interface AiResponse {
  result: string;
  credits_remaining: number;
  model_used: string;
  tokens_in?: number;
  tokens_out?: number;
  declined?: boolean;
  reason?: string;
}

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Only accept POST requests
    if (req.method !== "POST") {
      throw new Error("Method not allowed");
    }

    // Parse request body
    const body: AiRequest = await req.json();
    const { action_type, doc_id, user_id, prompt, file_url, file_content, language } = body;

    // Validate required fields
    if (!action_type || !user_id) {
      throw new Error("Missing required fields: action_type and user_id");
    }

    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      }
    );

    // Verify auth token from request header
    const authHeader = req.headers.get("authorization");
    if (!authHeader) {
      throw new Error("Missing authorization header");
    }

    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser(token);

    if (authError || !user) {
      throw new Error("Invalid or expired token");
    }

    // Verify user ID matches
    if (user.id !== user_id) {
      throw new Error("User ID mismatch");
    }

    // Fetch user data to check credits
    const { data: userData, error: userError } = await supabaseClient
      .from("users")
      .select("credits_remaining, plan, ai_docs_used")
      .eq("id", user_id)
      .single();

    if (userError || !userData) {
      throw new Error("Failed to fetch user data");
    }

    // Determine credit cost
    const isCustomRequest = action_type === "custom";
    const creditCost = isCustomRequest ? 3 : 1;

    // Check if user has enough credits (unless it's a standard skill for free tier)
    if (userData.plan === "free" && !isCustomRequest) {
      // Free tier uses ai_docs_used counter instead of credits for standard skills
      if (userData.ai_docs_used >= 3) {
        return new Response(
          JSON.stringify({
            error: "AI document limit reached. Please upgrade to Premium.",
            upgrade_required: true,
          }),
          {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
            status: 403,
          }
        );
      }
    } else if (userData.credits_remaining < creditCost) {
      return new Response(
        JSON.stringify({
          error: "Insufficient credits. Please upgrade or wait for monthly reset.",
          credits_remaining: userData.credits_remaining,
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 403,
        }
      );
    }

    // For custom requests, classify the request first
    let finalActionType = action_type;
    let classificationResult = null;
    
    if (action_type === "custom" && prompt) {
      // Step 1: Classification
      classificationResult = await classifyRequest(prompt, file_content || "");
      
      if (classificationResult.category === "A" && classificationResult.matched_skill) {
        // Redirect to standard skill, charge 1 credit
        finalActionType = classificationResult.matched_skill;
      } else if (classificationResult.category === "C") {
        // Decline request, charge 0 credits
        return new Response(
          JSON.stringify({
            declined: true,
            reason: classificationResult.reason,
            credits_remaining: userData.credits_remaining,
          }),
          {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }
      // Otherwise, proceed with custom AI (category B)
    }

    // Get document content if not provided
    let content = file_content || "";
    if (!content && doc_id) {
      const { data: docData } = await supabaseClient
        .from("documents")
        .select("ocr_text, file_url")
        .eq("id", doc_id)
        .single();

      content = docData?.ocr_text || "";
    }

    // Select AI model based on action type
    const modelConfig = action_type === "custom" ? MODELS.custom : MODELS.standard;

    // Build the prompt
    const systemPrompt = SYSTEM_PROMPTS[finalActionType] || SYSTEM_PROMPTS.chat;
    let userPrompt = prompt || "";

    if (finalActionType === "translate" && language) {
      userPrompt = `Translate to ${language}: ${userPrompt || content}`;
    } else if (content && !userPrompt) {
      userPrompt = content;
    } else if (content && userPrompt) {
      userPrompt = `${userPrompt}\n\nDocument content:\n${content}`;
    }

    // Call AI provider
    let aiResult: string;
    let tokensIn = 0;
    let tokensOut = 0;

    if (modelConfig.provider === "gemini") {
      const response = await fetch(`${modelConfig.endpoint}?key=${modelConfig.key}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{
            parts: [{
              text: `${systemPrompt}\n\n${userPrompt}`
            }]
          }],
          generationConfig: {
            temperature: 0.7,
            maxOutputTokens: 4096,
          },
        }),
      });

      const result = await response.json();
      aiResult = result.candidates?.[0]?.content?.parts?.[0]?.text || "";
      tokensIn = result.usageMetadata?.promptTokenCount || 0;
      tokensOut = result.usageMetadata?.candidatesTokenCount || 0;
    } else {
      // OpenAI-compatible format (for fallback and Chinese AI)
      const response = await fetch(modelConfig.endpoint, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${modelConfig.key}`,
        },
        body: JSON.stringify({
          model: action_type === "custom" ? "qwen-plus" : "gpt-4o-mini",
          messages: [
            { role: "system", content: systemPrompt },
            { role: "user", content: userPrompt },
          ],
          temperature: 0.7,
          max_tokens: 4096,
        }),
      });

      const result = await response.json();
      aiResult = result.choices?.[0]?.message?.content || "";
      tokensIn = result.usage?.prompt_tokens || 0;
      tokensOut = result.usage?.completion_tokens || 0;
    }

    if (!aiResult) {
      throw new Error("AI provider returned empty response");
    }

    // Deduct credits/update usage
    let newCreditsRemaining = userData.credits_remaining;
    const isRedirectedToStandard = classificationResult !== null && 
                                    classificationResult.category === "A" && 
                                    classificationResult.matched_skill;
    
    if (userData.plan === "free" && !isCustomRequest && !isRedirectedToStandard) {
      // Increment ai_docs_used for free tier standard skills
      await supabaseClient.rpc("increment_ai_docs_used");
      const { data: updatedUser } = await supabaseClient
        .from("users")
        .select("ai_docs_used")
        .eq("id", user_id)
        .single();
      newCreditsRemaining = 0; // Free tier doesn't use credits for standard skills
    } else {
      // Deduct credits (1 for standard/redirected, 3 for custom)
      const creditCost = isRedirectedToStandard ? 1 : 3;
      await supabaseClient.rpc("deduct_credits", { amount: creditCost });
      newCreditsRemaining -= creditCost;
    }

    // Log AI action
    await supabaseClient.from("ai_actions").insert({
      user_id: user_id,
      document_id: doc_id || null,
      action_type: finalActionType,
      model_used: modelConfig.provider,
      tokens_in: tokensIn,
      tokens_out: tokensOut,
      credits_charged: creditCost,
      result: aiResult.substring(0, 1000), // Store first 1000 chars
    });

    // Return response
    const response: AiResponse = {
      result: aiResult,
      credits_remaining: newCreditsRemaining,
      model_used: modelConfig.provider,
      tokens_in: tokensIn,
      tokens_out: tokensOut,
    };

    // Add redirect notice if we handled a custom request as standard
    if (isRedirectedToStandard) {
      response.result = `[Standard Request] ${aiResult}`;
    }

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (error) {
    console.error("AI Router Error:", error);
    
    return new Response(
      JSON.stringify({
        error: error.message || "AI service unavailable",
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 500,
      }
    );
  }
});

/**
 * Classify custom user requests
 */
async function classifyRequest(userRequest: string, documentContent: string) {
  const standardSkills = ["summarize", "translate", "extract_text", "extract_tables", "convert_format"];

  try {
    const response = await fetch(
      `${MODELS.standard.endpoint}?key=${MODELS.standard.key}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{
            parts: [{
              text: `Classify this user request into one of three categories:
A) standard_skill: the request matches one of these: ${standardSkills.join(", ")}
B) custom_feasible: the request is a valid document task our AI can do
C) out_of_scope: the request cannot be done with a document AI agent

Return JSON only: {"category": "A"|"B"|"C", "matched_skill": "skill_name"|"null", "reason": "explanation"}

User request: ${userRequest}

Document preview: ${documentContent.substring(0, 500)}`
            }]
          }],
        }),
      }
    );

    const result = await response.json();
    const text = result.candidates?.[0]?.content?.parts?.[0]?.text || "{}";
    
    // Parse JSON from response
    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      return JSON.parse(jsonMatch[0]);
    }
    
    return { category: "B", matched_skill: null, reason: "Custom feasible request" };
  } catch (error) {
    console.error("Classification error:", error);
    // Default to custom feasible on error
    return { category: "B", matched_skill: null, reason: "Classification failed, treating as custom" };
  }
}
