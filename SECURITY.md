# Security Policy

## Reporting Security Vulnerabilities

If you discover a security vulnerability in IntentOS Mobile, please **do not** open a public issue.

Instead, please email: varmaakshay1995@gmail.com

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

We will investigate and respond promptly.

## Supported Versions

| Version | Status | Support Until |
|---------|--------|---------------|
| 1.0.x   | Active | Current       |

## Security Best Practices

When using IntentOS Mobile:

1. **Always validate backend URLs** - Only connect to trusted backends
2. **Use HTTPS** - Never send data over unencrypted connections
3. **Secure bearer tokens** - Store tokens securely in Keychain
4. **Limit permissions** - Only request necessary microphone/screen access
5. **Audit actions** - Review what actions the app can execute

## Known Security Considerations

- Screen capture data is Base64 encoded but not encrypted before sending to backend
- Action execution happens after backend decision — trust your backend
- Microphone access requires explicit user permission (iOS enforces this)

## Updates

Keep IntentOS Mobile updated for the latest security patches.
