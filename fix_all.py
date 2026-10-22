import os, re, base64, subprocess

print("==> 1. Fixing all .dart files in lib/...")
fixed_files = []
for root, _, files in os.walk("lib"):
    for file in files:
        if file.endswith(".dart"):
            filepath = os.path.join(root, file)
            with open(filepath, "r", encoding="utf-8") as f:
                code = f.read()
            
            modified = False
            
            # Fix MainAxisAlignment.between -> MainAxisAlignment.spaceBetween
            if "MainAxisAlignment.between" in code:
                code = code.replace("MainAxisAlignment.between", "MainAxisAlignment.spaceBetween")
                modified = True
            
            # Fix HomeScreen constructor and calls
            if file == "home_screen.dart":
                code = code.replace("final Function(int) onNavigateTab;", "final Function(int)? onNavigateTab;")
                code = code.replace("required this.onNavigateTab", "this.onNavigateTab")
                code = re.sub(r'onNavigateTab\((\w+)\)', r'onNavigateTab?.call(\1)', code)
                modified = True
            
            if modified:
                with open(filepath, "w", encoding="utf-8") as f:
                    f.write(code)
                fixed_files.append(filepath)
                print(f"  Fixed: {filepath}")

print(f"==> Total files patched: {len(fixed_files)}")

# 2. Update base64 payloads inside fix_and_update.py & setup_project.py so they don't re-break
for script in ["fix_and_update.py", "setup_project.py"]:
    if os.path.exists(script):
        with open(script, "r", encoding="utf-8") as f:
            content = f.read()
        
        def update_b64(m):
            target = m.group(1)
            if os.path.exists(target):
                with open(target, "rb") as tf:
                    encoded = base64.b64encode(tf.read()).decode("ascii")
                return f'"{target}": "{encoded}"'
            return m.group(0)

        content = re.sub(r'\"(lib/[^\"]+\.dart)\":\s*\"[^\"]+\"', update_b64, content)
        with open(script, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"==> Updated embedded payloads in {script}")

# 3. Commit and push
print("==> 3. Committing and pushing to origin main...")
subprocess.run(["git", "add", "lib/", "fix_and_update.py"], check=False)
subprocess.run(["git", "commit", "-m", "fix: make HomeScreen.onNavigateTab optional and use MainAxisAlignment.spaceBetween across all screens"], check=False)
res = subprocess.run(["git", "push", "origin", "main"], capture_output=True, text=True)
print(res.stdout)
if res.stderr:
    print(res.stderr)
print("==> Finished! New GitHub Actions build triggered.")
