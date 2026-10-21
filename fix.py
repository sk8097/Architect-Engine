import os

for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            p = os.path.join(root, file)
            with open(p, 'r', encoding='utf-8') as f:
                c = f.read()
            if 'MainAxisAlignment.between' in c:
                c = c.replace('MainAxisAlignment.between', 'MainAxisAlignment.spaceBetween')
                with open(p, 'w', encoding='utf-8') as f:
                    f.write(c)

pp = os.path.join('lib', 'providers', 'project_provider.dart')
if os.path.exists(pp):
    with open(pp, 'r', encoding='utf-8') as f:
        c = f.read()
    c = c.replace('.findIndex(', '.indexWhere(')
    with open(pp, 'w', encoding='utf-8') as f:
        f.write(c)

pfd = os.path.join('lib', 'screens', 'project_form_dialog.dart')
if os.path.exists(pfd):
    with open(pfd, 'r', encoding='utf-8') as f:
        c = f.read()
    c = c.replace('($bhk,', '($_bhk,')
    with open(pfd, 'w', encoding='utf-8') as f:
        f.write(c)

for s in ['share_screen.dart', 'about_screen.dart', 'privacy_policy_screen.dart']:
    sp = os.path.join('lib', 'screens', s)
    with open(sp, 'w', encoding='utf-8') as f:
        f.write("export 'export_screen.dart';\n")

print("Sabhi errors theek ho gaye!")
