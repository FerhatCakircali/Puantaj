// Supabase Edge Function: send-push-notification
// Firebase Cloud Messaging API (V1) ile push notification gönderir
// Modern OAuth 2.0 authentication kullanır

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface NotificationRequest {
    recipientId: number;
    title: string;
    message: string;
    notificationType: string;
    relatedId?: number;
}

serve(async (req) => {
    if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders });
    }

    try {
        const { recipientId, title, message, notificationType, relatedId }: NotificationRequest = await req.json();

        console.log("📬 Push notification isteği:", { recipientId, title, notificationType });

        // Supabase client
        const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
        const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
        const supabase = createClient(supabaseUrl, supabaseServiceKey);

        // FCM token'ları al
        const { data: tokens, error: tokenError } = await supabase
            .from("fcm_tokens")
            .select("token, device_type")
            .or(`user_id.eq.${recipientId},worker_id.eq.${recipientId}`)
            .eq("is_active", true);

        if (tokenError) {
            console.error("❌ Token sorgusu hatası:", tokenError);
            return new Response(JSON.stringify({ error: "Token query failed" }), {
                status: 500,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            });
        }

        if (!tokens || tokens.length === 0) {
            console.warn("⚠️ FCM token bulunamadı (recipient:", recipientId, ")");
            return new Response(JSON.stringify({ success: false, message: "No FCM token found" }), {
                status: 404,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            });
        }

        console.log(`✅ ${tokens.length} adet FCM token bulundu`);

        // Firebase Service Account JSON
        const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
        if (!serviceAccountJson) {
            console.error("❌ FIREBASE_SERVICE_ACCOUNT_JSON bulunamadı");
            return new Response(JSON.stringify({ error: "Service account not configured" }), {
                status: 500,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            });
        }

        const serviceAccount = JSON.parse(serviceAccountJson);
        const projectId = serviceAccount.project_id;

        // OAuth 2.0 Access Token al (basitleştirilmiş)
        const accessToken = await getAccessToken(serviceAccount);

        // Her token için FCM'e push notification gönder
        const results = [];
        for (const tokenData of tokens) {
            try {
                // Firebase Cloud Messaging API (V1)
                const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

                const fcmResponse = await fetch(fcmUrl, {
                    method: "POST",
                    headers: {
                        "Authorization": `Bearer ${accessToken}`,
                        "Content-Type": "application/json",
                    },
                    body: JSON.stringify({
                        message: {
                            token: tokenData.token,
                            notification: {
                                title: title,
                                body: message,
                            },
                            data: {
                                notification_type: notificationType,
                                related_id: relatedId?.toString() || "",
                                click_action: "FLUTTER_NOTIFICATION_CLICK",
                            },
                            android: {
                                priority: "high",
                                notification: {
                                    sound: "default",
                                },
                            },
                        },
                    }),
                });

                if (fcmResponse.ok) {
                    console.log("✅ Push notification gönderildi:", tokenData.token.substring(0, 20) + "...");

                    // Token'ın last_used_at'ini güncelle
                    await supabase
                        .from("fcm_tokens")
                        .update({ last_used_at: new Date().toISOString() })
                        .eq("token", tokenData.token);

                    results.push({ token: tokenData.token, success: true });
                } else {
                    const errorData = await fcmResponse.json();
                    console.error("❌ FCM gönderim hatası:", errorData);

                    // Token geçersizse deaktif et
                    if (errorData.error?.status === "NOT_FOUND" || errorData.error?.status === "INVALID_ARGUMENT") {
                        console.warn("⚠️ Geçersiz token, deaktif ediliyor");
                        await supabase
                            .from("fcm_tokens")
                            .update({ is_active: false })
                            .eq("token", tokenData.token);
                    }

                    results.push({ token: tokenData.token, success: false, error: errorData });
                }
            } catch (error) {
                console.error("❌ Token için gönderim hatası:", error);
                results.push({ token: tokenData.token, success: false, error: error.message });
            }
        }

        const successCount = results.filter((r) => r.success).length;
        console.log(`📊 Sonuç: ${successCount}/${results.length} başarılı`);

        return new Response(
            JSON.stringify({
                success: true,
                totalTokens: tokens.length,
                successCount: successCount,
                results: results,
            }),
            {
                status: 200,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            }
        );
    } catch (error) {
        console.error("❌ Edge Function hatası:", error);
        return new Response(
            JSON.stringify({ error: "Internal server error", details: error.message }),
            {
                status: 500,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            }
        );
    }
});

// OAuth 2.0 Access Token alma (Google Service Account)
async function getAccessToken(serviceAccount: any): Promise<string> {
    const jwtHeader = btoa(JSON.stringify({ alg: "RS256", typ: "JWT" }));

    const now = Math.floor(Date.now() / 1000);
    const jwtPayload = btoa(JSON.stringify({
        iss: serviceAccount.client_email,
        scope: "https://www.googleapis.com/auth/firebase.messaging",
        aud: "https://oauth2.googleapis.com/token",
        exp: now + 3600,
        iat: now,
    }));

    const unsignedToken = `${jwtHeader}.${jwtPayload}`;

    // Private key ile JWT imzala (Deno crypto API)
    const privateKeyPem = serviceAccount.private_key;
    const privateKey = await crypto.subtle.importKey(
        "pkcs8",
        pemToArrayBuffer(privateKeyPem),
        { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
        false,
        ["sign"]
    );

    const signature = await crypto.subtle.sign(
        "RSASSA-PKCS1-v1_5",
        privateKey,
        new TextEncoder().encode(unsignedToken)
    );

    const signatureBase64 = btoa(String.fromCharCode(...new Uint8Array(signature)));
    const jwt = `${unsignedToken}.${signatureBase64}`;

    // Access token al
    const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({
            grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
            assertion: jwt,
        }),
    });

    const tokenData = await tokenResponse.json();

    if (!tokenData.access_token) {
        throw new Error(`OAuth token alınamadı: ${JSON.stringify(tokenData)}`);
    }

    return tokenData.access_token;
}

// PEM formatını ArrayBuffer'a çevir
function pemToArrayBuffer(pem: string): ArrayBuffer {
    const pemContents = pem
        .replace("-----BEGIN PRIVATE KEY-----", "")
        .replace("-----END PRIVATE KEY-----", "")
        .replace(/\s/g, "");

    const binaryString = atob(pemContents);
    const bytes = new Uint8Array(binaryString.length);

    for (let i = 0; i < binaryString.length; i++) {
        bytes[i] = binaryString.charCodeAt(i);
    }

    return bytes.buffer;
}
