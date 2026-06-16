# Custom fonts — drop the .ttf files here

The typography system (`Resources/Font+DearBella.swift`) and the `UIAppFonts`
entries in `Info.plist` are already set up. They expect these **exact filenames**
in this folder. Until the files are here, the app falls back to the system font
(it still builds and runs).

## Files to add

Download from Google Fonts (both SIL Open Font License, free):

**DM Serif Display** — https://fonts.google.com/specimen/DM+Serif+Display
- `DMSerifDisplay-Regular.ttf`
- `DMSerifDisplay-Italic.ttf`

**Inter** — https://fonts.google.com/specimen/Inter
Use the **static** instances (in the download's `static/` subfolder), not the
variable font:
- `Inter-Regular.ttf`
- `Inter-Medium.ttf`
- `Inter-SemiBold.ttf`
- `Inter-Bold.ttf`

## Where to put them

Copy all six `.ttf` files into this folder
(`DearBella/Resources/Fonts/`). Because the project uses Xcode's synchronized
folders, they'll be picked up automatically — then **verify** they appear under
**Target → Build Phases → Copy Bundle Resources**.

## If a font doesn't render

`Font.custom` matches on the **PostScript name**, which usually equals the
filename without `.ttf`. If a weight looks wrong, open the file in **Font Book**,
check its PostScript name, and update the matching constant in
`Font+DearBella.swift`. To list every registered font name at runtime, drop this
in temporarily:

```swift
for family in UIFont.familyNames.sorted() {
    print(family, UIFont.fontNames(forFamilyName: family))
}
```
