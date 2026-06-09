# LoginApp · Java Login Application

```
┌──────────────────────┐   HTTP/JSON    ┌───────────────────────┐   JPA/SQL   ┌──────────┐
│  Frontend            │ ────────────► │  Backend (Spring Boot)  │ ─────────► │  MySQL   │
│  http://localhost:5500│ ◄──────────── │  http://localhost:8080  │ ◄───────── │ loginapp │
└──────────────────────┘               └───────────────────────┘              └──────────┘
```

> ⚠️ **Important:** Never open `index.html` by double-clicking or using `open frontend/index.html`.
> That loads it as `file://` which browsers treat as `origin: null`, breaking all API calls.
> Always serve the frontend through a local HTTP server (see Step 4).

---

## Prerequisites

| Tool    | Version |
|---------|---------|
| Java    | 21+     |
| Maven   | 3.9+    |
| MariaDB | 8.0+    |
| Python3 | any     |

Verify before starting:

```bash
java -version   # openjdk 21...
mvn -version    # Apache Maven 3.9...
mysql --version # mysql  Ver 8.0...
python3 --version # Python 3.x.x
```

---

## Step 1 — Set up the database

From your terminal (not the MySQL shell), run the schema:

```bash
mysql -u root -p < database/schema.sql
```

Verify it worked:

```bash
mysql -u root -p -e "USE loginapp; SELECT username, email, role FROM users;"
```

Expected output:

```
+----------+----------------------+-------+
| username | email                | role  |
+----------+----------------------+-------+
| admin    | admin@loginapp.local | ADMIN |
| demo     | demo@loginapp.local  | USER  |
+----------+----------------------+-------+
```

---

## Step 2 — Configure the backend

Open `backend/src/main/resources/application.properties` and update:

```properties
# Set your MySQL password
spring.datasource.password=your_mysql_password

# Generate a strong JWT secret and paste it here:
#   Mac/Linux: openssl rand -base64 32
#   Windows PowerShell: [Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Maximum 256 }))
app.jwt.secret=PASTE_YOUR_GENERATED_SECRET_HERE

# CORS: must match the address you use to open the frontend (Step 4)
app.cors.allowed-origins=http://localhost:5500,http://127.0.0.1:5500
```

**Do not change** `server.servlet.context-path=/api` — the frontend is already configured for it.

---

## Step 3 — Start the backend

```bash
cd backend
mvn spring-boot:run
```

```output
═══════════════════════════════════════
  LoginApp Backend  v1.0.0 · Aurora · 2026-04-21
═══════════════════════════════════════
...
Started LoginAppApplication in 3.4 seconds
```

Verify it's running (open a new terminal tab):

```bash
curl http://localhost:8080/api/auth/health
# → {"success":true,"message":"Service is running","data":null}

curl http://localhost:8080/api/auth/version
# → {"version":"1.0.0","full":"v1.0.0 · Seagull · 2026-05-08",...}
```

---

## Step 4 — Serve the frontend (REQUIRED — do not skip)

**You must serve `index.html` through HTTP, not by opening the file directly.**

Open a new terminal tab and run:

```bash
cd frontend
python3 -m http.server 5500
```

Then open your browser and go to:

```
http://localhost:5500
```

> ✅ Correct URL starts with `http://localhost:5500`
> ❌ Wrong: `file:///...` — this will always fail with CORS errors

---

## Step 5 — Log in

Use one of the demo accounts:

| Email                  | Password   | Role  |
|------------------------|------------|-------|
| admin@loginapp.local   | Admin@123  | ADMIN |
| demo@loginapp.local    | Admin@123  | USER  |

---

## How It All Fits Together

```
Browser opens http://localhost:5500
  └─ Python HTTP server serves index.html
       └─ JS calls http://localhost:8080/api/auth/login
            └─ Spring Boot processes login, returns JWT
                 └─ JS stores token in sessionStorage
```

### Why `file://` breaks everything

When you open a file directly (`file:///path/to/index.html`), the browser sets the request origin to `null`. Spring's CORS filter compares this against `allowed-origins` — `null` never matches, so every request is blocked before it reaches the controller. A Python HTTP server fixes this by giving the page a real `http://localhost:5500` origin.

### Why `requestMatchers` don't include `/api`

`server.servlet.context-path=/api` is handled by the servlet container before Spring Security sees the request. By the time Spring Security evaluates the path, `/api` is already stripped. So the correct matcher is `/auth/login`, not `/api/auth/login`.

---

## Troubleshooting

### "Cannot reach server. Try again." (CORS error in browser console)

Check the browser DevTools Console (F12) for the exact error.

**"origin 'null' has been blocked by CORS policy"**
→ You opened `index.html` as a file. Stop, go to Step 4, use the Python server.

**"No 'Access-Control-Allow-Origin' header"**
→ The origin in `application.properties` doesn't match. Confirm the address bar shows `http://localhost:5500` then set:
```properties
app.cors.allowed-origins=http://localhost:5500,http://127.0.0.1:5500
```
Restart the backend after changing this.

**"ERR_CONNECTION_REFUSED"**
→ Backend is not running. Go to Step 3.


---

### Port 8080 already in use

Find and kill the process:
```bash
# Mac / Linux
lsof -i :8080
kill -9 <PID>

# Or change the port in application.properties:
server.port=9090
```
If you change the port, also update `frontend/index.html`:
```javascript
const API = 'http://localhost:9090/api';
```

---

### Port 5500 already in use (Python server)

Use a different port:
```bash
python3 -m http.server 8081
```
Open `http://localhost:8081` and add it to CORS:
```properties
app.cors.allowed-origins=http://localhost:8081,http://127.0.0.1:8081
```

---

## API Reference

| Method | Endpoint             | Auth | Description       |
|--------|----------------------|------|-------------------|
| POST   | `/api/auth/login`    | None | Authenticate user |
| GET    | `/api/auth/version`  | None | App version       |
| GET    | `/api/auth/health`   | None | Health check      |

**Test login directly with curl:**

```bash
curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@loginapp.local","password":"Admin@123"}' | python3 -m json.tool
```

Expected response:
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "eyJhbGci...",
    "username": "admin",
    "email": "admin@loginapp.local",
    "fullName": "System Administrator",
    "role": "ADMIN",
    "expiresIn": 3600
  }
}
```
---
