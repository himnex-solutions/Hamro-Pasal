import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import nodemailer from "npm:nodemailer";
import { GoogleAuth } from "npm:google-auth-library";

// ─── 1. SUPABASE CLIENT & ENV VARIABLES ─────────────────────────
const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";
const supabase = createClient(supabaseUrl, supabaseServiceKey);

// SMTP Credentials
const smtpHost = Deno.env.get("SMTP_HOST") || "";
const smtpPort = parseInt(Deno.env.get("SMTP_PORT") || "587");
const smtpUser = Deno.env.get("SMTP_USER") || "";
const smtpPass = Deno.env.get("SMTP_PASS") || "";
const smtpFrom = Deno.env.get("SMTP_FROM") || "";

// Firebase Service Account
const firebaseServiceAccount = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON") || "";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// ─── 2. FIREBASE OAUTH2 ACCESS TOKEN GENERATOR ───────────────────
async function getFcmAccessToken(): Promise<string | null> {
  if (!firebaseServiceAccount) {
    console.warn("FCM: FIREBASE_SERVICE_ACCOUNT_JSON not set. Skipping push notifications.");
    return null;
  }
  try {
    const credentials = JSON.parse(firebaseServiceAccount);
    const auth = new GoogleAuth({
      credentials,
      scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
    });
    const client = await auth.getClient();
    const tokenResponse = await client.getAccessToken();
    return tokenResponse.token || null;
  } catch (err) {
    console.error("FCM auth error:", err);
    return null;
  }
}

// ─── 3. SEND PUSH NOTIFICATION VIA FCM ──────────────────────────
async function sendPushNotification(userId: string, title: string, body: string, dataPayload: Record<string, string> = {}) {
  const token = await getFcmAccessToken();
  if (!token) return;

  // Get user devices
  const { data: devices, error } = await supabase
    .from("user_devices")
    .select("fcm_token")
    .eq("user_id", userId);

  if (error || !devices || devices.length === 0) {
    console.log(`No registered FCM tokens found for user ${userId}`);
    return;
  }

  // Get project ID from credentials
  const credentials = JSON.parse(firebaseServiceAccount);
  const projectId = credentials.project_id;

  for (const device of devices) {
    try {
      const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
      const response = await fetch(fcmUrl, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token: device.fcm_token,
            notification: { title, body },
            data: dataPayload,
          },
        }),
      });

      const resData = await response.json();
      if (!response.ok) {
        console.error(`FCM Message Send Error:`, resData);
        if (resData.error?.status === "UNREGISTERED") {
          // Clean up stale tokens
          await supabase.from("user_devices").delete().eq("fcm_token", device.fcm_token);
          console.log(`Cleaned up stale FCM token: ${device.fcm_token}`);
        }
      } else {
        console.log(`Successfully sent FCM notification to device of user ${userId}`);
      }
    } catch (err) {
      console.error(`Failed to send push notification to token ${device.fcm_token}:`, err);
    }
  }
}

// ─── 4. RENDER EMAIL HTML TEMPLATES ──────────────────────────────
interface EmailTemplateData {
  template: string;
  name?: string;
  plan_name?: string;
  screenshot_url?: string;
  reason?: string;
  user_name?: string;
  user_email?: string;
  created_at?: string;
  days_left?: number;
}

