# Shipon Deployment Guide

This repository contains a React (Vite) frontend and an Express.js backend that power the Shipon application. The notes below explain how to configure the environment variables, run the project locally, and prepare it for production hosting.

## Repository structure

```
Shipon/
├── backend/   # Express.js API, session handling, MySQL, S3 + Coinbase integrations
└── frontend/  # React single-page application built with Vite
```

## Prerequisites

Before running either project you will need:

- Node.js 18+ and npm
- A MySQL instance that contains the Shipon schema
- An AWS S3 bucket (the current code expects a bucket named `shipon`)
- A Coinbase Commerce account for payment processing
- (Production) A reverse proxy such as Nginx or a platform that can expose both the API and the static frontend

## Backend setup (`backend/`)

1. Install dependencies:
   ```bash
   cd backend
   npm install
   ```
2. Copy `.env.example` to `.env` and fill in the values:

   | Variable | Purpose |
   | --- | --- |
   | `COINBASE_CLIENT` | Coinbase Commerce API key used to initialise the SDK. |
   | `CORS_HOST` | Fully-qualified origin that is allowed to call the API (for local dev use `http://localhost:5173`). |
   | `AWS_ACCESSKEYID` / `AWS_SECRETACCESSKEY` / `AWS_REGION` | AWS credentials for accessing the `shipon` S3 bucket that stores profile images. |
   | `SESSION_KEY` | Cookie key for the Express session (e.g. `userId`). |
   | `SESSION_SECRET` | Secret value used to sign the session cookie. |
   | `DB_HOST`, `DB_USERNAME`, `DB_PASSWORD`, `DB_DATABASE` | MySQL connection details. |
   | `COINBASE_WEBHOOK_SECRET` | Coinbase webhook signing secret (required to verify payment events). |
   | `PACKAGE_FEES` | Percentage fee deducted from package payments (e.g. `15` for 15%). |

3. Provision the MySQL schema the API expects. The repository ships with `backend/sql/schema.sql`, which creates all of the tables referenced in `backend/server.js`:
   ```bash
   # from the repository root
   mysql -u <user> -p<password> <database> < backend/sql/schema.sql
   ```
   Update the column defaults or constraints if you already have production data that differs from the starter layout.
4. Start the server:
   ```bash
   # Development (auto-reload via nodemon)
   npm run dev

   # Production
   npm start
   ```
   The API listens on port **5080** by default (or whatever you set in the `PORT` environment variable). Expose this port behind your reverse proxy or hosting provider and keep the process alive with a supervisor such as PM2, systemd, or your platform's process manager.
5. Configure Coinbase webhooks to point to `https://your-api.example.com/webhooks` and use the same signing secret you placed in `COINBASE_WEBHOOK_SECRET`.

## Frontend setup (`frontend/`)

1. Install dependencies:
   ```bash
   cd frontend
   npm install
   ```
2. Create a `.env` (or `.env.local`) file and provide the API endpoint that the frontend should call:
   ```env
   VITE_API_BASE_URL=http://localhost:5080
   ```
   Replace the value with the public URL of the backend when deploying to production.
