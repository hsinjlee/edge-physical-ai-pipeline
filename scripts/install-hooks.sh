#!/bin/sh
hook=".git/hooks/pre-commit"
cat > "$hook" <<'HOOK'
#!/bin/sh
email=$(git config user.email)
if [ "$email" != "rlee4408@gmail.com" ]; then
  echo "BLOCKED: wrong git identity for this repo ($email)"
  exit 1
fi
HOOK
chmod +x "$hook"
echo "hook installed"
