// Vercel serverless function: privileged admin account operations.
//
// The MindKlass app itself only ever holds the public "anon" Supabase key,
// which is deliberately weak — real security comes from Row Level Security,
// not from keeping that key secret. Creating another person's login, or
// resetting their password, requires Supabase's Admin API, which in turn
// requires the *service role* key. That key must never reach the browser,
// so this endpoint is the one place it's allowed to live: it stays in a
// server-only environment variable, and every request here is re-checked
// against the database to confirm the caller is really an admin before it
// does anything.
//
// Setup required in the Vercel project (Settings -> Environment Variables):
//   SUPABASE_SERVICE_ROLE_KEY = the "service_role" secret key from
//   Supabase -> Project Settings -> API. Redeploy after adding it.

import { createClient } from "@supabase/supabase-js";

const SUPABASE_URL = "https://jozqiwlqektnvsbaqayt.supabase.co";

async function requireAdmin(req, admin){
  const authHeader = req.headers.authorization || "";
  const token = authHeader.replace(/^Bearer\s+/i, "").trim();
  if (!token) return { ok:false, status:401, error:"Missing session token." };

  const { data: callerData, error: callerErr } = await admin.auth.getUser(token);
  if (callerErr || !callerData?.user) return { ok:false, status:401, error:"Invalid or expired session — please sign in again." };

  const { data: callerProfile, error: profileErr } = await admin
    .from("profiles").select("role").eq("id", callerData.user.id).single();
  if (profileErr || callerProfile?.role !== "admin") {
    return { ok:false, status:403, error:"Only an administrator can do this." };
  }
  return { ok:true, callerId: callerData.user.id };
}

export default async function handler(req, res){
  if (req.method !== "POST"){
    res.status(405).json({ error:"Method not allowed." });
    return;
  }

  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!serviceKey){
    res.status(500).json({ error:"Server is missing SUPABASE_SERVICE_ROLE_KEY. Add it under the Vercel project's Environment Variables, then redeploy." });
    return;
  }

  const admin = createClient(SUPABASE_URL, serviceKey, { auth:{ autoRefreshToken:false, persistSession:false } });

  const auth = await requireAdmin(req, admin);
  if (!auth.ok){
    res.status(auth.status).json({ error: auth.error });
    return;
  }

  const body = req.body || {};
  const action = body.action;

  if (action === "createUser"){
    const { email, password, role, nick, name, subjects, department, regCode, refCode, country, currency, details } = body;
    if (!email || !password || !name){
      res.status(400).json({ error:"Name, email and password are required." });
      return;
    }
    if (String(password).length < 6){
      res.status(400).json({ error:"Password must be at least 6 characters." });
      return;
    }

    const { data: created, error: createErr } = await admin.auth.admin.createUser({
      email: String(email).trim(),
      password: String(password),
      email_confirm: true, // admin-created accounts skip the email-confirmation step
      user_metadata: { nick: nick || "", role: role || "student", country: country || "", currency: currency || "USD" },
    });
    if (createErr){
      res.status(400).json({ error: createErr.message || "Couldn't create the account." });
      return;
    }

    const newId = created.user.id;
    // The project's existing signup trigger creates the matching `profiles`
    // row automatically off of auth.users + the metadata above. Fill in the
    // rest of what the admin entered now that the row exists.
    const { error: updateErr } = await admin.from("profiles").update({
      role: role || "student",
      nick: nick || "",
      name: name || "",
      subjects: subjects || [],
      department: department || null,
      reg_code: regCode || null,
      ref_code: refCode || null,
      details: details || {},
    }).eq("id", newId);
    if (updateErr){
      // The login itself was created successfully even if this second step
      // hiccupped — say so rather than silently dropping the extra fields.
      res.status(200).json({ id:newId, warning:"Account created, but some profile details didn't save: " + updateErr.message });
      return;
    }

    res.status(200).json({ id:newId });
    return;
  }

  if (action === "resetPassword"){
    const { userId, newPassword } = body;
    if (!userId || !newPassword || String(newPassword).length < 6){
      res.status(400).json({ error:"A user and a new password (min 6 characters) are required." });
      return;
    }
    const { error: pwErr } = await admin.auth.admin.updateUserById(userId, { password:String(newPassword) });
    if (pwErr){
      res.status(400).json({ error: pwErr.message || "Couldn't reset that password." });
      return;
    }
    res.status(200).json({ ok:true });
    return;
  }

  res.status(400).json({ error:"Unknown action." });
}