function renderHtmlTemplate(data: EmailTemplateData): { html: string; text: string } {
  const primaryColor = "#4F46E5";
  const darkBg = "#0F172A";

  const header = `
    <div style="background-color: ${darkBg}; padding: 32px; text-align: center; border-radius: 16px 16px 0 0;">
      <h1 style="color: white; margin: 0; font-family: 'Outfit', 'Inter', sans-serif; font-size: 28px; font-weight: 800; letter-spacing: -0.5px;">Smart Saoji</h1>
      <p style="color: #6366F1; margin: 4px 0 0 0; font-family: 'Inter', sans-serif; font-size: 14px; font-weight: 600; letter-spacing: 1.5px; text-transform: uppercase;">Smart Retail Suite</p>
    </div>
  `;

  const footer = `
    <div style="padding: 24px; text-align: center; font-family: 'Inter', sans-serif; font-size: 12px; color: #64748B; border-top: 1px solid #E2E8F0; margin-top: 32px;">
      <p style="margin: 0 0 8px 0;">&copy; ${new Date().getFullYear()} Smart Saoji. All rights reserved.</p>
      <p style="margin: 0;">Need help? Contact our support at <a href="mailto:support@smartsaoji.com" style="color: ${primaryColor}; text-decoration: none; font-weight: 600;">support@smartsaoji.com</a></p>
    </div>
  `;

  const buildBody = (content: string) => `
    <div style="background-color: #F8FAFC; padding: 24px 12px; min-height: 100%; width: 100%; font-family: 'Inter', sans-serif; box-sizing: border-box;">
      <div style="max-width: 600px; margin: 0 auto; background-color: white; border-radius: 16px; box-shadow: 0 10px 15px -3px rgba(0,0,0,0.05); overflow: hidden;">
        ${header}
        <div style="padding: 32px 24px; color: #1E293B; line-height: 1.6;">
          ${content}
        </div>
        ${footer}
      </div>
    </div>
  `;

  switch (data.template) {
    case "welcome":
      return {
        html: buildBody(`
          <h2 style="font-size: 20px; font-weight: 700; color: #0F172A; margin-top: 0;">Welcome to the Family, ${data.name || "User"}! 🎉</h2>
          <p>We are absolutely thrilled to have you join Smart Saoji. Our platform is built to help you run, grow, and optimize your business operations with maximum ease.</p>
          <p>Here are a few things you can do right away:</p>
          <ul style="padding-left: 20px; margin-bottom: 24px;">
            <li style="margin-bottom: 8px;"><strong>Manage Stock:</strong> Keep track of items, categories, and barcodes.</li>
            <li style="margin-bottom: 8px;"><strong>Record Transactions:</strong> Log sales, purchases, and track credit flow.</li>
            <li style="margin-bottom: 8px;"><strong>Generate Invoices:</strong> Create and print professional invoices instantly.</li>
          </ul>
          <div style="text-align: center; margin: 32px 0;">
            <a href="https://smartsaoji.com/dashboard" style="background-color: ${primaryColor}; color: white; padding: 14px 28px; text-decoration: none; border-radius: 12px; font-weight: 600; display: inline-block; box-shadow: 0 4px 6px -1px rgba(79, 70, 229, 0.2);">Go to Dashboard</a>
          </div>
          <p style="margin-bottom: 0;">If you ever have questions, don't hesitate to reach out. We are here to support your retail journey every step of the way!</p>
        `),
        text: `Welcome to Smart Saoji, ${data.name || "User"}!\n\nWe are thrilled to have you join us. Smart Saoji is built to help you run, grow, and optimize your retail business. Start managing stock, recording transactions, and generating invoices today.\n\nSupport contact: support@smartsaoji.com`,
      };

    case "subscription_submitted":
      return {
        html: buildBody(`
          <h2 style="font-size: 20px; font-weight: 700; color: #0F172A; margin-top: 0;">Subscription Request Received ⏳</h2>
          <p>Hi ${data.name || "User"},</p>
          <p>We have successfully received your request for the <strong>${(data.plan_name || "").toUpperCase()}</strong> plan upgrade.</p>
          <p>Our team is currently reviewing your payment screenshot. This process typically takes between <strong>1 to 4 hours</strong> during standard business hours.</p>
          <p>We will notify you immediately via email and push notification once your premium access is activated.</p>
          <p style="margin-bottom: 0;">Thank you for your patience!</p>
        `),
        text: `Hi ${data.name || "User"},\n\nWe have received your subscription upgrade request for the ${(data.plan_name || "").toUpperCase()} plan. Our team is currently verifying the payment screenshot. We will notify you once active.\n\nThank you!`,
      };

    case "admin_subscription_submitted":
      return {
        html: buildBody(`
          <h2 style="font-size: 20px; font-weight: 700; color: #D97706; margin-top: 0;">🚨 Action Required: New Payment Screenshot</h2>
          <p>A user has submitted a manual subscription request:</p>
          <table style="width: 100%; border-collapse: collapse; margin-bottom: 24px; font-size: 14px;">
            <tr style="border-bottom: 1px solid #E2E8F0;"><td style="padding: 8px 0; font-weight: 600;">User Name</td><td style="padding: 8px 0;">${data.user_name || "N/A"}</td></tr>
            <tr style="border-bottom: 1px solid #E2E8F0;"><td style="padding: 8px 0; font-weight: 600;">Email</td><td style="padding: 8px 0;">${data.user_email || "N/A"}</td></tr>
            <tr style="border-bottom: 1px solid #E2E8F0;"><td style="padding: 8px 0; font-weight: 600;">Plan</td><td style="padding: 8px 0; text-transform: uppercase; font-weight: 700; color: ${primaryColor};">${data.plan_name || "N/A"}</td></tr>
            <tr style="border-bottom: 1px solid #E2E8F0;"><td style="padding: 8px 0; font-weight: 600;">Submitted At</td><td style="padding: 8px 0;">${data.created_at || new Date().toISOString()}</td></tr>
          </table>
          <p>Please review the uploaded receipt in the admin portal to approve or reject the request.</p>
          <div style="text-align: center; margin: 32px 0;">
            <a href="https://smartsaoji.com/admin/subscriptions" style="background-color: #D97706; color: white; padding: 14px 28px; text-decoration: none; border-radius: 12px; font-weight: 600; display: inline-block;">Open Admin Panel</a>
          </div>
          <p><strong>Payment Proof Preview:</strong></p>
          <div style="text-align: center; border: 1px solid #E2E8F0; border-radius: 12px; padding: 8px; background-color: #F8FAFC;">
            <img src="${data.screenshot_url}" alt="Payment Proof" style="max-width: 100%; max-height: 350px; border-radius: 8px;" />
          </div>
        `),
        text: `New manual payment request submitted!\n\nUser: ${data.user_name} (${data.user_email})\nPlan: ${data.plan_name}\nScreenshot: ${data.screenshot_url}\n\nPlease verify in the admin panel.`,
      };

    case "subscription_approved":
      return {
        html: buildBody(`
          <h2 style="font-size: 22px; font-weight: 800; color: #10B981; margin-top: 0;">Subscription Approved! 🎉</h2>
          <p>Hi ${data.name || "User"},</p>
          <p>Congratulations! Your upgrade request to the <strong>${(data.plan_name || "").toUpperCase()}</strong> plan has been verified and approved.</p>
          <p>All premium features associated with this plan are now active and ready for use. Please restart or refresh the application to sync your updated membership status.</p>
          <div style="background-color: #F0FDF4; border: 1px solid #DCFCE7; border-radius: 12px; padding: 16px; margin: 24px 0; font-size: 14px; color: #15803D;">
            <strong>Active Plan:</strong> ${(data.plan_name || "").toUpperCase()} Plan<br/>
            <strong>Billing Cycle:</strong> Annual Membership
          </div>
          <p style="margin-bottom: 0;">Thank you for partnering with Smart Saoji to power your retail journey!</p>
        `),
        text: `Congratulations! Your ${(data.plan_name || "").toUpperCase()} plan subscription has been approved and is now active. Refresh the app to start using your premium features.`,
      };

    case "subscription_rejected":
      return {
        html: buildBody(`
          <h2 style="font-size: 20px; font-weight: 700; color: #EF4444; margin-top: 0;">Upgrade Request Notice ❌</h2>
          <p>Hi ${data.name || "User"},</p>
          <p>We were unable to approve your subscription request for the <strong>${(data.plan_name || "").toUpperCase()}</strong> plan.</p>
          <p><strong>Reason for rejection:</strong></p>
          <blockquote style="background-color: #FEF2F2; border-left: 4px solid #EF4444; padding: 12px 16px; margin: 20px 0; font-style: italic; color: #991B1B;">
            ${data.reason || "We could not verify the payment proof screenshot. Please make sure the transaction details match."}
          </blockquote>
          <p>You can resubmit your payment proof receipt anytime from the subscription screen in the app.</p>
          <div style="text-align: center; margin: 32px 0;">
            <a href="https://smartsaoji.com/subscription" style="background-color: #EF4444; color: white; padding: 14px 28px; text-decoration: none; border-radius: 12px; font-weight: 600; display: inline-block;">Resubmit Payment Proof</a>
          </div>
          <p style="margin-bottom: 0;">If you believe this was an error, please reply to this email or contact support.</p>
        `),
        text: `Your subscription request was rejected.\n\nReason: ${data.reason}\n\nPlease resubmit your payment receipt on the subscription screen.`,
      };

    case "upgrade_reminder":
      return {
        html: buildBody(`
          <h2 style="font-size: 20px; font-weight: 800; color: #0F172A; margin-top: 0;">🚀 Supercharge Your Retail Business</h2>
          <p>Hi ${data.name || "User"},</p>
          <p>Are you ready to take your shop operations to the next level? Upgrade to a premium plan today to unlock the full potential of Smart Saoji:</p>
          <table style="width: 100%; border-collapse: collapse; margin: 24px 0; font-size: 14px;">
            <tr style="border-bottom: 1px solid #F1F5F9;"><td style="padding: 10px 0; font-weight: bold; color: ${primaryColor};">✓ Barcode Scanning</td><td style="padding: 10px 0; color: #64748B;">Add/sell products in seconds using device camera.</td></tr>
            <tr style="border-bottom: 1px solid #F1F5F9;"><td style="padding: 10px 0; font-weight: bold; color: ${primaryColor};">✓ Thermal Printing</td><td style="padding: 10px 0; color: #64748B;">Connect via Bluetooth to print instant receipts.</td></tr>
            <tr style="border-bottom: 1px solid #F1F5F9;"><td style="padding: 10px 0; font-weight: bold; color: ${primaryColor};">✓ Business Staff Accounts</td><td style="padding: 10px 0; color: #64748B;">Delegate access to cashiers with custom roles.</td></tr>
            <tr style="border-bottom: 1px solid #F1F5F9;"><td style="padding: 10px 0; font-weight: bold; color: ${primaryColor};">✓ Advanced Reports</td><td style="padding: 10px 0; color: #64748B;">Analyze profits, stock velocity, and tax ledgers.</td></tr>
          </table>
          <div style="text-align: center; margin: 32px 0;">
            <a href="https://smartsaoji.com/subscription" style="background-color: ${primaryColor}; color: white; padding: 14px 28px; text-decoration: none; border-radius: 12px; font-weight: 600; display: inline-block;">View Pricing Plans</a>
          </div>
          <p style="margin-bottom: 0; font-size: 13px; color: #64748B;">You are receiving this reminder because you are currently using the Free plan. Upgrade to stop these alerts.</p>
        `),
        text: `Supercharge your business with Smart Saoji Premium!\n\nUnlock barcode scanning, thermal printing, staff management, and advanced reports. View plans: https://smartsaoji.com/subscription`,
      };

    case "expiry_reminder":
      return {
        html: buildBody(`
          <h2 style="font-size: 20px; font-weight: 700; color: #D97706; margin-top: 0;">⚠️ Action Required: Subscription Expiring</h2>
          <p>Hi ${data.name || "User"},</p>
          <p>This is a notice that your premium subscription is expiring in <strong>${data.days_left} day(s)</strong>.</p>
          <p>To avoid any disruption to your retail software services (including barcode scanning, thermal printing, and cashier staff management), please renew your membership before the expiration date.</p>
          <div style="text-align: center; margin: 32px 0;">
            <a href="https://smartsaoji.com/subscription" style="background-color: #D97706; color: white; padding: 14px 28px; text-decoration: none; border-radius: 12px; font-weight: 600; display: inline-block;">Renew Membership</a>
          </div>
          <p style="margin-bottom: 0;">If you have any questions or need billing assistance, reply directly to this email.</p>
        `),
        text: `Notice: Your Smart Saoji subscription expires in ${data.days_left} day(s). Please renew in the subscription section of the app to avoid service interruption.`,
      };

    default:
      return {
        html: `<p>Default Notification: ${JSON.stringify(data)}</p>`,
        text: `Default Notification: ${JSON.stringify(data)}`,
      };
  }
}

