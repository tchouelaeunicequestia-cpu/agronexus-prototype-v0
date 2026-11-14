# Google Sign-In Setup

## Application flow

The Flutter client obtains a Google ID token with `google_sign_in` and sends it to:

```text
POST /api/v1/auth/google
```

The Spring Boot API verifies the token signature, issuer, expiration, verified-email claim, and audience against `GOOGLE_CLIENT_ID`. It then finds the account by Google's stable `sub` claim, or links a matching verified email to an existing account. New Google accounts are created as `BUYER` accounts and receive the normal AgroNexus JWT and refresh token response.

The API must never derive an identity from the raw token string. The `google_subject` column stores the stable Google subject identifier and is unique per account.

## Google Cloud configuration

1. Create or select a Google Cloud project.
2. Configure the OAuth consent screen.
3. Create an OAuth 2.0 **Web application** client. Use this client ID as the server client ID.
4. Configure an Android OAuth client for the exact Flutter Android application ID and each development/release SHA-1 certificate.
5. Configure a Web OAuth client and allowed origins if the Flutter web build is used.
6. Configure the same Web client ID in the backend:

```text
GOOGLE_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
```

7. The current prototype already contains the client ID in `frontend/web/index.html` and uses it as the default in the Flutter and backend configuration. For deployment, override it rather than relying on the repository default:

```text
flutter run --dart-define=GOOGLE_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
```

For Android, the generated `google-services.json` and the registered SHA-1 certificate must match the installed application. Do not commit credentials or OAuth client secrets to source control.

## Database migration

The JPA setting `ddl-auto: update` adds `google_subject` in development. Production deployments should apply the equivalent managed migration explicitly:

```sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS google_subject VARCHAR(255);
CREATE UNIQUE INDEX IF NOT EXISTS ux_users_google_subject
    ON users (google_subject)
    WHERE google_subject IS NOT NULL;
```

## Important limitations

Google authentication proves the Google account identity; it does not prove a user's agricultural role, phone number, national ID, or professional qualification. Google-created accounts therefore remain `BUYER` accounts until the normal AgroNexus verification and role-assignment process is completed.