3. Run the development server:
   ```bash
   npm run dev
   ```
   The app is available on [http://localhost:5173](http://localhost:5173) by default.
4. Build for production hosting:
   ```bash
   npm run build
   ```
   The static assets are emitted to `frontend/dist`. You can preview them locally with `npm run preview` or upload the `dist` folder to any static hosting service (S3, Vercel, Netlify, etc.). Ensure the deployment domain matches the `CORS_HOST` setting in the backend.

## Hosting recommendations

- **Single server deployment:**
  - Serve the backend on `https://api.yourdomain.com` (port 5080 internally).
  - Build the frontend and serve the `dist` folder via Nginx (or an object store + CDN) on `https://app.yourdomain.com`.
  - Update `CORS_HOST=https://app.yourdomain.com` and `VITE_API_BASE_URL=https://api.yourdomain.com`.
  - Configure HTTPS certificates for both domains and forward `/webhooks` from Coinbase to the backend.
- **Managed platforms:**
  - Deploy `backend/` to a Node-compatible service (Render, Railway, Heroku, etc.) that provides persistent environment variables and webhook endpoints.
  - Deploy `frontend/` to a static hosting provider. Supply `VITE_API_BASE_URL` at build time so the generated bundle knows where to send API requests.
- **Session handling:** Because the app relies on cookies (`withCredentials` is enabled in the Axios calls), ensure your hosting setup forwards cookies correctly and that the backend's session secret remains private.

With the environment variables configured and both services running, the application will be ready for live traffic.

## AWS deployment walkthrough

If you want an end-to-end setup on AWS without touching much code, the following sequence uses only managed services:

1. **Create the S3 bucket for uploaded assets**
   - In the AWS console go to S3 → “Create bucket”.
   - Use the bucket name `shipon` to avoid changing the hard-coded bucket reference inside `backend/server.js`. (If you prefer a different name, replace every occurrence of `'shipon'` in that file with your bucket name before deploying.)
   - Block all public access; the backend uploads objects with the correct ACLs when needed.
   - Under Permissions → Bucket policy allow the IAM user (created below) to access the bucket.

2. **Provision an IAM user for the backend**
   - IAM → Users → “Create user”. Enable programmatic access.
   - Attach the managed policy `AmazonS3FullAccess` temporarily, then replace it with a custom policy that only grants access to the `shipon` bucket.
   - Record the **Access key ID** and **Secret access key** – they populate `AWS_ACCESSKEYID` and `AWS_SECRETACCESSKEY` in the backend `.env`.

3. **Launch the MySQL database (Amazon RDS)**
   - RDS → “Create database” → Standard create → MySQL 8.x.
   - Choose the free tier template if eligible, otherwise pick the instance size that matches your workload.
   - Set the username/password you plan to reuse in `DB_USERNAME` / `DB_PASSWORD`.
   - Under Connectivity allow the backend security group to connect to port 3306.
   - After the instance is available, note the endpoint hostname for `DB_HOST` and import your schema/data with MySQL Workbench or the AWS Query Editor.

4. **Deploy the backend with Elastic Beanstalk**
   - Zip the contents of the `backend/` folder (you can run `npm install` locally first to verify the app builds, but do not include `node_modules` in the zip – Elastic Beanstalk installs dependencies during deployment).
   - In the AWS console go to Elastic Beanstalk → “Create application”. Choose “Node.js” on Amazon Linux 2023.
   - Upload the zipped backend as the application version. The default start command (`npm start`) uses `backend/package.json`.
   - Under Configuration → Software add the environment variables from `.env` (all variables listed in the table above plus `PORT` if you want to override the default). Elastic Beanstalk automatically injects `PORT`, so the updated server will bind to it.
   - Under Configuration → Networking allow inbound HTTPS/HTTP as required. Attach the same security group that can reach the RDS instance.
   - Once deployed, note the generated environment URL, e.g. `https://backend-env.eba-1234.us-east-1.elasticbeanstalk.com`.

5. **Set up Coinbase webhooks**
   - In Coinbase Commerce configure the webhook endpoint to point to your Elastic Beanstalk domain plus `/webhooks` (e.g. `https://backend-env.eba-1234.us-east-1.elasticbeanstalk.com/webhooks`).
   - Copy the signing secret into the `COINBASE_WEBHOOK_SECRET` environment variable in Elastic Beanstalk.

6. **Build and host the frontend on S3 + CloudFront**
   - In your local machine run:
     ```bash
     cd frontend
     npm install
     VITE_API_BASE_URL="https://<your-backend-domain>" npm run build
     ```
   - Create a second S3 bucket (for example `shipon-frontend`) and enable static website hosting or, preferably, create a CloudFront distribution with the bucket as the origin for HTTPS support.
   - Upload the contents of `frontend/dist` to the bucket (drag-and-drop in the console or use the AWS CLI).
   - If you use CloudFront, invalidate the cache whenever you deploy a new build.

7. **Wire up the domains and HTTPS**
   - Use Route 53 (or your DNS provider) to create `app.yourdomain.com` (pointing to CloudFront) and `api.yourdomain.com` (pointing to the Elastic Beanstalk load balancer).
   - Request SSL certificates from AWS Certificate Manager and attach them to CloudFront and the Elastic Beanstalk load balancer so both services run over HTTPS.
   - Update the backend `CORS_HOST` to the final frontend domain (`https://app.yourdomain.com`) and redeploy/apply the configuration changes.

8. **Final verification**
   - Open the frontend URL and confirm that login and data fetching work. Browser devtools → Network should show requests hitting the Elastic Beanstalk backend successfully with `Set-Cookie` headers present.
   - Create or update a record in the app that uploads files to verify the IAM credentials can read/write in S3.
   - Trigger a Coinbase payment in sandbox mode to ensure webhooks reach `/webhooks` on the backend.

At this point you have a fully managed AWS deployment: S3 handles both user uploads and the static frontend, RDS stores the relational data, Elastic Beanstalk runs the Express API, and CloudFront/Route 53 provide HTTPS endpoints for users.