// ─── 5. SEND EMAIL FUNCTION (SMTP / NODEMAILER) ───────────────────
async function sendEmail(to: string, subject: string, templateData: EmailTemplateData) {
  if (!smtpHost || !smtpUser || !smtpPass) {
    console.error("SMTP Configurations are missing. Skipping email send.");
    throw new Error("SMTP Configurations are missing.");
  }

  const transporter = nodemailer.createTransport({
    host: smtpHost,
    port: smtpPort,
    secure: smtpPort === 465, // True for 465, false for 587
    auth: {
      user: smtpUser,
      pass: smtpPass,
    },
  });

  const rendered = renderHtmlTemplate(templateData);

  const mailOptions: Record<string, any> = {
    from: smtpFrom || smtpUser,
    to,
    subject,
    html: rendered.html,
    text: rendered.text,
  };

  // If this is an admin alert containing a payment screenshot, attach it!
  if (templateData.template === "admin_subscription_submitted" && templateData.screenshot_url) {
    try {
      const response = await fetch(templateData.screenshot_url);
      if (response.ok) {
        const arrayBuffer = await response.arrayBuffer();
        const buffer = new Uint8Array(arrayBuffer);
        mailOptions.attachments = [
          {
            filename: "payment_screenshot.jpg",
            content: buffer,
            contentType: "image/jpeg",
          },
        ];
      }
    } catch (err) {
      console.warn("Could not download attachment for email:", err);
    }
  }

  await transporter.sendMail(mailOptions);
  console.log(`Successfully sent email: "${subject}" to ${to}`);
}

