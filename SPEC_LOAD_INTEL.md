# Load Intel — Product Spec v1.2 (Build Target)

## 0) Summary
Load Intel is an offline-first iOS + Android app for logging ammo reloading recipes and range results (chrono + group size + target photos). Users:
1) Build Load recipes
2) Batch-select loads for a Range Test workflow
3) Enter bench data for each load (distance + firearm + FPS)
4) Only when all loads have bench data can they proceed Down Range
5) On Down Range they capture target photo(s), group size, per-load notes, then save result
6) Load History splits New Loads vs Tested Loads and sorts tested by caliber then best group

Monetization: Free users limited to 10 load recipes total; one-time lifetime unlock enables unlimited.

Platforms: iOS + Android.
Offline-first: Required (no network dependencies for core features).
Photos: Target photos saved to phone gallery album "Load Intel" and referenced by the app.

---

## 1) Visual Theme (Constraints)
- Primary accent: blaze/orange (app bars + primary CTAs)
- Secondary: bronze/brown (secondary buttons/tiles)
- Surfaces: warm tan/cream cards, rounded corners, heavier borders
- Home may have branded background image; other screens should be clean/tan surfaces
- Large readable typography, high contrast for outdoor sunlight

---

## 2) Navigation
Home screen has 3 large buttons:
- Build Load
- Range Test
- Load History

---

## 3) Core Data Model (Local DB)
### Firearm
- id (uuid)
- name (required)
- type enum: rifle | pistol | muzzleloader (required)

### LoadRecipe
- id (uuid)
- recipeName (required)
- cartridge (required)
- bulletBrand (optional)
- bulletWeightGr (optional number)
- bulletType (optional)
- brass (optional)
- primer (optional)
- powder (required)
- powderChargeGr (required number)
- coal (optional number) (UI shows no unit; implied inches)
- seatingDepth (optional number) (UI shows no unit; implied inches)
- notes (optional)
- firearmId (required)
- isDangerous (bool default false)
- dangerConfirmedAt (datetime nullable)
- createdAt, updatedAt

Derived:
- hasTestResults = exists RangeResult for this load

### RangeResult (Per load test instance)
- id (uuid)
- loadId (FK required)
- testedAt (datetime required)
- firearmId (FK required) (default from recipe but editable at bench)
- distanceYds (required number)
- fpsShots (array<number> optional; used in shot mode)
- avgFps (required if manual avg mode; computed if shot mode has >=2 shots)
- sdFps (optional; computed if shot mode has >=2 shots)
- esFps (optional; computed if shot mode has >=2 shots)
- groupSizeIn (required number)
- notes (string optional) (composed from Session Notes + Load Notes)
- createdAt, updatedAt

### TargetPhoto
- id (uuid)
- rangeResultId (FK)
- galleryUri/path (string)
- thumbPath (optional cached thumbnail)

### Inventory (schema only, UI later)
- id, type, name, qty, unit, notes

---

## 4) Screens & Behavior

### 4.1 Home
Three buttons: Build Load, Range Test, Load History.

### 4.2 Build Load (Create/Edit Recipe)
Fields:
- Recipe Name* (required)
- Cartridge* (required)
- Bullet Brand
- Bullet Weight (gr) (numeric keyboard)
- Bullet Type
- Brass
- Primer
- Powder* (required)
- Powder Charge (gr)* (required numeric)
- COAL (numeric, no unit label)
- Seating Depth (numeric, no unit label)
- Notes

Actions:
- Save (creates/updates recipe)
- Duplicate Load (creates new draft prefilled from current recipe)

Dangerous:
- Toggle "Mark Dangerous" prompts confirmation: “Mark this load as DANGEROUS?”
- If confirmed: isDangerous=true, set dangerConfirmedAt.

Paywall:
- Free tier max 10 recipes.
- If trying to save recipe #11: block save and show lifetime purchase modal.

### 4.3 Load History
Two sections:
- New Loads: recipes with no results
- Tested Loads: recipes with >=1 result

Tested Loads grouping/sorting:
- Group by cartridge
- Sort by BEST group size ascending

Expandable tiles:
Collapsed shows:
- Cartridge
- Bullet summary (brand/weight/type if present)
- Powder + charge
- Best group size (inches)
- Firearm
- Dangerous red-flag icon if isDangerous=true

Expanded shows:
- All collapsed info
- COAL + seating depth
- Best result summary: best group + date tested + avg/sd/es
- Thumbnail(s) from best result
- If dangerous: show text "DANGEROUS!"
- Edit recipe button -> Build Load
- Result actions: view/edit results (MVP can edit best result first)

Selection:
- New Loads multi-select
- When selected, show CTA "Range Test" -> opens Range Test with those loads pre-added

Filtering:
- Common filters visible: cartridge, firearm, powder, bullet weight
- Button/tab “More Filters” opens full filter sheet for all recipe + result fields

### 4.4 Range Test (Bench Workflow)
Purpose: keep selected loads together until tested; DO NOT save sessions. Only RangeResults are persisted.

Top: sideways scroll list of selected loads as flat expandable tiles.
- Each tile has Remove button (removes load from workflow)
- Add Loads button opens picker of New Loads (multi-select)

Required per-load bench inputs:
- Firearm picker (default from recipe)
- Distance (yds) numeric
- FPS entry must be valid by either of two modes:

FPS Mode A: Manual Summary
- avgFps (required)
- sdFps (optional)
- esFps (optional)

FPS Mode B: Shot-by-shot (progressive)
- shot1 field shown
- when shot1 entered -> show shot2
- when shot2 entered -> show shot3 (etc)
- once >=2 shots: compute avg/sd/es live
- store shots array + computed values

Switching modes prompts confirm: “Switching entry mode clears current FPS inputs.”

Shared "Session Notes" (applies to all loads in this workflow).

Down Range button rule:
- Down Range is DISABLED until ALL selected loads have bench-complete data:
  - firearm chosen
  - distance entered
  - FPS valid (Mode A avg present OR Mode B has at least 1 shot entered)
- remove button affects completeness evaluation.

### 4.5 Down Range (Per-load Result Entry)
Down Range is only reachable once all loads bench-complete.

User selects which load to record (from same tile strip).
Per-load inputs:
- Take target photo (camera)
- Add photo from gallery
- MULTIPLE photos allowed
- Group size (inches) numeric
- Load Notes (per-load)
Context:
- Show Session Notes read-only preview

On Save Result:
- Create RangeResult for that load (bench data + down-range data)
- Save photos to phone gallery album "Load Intel"
- Store photo references + optional thumb cache
- Compose notes:
  - If Session Notes exists: prefix "Session: ..."
  - If Load Notes exists: append "Load: ..."
- After save: mark that load complete; user can select next load
- When all loads saved: return to Load History (or show simple completion dialog then return)

---

## 5) Backup/Restore (Local)
Export a single backup file (zip or json):
- Firearms, LoadRecipes, RangeResults, Settings, Inventory
- Photo references only (no binary images)
Import:
- Replace-all local data (MVP)
- Warn before overwrite

---

## 6) Exports (MVP)
- CSV/Excel:
  - Loads.csv
  - Results.csv
- PDF per-load report:
  - recipe summary
  - best result summary
  - dangerous status
  - thumbnails if accessible

---

## 7) Purchase
- One-time lifetime unlock removes 10-load limit
- Gate only creation of new recipes over limit; existing data remains accessible.
