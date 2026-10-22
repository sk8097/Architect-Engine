import os, re, subprocess

print("==> 1. Resolving Git rebase conflict...")
subprocess.run(["git", "rebase", "--abort"], check=False)
subprocess.run(["git", "checkout", "main"], check=False)

print("==> 2. Fixing MainAxisAlignment in all lib/ files...")
for root, _, files in os.walk("lib"):
    for file in files:
        if file.endswith(".dart"):
            filepath = os.path.join(root, file)
            with open(filepath, "r", encoding="utf-8") as f:
                content = f.read()
            if "MainAxisAlignment.between" in content:
                updated = content.replace("MainAxisAlignment.between", "MainAxisAlignment.spaceBetween")
                with open(filepath, "w", encoding="utf-8") as f:
                    f.write(updated)
                print(f"  Fixed MainAxisAlignment in {filepath}")

print("==> 3. Updating lib/screens/home_screen.dart constructor...")
home_path = "lib/screens/home_screen.dart"
if os.path.exists(home_path):
    with open(home_path, "r", encoding="utf-8") as f:
        code = f.read()
    
    # Make onNavigateTab optional
    code = code.replace("final Function(int) onNavigateTab;", "final Function(int)? onNavigateTab;")
    code = code.replace("required this.onNavigateTab", "this.onNavigateTab")
    
    # Safe null-aware calls
    code = re.sub(r'onNavigateTab\((\d+|[a-zA-Z0-9_]+)\)', r'onNavigateTab?.call(\1)', code)
    
    with open(home_path, "w", encoding="utf-8") as f:
        f.write(code)
    print("  lib/screens/home_screen.dart updated successfully.")

print("==> 4. Updating lib/main.dart...")
main_path = "lib/main.dart"
if os.path.exists(main_path):
    with open(main_path, "r", encoding="utf-8") as f:
        mcode = f.read()
    
    if "screens/main_scaffold.dart" not in mcode:
        mcode = "import 'screens/main_scaffold.dart';\n" + mcode
    
    mcode = mcode.replace("home: const HomeScreen(),", "home: const MainScaffold(),")
    
    with open(main_path, "w", encoding="utf-8") as f:
        f.write(mcode)
    print("  lib/main.dart updated to use MainScaffold.")

print("==> 5. Staging and committing changes...")
subprocess.run(["git", "add", "lib/"], check=False)
subprocess.run(["git", "commit", "-m", "fix: use MainAxisAlignment.spaceBetween and make onNavigateTab optional"], check=False)
res = subprocess.run(["git", "push", "origin", "main"], capture_output=True, text=True)
print(res.stdout)
if res.stderr:
    print(res.stderr)
print("==> All done!")