// ─── 6. QUEUE PROCESSOR FUNCTION ─────────────────────────────────
async function processEmailQueue() {
  console.log("Processing pending email queue...");
  // Fetch up to 10 pending emails to avoid rate limits
  const { data: logs, error } = await supabase
    .from("email_logs")
    .select("*")
    .eq("status", "pending")
    .limit(10);

  if (error) {
    console.error("Error fetching email logs:", error);
    return { success: false, error };
  }

  console.log(`Found ${logs?.length || 0} pending email logs.`);
  let processed = 0;

  for (const log of logs || []) {
    try {
      let templateData: EmailTemplateData = { template: "default" };
      try {
        templateData = JSON.parse(log.body);
      } catch (_) {
        templateData = { template: "default", reason: log.body };
      }

      // 1. Send Email
      await sendEmail(log.email, log.subject, templateData);

      // Update log to sent
      await supabase
        .from("email_logs")
        .update({ status: "sent" })
        .eq("id", log.id);

      // 2. Dispatch corresponding Push Notification to devices if user_id exists
      if (log.user_id) {
        let pushTitle = log.subject;
        let pushBody = "";

        if (templateData.template === "welcome") {
          pushTitle = "Welcome to Smart Saoji! 🎉";
          pushBody = "Start managing stock and invoicing right now.";
        } else if (templateData.template === "subscription_submitted") {
          pushTitle = "Subscription Pending Verification ⏳";
          pushBody = `Your payment screenshot for the ${(templateData.plan_name || "").toUpperCase()} plan is being verified.`;
        } else if (templateData.template === "subscription_approved") {
          pushTitle = "Subscription Approved! 🎉";
          pushBody = `Your ${(templateData.plan_name || "").toUpperCase()} membership is now active!`;
        } else if (templateData.template === "subscription_rejected") {
          pushTitle = "Subscription Request Update ❌";
          pushBody = `Your upgrade request was rejected: ${templateData.reason}`;
        } else if (templateData.template === "upgrade_reminder") {
          pushTitle = "🚀 Grow Your Business";
          pushBody = "Upgrade to a premium plan to unlock barcode scanning and printing.";
        } else if (templateData.template === "expiry_reminder") {
          pushTitle = "⚠️ Subscription Expiring Soon";
          pushBody = `Your premium access will expire in ${templateData.days_left} day(s). Renew now.`;
        }

        if (pushBody) {
          await sendPushNotification(log.user_id, pushTitle, pushBody, {
            click_action: "FLUTTER_NOTIFICATION_CLICK",
            template: templateData.template,
          });
        }
      }

      processed++;
    } catch (err) {
      console.error(`Failed to process email log ${log.id}:`, err);
      // Update log to failed
      await supabase
        .from("email_logs")
        .update({
          status: "failed",
          error_message: err instanceof Error ? err.message : String(err),
        })
        .eq("id", log.id);
    }
  }

  return { success: true, processed };
}

// ─── 7. HTTP REQUEST ROUTER ──────────────────────────────────────
serve(async (req: Request) => {
  // Handle CORS Preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { action } = await req.json();

    if (action === "process_queue") {
      const result = await processEmailQueue();
      return new Response(JSON.stringify(result), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    return new Response(JSON.stringify({ error: "Invalid action" }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: err instanceof Error ? err.message : String(err) }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});
