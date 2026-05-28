# RWFileManager

A runtime-injectable file manager dylib for iOS apps. Browse, edit, import, rename, and delete files within an app's sandbox — no jailbreak required.

## Features

- Browse the app's full sandbox directory
- Open and edit text files (`.txt`, `.json`, `.plist`, `.xml`, `.log`, `.yaml`, `.js`, `.html`, `.css`, `.m`, `.h`, `.swift`, `.py`, `.sh`, `.md`)
- Share/export any other file type via the system share sheet
- Import files into any directory via the document picker
- Swipe left on a file to delete it
- Swipe right on a file to rename it
- Long press a file to force-open it in the text editor

## Activation

Take a screenshot (**Power + Volume Up / Home + Power**) while inside the target app. The file manager will appear over the app.

Press **✕** (top-left) to dismiss.

## Screenshot

<img width="1125" height="2436" alt="IMG_1112" src="https://github.com/user-attachments/assets/ae0cebfb-13fe-40b4-8e4f-fc9ba327ff0f" />

## Building

Requirements:
- [Theos](https://theos.dev)
- iPhoneOS 16.5 SDK (place in `~/theos/sdks/`)

```bash
make clean && make
```

The built dylib will be at:
```
.theos/obj/debug/RWFileManager.dylib
```

## Injection

Inject `RWFileManager.dylib` into any IPA using a tool such as [KSign](https://github.com/34306/KSign), [Sideloadly](https://sideloadly.io), or similar. The dylib works on iOS 16 and later including iOS 26.

## Notes

- Only has access to the target app's sandbox — it cannot browse outside of it
- Works in Unity and other game engine apps since it uses a system-level screenshot trigger rather than touch gestures
