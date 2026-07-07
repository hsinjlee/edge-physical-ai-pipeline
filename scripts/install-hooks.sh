#!/bin/sh
hook=".git/hooks/pre-commit"
cat > "$hook" <<'HOOK'
#!/bin/sh
email=$(git config user.email)
case "$email" in
  *redacted*|*Redacted*) echo "BLOCKED: work email on personal repo"; exit 1;;
esac
HOOK
chmod +x "$hook"
echo "hook installed"
